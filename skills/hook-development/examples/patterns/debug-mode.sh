#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# Debug Mode Pattern
#
# Enable verbose logging and debugging for hooks.
#
# Usage:
#   export CLAUDE_HOOK_DEBUG=1
#   # or set in SessionStart hook:
#   echo "CLAUDE_HOOK_DEBUG=1" >> "$CLAUDE_ENV_FILE"
# ═══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

# ─── DEBUG CONFIG ───────────────────────────────────────────────────────────
DEBUG="${CLAUDE_HOOK_DEBUG:-0}"
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../" && pwd)}"
LOG_FILE="$PROJECT_ROOT/.claude/hooks/logs/debug.log"

# ─── DEBUG HELPERS ──────────────────────────────────────────────────────────

# Log only when debug mode is enabled
debug_log() {
  if [[ "$DEBUG" == "1" ]]; then
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S.%3N')
    echo "[$timestamp] [DEBUG] $*" >> "$LOG_FILE"
  fi
}

# Log payload (redacting sensitive fields)
debug_payload() {
  if [[ "$DEBUG" == "1" ]]; then
    local payload="$1"
    # Redact potential secrets
    local redacted
    redacted=$(echo "$payload" | jq '
      walk(if type == "string" and (test("password|secret|token|key|auth"; "i"))
           then "***REDACTED***"
           else . end)
    ' 2>/dev/null || echo "$payload")
    debug_log "Payload: $redacted"
  fi
}

# Log timing
debug_timing() {
  if [[ "$DEBUG" == "1" ]]; then
    local start_time="$1"
    local end_time
    end_time=$(date +%s%N)
    local duration_ms=$(( (end_time - start_time) / 1000000 ))
    debug_log "Duration: ${duration_ms}ms"
  fi
}

# ─── HELPERS ────────────────────────────────────────────────────────────────
json_get() { echo "$1" | jq -r "$2 // empty" 2>/dev/null; }

# ─── MAIN ───────────────────────────────────────────────────────────────────
START_TIME=$(date +%s%N)

debug_log "Hook started: $(basename "$0")"

payload="$(cat)"
debug_payload "$payload"

tool_name=$(json_get "$payload" ".tool_name")
hook_event=$(json_get "$payload" ".hook_event_name")

debug_log "tool_name=$tool_name, hook_event=$hook_event"

# Fast-path exit for non-matching cases
if [[ "$tool_name" != "Bash" ]]; then
  debug_log "Fast exit: non-matching tool"
  exit 0
fi

# ─── YOUR LOGIC HERE ────────────────────────────────────────────────────────
command=$(json_get "$payload" ".tool_input.command")
debug_log "command=$command"

# Example validation
if [[ "$command" == *"rm -rf /"* ]]; then
  debug_log "BLOCKED: dangerous command"
  jq -n --arg event "$hook_event" '{
    hookSpecificOutput: {
      hookEventName: $event,
      permissionDecision: "deny",
      permissionDecisionReason: "Dangerous command blocked"
    },
    systemMessage: "🚫 Blocked dangerous command"
  }'
  debug_timing "$START_TIME"
  exit 2
fi

debug_log "ALLOWED: command passed validation"

# ─── OUTPUT ─────────────────────────────────────────────────────────────────
jq -n --arg event "$hook_event" '{
  hookSpecificOutput: {
    hookEventName: $event,
    permissionDecision: "allow"
  },
  systemMessage: "✅ Validated"
}'

debug_timing "$START_TIME"
exit 0


# ═══════════════════════════════════════════════════════════════════════════════
# DEBUGGING TIPS
# ═══════════════════════════════════════════════════════════════════════════════
#
# 1. Enable debug mode:
#    export CLAUDE_HOOK_DEBUG=1
#
# 2. Check logs:
#    tail -f .claude/hooks/logs/debug.log
#
# 3. Test hook manually:
#    echo '{"tool_name":"Bash","hook_event_name":"PreToolUse","tool_input":{"command":"echo hi"}}' \
#      | CLAUDE_HOOK_DEBUG=1 bash .claude/hooks/utils/preToolUse/your-hook.sh
#
# 4. Validate JSON output:
#    echo '...' | bash your-hook.sh | jq empty
#
# 5. Check exit codes:
#    echo '...' | bash your-hook.sh; echo "Exit code: $?"
#
# 6. Performance profiling:
#    time (echo '...' | bash your-hook.sh)
#
# 7. Trace execution:
#    bash -x your-hook.sh
