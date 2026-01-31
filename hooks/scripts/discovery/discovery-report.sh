#!/usr/bin/env bash
# Stop hook for starter-agent - Discovery completion report
set -euo pipefail

# Check dependencies
command -v jq >/dev/null 2>&1 || { echo "Warning: jq not installed, skipping discovery report" >&2; exit 0; }

# Read stdin safely
INPUT=""
if ! INPUT=$(cat 2>/dev/null); then
  echo "Warning: Failed to read stdin" >&2
  exit 0
fi

# Validate JSON
if ! echo "$INPUT" | jq -e . >/dev/null 2>&1; then
  echo "Warning: Invalid JSON input" >&2
  exit 0
fi

STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // "false"')

# Prevent infinite loop
if [[ "$STOP_HOOK_ACTIVE" == "true" ]] || [[ "$STOP_HOOK_ACTIVE" == "1" ]]; then
  exit 0
fi

echo "=== Discovery Report ==="
echo ""
echo "Components Found:"

# Skills - use ls with timeout fallback, count lines properly
SKILL_COUNT=0
if command -v timeout >/dev/null 2>&1; then
  # GNU timeout available
  SKILL_COUNT=$(timeout 5 bash -c 'ls .claude/skills/*/SKILL.md ~/.claude/skills/*/SKILL.md 2>/dev/null | wc -l' 2>/dev/null || echo "0")
else
  # No timeout, use basic ls
  SKILL_COUNT=$(ls .claude/skills/*/SKILL.md ~/.claude/skills/*/SKILL.md 2>/dev/null | wc -l || echo "0")
fi
# Trim whitespace (BSD vs GNU wc difference)
SKILL_COUNT="${SKILL_COUNT##* }"
SKILL_COUNT="${SKILL_COUNT:-0}"
echo "  Skills: $SKILL_COUNT"

# Agents - same pattern
AGENT_COUNT=0
if command -v timeout >/dev/null 2>&1; then
  AGENT_COUNT=$(timeout 5 bash -c 'ls .claude/agents/*.md ~/.claude/agents/*.md 2>/dev/null | wc -l' 2>/dev/null || echo "0")
else
  AGENT_COUNT=$(ls .claude/agents/*.md ~/.claude/agents/*.md 2>/dev/null | wc -l || echo "0")
fi
AGENT_COUNT="${AGENT_COUNT##* }"
AGENT_COUNT="${AGENT_COUNT:-0}"
echo "  Agents: $AGENT_COUNT"

# Hooks configured
HOOK_EVENTS=0
if [[ -f ".claude/settings.json" ]]; then
  HOOK_EVENTS=$(jq -r '.hooks // {} | keys | length' .claude/settings.json 2>/dev/null || echo "0")
fi
echo "  Hook events: $HOOK_EVENTS"

# MCP servers
MCP_COUNT=0
if [[ -f ".mcp.json" ]]; then
  MCP_COUNT=$(jq -r '.mcpServers // {} | keys | length' .mcp.json 2>/dev/null || echo "0")
fi
echo "  MCP servers: $MCP_COUNT"

echo ""
echo "Recommendation: Use appropriate creator agent for next steps"
exit 0
