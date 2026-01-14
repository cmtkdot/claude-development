#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# NOTIFICATION HOOK TEMPLATE
# ═══════════════════════════════════════════════════════════════════════════════
#
# Hook Name: [YOUR_HOOK_NAME]
# Description: [What this hook does with notifications]
# Author: [Your name]
# Created: [Date]
#
# ═══════════════════════════════════════════════════════════════════════════════
# EVENT: Notification
# ═══════════════════════════════════════════════════════════════════════════════
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ CAPABILITIES                                                                │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │ [x] Matcher supported     - Filter by notification_type (not tool_name)     │
# │ [ ] Can block             - NO blocking; notification will proceed          │
# │ [ ] Can modify input      - NO input modification                           │
# │ [ ] Can inject context    - NO context injection                            │
# │ [x] Runs on notification  - Runs when Claude sends a notification           │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ PLANNING QUESTIONS                                                          │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │ [ ] Should this provide custom notification handling (sound, popup)?        │
# │ [ ] Should this log notifications for analysis?                             │
# │ [ ] Should this filter by notification type?                                │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ NOTIFICATION TYPES (use as matcher)                                         │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │ "permission_prompt"   - Permission request dialog                           │
# │ "idle_prompt"         - Claude waiting for input (60+ seconds)              │
# │ "auth_success"        - Authentication success                              │
# │ "elicitation_dialog"  - MCP tool input needed                               │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ MATCHER PATTERN (fill in)                                                   │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │ Pattern: [YOUR_PATTERN]                                                     │
# │                                                                             │
# │ [ ] Single type        - "permission_prompt"                                │
# │ [ ] Multiple types     - "permission_prompt|idle_prompt"                    │
# │ [ ] All notifications  - "" or "*"                                          │
# │                                                                             │
# │ ⚠️  Matcher matches notification_type, NOT tool_name                        │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ═══════════════════════════════════════════════════════════════════════════════
# EXIT CODES (Notification-specific)
# ═══════════════════════════════════════════════════════════════════════════════
#
# │ Code │ Behavior                                                             │
# │──────│─────────────────────────────────────────────────────────────────────│
# │  0   │ Success; stdout/stderr not shown                                    │
# │  1   │ stderr shown to user                                                │
# │  2   │ stderr shown to user ONLY (not Claude)                              │
# │ 3+   │ stderr shown to user                                                │
#
# ⚠️  Cannot block notifications; hook is for custom handling only
#
# ═══════════════════════════════════════════════════════════════════════════════
# RESPONSE PATTERNS
# ═══════════════════════════════════════════════════════════════════════════════
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ RESPONSE BEHAVIOR (pick one)                                                │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │ [ ] Silent                - return_silent (hook doesn't apply)              │
# │ [ ] Custom notification   - Play sound, show popup, etc.                    │
# │ [ ] Log notification      - Write to log file                               │
# │ [ ] User message          - echo "message" >&2 (shown to user)              │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ═══════════════════════════════════════════════════════════════════════════════
# INPUT PAYLOAD (stdin JSON)
# ═══════════════════════════════════════════════════════════════════════════════
#
# {
#   "hook_event_name": "Notification",
#   "session_id": "abc123",
#   "transcript_path": "/path/to/transcript.jsonl",
#   "cwd": "/current/working/dir",
#   "permission_mode": "default",
#   "message": "Claude needs your permission to use Bash",
#   "notification_type": "permission_prompt"    // ← Match against this
# }
#
# ═══════════════════════════════════════════════════════════════════════════════
# SETTINGS.JSON WIRING
# ═══════════════════════════════════════════════════════════════════════════════
#
# {
#   "hooks": {
#     "Notification": [{
#       "matcher": "permission_prompt",          // ← notification_type pattern
#       "hooks": [{
#         "type": "command",
#         "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/utils/notification/YOUR_HOOK.sh",
#         "timeout": 5
#       }]
#     }]
#   }
# }
#
# ═══════════════════════════════════════════════════════════════════════════════
# IMPLEMENTATION CHECKLIST
# ═══════════════════════════════════════════════════════════════════════════════
#
# - [ ] settings.json: Notification wiring with notification_type matcher
# - [ ] Tests added under .claude/hooks/tests/
# - [ ] CHANGELOG.md updated if behavior changes
# - [ ] Keep execution fast (notifications should be responsive)
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
message="$(json_get "$payload" ".message")"
notification_type="$(json_get "$payload" ".notification_type")"

# ═══════════════════════════════════════════════════════════════════════════════
# YOUR HOOK LOGIC HERE
# ═══════════════════════════════════════════════════════════════════════════════

# ─── Example: Play sound on permission request ────────────────────────────────
# if [[ "$notification_type" == "permission_prompt" ]]; then
#   afplay /System/Library/Sounds/Ping.aiff 2>/dev/null || true
# fi

# ─── Example: Log notifications ───────────────────────────────────────────────
# log_info "Notification: type=$notification_type message=$message"

# ─── Example: Custom handling by type ─────────────────────────────────────────
# case "$notification_type" in
#   "permission_prompt")
#     # Play attention sound
#     ;;
#   "idle_prompt")
#     # Maybe send desktop notification
#     ;;
#   "auth_success")
#     # Log authentication
#     ;;
# esac

# ─── Default: pass-through ────────────────────────────────────────────────────
exit 0
