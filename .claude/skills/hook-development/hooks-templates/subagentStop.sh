#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# SUBAGENTSTOP HOOK TEMPLATE
# ═══════════════════════════════════════════════════════════════════════════════
#
# Hook Name: [YOUR_HOOK_NAME]
# Description: [What this hook checks when a subagent finishes]
# Author: [Your name]
# Created: [Date]
#
# ═══════════════════════════════════════════════════════════════════════════════
# EVENT: SubagentStop
# ═══════════════════════════════════════════════════════════════════════════════
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ CAPABILITIES                                                                │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │ [ ] Matcher supported     - NO matcher; runs when any subagent stops        │
# │ [x] Can block (continue)  - exit 2 or decision: "block" forces continue     │
# │ [ ] Can modify input      - NO input modification                           │
# │ [x] Can inject context    - stderr sent to SUBAGENT on exit 2               │
# │ [x] Runs on stop          - Runs when a subagent finishes its task          │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ PLANNING QUESTIONS                                                          │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │ [ ] Should this verify subagent completed all required tasks?               │
# │ [ ] Should this validate subagent output quality?                           │
# │ [ ] Should this log subagent completion metrics?                            │
# │ [ ] Should this use prompt type (LLM) for intelligent completion check?     │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ HOOK TYPES                                                                  │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │ type: "command" - Deterministic check (fast, bash script)                   │
# │ type: "prompt"  - LLM evaluation (slower, context-aware) - SubagentStop OK! │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ═══════════════════════════════════════════════════════════════════════════════
# EXIT CODES (SubagentStop-specific)
# ═══════════════════════════════════════════════════════════════════════════════
#
# │ Code │ Behavior                                                             │
# │──────│─────────────────────────────────────────────────────────────────────│
# │  0   │ Allow stop; stdout/stderr not shown                                 │
# │  1   │ Allow stop; stderr logged                                           │
# │  2   │ FORCE CONTINUE; stderr sent to SUBAGENT as "why continue"           │
# │ 3+   │ Allow stop; stderr shown to user                                    │
#
# ⚠️  IMPORTANT: Check stop_hook_active to prevent infinite loops!
# ⚠️  stderr on exit 2 goes to the SUBAGENT, not main conversation
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
# │ [ ] Log completion        - Log metrics, then allow stop                    │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ═══════════════════════════════════════════════════════════════════════════════
# JSON OUTPUT SCHEMA
# ═══════════════════════════════════════════════════════════════════════════════
#
# {
#   "decision": "block",                   // Force subagent to continue
#   "reason": "Why subagent shouldn't stop yet"
# }
#
# ═══════════════════════════════════════════════════════════════════════════════
# INPUT PAYLOAD (stdin JSON)
# ═══════════════════════════════════════════════════════════════════════════════
#
# {
#   "hook_event_name": "SubagentStop",
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
#     "SubagentStop": [{
#       "hooks": [{
#         "type": "command",
#         "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/utils/subagentStop/YOUR_HOOK.sh",
#         "timeout": 30
#       }]
#     }]
#   }
# }
#
# # Prompt type (LLM evaluation) - SubagentStop supported!
# {
#   "hooks": {
#     "SubagentStop": [{
#       "hooks": [{
#         "type": "prompt",
#         "prompt": "Evaluate if subagent completed its task: $ARGUMENTS. Is the output complete?",
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
# - [ ] settings.json: SubagentStop wiring (no matcher)
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

# ─── Example: Force continue if output validation fails ───────────────────────
# output_file="/tmp/subagent_output"
# if [[ -f "$output_file" ]] && [[ $(wc -l < "$output_file") -lt 5 ]]; then
#   echo "Output too short. Please provide more detail." >&2
#   exit 2
# fi

# ─── Example: Log subagent completion ─────────────────────────────────────────
# log_info "Subagent completed"

# ─── Example: Force continue with JSON ────────────────────────────────────────
# if [[ -f /tmp/subagent_incomplete ]]; then
#   jq -n '{
#     decision: "block",
#     reason: "Subagent task incomplete. Please finish all items."
#   }'
#   exit 0
# fi

# ─── Default: allow stop ──────────────────────────────────────────────────────
exit 0
