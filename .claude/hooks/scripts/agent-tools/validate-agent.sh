#!/bin/bash
# Validates agent markdown structure and frontmatter
# Exit 0 = valid, Exit 2 = block with error

set -euo pipefail

# Read tool input from stdin
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // empty' 2>/dev/null || true)

# Only validate agent files
if [[ ! "$FILE_PATH" =~ \.claude/agents/.*\.md$ ]]; then
    exit 0
fi

# Check if file exists (for edits)
if [[ ! -f "$FILE_PATH" ]]; then
    exit 0  # New file, will validate on PostToolUse
fi

# Extract frontmatter only (between first two --- lines)
FRONTMATTER=$(awk '/^---$/{n++; next} n==1{print} n==2{exit}' "$FILE_PATH")

if [[ -z "$FRONTMATTER" ]]; then
    echo "ERROR: Agent file missing frontmatter (---)" >&2
    exit 2
fi

# Check required field: name (first match only)
NAME=$(echo "$FRONTMATTER" | grep -m1 -E "^name:" | sed 's/^name:[[:space:]]*//; s/["'"'"']//g' | tr -d ' ' || true)
if [[ -z "$NAME" ]]; then
    echo "ERROR: Missing 'name' field in frontmatter" >&2
    exit 2
fi

# Validate name format (lowercase, hyphens, numbers only, max 64 chars)
if [[ ! "$NAME" =~ ^[a-z0-9-]+$ ]]; then
    echo "ERROR: Agent name '$NAME' must be lowercase letters, numbers, and hyphens only" >&2
    exit 2
fi

if [[ ${#NAME} -gt 64 ]]; then
    echo "ERROR: Agent name '$NAME' exceeds 64 characters (${#NAME} chars)" >&2
    exit 2
fi

# Check required field: description (first match only)
DESCRIPTION=$(echo "$FRONTMATTER" | grep -m1 -E "^description:" | sed 's/^description:[[:space:]]*//; s/^["'"'"']//; s/["'"'"']$//' || true)
if [[ -z "$DESCRIPTION" ]]; then
    echo "ERROR: Missing 'description' field in frontmatter" >&2
    exit 2
fi

# Check description length
if [[ ${#DESCRIPTION} -gt 1024 ]]; then
    echo "ERROR: Description exceeds 1024 characters (${#DESCRIPTION} chars)" >&2
    exit 2
fi

# Warn if description doesn't start with "Use when" or action verbs (non-blocking)
if [[ ! "$DESCRIPTION" =~ ^(Use\ when|Creates|Analyzes|Expert) ]]; then
    echo "WARNING: Description should start with 'Use when...' or action verb for better discoverability" >&2
fi

# Validate tools field if present (first match only)
TOOLS=$(echo "$FRONTMATTER" | grep -m1 -E "^tools:" || true)
if [[ -n "$TOOLS" ]]; then
    VALID_TOOLS="Read|Write|Edit|Bash|Glob|Grep|Task|TodoWrite|WebFetch|WebSearch|AskUserQuestion|NotebookEdit"
    # Clean up YAML array syntax: remove brackets, quotes, then split by comma
    TOOL_LIST=$(echo "$TOOLS" | sed 's/tools:[[:space:]]*//; s/^\[//; s/\]$//; s/["'"'"']//g' | tr ',' '\n')
    while read -r tool; do
        tool=$(echo "$tool" | tr -d ' ')
        [[ -z "$tool" ]] && continue
        if [[ ! "$tool" =~ ^($VALID_TOOLS)$ ]]; then
            echo "WARNING: Unknown tool '$tool' in tools field" >&2
        fi
    done <<< "$TOOL_LIST"
fi

# Validate model field if present (first match only)
MODEL=$(echo "$FRONTMATTER" | grep -m1 -E "^model:" | sed 's/^model:[[:space:]]*//; s/["'"'"']//g' | tr -d ' ' || true)
if [[ -n "$MODEL" ]]; then
    if [[ ! "$MODEL" =~ ^(haiku|sonnet|opus)$ ]]; then
        echo "WARNING: Model '$MODEL' may not be valid. Expected: haiku, sonnet, or opus" >&2
    fi
fi

echo "Agent validation passed: $NAME"
exit 0
