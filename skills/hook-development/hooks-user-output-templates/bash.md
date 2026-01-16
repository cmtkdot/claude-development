### Hook Output Templates

- Use these templates for consistent, visually appealing hook output.
- Apply the template(s) applicable to your hook.
- ANSI codes are stripped, so use Unicode only.

#### **Unicode Characters Reference**

```bash
# Status indicators
SUCCESS="✅"
FAILURE="❌"
WARNING="⚠️"
INFO="ℹ️"
PROGRESS="⏳"
BLOCKED="🚫"

# Progress bars
FULL="█"
EMPTY="░"

# Box drawing
BOX_TL="╔"  # top-left
BOX_TR="╗"  # top-right
BOX_BL="╚"  # bottom-left
BOX_BR="╝"  # bottom-right
BOX_H="═"   # horizontal
BOX_V="║"   # vertical
BOX_VR="╠"  # vertical-right
BOX_VL="╣"  # vertical-left
```

#### **Bash Template**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Unicode symbols
readonly SUCCESS="✅"
readonly FAILURE="❌"
readonly WARNING="⚠️"
readonly INFO="ℹ️"
readonly PROGRESS="⏳"
readonly BLOCKED="🚫"

# Box drawing characters
readonly BOX_TL="╔"
readonly BOX_TR="╗"
readonly BOX_BL="╚"
readonly BOX_BR="╝"
readonly BOX_H="═"
readonly BOX_V="║"
readonly BOX_VR="╠"
readonly BOX_VL="╣"

# Read and parse input
INPUT=$(cat)
HOOK_EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // "PreToolUse"')
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "N/A"')

# Log file
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
LOG_FILE="$PROJECT_DIR/.claude/hooks/logs/$(basename "$0" .sh).log"
mkdir -p "$(dirname "$LOG_FILE")"
echo "[$(date)] Hook started: $HOOK_EVENT for $TOOL_NAME" >> "$LOG_FILE"

# Function: Output with systemMessage
output_message() {
  local icon="$1"
  local message="$2"
  local decision="${3:-allow}"
  local reason="${4:-}"

  jq -n \
    --arg icon "$icon" \
    --arg msg "$message" \
    --arg event "$HOOK_EVENT" \
    --arg dec "$decision" \
    --arg rsn "$reason" \
    '{
      systemMessage: (if $icon == "" then $msg else ($icon + " " + $msg) end),
      hookSpecificOutput: {
        hookEventName: $event,
        permissionDecision: $dec
      }
    }
    | if $rsn != "" then .hookSpecificOutput.permissionDecisionReason = $rsn else . end'
}

# Your validation logic here
if [[ "$TOOL_NAME" == "Bash" ]]; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

  if [[ "$COMMAND" == *"rm -rf"* ]]; then
    output_message "$FAILURE" "Blocked dangerous command" "deny" "rm -rf not allowed"
    exit 2
  fi
fi

# Success case
output_message "$SUCCESS" "Validation passed" "allow"
exit 0
```

#### **Progress Bar Template (Bash)**

```bash
progress_bar() {
  local percent="$1"
  local width=20
  local filled=$((percent * width / 100))
  local empty=$((width - filled))

  printf "["
  printf "%${filled}s" | tr ' ' '█'
  printf "%${empty}s" | tr ' ' '░'
  printf "] %d%%" "$percent"
}

# Usage:
MESSAGE="Processing: $(progress_bar 75)"
output_message "$INFO" "$MESSAGE" "allow"
```

#### **Box Template (Bash)**

```bash
create_box() {
  local title="$1"
  shift
  local lines=("$@")

  local width=${#title}
  local line
  for line in "${lines[@]}"; do
    if [[ ${#line} -gt $width ]]; then
      width=${#line}
    fi
  done
  width=$((width + 4))

  echo -n "$BOX_TL"
  printf "%${width}s" | tr ' ' "$BOX_H"
  echo "$BOX_TR"

  local padding=$((width - ${#title} - 2))
  echo "$BOX_V $title$(printf "%${padding}s")$BOX_V"

  echo -n "$BOX_VR"
  printf "%${width}s" | tr ' ' "$BOX_H"
  echo "$BOX_VL"

  for line in "${lines[@]}"; do
    local line_padding=$((width - ${#line} - 2))
    echo "$BOX_V $line$(printf "%${line_padding}s")$BOX_V"
  done

  echo -n "$BOX_BL"
  printf "%${width}s" | tr ' ' "$BOX_H"
  echo "$BOX_BR"
}

# Usage:
BOX=$(create_box "Hook Status" \
  "$SUCCESS Validation: Passed" \
  "$INFO Tool: $TOOL_NAME" \
  "$PROGRESS Duration: 0.5s")

output_message "" "$BOX" "allow"
```
