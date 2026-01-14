#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# SESSIONEND HOOK TEMPLATE
# ═══════════════════════════════════════════════════════════════════════════════
#
# Hook Name: [YOUR_HOOK_NAME]
# Description: [What this hook does on session end - cleanup/logging]
# Author: [Your name]
# Created: [Date]
#
# ═══════════════════════════════════════════════════════════════════════════════
# EVENT: SessionEnd
# ═══════════════════════════════════════════════════════════════════════════════
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ CAPABILITIES                                                                │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │ [ ] Matcher supported     - NO matcher; runs on ALL session ends            │
# │ [ ] Can block             - NO blocking; session will end                   │
# │ [ ] Can modify input      - NO input modification                           │
# │ [ ] Can inject context    - NO context injection (session ending)           │
# │ [x] Runs on end           - Runs when session terminates                    │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ PLANNING QUESTIONS                                                          │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │ [ ] Should this clean up temporary files?                                   │
# │ [ ] Should this log session metrics?                                        │
# │ [ ] Should this commit pending changes?                                     │
# │ [ ] Should this behave differently by end reason?                           │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ SESSION END REASONS                                                         │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │ "clear"            - Session cleared with /clear command                    │
# │ "logout"           - User logged out                                        │
# │ "prompt_input_exit"- User exited while prompt input was visible             │
# │ "other"            - Other exit reasons                                     │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ═══════════════════════════════════════════════════════════════════════════════
# EXIT CODES (SessionEnd-specific)
# ═══════════════════════════════════════════════════════════════════════════════
#
# │ Code │ Behavior                                                             │
# │──────│─────────────────────────────────────────────────────────────────────│
# │  0   │ Success; session ends normally                                      │
# │  1   │ stderr shown to user; session ends                                  │
# │  2   │ stderr shown to user ONLY; session ends                             │
# │ 3+   │ stderr shown to user; session ends                                  │
#
# ⚠️  Cannot prevent session end; hook is for cleanup/logging only
#
# ═══════════════════════════════════════════════════════════════════════════════
# RESPONSE PATTERNS
# ═══════════════════════════════════════════════════════════════════════════════
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ RESPONSE BEHAVIOR (pick one)                                                │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │ [ ] Silent                - return_silent (hook doesn't apply)              │
# │ [ ] Cleanup files         - Remove temp files, reset state                  │
# │ [ ] Log session metrics   - Write to log file                               │
# │ [ ] User notification     - echo "message" (shown on exit)                  │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ═══════════════════════════════════════════════════════════════════════════════
# INPUT PAYLOAD (stdin JSON)
# ═══════════════════════════════════════════════════════════════════════════════
#
# {
#   "hook_event_name": "SessionEnd",
#   "session_id": "abc123",
#   "reason": "prompt_input_exit"           // ← clear|logout|prompt_input_exit|other
# }
#
# ═══════════════════════════════════════════════════════════════════════════════
# SETTINGS.JSON WIRING
# ═══════════════════════════════════════════════════════════════════════════════
#
# {
#   "hooks": {
#     "SessionEnd": [{
#       "hooks": [{
#         "type": "command",
#         "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/utils/sessionEnd/YOUR_HOOK.sh",
#         "timeout": 10
#       }]
#     }]
#   }
# }
#
# ═══════════════════════════════════════════════════════════════════════════════
# IMPLEMENTATION CHECKLIST
# ═══════════════════════════════════════════════════════════════════════════════
#
# - [ ] settings.json: SessionEnd wiring (no matcher)
# - [ ] Tests added under .claude/hooks/tests/
# - [ ] CHANGELOG.md updated if behavior changes
# - [ ] Keep execution fast (user is waiting to exit)
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
# shellcheck disable=SC2034  # Variables for template customization
reason="$(json_get "$payload" ".reason")"

# ═══════════════════════════════════════════════════════════════════════════════
# YOUR HOOK LOGIC HERE
# ═══════════════════════════════════════════════════════════════════════════════

# ─── Example: Cleanup temporary files ─────────────────────────────────────────
# rm -f /tmp/claude-session-* 2>/dev/null || true

# ─── Example: Log session end ─────────────────────────────────────────────────
# log_info "Session ended: reason=$reason"

# ─── Example: Auto-commit on clean exit ───────────────────────────────────────
# if [[ "$reason" == "prompt_input_exit" ]]; then
#   if git diff --quiet 2>/dev/null; then
#     : # No changes
#   else
#     echo "Uncommitted changes detected. Remember to commit!"
#   fi
# fi

# ─── Example: Different behavior by reason ────────────────────────────────────
# case "$reason" in
#   "clear")
#     log_info "Session cleared"
#     ;;
#   "logout")
#     log_info "User logged out"
#     ;;
#   "prompt_input_exit")
#     log_info "Normal exit"
#     ;;
# esac

# ─── Default: pass-through ────────────────────────────────────────────────────
exit 0
