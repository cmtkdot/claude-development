#!/bin/bash
# Lints agent markdown after Write/Edit operations
# PostToolUse hook - non-blocking

set -euo pipefail

# Read tool input from stdin
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // empty' 2>/dev/null || true)

# Only lint agent files
if [[ ! "$FILE_PATH" =~ \.claude/agents/.*\.md$ ]]; then
    exit 0
fi

# Check if file exists
if [[ ! -f "$FILE_PATH" ]]; then
    exit 0
fi

ISSUES=()
WARNINGS=()

# Extract frontmatter only (between first two --- lines)
FRONTMATTER=$(awk '/^---$/{n++; next} n==1{print} n==2{exit}' "$FILE_PATH")

# Check for common issues
if [[ -z "$FRONTMATTER" ]]; then
    ISSUES+=("Missing frontmatter")
fi

# Check name matches filename
NAME=$(echo "$FRONTMATTER" | grep -m1 -E "^name:" | sed 's/^name:[[:space:]]*//; s/["'"'"']//g' | tr -d ' ' || true)
FILENAME=$(basename "$FILE_PATH" .md)
if [[ -n "$NAME" && "$NAME" != "$FILENAME" ]]; then
    WARNINGS+=("Agent name '$NAME' doesn't match filename '$FILENAME'")
fi

# Check for skills field referencing non-existent skills
SKILLS_LINE=$(echo "$FRONTMATTER" | grep -m1 -E "^skills:" || true)
if [[ -n "$SKILLS_LINE" ]]; then
    # Clean up YAML array syntax: remove brackets, quotes, then split
    SKILLS=$(echo "$SKILLS_LINE" | sed 's/skills:[[:space:]]*//; s/^\[//; s/\]$//; s/["'"'"']//g')
    IFS=',' read -ra SKILL_ARRAY <<< "$SKILLS"
    for skill in "${SKILL_ARRAY[@]}"; do
        skill=$(echo "$skill" | tr -d ' ')
        [[ -z "$skill" ]] && continue
        # Check both project and user skills
        if [[ ! -d ".claude/skills/$skill" && ! -d "$HOME/.claude/skills/$skill" ]]; then
            WARNINGS+=("Skill '$skill' not found in project or user skills")
        fi
    done
fi

# Check file size
LINE_COUNT=$(wc -l < "$FILE_PATH" | tr -d ' ')
if [[ $LINE_COUNT -gt 300 ]]; then
    WARNINGS+=("Agent file has $LINE_COUNT lines (recommended: <300)")
fi

# Report results
if [[ ${#ISSUES[@]} -gt 0 ]]; then
    echo "Issues found in $FILE_PATH:"
    for issue in "${ISSUES[@]}"; do
        echo "  - $issue"
    done
fi

if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    echo "Warnings for $FILE_PATH:"
    for warning in "${WARNINGS[@]}"; do
        echo "  - $warning"
    done
fi

if [[ ${#ISSUES[@]} -eq 0 && ${#WARNINGS[@]} -eq 0 ]]; then
    echo "Agent lint passed: $FILE_PATH"
fi

exit 0
