# Hook Communication Reference

> Extracted from skill-creator.md for progressive disclosure.

## Exit Codes

| Exit Code | Meaning | stdout | stderr |
|-----------|---------|--------|--------|
| `0` | Success | Shown in verbose mode | - |
| `2` | Block operation | Ignored | Shown to Claude as error |
| Other | Non-blocking error | - | Shown in verbose mode |

## Hook Events for Skills

### PreToolUse

Fires before a tool is used. Can block with exit 2.

```yaml
hooks:
  PreToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/validate.sh"
          once: true  # Only run once per session
```

### PostToolUse

Fires after a tool completes. Cannot block.

```yaml
hooks:
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/lint.sh"
```

### Stop

Fires when agent is about to stop. Can force continue with exit 2.

```yaml
hooks:
  Stop:
    - hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/audit-report.sh"
```

## Input Format (stdin)

Hooks receive JSON on stdin:

```json
{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/path/to/file.md",
    "content": "..."
  }
}
```

## Output Format (stdout)

Return JSON to modify tool behavior:

```json
{
  "decision": "allow",
  "reason": "Validation passed"
}
```

Or for blocking:

```json
{
  "decision": "block",
  "reason": "Missing required field: name"
}
```
