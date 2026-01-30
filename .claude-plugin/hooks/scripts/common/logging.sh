#!/usr/bin/env bash
# Shared logging utilities for hooks
# Logs are stored in the PROJECT where Claude Code is running, not the plugin source
#
# Source this file: source "$(dirname "$0")/logging.sh"
#
# Log location: $CLAUDE_PROJECT_DIR/.claude/hooks/.cache/YYYY-MM-DD/
# This ensures logs stay with the project being worked on, not the plugin itself.

# Initialize logging directory structure
# Usage: init_log_dir [session_id]
# Returns: Sets LOG_BASE, LOG_DATE_DIR, SESSION_LOG variables
init_log_dir() {
    # CLAUDE_PROJECT_DIR is set by Claude Code to the project being worked on
    # This is NOT the plugin directory - it's where the user is running Claude
    local project_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"
    local session_id="${1:-unknown}"
    local date_folder=$(date '+%Y-%m-%d')

    # Log to the TARGET PROJECT's .claude/hooks/.cache/
    # NOT to the plugin source directory
    LOG_BASE="$project_dir/.claude/hooks/.cache"
    LOG_DATE_DIR="$LOG_BASE/$date_folder"
    SESSION_LOG="$LOG_DATE_DIR/session-${session_id}.log"

    # Create directory structure in the target project
    mkdir -p "$LOG_DATE_DIR" 2>/dev/null || true

    # Ensure .gitignore exists in target project to exclude cache
    local gitignore="$project_dir/.gitignore"
    if [[ -f "$gitignore" ]]; then
        if ! grep -q ".claude/hooks/.cache" "$gitignore" 2>/dev/null; then
            echo "" >> "$gitignore"
            echo "# Claude Code hook logs (auto-added)" >> "$gitignore"
            echo ".claude/hooks/.cache/" >> "$gitignore"
        fi
    fi

    # Export for use by caller
    export LOG_BASE LOG_DATE_DIR SESSION_LOG
}

# Log a message to the appropriate log file
# Usage: log_event <category> <message> [session_id]
# Categories: tool-failure, subagent, audit, validation, init
log_event() {
    local category="$1"
    local message="$2"
    local session_id="${3:-unknown}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    init_log_dir "$session_id"

    # Category-specific log file
    local category_log="$LOG_DATE_DIR/${category}.log"

    # Write to category log
    echo "[$timestamp] $message" >> "$category_log" 2>/dev/null || true

    # Also write to session log if session is known
    if [[ "$session_id" != "unknown" ]]; then
        echo "[$timestamp] [$category] $message" >> "$SESSION_LOG" 2>/dev/null || true
    fi
}

# Log structured JSON event
# Usage: log_json <category> <json_string> [session_id]
log_json() {
    local category="$1"
    local json="$2"
    local session_id="${3:-unknown}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    init_log_dir "$session_id"

    # JSON log file (append JSONL format)
    local json_log="$LOG_DATE_DIR/${category}.jsonl"

    # Add timestamp to JSON and write
    if command -v jq &>/dev/null; then
        echo "$json" | jq -c --arg ts "$timestamp" '. + {timestamp: $ts}' >> "$json_log" 2>/dev/null || \
            echo "{\"timestamp\": \"$timestamp\", \"raw\": \"$(echo "$json" | tr '"' "'" | head -c 1000)\"}" >> "$json_log"
    else
        echo "{\"timestamp\": \"$timestamp\", \"data\": \"jq not available\"}" >> "$json_log"
    fi
}

# Get summary of today's logs
# Usage: get_log_summary [project_dir]
get_log_summary() {
    local project_dir="${1:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"
    local date_folder=$(date '+%Y-%m-%d')
    local log_dir="$project_dir/.claude/hooks/.cache/$date_folder"

    if [[ -d "$log_dir" ]]; then
        echo "=== Log Summary for $date_folder ==="
        echo "Location: $log_dir"
        echo ""
        for log in "$log_dir"/*.log; do
            if [[ -f "$log" ]]; then
                local name=$(basename "$log" .log)
                local count=$(wc -l < "$log" 2>/dev/null | tr -d ' ')
                echo "  $name: $count entries"
            fi
        done
    else
        echo "No logs for today at: $log_dir"
    fi
}

# Clean old logs (keep last N days)
# Usage: clean_old_logs [days_to_keep]
clean_old_logs() {
    local days="${1:-7}"
    local project_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"
    local log_base="$project_dir/.claude/hooks/.cache"

    if [[ -d "$log_base" ]]; then
        find "$log_base" -type d -mtime +"$days" -exec rm -rf {} \; 2>/dev/null || true
        echo "Cleaned logs older than $days days"
    fi
}
