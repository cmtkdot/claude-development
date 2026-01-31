#!/bin/bash
# Lints skill files after writing - quality checks
# PostToolUse hook - non-blocking warnings
set -euo pipefail

# Check jq dependency
command -v jq >/dev/null 2>&1 || { echo "Warning: jq not installed" >&2; exit 0; }

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only process skill files
if [[ ! "$FILE_PATH" =~ SKILL\.md$ ]]; then
    exit 0
fi

# Check if file exists
if [[ ! -f "$FILE_PATH" ]]; then
    exit 0
fi

WARNINGS=()

# Check for workflow summary in description (common mistake)
if grep -qE 'description:.*then.*then|description:.*step.*step|description:.*first.*then' "$FILE_PATH" 2>/dev/null; then
    WARNINGS+=("Description may contain workflow summary (should only have triggers)")
fi

# Check description starts with "Use when"
DESC=$(grep -m1 "^description:" "$FILE_PATH" | sed 's/^description:[[:space:]]*//' || true)
if [[ -n "$DESC" && ! "$DESC" =~ ^\"?Use\ when ]]; then
    WARNINGS+=("Description should start with 'Use when...'")
fi

# Check hooks syntax if present - validate flat format
if grep -q "^hooks:" "$FILE_PATH" 2>/dev/null; then
    # Check for nested hooks: array (wrong format)
    if grep -qE '^\s+hooks:\s*$' "$FILE_PATH" 2>/dev/null; then
        WARNINGS+=("Hook format may be wrong - use flat format (type: at same level as matcher:)")
    fi
fi

# Check for missing references to supporting files
if grep -qE '\[.*\]\(references?/' "$FILE_PATH" 2>/dev/null; then
    REF_DIR=$(dirname "$FILE_PATH")/references
    if [[ ! -d "$REF_DIR" ]]; then
        WARNINGS+=("References to references/ but directory doesn't exist")
    fi
fi

if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    echo "Skill lint warnings for $FILE_PATH:"
    for warning in "${WARNINGS[@]}"; do
        echo "  - $warning"
    done
else
    echo "Skill lint passed: $FILE_PATH"
fi

exit 0
