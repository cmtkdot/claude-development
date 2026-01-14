# Hook Troubleshooting Guide

## Common Issues

| Symptom | Check |
|---------|-------|
| Hook not firing | Is it in settings.json? Check global/project/local settings |
| Matcher not matching | Case-sensitive! `Write` != `write` |
| JSON parse error | Is output valid JSON? Use `jq empty` to validate |
| Timeout | Is hook too slow? Check performance budget |
| Wrong behavior | Read the template for correct exit semantics |
| Can't find session_id | It's in stdin JSON, not env var |
| Script not found | Verify path under `.claude/hooks/utils/<event>/` |
| Script not running | Is it executable? Has `#!/usr/bin/env bash`? |

## Configuration Sources

Checked in order (later overrides earlier):
1. `~/.claude/settings.json` (global)
2. `.claude/settings.json` (project, shareable)
3. `.claude/settings.local.json` (project, local only)

## Quick Smoke Test

```bash
# Syntax check
bash -n .claude/hooks/utils/preToolUse/hook-name.sh

# Functional test
echo '{"tool_name":"Bash","tool_input":{"command":"echo hi"},"hook_event_name":"PreToolUse"}' \
  | bash .claude/hooks/utils/preToolUse/hook-name.sh
```

## Check Logs

```bash
cat .claude/hooks/logs/hook-name.log
```

## Environment Variables

Always available:
- `$CLAUDE_PROJECT_DIR` - Project root path
- `$CLAUDE_CODE_REMOTE` - Set to `true` in remote/web environments

SessionStart only:
- `$CLAUDE_ENV_FILE` - Write env vars to persist for session

In stdin JSON (NOT env vars):
- `hook_event_name` - Event type
- `session_id` - Current session
- `tool_name` - Tool being called (PreToolUse/PostToolUse)
- `tool_input` - Tool parameters
- `tool_response` - Tool output (PostToolUse only)

## Exit Code Reference

| Event | Exit 0 | Exit 1 | Exit 2 |
|-------|--------|--------|--------|
| PreToolUse | Allow (parse JSON) | Error (pass through) | Block (stderr -> Claude) |
| PostToolUse | Success (parse JSON) | Error (ignore) | N/A |
| Stop | Allow stop | Error | Force continue |
| SubagentStop | Allow stop | Error | Force continue* |
| UserPromptSubmit | Process prompt | Error | Block (stderr -> user) |

*SubagentStop caveat: Always check `stop_hook_active` before exit 2 to prevent infinite loops.

*UserPromptSubmit caveat: You cannot rewrite the prompt; `additionalContext` is appended.

## Debugging Workflow

1. **Verify wiring**: Check settings.json has correct path
2. **Check permissions**: `ls -la` on hook script
3. **Syntax test**: `bash -n script.sh`
4. **Manual test**: Pipe test JSON to script
5. **Check logs**: Look for errors in hook log file
6. **Add debug output**: Temporarily log to file
