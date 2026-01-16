#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# SubagentStop Hook Template
# Description: Cleanup after a subagent completes
#
# Payload fields:
#   - hook_event_name: "SubagentStop"
#   - session_id: Current session ID
#   - agent_type: Name of the agent that completed
#   - stop_hook_active: CRITICAL - check before exit 2
#   - result: { success: bool, output: string }
#
# CRITICAL: Always check stop_hook_active before exit 2 to prevent infinite loops
# Exit 2 forces the subagent to continue working
# ═══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

# ─── CONFIG ─────────────────────────────────────────────────────────────────
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../" && pwd)}"
LOG_FILE="$PROJECT_ROOT/.claude/hooks/logs/subagent-stop.log"

# ─── HELPERS ────────────────────────────────────────────────────────────────
json_get() { echo "$1" | jq -r "$2 // empty" 2>/dev/null; }
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"; }

# ─── MAIN ───────────────────────────────────────────────────────────────────
payload="$(cat)"
agent_type=$(json_get "$payload" ".agent_type")
hook_event=$(json_get "$payload" ".hook_event_name")
stop_hook_active=$(json_get "$payload" ".stop_hook_active")

log "SubagentStop: $agent_type (stop_hook_active=$stop_hook_active)"

# Fast-path exit for non-matching agents
# Uncomment and modify to target specific agents:
# [[ "$agent_type" == "your-agent-name" ]] || exit 0

# ─── CRITICAL: PREVENT INFINITE LOOP ────────────────────────────────────────
# If stop_hook_active is true, NEVER exit 2 - it will cause infinite loop
if [[ "$stop_hook_active" == "true" ]]; then
  log "Stop hook active - skipping force continue"
  jq -n '{
    systemMessage: "⚠️  Stop hook active - cannot force continue"
  }'
  exit 0
fi

# ─── AGENT-SPECIFIC CLEANUP ─────────────────────────────────────────────────
case "$agent_type" in
  hook-creator)
    # Cleanup hook development temp files
    rm -f /tmp/hook-dev-* 2>/dev/null || true
    ;;

  code-reviewer)
    # Cleanup review artifacts
    rm -f /tmp/review-* 2>/dev/null || true
    ;;

  *)
    # Default: no special cleanup
    exit 0
    ;;
esac

# ─── OUTPUT ─────────────────────────────────────────────────────────────────
jq -n --arg agent "$agent_type" '{
  systemMessage: ("✅ Cleaned up environment for " + $agent)
}'
exit 0

# ─── EXAMPLE: Force Continue ────────────────────────────────────────────────
# Uncomment to force the agent to continue working:
#
# result_success=$(json_get "$payload" ".result.success")
# if [[ "$result_success" != "true" ]] && [[ "$stop_hook_active" != "true" ]]; then
#   echo "Task not complete - forcing continue" >&2
#   exit 2
# fi
