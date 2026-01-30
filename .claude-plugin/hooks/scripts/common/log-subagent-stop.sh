#!/usr/bin/env bash
# SubagentStop hook - Log when subagents complete
set -euo pipefail

# Source shared logging utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logging.sh"

# Read JSON input from stdin
INPUT=$(cat)

# Extract relevant fields
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // "unknown"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')

# Log the subagent stop
log_event "subagent" "STOP: $AGENT_ID (stop_hook_active: $STOP_HOOK_ACTIVE)" "$SESSION_ID"

# Also log structured JSON
log_json "subagent" "$INPUT" "$SESSION_ID"

# Exit success - allow subagent to stop normally
exit 0
