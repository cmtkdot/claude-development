#!/usr/bin/env bash
# Stop hook - Generate completion report for any agent
set -euo pipefail

# Check dependencies
command -v jq >/dev/null 2>&1 || { echo "Warning: jq not installed, skipping completion report" >&2; exit 0; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/logging.sh" 2>/dev/null || true

# Read stdin safely
INPUT=""
if ! INPUT=$(cat 2>/dev/null); then
  echo "Warning: Failed to read stdin" >&2
  exit 0
fi

# Validate JSON and extract fields with defaults
if ! echo "$INPUT" | jq -e . >/dev/null 2>&1; then
  echo "Warning: Invalid JSON input" >&2
  exit 0
fi

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // "false"')

# Prevent infinite loop - check for both string and boolean true
if [[ "$STOP_HOOK_ACTIVE" == "true" ]] || [[ "$STOP_HOOK_ACTIVE" == "1" ]]; then
  exit 0
fi

echo "=== Session Completion Report ==="
echo "Session: $SESSION_ID"
echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Summary of work done (from transcript if available)
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')
if [[ -n "$TRANSCRIPT" ]] && [[ -f "$TRANSCRIPT" ]]; then
  TOOL_COUNT=$(grep -c '"tool_use"' "$TRANSCRIPT" 2>/dev/null || echo "0")
  echo "Tools used: $TOOL_COUNT"
fi

exit 0
