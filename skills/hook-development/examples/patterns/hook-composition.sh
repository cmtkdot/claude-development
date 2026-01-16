#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# Hook Composition Patterns
#
# When multiple hooks are configured for the same event/matcher, they execute
# sequentially. If any hook exits 2, execution stops and the tool is blocked.
#
# This file documents patterns for composing hooks effectively.
# ═══════════════════════════════════════════════════════════════════════════════

# ─────────────────────────────────────────────────────────────────────────────
# PATTERN 1: SEQUENTIAL MULTI-STAGE VALIDATION
# ─────────────────────────────────────────────────────────────────────────────
#
# Configure in settings.json:
# {
#   "hooks": {
#     "PreToolUse": [
#       {
#         "matcher": "Bash",
#         "hooks": [
#           {"type": "command", "command": "bash ...01-syntax-check.sh", "timeout": 5},
#           {"type": "command", "command": "bash ...02-security-check.sh", "timeout": 10},
#           {"type": "command", "command": "bash ...03-policy-check.sh", "timeout": 15}
#         ]
#       }
#     ]
#   }
# }
#
# Execution order:
# 1. 01-syntax-check.sh runs first
# 2. If exit 0, 02-security-check.sh runs
# 3. If exit 0, 03-policy-check.sh runs
# 4. If any exits 2, execution stops and tool is blocked


# ─────────────────────────────────────────────────────────────────────────────
# PATTERN 2: SHARED STATE BETWEEN HOOKS
# ─────────────────────────────────────────────────────────────────────────────
#
# Hooks can share state through files. Use PID-based files for isolation.

# First hook: Save state
# .claude/hooks/utils/preToolUse/01-analyze.sh
cat > /dev/null << 'FIRST_HOOK'
#!/usr/bin/env bash
set -euo pipefail

payload="$(cat)"
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/hooks/.hook-state-$$"

# Analyze and compute score
complexity_score=75

# Save state for next hook
jq -n --arg score "$complexity_score" '{
  complexity_score: ($score | tonumber),
  timestamp: now
}' > "$STATE_FILE"

exit 0
FIRST_HOOK

# Second hook: Read state
# .claude/hooks/utils/preToolUse/02-validate.sh
cat > /dev/null << 'SECOND_HOOK'
#!/usr/bin/env bash
set -euo pipefail

payload="$(cat)"
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/hooks/.hook-state-$$"
hook_event=$(echo "$payload" | jq -r '.hook_event_name // "PreToolUse"')

# Load state from previous hook
if [[ -f "$STATE_FILE" ]]; then
  complexity=$(jq -r '.complexity_score' "$STATE_FILE")

  # Adjust validation based on complexity
  if [[ $complexity -gt 80 ]]; then
    # Stricter checks for complex operations
    jq -n --arg event "$hook_event" '{
      hookSpecificOutput: {
        hookEventName: $event,
        additionalContext: "High complexity detected - applying strict validation"
      }
    }'
  fi

  # Cleanup state file
  rm -f "$STATE_FILE"
fi

exit 0
SECOND_HOOK


# ─────────────────────────────────────────────────────────────────────────────
# PATTERN 3: CONDITIONAL HOOK CHAINS
# ─────────────────────────────────────────────────────────────────────────────
#
# Use environment variables to enable/disable hook chains.

# First hook sets a flag:
cat > /dev/null << 'FLAG_SETTER'
#!/usr/bin/env bash
set -euo pipefail

payload="$(cat)"
command=$(echo "$payload" | jq -r '.tool_input.command // ""')

# If command looks risky, set flag for deep scan
if [[ "$command" =~ (sudo|chmod|chown|rm) ]]; then
  echo "HOOK_REQUIRE_DEEP_SCAN=1" >> "$CLAUDE_ENV_FILE"
fi

exit 0
FLAG_SETTER

# Second hook checks the flag:
cat > /dev/null << 'FLAG_CHECKER'
#!/usr/bin/env bash
set -euo pipefail

# Only run if previous hook set this flag
if [[ "${HOOK_REQUIRE_DEEP_SCAN:-}" != "1" ]]; then
  exit 0
fi

# Perform deep security scan
# ...

exit 0
FLAG_CHECKER


# ─────────────────────────────────────────────────────────────────────────────
# PATTERN 4: TELEMETRY AGGREGATION
# ─────────────────────────────────────────────────────────────────────────────
#
# Multiple hooks can write to a shared telemetry file.

cat > /dev/null << 'TELEMETRY'
#!/usr/bin/env bash
set -euo pipefail

payload="$(cat)"
TELEMETRY_FILE="${CLAUDE_PROJECT_DIR}/.claude/hooks/telemetry.jsonl"

# Each hook appends its metrics
jq -n --arg hook "$(basename "$0")" \
      --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      --arg duration_ms "$(($(date +%s%N) - START_TIME))" '{
  hook: $hook,
  timestamp: $timestamp,
  duration_ms: ($duration_ms | tonumber / 1000000)
}' >> "$TELEMETRY_FILE"

exit 0
TELEMETRY


# ─────────────────────────────────────────────────────────────────────────────
# BEST PRACTICES
# ─────────────────────────────────────────────────────────────────────────────
#
# 1. Name hooks with numeric prefixes for clear ordering: 01-, 02-, 03-
# 2. Keep each hook focused on one responsibility
# 3. Use state files with PID suffix for isolation: .hook-state-$$
# 4. Clean up state files after use
# 5. Set reasonable timeouts for each stage
# 6. Use environment variables for simple flags
# 7. Use state files for complex data
