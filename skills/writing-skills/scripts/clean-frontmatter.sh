#!/usr/bin/env bash
# Clean SKILL.md frontmatter to only include valid fields
# Valid fields: name, description, allowed-tools, model, context, agent, hooks, user-invocable, disable-model-invocation

set -euo pipefail

SKILLS_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/skills"
VALID_FIELDS=("name" "description" "allowed-tools" "model" "context" "agent" "hooks" "user-invocable" "disable-model-invocation")

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

# Extract and clean frontmatter
clean_frontmatter() {
  local file="$1"
  local temp_file="${file}.tmp"

  # Extract frontmatter and body separately
  awk '
    /^---$/ {
      if (in_fm) {
        in_fm=0
        print "---"
        next
      } else {
        in_fm=1
        print
        next
      }
    }
    !in_fm { print }
  ' "$file" > "$temp_file"

  # Now extract just the frontmatter fields
  local fm_temp="${file}.fm"
  awk '
    /^---$/ { if(in_fm) exit; in_fm=1; next }
    in_fm { print }
  ' "$file" > "$fm_temp"

  # Rebuild file with cleaned frontmatter
  {
    echo "---"

    # Extract fields in order: name, description, then others
    awk -v f="name" '
      /^[a-z-]+:/ {
        field = $1
        sub(/:$/, "", field)
        if (field == f) {
          sub("^"f": *", "")
          print f": " $0
        }
      }
    ' "$fm_temp"

    awk -v f="description" '
      /^[a-z-]+:/ {
        field = $1
        sub(/:$/, "", field)
        if (field == f) {
          sub("^"f": *", "")
          print f": " $0
        }
      }
    ' "$fm_temp"

    # Other valid fields (excluding name and description)
    awk '
      /^[a-z-]+:/ {
        field = $1
        sub(/:$/, "", field)
        if (field != "name" && field != "description") {
          # Check if valid
          valid=0
          if (field == "allowed-tools" || field == "model" || field == "context" ||
              field == "agent" || field == "hooks" || field == "user-invocable" ||
              field == "disable-model-invocation") {
            valid=1
          }
          if (valid) {
            sub("^"field": *", "")
            print field": " $0
          }
        }
      }
    ' "$fm_temp"

    echo "---"
  } > "$temp_file.new"

  # Append body (everything after second ---)
  tail -n +1 "$temp_file" | awk '
    /^---$/ { if(count==1) { found=1; next } count++ }
    found { print }
  ' >> "$temp_file.new"

  # Replace original file
  mv "$temp_file.new" "$file"
  rm -f "$temp_file" "$fm_temp"
}

# Main loop
echo "Cleaning SKILL.md frontmatter..."
cleaned=0
total=0

if [[ -d "$SKILLS_DIR" ]]; then
  while IFS= read -r f; do
    [[ -f "$f" ]] || continue
    ((total++))

    # Check if file has invalid fields
    has_invalid=false
    while IFS= read -r line; do
      if [[ $line =~ ^[a-z-]+: ]]; then
        field="${line%%:*}"
        if ! is_valid_field "$field"; then
          has_invalid=true
          break
        fi
      fi
    done < <(awk '/^---$/{if(in_fm)exit;in_fm=1;next} in_fm' "$f")

    if [[ "$has_invalid" == "true" ]]; then
      echo "  Cleaning $(basename "$f")..."
      clean_frontmatter "$f"
      ((cleaned++))
    fi
  done < <(find "$SKILLS_DIR" -name "SKILL.md" -type f 2>/dev/null | sort)
fi

echo ""
echo "Summary:"
echo "  Total SKILL.md files: $total"
echo "  Files cleaned: $cleaned"
echo ""
echo "Done!"
