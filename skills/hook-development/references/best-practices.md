# Hook Best Practices

## Do's

| Pattern | Why |
|---------|-----|
| Read stdin once, cache in variable | Stream consumed on first read |
| Fast-path exit for non-matching | Performance |
| Use `set -euo pipefail` | Catch errors early |
| Use `jq` for JSON (Bash) | Safe parsing/generation |
| Use `$CLAUDE_PROJECT_DIR` | Portable paths |
| Log to `.claude/hooks/logs/<name>.log` | Debugging |
| Always emit valid JSON on stdout | Claude expects it |
| Include `hookSpecificOutput.hookEventName` | Required field |
| Use `systemMessage` for user feedback | 0 tokens |
| Exit 0 for success | Only exit 0 parses JSON output |
| Exit 2 to block (PreToolUse) | Blocks tool, stderr -> Claude |
| Quote all variables `"$var"` | Prevent injection |
| Prefer allow-on-error | Graceful degradation |
| Keep PreToolUse < 100ms | Hot path |
| Enforce strict timeouts for subprocess/network | Reliability |

## Don'ts

| Pattern | Why | Fix |
|---------|-----|-----|
| Output JSON on exit 2 | Stdout ignored on error | Use stderr text only |
| Use "deny" for retry | Permanently blocks | Use exit 2 instead |
| Assume payload fields exist | Shapes vary by event/tool | Use `jq -e` checks |
| Parse JSON with grep/sed | Fragile, unsafe | Use `jq` always |
| Hardcode paths | Breaks environments | Use env vars |
| Trust user input | Security risk | Validate everything |
| Network calls in PreToolUse | Too slow | Move to PostToolUse |
| Print raw text | Claude expects JSON | Wrap in JSON |
| Rely on env vars for session_id | It's in stdin JSON | Parse from payload |
| Match `.*` without need | Performance hit | Narrow matchers |
| LLM calls for gating | Never on hot path | Use PostToolUse |

## Performance Budgets

| Event | Target | Rationale |
|-------|--------|-----------|
| PreToolUse | < 100ms | Blocks user action |
| PostToolUse | < 500ms | Tracking/logging |
| Stop | < 30s | Auto-fixing allowed |

## Security Checklist

- [ ] No command injection vulnerabilities
- [ ] All variables quoted
- [ ] No hardcoded paths (uses `$CLAUDE_PROJECT_DIR`)
- [ ] Graceful error handling (allow-on-error)
- [ ] Input validation on all user data
- [ ] Timeouts on network/subprocess calls
