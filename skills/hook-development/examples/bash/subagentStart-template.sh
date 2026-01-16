#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# SubagentStart Hook Template
# Description: Setup agent-specific environment when a subagent starts
#
# Payload fields:
#   - hook_event_name: "SubagentStart"
#   - session_id: Current session ID
#   - agent_type: Name of the agent being started (e.g., "hook-creator")
#   - parent_agent_type: Name of parent agent (or "main")
#   - agent_config: Full agent configuration from AGENT.md
#
# NOTE: SubagentStart stdout goes to the SUBAGENT, not main conversation
# NOTE: Blocking errors are ignored; exit 2 has no effect
# ═══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

# ─── CONFIG ─────────────────────────────────────────────────────────────────
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../" && pwd)}"
LOG_FILE="$PROJECT_ROOT/.claude/hooks/logs/subagent-start.log"

# ─── HELPERS ────────────────────────────────────────────────────────────────
json_get() { echo "$1" | jq -r "$2 // empty" 2>/dev/null; }
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"; }

# ─── MAIN ───────────────────────────────────────────────────────────────────
payload="$(cat)"
agent_type=$(json_get "$payload" ".agent_type")
hook_event=$(json_get "$payload" ".hook_event_name")

log "SubagentStart: $agent_type"

# Fast-path exit for non-matching agents
# Uncomment and modify to target specific agents:
# [[ "$agent_type" == "your-agent-name" ]] || exit 0

# ─── AGENT-SPECIFIC SETUP ───────────────────────────────────────────────────
case "$agent_type" in
  hook-creator)
    # Setup hook development environment
    echo "HOOK_DEV_MODE=1" >> "$CLAUDE_ENV_FILE"
    echo "HOOK_TEMPLATE_DIR=$PROJECT_ROOT/.claude/skills/hook-development/hooks-templates" >> "$CLAUDE_ENV_FILE"
    ;;

  code-reviewer)
    # Setup code review environment
    echo "REVIEW_MODE=1" >> "$CLAUDE_ENV_FILE"
    echo "LINT_STRICT=1" >> "$CLAUDE_ENV_FILE"
    ;;

  *)
    # Default: no special setup
    exit 0
    ;;
esac

# ─── OUTPUT ─────────────────────────────────────────────────────────────────
jq -n --arg agent "$agent_type" '{
  systemMessage: ("🔧 Environment configured for " + $agent)
}'
exit 0
