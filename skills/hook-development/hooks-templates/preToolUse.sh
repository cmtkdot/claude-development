#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# PRETOOLUSE HOOK TEMPLATE
# ═══════════════════════════════════════════════════════════════════════════════
#
# Hook Name: [YOUR_HOOK_NAME]
# Description: [What this hook validates/blocks/modifies]
# Author: [Your name]
# Created: [Date]
#
# ═══════════════════════════════════════════════════════════════════════════════
# EVENT: PreToolUse
# ═══════════════════════════════════════════════════════════════════════════════
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ CAPABILITIES                                                                │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │ [x] Matcher supported     - Filter by tool_name (regex)                     │
# │ [x] Can block execution   - exit 2 or permissionDecision: "deny"            │
# │ [x] Can modify input      - updatedInput in JSON response                   │
# │ [x] Can inject context    - additionalContext for Claude                    │
# │ [ ] Runs after execution  - Runs BEFORE tool executes                       │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ PLANNING QUESTIONS (from SKILL.md)                                          │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │ [ ] Should this BLOCK the action or just OBSERVE/LOG it?                    │
# │     → PreToolUse CAN block; use PostToolUse for observe-only                │
# │ [ ] If validation fails, should Claude RETRY with guidance or ABANDON?      │
# │     → exit 2 = retry with stderr as guidance                                │
# │     → permissionDecision: "deny" = abandon permanently                      │
# │ [ ] Should this MODIFY the input before execution?                          │
# │     → Use updatedInput in JSON response                                     │
# │ [ ] Is this critical path (<50ms) or can it be slower?                      │
# │     → Target <100ms for PreToolUse hooks                                    │
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
# │                                                                             │
# │ Native: Read, Write, Edit, MultiEdit, Glob, Grep, Bash, WebFetch, WebSearch │
# │ Discovery: mcp-cli tools | mcp-cli grep "pattern"                           │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ═══════════════════════════════════════════════════════════════════════════════
# EXIT CODES (PreToolUse-specific)
# ═══════════════════════════════════════════════════════════════════════════════
#
# │ Code │ Behavior                                                             │
# │──────│─────────────────────────────────────────────────────────────────────│
# │  0   │ Process JSON output; tool proceeds if allowed                       │
# │  1   │ Non-blocking error; stderr logged, tool proceeds                    │
# │  2   │ BLOCK tool; stderr sent to Claude as retry guidance                 │
# │ 3+   │ Non-blocking; stderr shown to user, tool proceeds                   │
#
# ═══════════════════════════════════════════════════════════════════════════════
# RESPONSE PATTERNS (check ONE primary behavior)
# ═══════════════════════════════════════════════════════════════════════════════
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ RESPONSE BEHAVIOR (pick one)                                                │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │ [ ] Silent pass-through    - return_silent (hook doesn't apply)             │
# │ [ ] Allow (auto-approve)   - return_permission "allow" "reason"             │
# │ [ ] Allow + modify input   - JSON with permissionDecision + updatedInput    │
# │ [ ] Ask user               - return_permission "ask" "reason"               │
# │ [ ] Block with guidance    - exit 2 + echo "guidance" >&2 (CLAUDE RETRIES)  │
# │ [ ] Block permanently      - return_permission "deny" "reason" (ABANDONED)  │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ⚠️  COMMON MISTAKE: Using "deny" when you want Claude to retry differently.
#     "deny"  = Tool is FORBIDDEN → Claude uses different tool entirely
#     exit 2  = Error, here's guidance → Claude RETRIES same tool with fix
#
# ═══════════════════════════════════════════════════════════════════════════════
# JSON OUTPUT SCHEMA
# ═══════════════════════════════════════════════════════════════════════════════
#
# {
#   "hookSpecificOutput": {
#     "hookEventName": "PreToolUse",
#     "permissionDecision": "allow" | "deny" | "ask",
#     "permissionDecisionReason": "Shown to Claude (deny) or user (allow/ask)",
#     "updatedInput": {                    // Optional: modify tool params
#       "file_path": "/corrected/path.ts",
#       "command": "safer-command"
#     }
#   },
#   "suppressOutput": false,               // true = hide from transcript
#   "systemMessage": "User-only message"   // 0 tokens, shown to user
# }
#
# ═══════════════════════════════════════════════════════════════════════════════
# INPUT PAYLOAD (stdin JSON)
# ═══════════════════════════════════════════════════════════════════════════════
#
# {
#   "session_id": "abc123",
#   "transcript_path": "~/.claude/projects/.../session.jsonl",
#   "cwd": "/current/working/directory",
#   "permission_mode": "default" | "plan" | "acceptEdits" | "bypassPermissions",
#   "hook_event_name": "PreToolUse",
#   "tool_name": "Edit",                   // ← Match against this
#   "tool_input": {                        // ← Tool-specific params
#     "file_path": "/path/to/file.ts",
#     "old_string": "...",
#     "new_string": "..."
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
#     "PreToolUse": [{
#       "matcher": "Write|Edit",           // ← Your pattern
#       "hooks": [{
#         "type": "command",
#         "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/utils/preToolUse/YOUR_HOOK.sh",
#         "timeout": 5                      // seconds (keep fast!)
#       }]
#     }]
#   }
# }
#
# ═══════════════════════════════════════════════════════════════════════════════
# IMPLEMENTATION CHECKLIST
# ═══════════════════════════════════════════════════════════════════════════════
#
# - [ ] settings.json: PreToolUse wiring with matcher
# - [ ] Tests added under .claude/hooks/tests/
# - [ ] CHANGELOG.md updated if behavior changes
# - [ ] Timeout < 5s for critical path
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

# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

payload="$(cat)"

# ─── Parse Input ──────────────────────────────────────────────────────────────
# shellcheck disable=SC2034  # Variables for template customization
tool_name="$(json_get "$payload" ".tool_name")"
tool_input="$(json_get "$payload" ".tool_input")"
# tool_use_id="$(json_get "$payload" ".tool_use_id")"

# ═══════════════════════════════════════════════════════════════════════════════
# YOUR HOOK LOGIC HERE
# ═══════════════════════════════════════════════════════════════════════════════

# ─── Example: Block dangerous patterns (permanently) ──────────────────────────
# file_path="$(json_get "$tool_input" ".file_path")"
# if [[ "$file_path" =~ \.(env|credentials|secrets) ]]; then
#   jq -n --arg reason "Blocked: sensitive file" '{
#     hookSpecificOutput: {
#       hookEventName: "PreToolUse",
#       permissionDecision: "deny",
#       permissionDecisionReason: $reason
#     }
#   }'
#   exit 0
# fi

# ─── Example: Block with retry guidance (Claude retries with hint) ────────────
# if [[ "$tool_input" == *"SELECT *"* ]]; then
#   echo "Use specific columns instead of SELECT *" >&2
#   exit 2
# fi

# ─── Example: Modify input before execution ───────────────────────────────────
# if [[ "$file_path" =~ -v[0-9]+\. ]]; then
#   clean_path="${file_path/-v[0-9]*/}"
#   jq -n --arg path "$clean_path" '{
#     hookSpecificOutput: {
#       hookEventName: "PreToolUse",
#       permissionDecision: "allow",
#       permissionDecisionReason: "Redirected to original file",
#       updatedInput: { file_path: $path }
#     }
#   }'
#   exit 0
# fi

# ─── Example: Auto-approve safe operations ────────────────────────────────────
# jq -n '{
#   hookSpecificOutput: {
#     hookEventName: "PreToolUse",
#     permissionDecision: "allow",
#     permissionDecisionReason: "Validation passed"
#   }
# }'
# exit 0

# ─── Default: pass-through ────────────────────────────────────────────────────
exit 0
