#!/usr/bin/env bash
# Setup hook (init) - Validate plugin structure and initialize logging
set -euo pipefail

# Source shared logging utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logging.sh"

# Read JSON input from stdin
INPUT=$(cat)

# Extract session ID
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

# Initialize log directory
init_log_dir "$SESSION_ID"

# Validate plugin structure
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"
REQUIRED_DIRS=("agents" "skills" "hooks" "commands")
MISSING=()

for dir in "${REQUIRED_DIRS[@]}"; do
    if [[ ! -d "$PLUGIN_ROOT/$dir" ]]; then
        MISSING+=("$dir")
    fi
done

# Log initialization
if [[ ${#MISSING[@]} -gt 0 ]]; then
    log_event "init" "Plugin initialized. Missing optional directories: ${MISSING[*]}" "$SESSION_ID"
else
    log_event "init" "Plugin initialized. All directories present." "$SESSION_ID"
fi

# Output context for Claude
cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "Setup",
    "additionalContext": "Plugin initialized. Logs: $LOG_DATE_DIR"
  }
}
EOF

exit 0
