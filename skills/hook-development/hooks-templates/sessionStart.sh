#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# SESSIONSTART HOOK TEMPLATE
# ═══════════════════════════════════════════════════════════════════════════════
#
# Hook Name: [YOUR_HOOK_NAME]
# Description: [What this hook does on session start - load context/set env]
# Author: [Your name]
# Created: [Date]
#
# ═══════════════════════════════════════════════════════════════════════════════
# EVENT: SessionStart
# ═══════════════════════════════════════════════════════════════════════════════
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ CAPABILITIES                                                                │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │ [ ] Matcher supported     - NO matcher; runs on ALL session starts          │
# │ [ ] Can block             - NO blocking; errors are ignored                 │
# │ [ ] Can modify input      - NO input modification                           │
# │ [x] Can inject context    - stdout/additionalContext sent to Claude         │
# │ [x] Can persist env vars  - Write to $CLAUDE_ENV_FILE                       │
# │ [x] Runs on start         - Runs on session start/resume/clear/compact      │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ PLANNING QUESTIONS                                                          │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │ [ ] Should this load project context for Claude?                            │
# │ [ ] Should this persist environment variables for the session?              │
# │ [ ] Should this behave differently for startup vs resume vs compact?        │
# │ [ ] Should this skip in remote environments ($CLAUDE_CODE_REMOTE)?          │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ SESSION SOURCES                                                             │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │ "startup"  - Fresh session start                                            │
# │ "resume"   - From --resume, --continue, or /resume                          │
# │ "clear"    - From /clear command                                            │
# │ "compact"  - After auto or manual compaction                                │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ═══════════════════════════════════════════════════════════════════════════════
# EXIT CODES (SessionStart-specific)
# ═══════════════════════════════════════════════════════════════════════════════
#
# │ Code │ Behavior                                                             │
# │──────│─────────────────────────────────────────────────────────────────────│
# │  0   │ stdout sent to Claude; JSON processed                               │
# │  1   │ stderr shown to user; session continues                             │
# │  2   │ Blocking errors IGNORED; session continues                          │
# │ 3+   │ stderr shown to user; session continues                             │
#
# ⚠️  Exit 2 does NOT block session start (ignored for reliability)
#
# ═══════════════════════════════════════════════════════════════════════════════
# RESPONSE PATTERNS (check ONE primary behavior)
# ═══════════════════════════════════════════════════════════════════════════════
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ RESPONSE BEHAVIOR (pick one)                                                │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │ [ ] Silent                - return_silent (hook doesn't apply)              │
# │ [ ] Inject context        - additionalContext for Claude                    │
# │ [ ] Persist env vars      - Write to $CLAUDE_ENV_FILE                       │
# │ [ ] Plain text context    - exit 0 + echo "context" (Claude sees)           │
# │ [ ] Conditional by source - Different behavior for startup/resume/etc       │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ═══════════════════════════════════════════════════════════════════════════════
# JSON OUTPUT SCHEMA
# ═══════════════════════════════════════════════════════════════════════════════
#
# {
#   "hookSpecificOutput": {
#     "hookEventName": "SessionStart",
#     "additionalContext": "Project context loaded on startup"
#   },
#   "systemMessage": "User-only status message",  // 0 tokens
#   "suppressOutput": false
# }
#
# ═══════════════════════════════════════════════════════════════════════════════
# INPUT PAYLOAD (stdin JSON)
# ═══════════════════════════════════════════════════════════════════════════════
#
# {
#   "hook_event_name": "SessionStart",
#   "session_id": "abc123",
#   "source": "startup"                     // ← startup|resume|clear|compact
# }
#
# ═══════════════════════════════════════════════════════════════════════════════
# ENVIRONMENT VARIABLES
# ═══════════════════════════════════════════════════════════════════════════════
#
# $CLAUDE_PROJECT_DIR  - Project root (all hooks)
# $CLAUDE_ENV_FILE     - File to persist env vars (SessionStart ONLY!)
# $CLAUDE_CODE_REMOTE  - "true" if web/remote environment
#
# ═══════════════════════════════════════════════════════════════════════════════
# SETTINGS.JSON WIRING
# ═══════════════════════════════════════════════════════════════════════════════
#
# {
#   "hooks": {
#     "SessionStart": [{
#       "hooks": [{                         // NO matcher
#         "type": "command",
#         "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/utils/sessionStart/YOUR_HOOK.sh",
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
# - [ ] settings.json: SessionStart wiring (no matcher)
# - [ ] Tests added under .claude/hooks/tests/
# - [ ] CHANGELOG.md updated if behavior changes
# - [ ] Consider $CLAUDE_CODE_REMOTE for remote environments
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
source_reason="$(json_get "$payload" ".source")"

# ═══════════════════════════════════════════════════════════════════════════════
# YOUR HOOK LOGIC HERE
# ═══════════════════════════════════════════════════════════════════════════════

# ─── Example: Skip in remote environments ─────────────────────────────────────
# if [[ "$CLAUDE_CODE_REMOTE" == "true" ]]; then
#   exit 0
# fi

# ─── Example: Load context only on fresh startup ──────────────────────────────
# if [[ "$source_reason" == "startup" ]]; then
#   echo "Project: XanBZS - SMB Financial Platform"
#   echo "Use postgresql/get_object_details with tableName filter"
#   exit 0
# fi

# ─── Example: Persist environment variables ───────────────────────────────────
# if [[ -n "$CLAUDE_ENV_FILE" ]]; then
#   echo 'export NODE_ENV=development' >> "$CLAUDE_ENV_FILE"
#   echo 'export PATH="$PATH:./node_modules/.bin"' >> "$CLAUDE_ENV_FILE"
# fi

# ─── Example: Different behavior by source ────────────────────────────────────
# case "$source_reason" in
#   "startup")
#     echo "Fresh session - loading full context..."
#     ;;
#   "resume")
#     echo "Resumed session - checking for stale context..."
#     ;;
#   "compact")
#     echo "Post-compaction - critical context reminder..."
#     ;;
# esac

# ─── Default: pass-through ────────────────────────────────────────────────────
exit 0
