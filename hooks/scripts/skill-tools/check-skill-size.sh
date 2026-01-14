#!/bin/bash
# Warns if SKILL.md exceeds recommended size
# PostToolUse hook - non-blocking warning

set -euo pipefail

# Read tool input from stdin
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // empty' 2>/dev/null || true)

# Only check SKILL.md files
if [[ ! "$FILE_PATH" =~ SKILL\.md$ ]]; then
    exit 0
fi

# Check if file exists
if [[ ! -f "$FILE_PATH" ]]; then
    exit 0
fi

LINE_COUNT=$(wc -l < "$FILE_PATH" | tr -d ' ')
WORD_COUNT=$(wc -w < "$FILE_PATH" | tr -d ' ')

echo "Skill size check: $FILE_PATH"
echo "  Lines: $LINE_COUNT"
echo "  Words: $WORD_COUNT"

# Progressive disclosure thresholds
ISSUES=()

if [[ $LINE_COUNT -gt 500 ]]; then
    ISSUES+=("SKILL.md has $LINE_COUNT lines (recommended: <500)")
    ISSUES+=("Consider moving detailed content to reference.md")
fi

if [[ $WORD_COUNT -gt 2000 ]]; then
    ISSUES+=("SKILL.md has $WORD_COUNT words (recommended: <2000)")
fi

# Check for common bloat indicators - code blocks
CODE_BLOCKS=$(grep -c '^\`\`\`' "$FILE_PATH" 2>/dev/null || echo "0")
if [[ $CODE_BLOCKS -gt 10 ]]; then
    ISSUES+=("Many code blocks ($CODE_BLOCKS) - consider moving examples to scripts/")
fi

# Check for tables (can bloat token count)
TABLE_ROWS=$(grep -c '^|' "$FILE_PATH" 2>/dev/null || echo "0")
if [[ $TABLE_ROWS -gt 50 ]]; then
    ISSUES+=("Many table rows ($TABLE_ROWS) - consider moving to reference.md")
fi

if [[ ${#ISSUES[@]} -gt 0 ]]; then
    echo ""
    echo "Size warnings:"
    for issue in "${ISSUES[@]}"; do
        echo "  - $issue"
    done
else
    echo "  Size within limits"
fi

exit 0
