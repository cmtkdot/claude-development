#!/bin/bash
# Logs Read tool usage during ecosystem discovery
# Used as PostToolUse hook for Read tool

set -euo pipefail

# Create logs directory if needed (inside scripts/ to avoid IDE pollution)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"

INPUT=$(cat)

# Extract file path from tool input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "")

if [[ -n "$FILE_PATH" ]]; then
    # Log the read operation
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Read: $FILE_PATH" >> "$LOG_DIR/discovery.log"

    # Track which types of files are being read
    case "$FILE_PATH" in
        *SKILL.md)
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Skill discovered: $FILE_PATH" >> "$LOG_DIR/discovery.log"
            ;;
        *.claude/agents/*.md)
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Agent discovered: $FILE_PATH" >> "$LOG_DIR/discovery.log"
            ;;
        *.mcp.json)
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] MCP config discovered: $FILE_PATH" >> "$LOG_DIR/discovery.log"
            ;;
        *settings.json)
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Settings discovered: $FILE_PATH" >> "$LOG_DIR/discovery.log"
            ;;
    esac
fi

exit 0
