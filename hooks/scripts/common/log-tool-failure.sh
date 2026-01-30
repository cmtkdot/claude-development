#!/usr/bin/env bash
# PostToolUseFailure hook - Log failed tool operations
set -euo pipefail

# Source shared logging utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logging.sh"

# Read JSON input from stdin
INPUT=$(cat)

# Extract relevant fields
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
ERROR=$(echo "$INPUT" | jq -r '.tool_response.error // .tool_response // "no error info"' | head -c 500)

# Log the failure
log_event "tool-failure" "FAILURE: $TOOL_NAME - $ERROR" "$SESSION_ID"

# Also log structured JSON for detailed analysis
log_json "tool-failure" "$INPUT" "$SESSION_ID"

# Exit success - don't block on logging failures
exit 0
