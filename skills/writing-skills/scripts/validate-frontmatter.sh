#!/usr/bin/env bash
# Validate and clean SKILL.md frontmatter to only include valid fields
# Valid fields: name, description, allowed-tools, model, context, agent, hooks, user-invocable, disable-model-invocation

set -euo pipefail

SKILLS_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/skills"
VALID_FIELDS=("name" "description" "allowed-tools" "model" "context" "agent" "hooks" "user-invocable" "disable-model-invocation")

# Extract frontmatter from a file
extract_frontmatter() {
  local file="$1"
  awk '
    /^---$/ { if(in_fm) { print "---"; exit } else { in_fm=1; print; next } }
    in_fm { print }
  ' "$file"
}

# Check if field is valid
is_valid_field() {
  local field="$1"
  for valid in "${VALID_FIELDS[@]}"; do
    if [[ "$field" == "$valid" ]]; then
      return 0
    fi
  done
  return 1
}

# Extract specific field value from frontmatter
get_field_value() {
  local file="$1" field="$2"
  awk -v f="$field" '
    /^---$/ { if(in_fm) exit; in_fm=1; next }
    in_fm && $0 ~ "^"f":" {
      sub("^"f": *", "")
      print
      exit
    }
  ' "$file"
}

# Report invalid fields found
report_invalid_fields() {
  local file="$1"
  local invalid_found=0

  awk '
    /^---$/ { if(in_fm) exit; in_fm=1; next }
    in_fm && /^[a-z-]+:/ {
      field = $1
      sub(/:$/, "", field)
      print field
    }
  ' "$file" | while read -r field; do
    if ! is_valid_field "$field"; then
      if [[ $invalid_found -eq 0 ]]; then
        echo "  Invalid fields in $(basename "$file"):"
        invalid_found=1
      fi
      echo "    - $field"
    fi
  done
}

# Count files with issues
echo "Scanning SKILL.md files for invalid frontmatter..."
echo ""

invalid_count=0
total_count=0

if [[ -d "$SKILLS_DIR" ]]; then
  while IFS= read -r f; do
    [[ -f "$f" ]] || continue
    ((total_count++))

    # Check for invalid fields
    has_invalid=false
    awk '
      /^---$/ { if(in_fm) exit; in_fm=1; next }
      in_fm && /^[a-z-]+:/ {
        field = $1
        sub(/:$/, "", field)
        print field
      }
    ' "$f" | while read -r field; do
      if ! is_valid_field "$field"; then
        has_invalid=true
        break
      fi
    done

    if [[ "$has_invalid" == "true" ]]; then
      ((invalid_count++))
      report_invalid_fields "$f"
    fi
  done < <(find "$SKILLS_DIR" -name "SKILL.md" -type f 2>/dev/null | sort)
fi

echo ""
echo "Summary:"
echo "  Total SKILL.md files: $total_count"
echo "  Files with invalid fields: $invalid_count"
echo ""

if [[ $invalid_count -gt 0 ]]; then
  echo "Run 'clean-frontmatter.sh' to fix these issues."
  exit 1
else
  echo "All SKILL.md files have valid frontmatter!"
  exit 0
fi
