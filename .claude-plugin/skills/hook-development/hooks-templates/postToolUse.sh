#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# POSTTOOLUSE HOOK TEMPLATE
# ═══════════════════════════════════════════════════════════════════════════════
#
# Hook Name: [YOUR_HOOK_NAME]
# Description: [What this hook observes/logs/analyzes after tool execution]
# Author: [Your name]
# Created: [Date]
#
# ═══════════════════════════════════════════════════════════════════════════════
# EVENT: PostToolUse
# ═══════════════════════════════════════════════════════════════════════════════
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ CAPABILITIES                                                                │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │ [x] Matcher supported     - Filter by tool_name (regex)                     │
# │ [ ] Can block execution   - Tool ALREADY ran; can only flag issues          │
# │ [ ] Can modify input      - Tool ALREADY ran; no input modification         │
# │ [ ] Can modify output     - Cannot rewrite tool_response (not supported)    │
# │ [x] Can inject context    - additionalContext for Claude's next action      │
# │ [x] Runs after execution  - Runs AFTER successful tool execution            │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ⚠️  For FAILED tool executions, use PostToolUseFailure hook instead
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ PLANNING QUESTIONS (from SKILL.md)                                          │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │ [ ] Should Claude see the result (costs tokens) or just the user?           │
# │     → additionalContext = Claude sees (costs tokens)                        │
# │     → systemMessage = User only (0 tokens)                                  │
# │ [ ] Is this for logging, formatting, or providing follow-up guidance?       │
# │ [ ] Should this trigger additional processing (lint, format, analyze)?      │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ MATCHER PATTERN (fill in)                                                   │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │ Pattern: [YOUR_PATTERN]                                                     │
# │                                                                             │
# │ [ ] Single tool      - "Bash", "Edit", "Write"                              │
# │ [ ] Multiple tools   - "Write|Edit|MultiEdit"                               │
# │ [ ] MCP server       - "mcp__supabase__.*"                                  │
# │ [ ] Specific MCP     - "mcp__supabase__apply_migration"                     │
# │ [ ] All tools        - "" or "*" (SLOW - avoid)                             │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ═══════════════════════════════════════════════════════════════════════════════
# EXIT CODES (PostToolUse-specific)
# ═══════════════════════════════════════════════════════════════════════════════
#
# │ Code │ Behavior                                                             │
# │──────│─────────────────────────────────────────────────────────────────────│
# │  0   │ stdout shown in transcript mode (ctrl+o); JSON processed            │
# │  1   │ Error label shown to user; stderr logged                            │
# │  2   │ stderr sent to Claude IMMEDIATELY (feedback about result)           │
# │ 3+   │ stderr shown to user only                                           │
#
# ═══════════════════════════════════════════════════════════════════════════════
# RESPONSE PATTERNS (check ONE primary behavior)
# ═══════════════════════════════════════════════════════════════════════════════
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ RESPONSE BEHAVIOR (pick one)                                                │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │ [ ] Silent (no feedback)   - exit 0 (hook doesn't apply)                    │
# │ [ ] User message only      - JSON with systemMessage (0 tokens)             │
# │ [ ] Claude context         - JSON with hookSpecificOutput + additionalCtx   │
# │ [ ] Report issue           - exit 2 + echo "issue" >&2 (Claude sees)        │
# │ [ ] Block decision         - JSON with decision: "block" + reason           │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ═══════════════════════════════════════════════════════════════════════════════
# JSON OUTPUT SCHEMA
# ═══════════════════════════════════════════════════════════════════════════════
#
# {
#   "decision": "block",                   // Optional: flag issue to Claude
#   "reason": "Issue detected - shown to Claude",
#   "hookSpecificOutput": {
#     "hookEventName": "PostToolUse",
#     "additionalContext": "Guidance for Claude's next action"
#   },
#   "systemMessage": "User-only message",  // 0 tokens
#   "suppressOutput": false                // true = hide from transcript
# }
#
# ═══════════════════════════════════════════════════════════════════════════════
# INPUT PAYLOAD (stdin JSON)
# ═══════════════════════════════════════════════════════════════════════════════
#
# {
#   "session_id": "abc123",
#   "hook_event_name": "PostToolUse",
#   "tool_name": "Edit",
#   "tool_input": {
#     "file_path": "/path/to/file.ts",
#     "old_string": "...",
#     "new_string": "..."
#   },
#   "tool_response": {                     // ← Result of tool execution
#     "success": true,
#     "filePath": "/path/to/file.ts"
#   },
#   "tool_use_id": "toolu_01ABC123..."
# }
#
# ═══════════════════════════════════════════════════════════════════════════════
# SETTINGS.JSON WIRING
# ═══════════════════════════════════════════════════════════════════════════════
#
# {
#   "hooks": {
#     "PostToolUse": [{
#       "matcher": "Write|Edit",
#       "hooks": [{
#         "type": "command",
#         "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/utils/postToolUse/YOUR_HOOK.sh",
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
# - [ ] settings.json: PostToolUse wiring with matcher
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
# shellcheck disable=SC2034  # Variables for template customization
tool_name="$(json_get "$payload" ".tool_name")"
tool_input="$(json_get "$payload" ".tool_input")"
tool_response="$(json_get "$payload" ".tool_response")"

# ═══════════════════════════════════════════════════════════════════════════════
# YOUR HOOK LOGIC HERE
# ═══════════════════════════════════════════════════════════════════════════════

# ─── Example: User-only success message (0 tokens) ────────────────────────────
# jq -n --arg msg "File formatted successfully" '{systemMessage: $msg}'

# ─── Example: Inject guidance for Claude ──────────────────────────────────────
# jq -n --arg ctx "Run tests next" --arg msg "✓ Analyzed" '{
#   "hookSpecificOutput": {
#     "hookEventName": "PostToolUse",
#     "additionalContext": $ctx
#   },
#   "systemMessage": $msg
# }'

# ─── Example: Report issue to Claude (stderr) ─────────────────────────────────
# if [[ "$tool_response" == *"error"* ]]; then
#   echo "Tool produced errors - please review the output" >&2
#   exit 2
# fi

# ─── Example: Auto-format after file write ────────────────────────────────────
# file_path="$(json_get "$tool_input" ".file_path // empty")"
# if [[ "$file_path" =~ \.(ts|tsx|js|jsx)$ ]]; then
#   npx prettier --write "$file_path" 2>/dev/null || true
#   jq -n --arg msg "Formatted: $(basename "$file_path")" '{systemMessage: $msg}'
# fi

# ─── Default: pass-through ────────────────────────────────────────────────────
exit 0
