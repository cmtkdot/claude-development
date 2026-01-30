#!/usr/bin/env bash
# View hook logs - utility for browsing logs in any project
# Logs are stored in: $CLAUDE_PROJECT_DIR/.claude/hooks/.cache/
#
# Usage: view-logs.sh [date] [category]
#   date: YYYY-MM-DD (default: today)
#   category: subagent, tool-failure, init, validation, audit (default: all)
#
# Examples:
#   view-logs.sh                    # Today's logs
#   view-logs.sh 2026-01-29         # Specific date
#   view-logs.sh today subagent     # Today's subagent logs only
#   view-logs.sh --list             # List available dates

set -euo pipefail

# Use CLAUDE_PROJECT_DIR (set by Claude Code) or current directory
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LOG_BASE="$PROJECT_DIR/.claude/hooks/.cache"

# Parse arguments
DATE="${1:-$(date '+%Y-%m-%d')}"
CATEGORY="${2:-}"

# Handle special commands
if [[ "$DATE" == "--list" || "$DATE" == "-l" ]]; then
    echo "=== Available Log Dates ==="
    echo "Location: $LOG_BASE"
    echo ""
    if [[ -d "$LOG_BASE" ]]; then
        ls -1 "$LOG_BASE" 2>/dev/null | sort -r | head -20 || echo "  (no logs yet)"
    else
        echo "  (no logs directory yet)"
    fi
    exit 0
fi

if [[ "$DATE" == "--clean" ]]; then
    DAYS="${2:-7}"
    echo "Cleaning logs older than $DAYS days..."
    if [[ -d "$LOG_BASE" ]]; then
        find "$LOG_BASE" -type d -mtime +"$DAYS" -exec rm -rf {} \; 2>/dev/null || true
        echo "Done."
    fi
    exit 0
fi

if [[ "$DATE" == "today" ]]; then
    DATE=$(date '+%Y-%m-%d')
fi

LOG_DIR="$LOG_BASE/$DATE"

if [[ ! -d "$LOG_DIR" ]]; then
    echo "No logs found for $DATE"
    echo "Log location: $LOG_BASE"
    echo ""
    echo "Available dates:"
    if [[ -d "$LOG_BASE" ]]; then
        ls -1 "$LOG_BASE" 2>/dev/null | sort -r | head -10 || echo "  (no logs yet)"
    else
        echo "  (no logs directory yet - logs will appear after hooks run)"
    fi
    exit 0
fi

echo "=== Hook Logs for $DATE ==="
echo "Project: $PROJECT_DIR"
echo "Location: $LOG_DIR"
echo ""

if [[ -n "$CATEGORY" ]]; then
    # Show specific category
    if [[ -f "$LOG_DIR/${CATEGORY}.log" ]]; then
        echo "--- $CATEGORY.log ---"
        cat "$LOG_DIR/${CATEGORY}.log"
    fi
    if [[ -f "$LOG_DIR/${CATEGORY}.jsonl" ]]; then
        echo ""
        echo "--- $CATEGORY.jsonl (structured) ---"
        if command -v jq &>/dev/null; then
            cat "$LOG_DIR/${CATEGORY}.jsonl" | jq -c '.'
        else
            cat "$LOG_DIR/${CATEGORY}.jsonl"
        fi
    fi
    if [[ ! -f "$LOG_DIR/${CATEGORY}.log" && ! -f "$LOG_DIR/${CATEGORY}.jsonl" ]]; then
        echo "No logs for category: $CATEGORY"
        echo ""
        echo "Available categories:"
        ls -1 "$LOG_DIR"/*.log 2>/dev/null | xargs -I{} basename {} .log || echo "  (none)"
    fi
else
    # Show summary of all categories
    echo "--- Summary ---"
    for log in "$LOG_DIR"/*.log; do
        if [[ -f "$log" ]]; then
            name=$(basename "$log" .log)
            count=$(wc -l < "$log" 2>/dev/null | tr -d ' ')
            echo "  $name: $count entries"
        fi
    done
    echo ""

    # Show recent entries from each category
    for log in "$LOG_DIR"/*.log; do
        if [[ -f "$log" ]]; then
            name=$(basename "$log" .log)
            # Skip session logs in summary (show separately)
            if [[ "$name" != session-* ]]; then
                count=$(wc -l < "$log" 2>/dev/null | tr -d ' ')
                echo "--- $name (last 5 of $count) ---"
                tail -5 "$log"
                echo ""
            fi
        fi
    done

    # Show session logs separately
    session_count=0
    for session in "$LOG_DIR"/session-*.log; do
        if [[ -f "$session" ]]; then
            ((session_count++))
        fi
    done
    if [[ $session_count -gt 0 ]]; then
        echo "--- Sessions ($session_count total) ---"
        for session in "$LOG_DIR"/session-*.log; do
            if [[ -f "$session" ]]; then
                name=$(basename "$session" .log)
                count=$(wc -l < "$session" 2>/dev/null | tr -d ' ')
                echo "  $name: $count entries"
            fi
        done
    fi
fi
