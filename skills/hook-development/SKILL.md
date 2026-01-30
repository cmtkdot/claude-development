---
name: hook-development
description: "Use when creating hooks, configuring hook events, debugging hooks not firing, choosing hook types (command vs prompt), or understanding exit codes. Triggers: create hook, hook not working, PreToolUse, PostToolUse, Stop, settings.json hooks"
argument-hint: "[event-type]"
disable-model-invocation: true
---

# Hook Development

Hooks run scripts automatically at specific points in Claude's workflow. Unlike CLAUDE.md instructions which are advisory, hooks are deterministic.

## Hook Events

| Event | When | Matcher | Can Block |
|-------|------|---------|-----------|
| `SessionStart` | Session begins/resumes | source¹ | No |
| `UserPromptSubmit` | User submits prompt | No | Yes (exit 2) |
| `PreToolUse` | Before tool runs | Yes | Yes (exit 2) |
| `PermissionRequest` | Permission dialog shown | Yes | Yes (deny) |
| `PostToolUse` | After tool succeeds | Yes | No |
| `PostToolUseFailure` | After tool fails | Yes | No |
| `SubagentStart` | Subagent spawns | No | No |
| `SubagentStop` | Subagent finishes | No | Yes (exit 2) |
| `Stop` | Claude finishes | No | Yes (exit 2) |
| `PreCompact` | Before compaction | trigger² | No |
| `Setup` | --init or --maintenance | trigger³ | No |
| `Notification` | Notification sent | type⁴ | No |
| `SessionEnd` | Session ends | No | No |

¹ `startup`, `resume`, `clear`, `compact`
² `manual`, `auto`
³ `init`, `maintenance`
⁴ `permission_prompt`, `idle_prompt`, `auth_success`

## Configuration

Hooks in settings files (`~/.claude/settings.json`, `.claude/settings.json`):

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "npm run lint:fix $FILE",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

Plugin hooks use `${CLAUDE_PLUGIN_ROOT}` for portability.

## Hook Types

### Command Hooks (type: "command")

Run bash commands. Most common type.

```json
{
  "type": "command",
  "command": "bash /path/to/script.sh",
  "timeout": 30
}
```

### Prompt Hooks (type: "prompt")

LLM-evaluated hooks for context-aware decisions. Best for `Stop` and `SubagentStop`.

```json
{
  "type": "prompt",
  "prompt": "Evaluate if Claude should stop. Check if all tasks complete. Return {\"ok\": true} to allow, or {\"ok\": false, \"reason\": \"explanation\"} to continue.",
  "timeout": 30
}
```

## Exit Codes

| Exit | Behavior |
|------|----------|
| 0 | Success - parse JSON stdout if present |
| 2 | Block action - stderr shown to Claude |
| Other | Non-blocking error - logged only |

## Input (JSON via stdin)

Common fields:
```json
{
  "session_id": "abc123",
  "transcript_path": "~/.claude/projects/.../session.jsonl",
  "cwd": "/path/to/project",
  "permission_mode": "default",
  "hook_event_name": "PreToolUse"
}
```

Tool hooks add: `tool_name`, `tool_input`, `tool_use_id`
PostToolUse adds: `tool_response`

## Output (JSON via stdout)

### PreToolUse

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "Safe operation",
    "updatedInput": {"field": "modified value"},
    "additionalContext": "Info for Claude"
  },
  "systemMessage": "User-only message"
}
```

`permissionDecision`: `"allow"` | `"deny"` | `"ask"`

### Stop/SubagentStop (force continue)

```json
{
  "decision": "block",
  "reason": "Not finished - still need to run tests"
}
```

### SessionStart (persist env vars)

Use `CLAUDE_ENV_FILE`:
```bash
if [ -n "$CLAUDE_ENV_FILE" ]; then
  echo 'export NODE_ENV=production' >> "$CLAUDE_ENV_FILE"
fi
```

## Environment Variables

Always available:
- `CLAUDE_PROJECT_DIR` - Project root
- `CLAUDE_CODE_REMOTE` - `"true"` in remote environments

SessionStart/Setup only:
- `CLAUDE_ENV_FILE` - Write env vars here to persist

## Matchers

For `PreToolUse`, `PostToolUse`, `PermissionRequest`:

| Pattern | Matches |
|---------|---------|
| `"Write"` | Write tool only |
| `"Write\|Edit"` | Write or Edit |
| `"mcp__memory__.*"` | All memory MCP tools |
| `".*"` or `"*"` | All tools (avoid) |

Case-sensitive regex.

## Quick Patterns

**Block dangerous commands:**
```bash
#!/bin/bash
INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
if echo "$CMD" | grep -qE 'rm -rf|git push.*--force'; then
  echo "Blocked: Dangerous command" >&2
  exit 2
fi
exit 0
```

**Auto-approve safe files:**
```bash
#!/bin/bash
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
if [[ "$FILE" == *.md || "$FILE" == *.txt ]]; then
  echo '{"hookSpecificOutput":{"permissionDecision":"allow"}}'
fi
exit 0
```

**Add context on prompt:**
```bash
#!/bin/bash
echo "Current time: $(date)"
exit 0
```

## Skills/Agents Hooks

Hooks in skill/agent frontmatter (scoped to that component):

```yaml
---
name: my-skill
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./validate.sh"
  Stop:
    - hooks:
        - type: prompt
          prompt: "Check if all tasks complete"
---
```

Add `once: true` to run only once per session.

## Debugging

1. Check `/hooks` to see registered hooks
2. Use `claude --debug` for execution details
3. Test commands manually first
4. Verify scripts are executable

## Best Practices

- Use `${CLAUDE_PROJECT_DIR}` for paths
- Quote all variables (`"$VAR"`)
- Keep PreToolUse < 100ms
- Exit 0 for success, 2 to block
- Validate JSON input exists before parsing
