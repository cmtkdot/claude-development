#!/bin/bash
# Lints skill files after writing

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only process skill files
if [[ ! "$FILE_PATH" =~ SKILL\.md$ ]]; then
    exit 0
fi

ERRORS=""

# Check file size (warn if over 500 lines)
LINE_COUNT=$(wc -l < "$FILE_PATH" 2>/dev/null || echo "0")
if [ "$LINE_COUNT" -gt 500 ]; then
    ERRORS="${ERRORS}* Warning: Skill has $LINE_COUNT lines (recommend <500)\n"
fi

# Check for workflow summary in description (common mistake)
if grep -q "description:.*then.*then\|description:.*step.*step\|description:.*first.*then" "$FILE_PATH" 2>/dev/null; then
    ERRORS="${ERRORS}* Description may contain workflow summary (should only have triggers)\n"
fi

# Check hooks syntax if present
if grep -q "^hooks:" "$FILE_PATH" 2>/dev/null; then
    # Verify hook events are valid
    if grep -E "^\s+\w+:" "$FILE_PATH" | grep -vE "(PreToolUse|PostToolUse|Stop|matcher|hooks|type|command|prompt|once):" > /dev/null 2>&1; then
        ERRORS="${ERRORS}* Unknown hook event (valid: PreToolUse, PostToolUse, Stop)\n"
    fi
fi

if [ -n "$ERRORS" ]; then
    echo -e "$ERRORS" >&2
    exit 0  # Non-blocking warnings
fi

echo "Skill lint passed"
exit 0
