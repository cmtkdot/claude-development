# Hook Audit Guide

## PHASE 6: AUDIT

After implementation, audit hooks for security, performance, and correctness.

## Step 13: Security Audit

Check for common vulnerabilities:

### Command Injection
```bash
# BAD - vulnerable
eval "$user_input"
bash -c "$var"
$(echo $untrusted)

# GOOD - safe
printf '%s' "$var"
jq -r '.field' <<< "$json"
```

### Unquoted Variables
```bash
# BAD
rm -rf $path
cd $dir

# GOOD
rm -rf "$path"
cd "$dir"
```

### Unsafe File Operations
```bash
# BAD
rm -rf $var  # Could be /

# GOOD
[[ -n "$var" && "$var" != "/" ]] && rm -rf "$var"
```

### Network Calls
```bash
# BAD - no timeout
curl "$url"

# GOOD - with timeout
curl --max-time 5 "$url"
```

## Step 14: Performance Audit

Measure hook execution time against budgets:

| Event | Budget | Measurement |
|-------|--------|-------------|
| PreToolUse | < 100ms | `time bash hook.sh < payload.json` |
| PostToolUse | < 500ms | `time bash hook.sh < payload.json` |
| Stop | < 30s | `time bash hook.sh < payload.json` |

### Performance Testing Script

```bash
#!/usr/bin/env bash
HOOK="$1"
ITERATIONS="${2:-10}"

for i in $(seq 1 $ITERATIONS); do
  time (echo '{"tool_name":"Write"}' | bash "$HOOK") 2>&1
done | grep real | awk -F'm' '{sum += $2} END {print "Avg:", sum/NR "s"}'
```

## Audit Checklist

### Security
- [ ] No command injection vulnerabilities
- [ ] All variables quoted
- [ ] No `eval` or `bash -c` with user input
- [ ] No hardcoded paths (uses `$CLAUDE_PROJECT_DIR`)
- [ ] Graceful error handling (allow-on-error)
- [ ] Input validation on all external data

### Performance
- [ ] PreToolUse hooks < 100ms
- [ ] PostToolUse hooks < 500ms
- [ ] No network calls in PreToolUse
- [ ] Fast-path exit for non-matching cases
- [ ] No unnecessary subprocess spawning

### Correctness
- [ ] Valid JSON output on exit 0
- [ ] Correct exit codes for event type
- [ ] `hookEventName` field included
- [ ] Stderr used for error messages (not stdout)
- [ ] Idempotent behavior (safe to run multiple times)

### Maintainability
- [ ] Clear logging to `.claude/hooks/logs/`
- [ ] Documented in hooks-config.json
- [ ] Unit tests exist and pass
- [ ] Changelog updated
