#!/bin/bash
# Lints hook scripts after writing

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only process hook scripts in hooks/scripts/ or .claude/hooks/scripts/
if [[ ! "$FILE_PATH" =~ hooks/scripts/.+\.(sh|py|cjs)$ ]]; then
    exit 0
fi

ERRORS=""
WARNINGS=""

# Get file extension
EXT="${FILE_PATH##*.}"

# Syntax check based on language
case "$EXT" in
    sh)
        if ! bash -n "$FILE_PATH" 2>/dev/null; then
            ERRORS="${ERRORS}* Bash syntax error in $FILE_PATH\n"
        fi

        # Check for common bash hook issues
        if ! grep -q 'set -.*u' "$FILE_PATH" 2>/dev/null; then
            WARNINGS="${WARNINGS}* Missing 'set -u' (unset variable protection)\n"
        fi

        if ! grep -q 'jq' "$FILE_PATH" 2>/dev/null && grep -q 'tool_input\|tool_name' "$FILE_PATH" 2>/dev/null; then
            WARNINGS="${WARNINGS}* Parsing JSON without jq (recommended for safety)\n"
        fi

        # Check for reading stdin once
        STDIN_READS=$(grep -c 'cat\s*$\|read\s\|</dev/stdin' "$FILE_PATH" 2>/dev/null || echo "0")
        if [ "$STDIN_READS" -gt 1 ]; then
            ERRORS="${ERRORS}* Reading stdin multiple times (cache in variable)\n"
        fi
        ;;
    py)
        if ! python -m py_compile "$FILE_PATH" 2>/dev/null; then
            ERRORS="${ERRORS}* Python syntax error in $FILE_PATH\n"
        fi
        ;;
    cjs)
        if ! node --check "$FILE_PATH" 2>/dev/null; then
            ERRORS="${ERRORS}* Node.js syntax error in $FILE_PATH\n"
        fi
        ;;
esac

# Check for proper exit codes documentation
if ! grep -qE 'exit\s+[02]' "$FILE_PATH" 2>/dev/null; then
    WARNINGS="${WARNINGS}* No explicit exit codes (0=success, 2=block)\n"
fi

# Check for hardcoded paths
if grep -E '"/Users/|"/home/|/tmp/' "$FILE_PATH" 2>/dev/null | grep -qv 'CLAUDE_PROJECT_DIR'; then
    WARNINGS="${WARNINGS}* Hardcoded paths detected (use \$CLAUDE_PROJECT_DIR)\n"
fi

# Output errors first (blocking)
if [ -n "$ERRORS" ]; then
    echo -e "Hook lint ERRORS:\n$ERRORS" >&2
    exit 2  # Block on errors
fi

# Output warnings (non-blocking)
if [ -n "$WARNINGS" ]; then
    jq -n --arg warnings "$WARNINGS" '{
        hookSpecificOutput: {
            hookEventName: "PostToolUse",
            additionalContext: ("Hook lint warnings:\n" + $warnings)
        }
    }'
    exit 0
fi

echo "Hook lint passed"
exit 0
