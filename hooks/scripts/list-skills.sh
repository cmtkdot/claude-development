#!/usr/bin/env bash
# List all skills with full metadata for overlap detection
# Searches: Project (.claude/skills), User (~/.claude/skills), Plugin (~/.claude/plugins/cache)
# Output: JSON array of skill objects

set -euo pipefail

PROJECT="${CLAUDE_PROJECT_DIR:-.}/.claude/skills"
USER_SKILLS="$HOME/.claude/skills"
PLUGINS="$HOME/.claude/plugins/cache"

# Extract field from YAML frontmatter
get_field() {
  local file="$1" field="$2"
  awk -v f="$field" '
    /^---$/ { if(in_fm) exit; in_fm=1; next }
    in_fm && $0 ~ "^"f":" {
      sub("^"f": *", "")
      gsub(/^["'\''"]|["'\''"]$/, "")
      print
      exit
    }
  ' "$file"
}

# Extract array field from YAML frontmatter (handles both inline [a,b] and multiline - a)
get_array_field() {
  local file="$1" field="$2"
  awk -v f="$field" '
    /^---$/ { if(in_fm) exit; in_fm=1; next }
    in_fm && $0 ~ "^"f":" {
      # Check for inline array [a, b, c]
      if (match($0, /\[.*\]/)) {
        arr = substr($0, RSTART+1, RLENGTH-2)
        gsub(/ /, "", arr)
        print arr
        exit
      }
      # Check for inline comma-separated (allowed-tools: Read, Grep, Glob)
      sub("^"f": *", "")
      if (length($0) > 0 && $0 !~ /^$/) {
        gsub(/ /, "", $0)
        print $0
        exit
      }
      # Multiline array starts
      in_array=1
      next
    }
    in_fm && in_array {
      if (/^  - /) {
        sub(/^  - /, "")
        gsub(/^["'\''"]|["'\''"]$/, "")
        items = items ? items","$0 : $0
      } else if (/^[^ ]/) {
        # New field, end of array
        print items
        exit
      }
    }
    END { if (in_array && items) print items }
  ' "$file"
}

# JSON escape helper
json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g' | tr -d '\n'
}

# Convert comma-separated to JSON array
to_json_array() {
  local input="$1"
  if [[ -z "$input" ]]; then
    echo "[]"
    return
  fi
  local result="["
  local first=true
  IFS=',' read -ra items <<< "$input"
  for item in "${items[@]}"; do
    item=$(echo "$item" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [[ -n "$item" ]]; then
      if $first; then
        first=false
      else
        result+=","
      fi
      result+="\"$(json_escape "$item")\""
    fi
  done
  result+="]"
  echo "$result"
}

# Check if hooks field exists in YAML frontmatter
has_hooks() {
  local file="$1"
  awk '
    /^---$/ { if(in_fm) exit; in_fm=1; next }
    in_fm && /^hooks:/ { found=1; print "true"; exit }
    END { if (!found) print "false" }
  ' "$file" | head -1
}

# Process a single skill file
process_skill() {
  local f="$1" location="$2"

  local name=$(get_field "$f" "name")
  local desc=$(get_field "$f" "description")
  local allowed_tools=$(get_array_field "$f" "allowed-tools")
  local model=$(get_field "$f" "model")
  local context=$(get_field "$f" "context")
  local agent=$(get_array_field "$f" "agent")  # Can be array or single
  local user_invocable=$(get_field "$f" "user-invocable")
  local has_hooks_val=$(has_hooks "$f")

  # Use directory name as name if not in frontmatter
  if [[ -z "$name" ]]; then
    name=$(basename "$(dirname "$f")")
  fi

  # Default user-invocable to true if not specified
  if [[ -z "$user_invocable" ]]; then
    user_invocable="true"
  fi

  local tools_json=$(to_json_array "$allowed_tools")
  local agent_json=$(to_json_array "$agent")

  echo "{\"location\":\"$location: $(json_escape "$f")\",\"name\":\"$(json_escape "$name")\",\"description\":\"$(json_escape "$desc")\",\"allowed-tools\":$tools_json,\"model\":\"$(json_escape "$model")\",\"context\":\"$(json_escape "$context")\",\"agent\":$agent_json,\"user-invocable\":$user_invocable,\"has-hooks\":$has_hooks_val}"
}

# Collect all skills
skills=()

# Project skills
if [[ -d "$PROJECT" ]]; then
  for f in "$PROJECT"/*/SKILL.md; do
    [[ -f "$f" ]] || continue
    skills+=("$(process_skill "$f" "project")")
  done
fi

# User skills
if [[ -d "$USER_SKILLS" ]]; then
  for f in "$USER_SKILLS"/*/SKILL.md; do
    [[ -f "$f" ]] || continue
    skills+=("$(process_skill "$f" "user")")
  done
fi

# Plugin skills
if [[ -d "$PLUGINS" ]]; then
  while IFS= read -r f; do
    [[ -f "$f" ]] || continue
    skills+=("$(process_skill "$f" "plugin")")
  done < <(find "$PLUGINS" -path "*/skills/*/SKILL.md" -type f 2>/dev/null)
fi

# Output JSON array
echo "["
for i in "${!skills[@]}"; do
  if [[ $i -eq $((${#skills[@]} - 1)) ]]; then
    echo "  ${skills[$i]}"
  else
    echo "  ${skills[$i]},"
  fi
done
echo "]"

exit 0
