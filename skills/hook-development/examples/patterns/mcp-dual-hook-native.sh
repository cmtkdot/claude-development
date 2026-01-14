#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# MCP Native Hook Pattern
# Description: Hook that matches native MCP tool calls (mcp__<server>__<tool>)
#
# Matcher: "mcp__linear__.*" (or specific: "mcp__linear__delete_issue")
#
# This is one half of the dual-hook pattern. MCP tools can be called:
#   1. Natively (this hook) - tool_name: "mcp__linear__delete_issue"
#   2. Via mcp-cli (companion hook) - tool_name: "Bash", command: "mcp-cli call linear/delete_issue"
#
# Create BOTH hooks to fully cover MCP tool gating.
# ═══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

# ─── HELPERS ────────────────────────────────────────────────────────────────
json_get() { echo "$1" | jq -r "$2 // empty" 2>/dev/null; }

# ─── MAIN ───────────────────────────────────────────────────────────────────
payload="$(cat)"
tool_name=$(json_get "$payload" ".tool_name")
hook_event=$(json_get "$payload" ".hook_event_name")

# Extract MCP server and tool from tool_name
# Format: mcp__<server>__<tool>
if [[ "$tool_name" =~ ^mcp__([^_]+)__(.+)$ ]]; then
  mcp_server="${BASH_REMATCH[1]}"
  mcp_tool="${BASH_REMATCH[2]}"
else
  # Not an MCP tool - fast exit
  exit 0
fi

# ─── MCP TOOL VALIDATION ────────────────────────────────────────────────────
# Example: Block destructive Linear operations
case "$mcp_server" in
  linear)
    case "$mcp_tool" in
      delete_issue|delete_project)
        jq -n --arg event "$hook_event" --arg tool "$mcp_tool" '{
          hookSpecificOutput: {
            hookEventName: $event,
            permissionDecision: "deny",
            permissionDecisionReason: ("Destructive operation blocked: " + $tool)
          },
          systemMessage: ("🚫 Blocked: Linear " + $tool + " is not allowed")
        }'
        exit 2
        ;;
    esac
    ;;

  postgresql)
    # Get the SQL from tool input
    sql=$(json_get "$payload" ".tool_input.sql")

    # Block destructive SQL
    if [[ "$sql" =~ (DROP|TRUNCATE|DELETE[[:space:]]+FROM[[:space:]]+[^[:space:]]+[[:space:]]*$) ]]; then
      jq -n --arg event "$hook_event" '{
        hookSpecificOutput: {
          hookEventName: $event,
          permissionDecision: "deny",
          permissionDecisionReason: "Destructive SQL blocked"
        },
        systemMessage: "🚫 Blocked: Destructive SQL operation"
      }'
      exit 2
    fi
    ;;
esac

# ─── ALLOW ──────────────────────────────────────────────────────────────────
jq -n --arg event "$hook_event" '{
  hookSpecificOutput: {
    hookEventName: $event,
    permissionDecision: "allow"
  },
  systemMessage: "✅ MCP call validated"
}'
exit 0
