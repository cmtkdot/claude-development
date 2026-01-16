#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# STOP HOOK TEMPLATE
# ═══════════════════════════════════════════════════════════════════════════════
#
# Hook Name: [YOUR_HOOK_NAME]
# Description: [What this hook checks when Claude finishes responding]
# Author: [Your name]
# Created: [Date]
#
# ═══════════════════════════════════════════════════════════════════════════════
# EVENT: Stop
# ═══════════════════════════════════════════════════════════════════════════════
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ CAPABILITIES                                                                │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │ [ ] Matcher supported     - NO matcher; runs when Claude stops              │
# │ [x] Can block (continue)  - exit 2 or decision: "block" forces continue     │
# │ [ ] Can modify input      - NO input modification                           │
# │ [x] Can inject context    - stderr sent to Claude on exit 2                 │
# │ [x] Runs on stop          - Runs when Claude finishes responding            │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ PLANNING QUESTIONS (from SKILL.md)                                          │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │ [ ] Should this check if tasks are complete before allowing stop?           │
# │ [ ] Should this auto-lint/format before stopping?                           │
# │ [ ] Should this validate tests pass before stopping?                        │
# │ [ ] Should this use prompt type (LLM) for intelligent completion check?     │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ HOOK TYPES                                                                  │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │ type: "command" - Deterministic check (fast, bash script)                   │
# │ type: "prompt"  - LLM evaluation (slower, context-aware) - Stop ONLY!       │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ═══════════════════════════════════════════════════════════════════════════════
# EXIT CODES (Stop-specific)
# ═══════════════════════════════════════════════════════════════════════════════
#
# │ Code │ Behavior                                                             │
# │──────│─────────────────────────────────────────────────────────────────────│
# │  0   │ Allow stop; stdout/stderr not shown                                 │
# │  1   │ Allow stop; stderr logged                                           │
# │  2   │ FORCE CONTINUE; stderr sent to Claude as "why continue"             │
# │ 3+   │ Allow stop; stderr shown to user                                    │
#
# ⚠️  IMPORTANT: Check stop_hook_active to prevent infinite loops!
#
# ═══════════════════════════════════════════════════════════════════════════════
# RESPONSE PATTERNS (check ONE primary behavior)
# ═══════════════════════════════════════════════════════════════════════════════
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ RESPONSE BEHAVIOR (pick one)                                                │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │ [ ] Allow stop            - return_silent or exit 0                         │
# │ [ ] Force continue        - exit 2 + echo "reason" >&2                      │
# │ [ ] Force continue (JSON) - decision: "block" + reason                      │
# │ [ ] Conditional continue  - Check condition, then exit 2 if not met         │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ═══════════════════════════════════════════════════════════════════════════════
# JSON OUTPUT SCHEMA
# ═══════════════════════════════════════════════════════════════════════════════
#
# {
#   "decision": "block",                   // Force Claude to continue
#   "reason": "Why Claude shouldn't stop yet"
# }
#
# ═══════════════════════════════════════════════════════════════════════════════
# INPUT PAYLOAD (stdin JSON)
# ═══════════════════════════════════════════════════════════════════════════════
#
# {
#   "hook_event_name": "Stop",
#   "session_id": "abc123",
#   "stop_hook_active": false              // ← TRUE if already continuing from hook
# }
#
# ⚠️  ALWAYS check stop_hook_active! If true, don't force continue again.
#
# ═══════════════════════════════════════════════════════════════════════════════
# SETTINGS.JSON WIRING
# ═══════════════════════════════════════════════════════════════════════════════
#
# # Command type (deterministic)
# {
#   "hooks": {
#     "Stop": [{
#       "hooks": [{
#         "type": "command",
#         "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/utils/stop/YOUR_HOOK.sh",
#         "timeout": 30
#       }]
#     }]
#   }
# }
#
# # Prompt type (LLM evaluation) - Stop/SubagentStop ONLY
# {
#   "hooks": {
#     "Stop": [{
#       "hooks": [{
#         "type": "prompt",
#         "prompt": "Evaluate if Claude should stop: $ARGUMENTS. Are all tasks complete?",
#         "timeout": 30
#       }]
#     }]
#   }
# }
#
# ═══════════════════════════════════════════════════════════════════════════════
# IMPLEMENTATION CHECKLIST
# ═══════════════════════════════════════════════════════════════════════════════
#
# - [ ] settings.json: Stop wiring (no matcher)
# - [ ] Tests added under .claude/hooks/tests/
# - [ ] CHANGELOG.md updated if behavior changes
# - [ ] CRITICAL: Check stop_hook_active to prevent infinite loops
#
# ═══════════════════════════════════════════════════════════════════════════════
# IMPLEMENTATION
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# CONFIG
# ─────────────────────────────────────────────────────────────────────────────

# shellcheck disable=SC2034  # Used as base path reference in templates
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../" && pwd)}"

# ─────────────────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────────────────

json_get() { echo "$1" | jq -r "$2 // empty" 2>/dev/null; }

payload="$(cat)"

# ─── Parse Input ──────────────────────────────────────────────────────────────
stop_hook_active="$(json_get "$payload" ".stop_hook_active")"

# ═══════════════════════════════════════════════════════════════════════════════
# YOUR HOOK LOGIC HERE
# ═══════════════════════════════════════════════════════════════════════════════

# ─── CRITICAL: Prevent infinite loops ─────────────────────────────────────────
if [[ $stop_hook_active == "true" ]]; then
	exit 0 # Already continuing from a previous hook; allow stop
fi

# ─── Example: Force continue if lint errors exist ─────────────────────────────
# lint_errors=$(pnpm lint:check 2>&1 || true)
# if [[ "$lint_errors" == *"error"* ]]; then
#   echo "Lint errors detected. Please fix before stopping." >&2
#   exit 2
# fi

# ─── Example: Force continue if tests fail ────────────────────────────────────
# if ! pnpm test:run --passWithNoTests 2>/dev/null; then
#   echo "Tests are failing. Please fix before stopping." >&2
#   exit 2
# fi

# ─── Example: Force continue with JSON ────────────────────────────────────────
# if [[ -f /tmp/incomplete-tasks ]]; then
#   jq -n '{
#     decision: "block",
#     reason: "Incomplete tasks detected. Please complete them first."
#   }'
#   exit 0
# fi

# ─── Default: allow stop ──────────────────────────────────────────────────────
exit 0
