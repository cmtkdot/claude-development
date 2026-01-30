#!/bin/bash
# Shared YAML parsing helpers for hook scripts
# Source this file: source "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/utils/yaml-helpers.sh"

# Extract frontmatter from markdown file (content between first two --- lines)
get_frontmatter() {
    local file="$1"
    awk '/^---$/{n++; next} n==1{print} n==2{exit}' "$file"
}

# Get YAML field value from frontmatter
# Usage: yaml_field "$frontmatter" "name"
yaml_field() {
    local frontmatter="$1"
    local field="$2"
    echo "$frontmatter" | grep -m1 -E "^${field}:" | sed "s/^${field}:[[:space:]]*//; s/^[\"']//; s/[\"']$//" | tr -d ' '
}

# Get YAML field with quotes preserved (for descriptions)
# Usage: yaml_field_quoted "$frontmatter" "description"
yaml_field_quoted() {
    local frontmatter="$1"
    local field="$2"
    echo "$frontmatter" | grep -m1 -E "^${field}:" | sed "s/^${field}:[[:space:]]*//; s/^[\"']//; s/[\"']$//"
}

# Get YAML array field as newline-separated values
# Usage: yaml_array "$frontmatter" "tools"
yaml_array() {
    local frontmatter="$1"
    local field="$2"
    echo "$frontmatter" | grep -m1 -E "^${field}:" | sed "s/^${field}:[[:space:]]*//; s/^\[//; s/\]$//; s/[\"']//g" | tr ',' '\n' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

# Check if frontmatter has a field
# Usage: has_field "$frontmatter" "model"
has_field() {
    local frontmatter="$1"
    local field="$2"
    echo "$frontmatter" | grep -qE "^${field}:"
}
