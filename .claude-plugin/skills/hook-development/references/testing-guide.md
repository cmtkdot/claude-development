# Hook Testing Guide

Complete testing workflow for hook scripts.

## Step 7: Syntax Check

```bash
# Bash
bash -n .claude/hooks/utils/{eventType}/{hook-name}.sh

# Node.js
node --check .claude/hooks/utils/{eventType}/{hook-name}.cjs

# Python
python -m py_compile .claude/hooks/utils/{eventType}/{hook-name}.py
```

## Step 8: Unit Test

Create `.claude/hooks/utils/{eventType}/{hook-name}.test.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$SCRIPT_DIR/{hook-name}.sh"

# Test: matching case
output=$(echo '{"tool_name": "Write", "hook_event_name": "PreToolUse"}' | bash "$HOOK")
[[ $? -eq 0 ]] || { echo "FAIL: exit code"; exit 1; }
echo "$output" | jq -e '.hookSpecificOutput' >/dev/null || { echo "FAIL: JSON"; exit 1; }

# Test: non-matching case (fast exit)
echo '{"tool_name": "Read", "hook_event_name": "PreToolUse"}' | bash "$HOOK"
[[ $? -eq 0 ]] || { echo "FAIL: should pass non-matching"; exit 1; }

echo "PASS"
```

Run all hook tests:
```bash
bash .claude/hooks/tests/run-all-tests.sh --quick
```

## Step 9: Integration Test

Trigger the actual hook in Claude:

| Event | How to Test |
|-------|-------------|
| `PreToolUse` | Ask Claude to use the matched tool |
| `PostToolUse` | Execute the matched tool, verify side effects |
| `UserPromptSubmit` | Submit prompt with trigger pattern |
| `Stop` | Complete a response, verify auto-fix runs |
| `SessionStart` | Start new session |

## Test Payloads by Event

### PreToolUse
```json
{
  "tool_name": "Write",
  "tool_input": {"file_path": "/test/file.txt", "content": "test"},
  "hook_event_name": "PreToolUse",
  "session_id": "test-session"
}
```

### PostToolUse
```json
{
  "tool_name": "Write",
  "tool_input": {"file_path": "/test/file.txt"},
  "tool_response": {"success": true},
  "hook_event_name": "PostToolUse",
  "session_id": "test-session"
}
```

### UserPromptSubmit
```json
{
  "prompt": "test prompt",
  "hook_event_name": "UserPromptSubmit"
}
```

### SessionStart
```json
{
  "source": "startup",
  "hook_event_name": "SessionStart"
}
```
