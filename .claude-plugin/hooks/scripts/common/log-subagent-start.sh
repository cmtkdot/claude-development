#!/usr/bin/env bash
# SubagentStart hook - Log when subagents are spawned
set -euo pipefail

# Source shared logging utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logging.sh"

# Read JSON input from stdin
INPUT=$(cat)

# Extract relevant fields
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // "unknown"')
AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // "unknown"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

# Log the subagent start
log_event "subagent" "START: $AGENT_TYPE (id: $AGENT_ID)" "$SESSION_ID"

# Also log structured JSON
log_json "subagent" "$INPUT" "$SESSION_ID"

# Exit success
exit 0
