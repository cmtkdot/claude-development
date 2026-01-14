# Bash Hook Guide

## Use Bash When

- `PreToolUse` gating must be fast (< 1s) and mostly string/pattern checks.
- You’re validating shell commands, git operations, file paths, or environment constraints.
- You can express the logic as simple checks with early exits.

## Avoid Bash When

- You need complex JSON transforms, multi-stage reasoning, or non-trivial state.
- You need async I/O (HTTP calls, long-running checks).
- The logic is becoming hard to read or test.

## Skeleton (recommended)

Use the output helper style from `.claude/hooks/hooks-user-output-templates/bash.md`.

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
HOOK_EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // "PreToolUse"')
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "N/A"')

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
      systemMessage: ($icon + " " + $msg),
      hookSpecificOutput: {
        hookEventName: $event,
        permissionDecision: $dec
      }
    } + (if $rsn != "" then {hookSpecificOutput: {permissionDecisionReason: $rsn}} else {} end)'
}
```

## Example 1: PreToolUse “Dangerous Command” Guard

Use when you want quick, deterministic blocking.

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
HOOK_EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // "PreToolUse"')
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "N/A"')

output_message() {
  local icon="$1"
  local message="$2"
  local decision="${3:-allow}"
  local reason="${4:-}"
  jq -n --arg icon "$icon" --arg msg "$message" --arg event "$HOOK_EVENT" --arg dec "$decision" --arg rsn "$reason" \
    '{
      systemMessage: ($icon + " " + $msg),
      hookSpecificOutput: { hookEventName: $event, permissionDecision: $dec }
    } + (if $rsn != "" then {hookSpecificOutput: {permissionDecisionReason: $rsn}} else {} end)'
}

if [[ "$TOOL_NAME" != "Bash" ]]; then
  output_message "ℹ️" "Not a Bash tool call" "allow"
  exit 0
fi

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

case "$COMMAND" in
  *"rm -rf /"*|*"rm -rf ~"*|*"mkfs"*|*"dd if="* )
    output_message "🚫" "Blocked dangerous command" "deny" "Command matches a blocked pattern"
    exit 2
    ;;
esac

output_message "✅" "Command allowed" "allow"
exit 0
```

## Example 2: UserPromptSubmit “Trailing Flag Only” Trigger

Use when you want opt-in behavior like `... //` without accidentally matching URLs/paths.

```bash
has_optimize_flag() {
  local prompt="$1"
  [[ "$prompt" =~ //enhance[[:space:]]*$ ]] || [[ "$prompt" =~ //[[:space:]]*$ ]]
}
```

## Do / Don’t

- Do: short-circuit early for non-matching tools/events.
- Do: keep logic deterministic; avoid long subprocess chains.
- Don’t: “parse JSON” with regex; use `jq`.
- Don’t: add network calls to `PreToolUse`.

