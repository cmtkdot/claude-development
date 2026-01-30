#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# MCP-CLI Hook Pattern
# Description: Hook that catches MCP calls made via mcp-cli in Bash
#
# Matcher: "Bash"
#
# This is the companion to the native MCP hook. Together they form the dual-hook
# pattern that catches ALL MCP tool calls:
#   1. Native calls - handled by mcp-dual-hook-native.sh
#   2. mcp-cli calls - handled by THIS hook
#
# Command pattern: mcp-cli call <server>/<tool> '<json>'
# ═══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

# ─── HELPERS ────────────────────────────────────────────────────────────────
json_get() { echo "$1" | jq -r "$2 // empty" 2>/dev/null; }

# ─── MAIN ───────────────────────────────────────────────────────────────────
payload="$(cat)"
tool_name=$(json_get "$payload" ".tool_name")
hook_event=$(json_get "$payload" ".hook_event_name")

# Only process Bash commands
[[ "$tool_name" == "Bash" ]] || exit 0

command=$(json_get "$payload" ".tool_input.command")

# Check if this is an mcp-cli call
# Pattern: mcp-cli call <server>/<tool>
if [[ "$command" =~ mcp-cli[[:space:]]+call[[:space:]]+([^/]+)/([^[:space:]]+) ]]; then
  mcp_server="${BASH_REMATCH[1]}"
  mcp_tool="${BASH_REMATCH[2]}"
else
  # Not an mcp-cli call - fast exit
  exit 0
fi

# ─── MCP TOOL VALIDATION ────────────────────────────────────────────────────
# Apply SAME validation as native MCP hook
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
          systemMessage: ("🚫 Blocked: mcp-cli linear/" + $tool + " is not allowed")
        }'
        exit 2
        ;;
    esac
    ;;

  postgresql)
    # Extract SQL from the JSON argument
    # Pattern: mcp-cli call postgresql/execute_sql '{"sql": "..."}'
    if [[ "$command" =~ \'(\{[^\']+\})\' ]]; then
      json_arg="${BASH_REMATCH[1]}"
      sql=$(echo "$json_arg" | jq -r '.sql // empty' 2>/dev/null)

      # Block destructive SQL
      if [[ "$sql" =~ (DROP|TRUNCATE|DELETE[[:space:]]+FROM[[:space:]]+[^[:space:]]+[[:space:]]*$) ]]; then
        jq -n --arg event "$hook_event" '{
          hookSpecificOutput: {
            hookEventName: $event,
            permissionDecision: "deny",
            permissionDecisionReason: "Destructive SQL blocked"
          },
          systemMessage: "🚫 Blocked: Destructive SQL via mcp-cli"
        }'
        exit 2
      fi
    fi
    ;;
esac

# ─── ALLOW ──────────────────────────────────────────────────────────────────
jq -n --arg event "$hook_event" '{
  hookSpecificOutput: {
    hookEventName: $event,
    permissionDecision: "allow"
  },
  systemMessage: "✅ mcp-cli call validated"
}'
exit 0
