#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# SUBAGENTSTART HOOK TEMPLATE
# ═══════════════════════════════════════════════════════════════════════════════
#
# Hook Name: [YOUR_HOOK_NAME]
# Description: [What this hook does when a subagent starts]
# Author: [Your name]
# Created: [Date]
#
# ═══════════════════════════════════════════════════════════════════════════════
# EVENT: SubagentStart
# ═══════════════════════════════════════════════════════════════════════════════
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ CAPABILITIES                                                                │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │ [ ] Matcher supported     - NO matcher; runs on ALL subagent starts         │
# │ [ ] Can block             - NO blocking; errors are ignored                 │
# │ [ ] Can modify input      - NO input modification                           │
# │ [x] Can inject context    - stdout sent to the SUBAGENT (not main)          │
# │ [x] Runs on start         - Runs when a subagent task starts                │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ PLANNING QUESTIONS                                                          │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │ [ ] Should this inject context for the subagent?                            │
# │ [ ] Should this log subagent launches for tracking?                         │
# │ [ ] Should this behave differently by agent_type?                           │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ AGENT TYPES                                                                 │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │ "task"      - General Task tool agents                                      │
# │ "explore"   - Codebase exploration agents                                   │
# │ "plan"      - Planning agents                                               │
# │ Other types defined by Task tool subagent_type                              │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ═══════════════════════════════════════════════════════════════════════════════
# EXIT CODES (SubagentStart-specific)
# ═══════════════════════════════════════════════════════════════════════════════
#
# │ Code │ Behavior                                                             │
# │──────│─────────────────────────────────────────────────────────────────────│
# │  0   │ stdout sent to SUBAGENT; JSON processed                             │
# │  1   │ stderr shown to user; subagent continues                            │
# │  2   │ Blocking errors IGNORED; subagent continues                         │
# │ 3+   │ stderr shown to user; subagent continues                            │
#
# ⚠️  Exit 2 does NOT block subagent start (ignored for reliability)
# ⚠️  stdout goes to the SUBAGENT, not the main conversation
#
# ═══════════════════════════════════════════════════════════════════════════════
# RESPONSE PATTERNS
# ═══════════════════════════════════════════════════════════════════════════════
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ RESPONSE BEHAVIOR (pick one)                                                │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │ [ ] Silent                - return_silent (hook doesn't apply)              │
# │ [ ] Inject subagent ctx   - echo "context" (subagent sees)                  │
# │ [ ] Log subagent start    - Write to log file                               │
# │ [ ] Conditional by type   - Different behavior per agent_type               │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ═══════════════════════════════════════════════════════════════════════════════
# JSON OUTPUT SCHEMA
# ═══════════════════════════════════════════════════════════════════════════════
#
# {
#   "hookSpecificOutput": {
#     "hookEventName": "SubagentStart",
#     "additionalContext": "Context injected for the subagent"
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
#   "hook_event_name": "SubagentStart",
#   "session_id": "abc123",
#   "agent_id": "task_abc123",               // ← Unique agent ID
#   "agent_type": "task"                     // ← Type of agent
# }
#
# ═══════════════════════════════════════════════════════════════════════════════
# SETTINGS.JSON WIRING
# ═══════════════════════════════════════════════════════════════════════════════
#
# {
#   "hooks": {
#     "SubagentStart": [{
#       "hooks": [{                          // NO matcher
#         "type": "command",
#         "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/utils/subagentStart/YOUR_HOOK.sh",
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
# - [ ] settings.json: SubagentStart wiring (no matcher)
# - [ ] Tests added under .claude/hooks/tests/
# - [ ] CHANGELOG.md updated if behavior changes
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
agent_id="$(json_get "$payload" ".agent_id")"
agent_type="$(json_get "$payload" ".agent_type")"

# ═══════════════════════════════════════════════════════════════════════════════
# YOUR HOOK LOGIC HERE
# ═══════════════════════════════════════════════════════════════════════════════

# ─── Example: Log subagent start ──────────────────────────────────────────────
# log_info "Subagent started: id=$agent_id type=$agent_type"

# ─── Example: Inject context for specific agent types ─────────────────────────
# if [[ "$agent_type" == "explore" ]]; then
#   echo "Focus on the apps/web and packages/shared directories"
#   exit 0
# fi

# ─── Example: Different context by agent type ─────────────────────────────────
# case "$agent_type" in
#   "task")
#     echo "Follow project coding standards in .claude/rules/"
#     ;;
#   "explore")
#     echo "Key directories: apps/, packages/, docs/"
#     ;;
#   "plan")
#     echo "Reference openspec/specs/ for feature specifications"
#     ;;
# esac

# ─── Default: pass-through ────────────────────────────────────────────────────
exit 0
