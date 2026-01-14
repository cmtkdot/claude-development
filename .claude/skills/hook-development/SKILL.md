---
name: hook-development
description: "Create, modify, or debug Claude Code project hooks. Triggers: hook, PreToolUse, PostToolUse, SessionStart, automate, intercept tool, validate input, track changes, .claude/hooks/"
context: fork
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Grep
  - Glob
  - TodoWrite
  - mcp__morph-mcp__edit_file
hooks:
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: 'bash "$CLAUDE_PROJECT_DIR"/.claude/hooks/utils/preToolUse/validate-hook-syntax.sh'
          once: true
---

# Hook Development Skill

**Workflow:** DECIDE → PLAN → IMPLEMENT → TEST → DOCUMENT → AUDIT

Create, modify, or debug project-level hooks in `.claude/hooks/utils/` wired via `.claude/settings.json`.

## Skill-Scoped Hooks

This skill defines hooks in the frontmatter above. The `once: true` option runs the hook only once per session.

Agents can reference this skill with `skills: hook-development` in their frontmatter to inherit all knowledge.

---

## Local Resources (Read These)

All resources are in this skill folder:

| Resource | Path | Purpose |
|----------|------|---------|
| **Language Guide** | `hooks-language-guide/README.md` | Which language to use |
| **Bash Guide** | `hooks-language-guide/bash.md` | Bash patterns and examples |
| **Python Guide** | `hooks-language-guide/python.md` | Python patterns and examples |
| **Node Guide** | `hooks-language-guide/node.md` | Node.js patterns and examples |
| **Output Templates** | `hooks-user-output-templates/README.md` | User-visible feedback patterns |
| **Event Templates** | `hooks-templates/{event}.sh` | Event-specific implementation patterns |
| **Examples** | `examples/` | Complete hook examples by language and pattern |

Project registry files:
- `.claude/settings.json` — Hook wiring (shareable)
- `.claude/settings.local.json` — Hook wiring (local only)
- `~/.claude/settings.json` — Global hooks (all projects)
- `.claude/hooks/hooks-config.json` — Hook documentation registry
- `.claude/hooks/CHANGELOG.md` — Change history

---

## When to Use Hooks

**Use hooks for:**
- Blocking dangerous operations (force push, secrets exposure)
- Injecting reminders at session boundaries
- Tool gating, logging, shell automation
- Edge cases that can't be expressed in skill/agent metadata

**Don't use hooks for:**
- Workflow enforcement (use skill chaining)
- Model tier selection (use frontmatter)
- Output validation (skills validate agent returns)

---

## PHASE 1: DECIDE (Event + Matcher + Language)

### Step 1: Choose Hook Event

| User Says | Event Type | Can Block | Has Matcher |
|-----------|------------|-----------|-------------|
| "before tool runs", "validate", "prevent" | `PreToolUse` | ✅ Exit 2 | ✅ |
| "after tool runs", "track", "log result" | `PostToolUse` | ❌ | ✅ |
| "tool failed", "handle error" | `PostToolUseFailure` | ❌ | ❌ |
| "check permission", "approve/deny dialog" | `PermissionRequest` | ✅ deny | ✅ |
| "enhance prompt", "add context" | `UserPromptSubmit` | ✅ Exit 2 | ❌ |
| "session startup", "initialize" | `SessionStart` | ❌ | ❌ |
| "session end", "cleanup" | `SessionEnd` | ❌ | ❌ |
| "after response", "auto-fix" | `Stop` | ✅ Exit 2 | ❌ |
| "subagent starts" | `SubagentStart` | ❌* | ❌ |
| "subagent completes" | `SubagentStop` | ✅ Exit 2 | ❌ |
| "before compaction" | `PreCompact` | ✅ Exit 2 | ❌ |
| "notification", "alert" | `Notification` | ❌ | ❌ |

*SubagentStart: blocking errors are ignored; stdout goes to the **subagent**, not the main conversation.

**Read the template:** `hooks-templates/{eventType}.sh` for payload fields and exit semantics.

### Step 2: Choose Matcher (If Supported)

Only `PreToolUse`, `PostToolUse`, `PermissionRequest` support matchers. Choose narrowest scope:

| Pattern | Scope | Performance |
|---------|-------|-------------|
| `"Write"` | One native tool | ✅ Optimal |
| `"Write\|Edit"` | Few tools | ✅ Good |
| `"mcp__postgresql__execute_sql"` | One MCP tool | ✅ Optimal |
| `"mcp__postgresql__.*"` | One MCP server | ✅ Good |
| `"mcp__.*"` | All MCP | ⚠️ Broad |
| `".*"` | Everything | ❌ Avoid |

**Matchers are case-sensitive** and match tool names exactly.

**Discover MCP tools:**
```bash
mcp-cli tools                    # List all available
mcp-cli tools postgresql         # Filter by server
mcp-cli grep "keyword"           # Search by keyword
```

### Step 3: Choose Language

Read `hooks-language-guide/README.md` first. Quick decision:

| Complexity | Language | Use When |
|------------|----------|----------|
| Simple gating | **Bash** | Fast checks, allowlist/denylist, PreToolUse default |
| Complex logic | **Python** | Multi-stage transforms, structured data, scoring |
| Async I/O | **Node.js** | HTTP calls, parallel reads, JS/TS ecosystem |
| LLM-assisted | **Python/Node** | Opus + thinking via `claude` CLI (PostToolUse only, never gating) |

**Performance budgets:**
- `PreToolUse`: < 100ms (blocks user action)
- `PostToolUse`: < 500ms (tracking/logging)
- `Stop`: < 30s (auto-fixing)

---

## PHASE 2: PLAN

### Step 4: Read the Event Template

Open `hooks-templates/{eventType}.sh` and extract:

1. **Payload fields** — What stdin JSON provides
2. **Exit semantics** — What each exit code does
3. **Response options** — `additionalContext`, `systemMessage`, `updatedInput`
4. **Example patterns** — Copy and adapt

### Event-Specific Stdin Fields

| Event | Key Fields |
|-------|------------|
| PreToolUse | `tool_name`, `tool_input`, `session_id`, `permission_mode` |
| PostToolUse | `tool_name`, `tool_input`, `tool_response`, `session_id` |
| SessionStart | `source` (startup\|resume\|clear\|compact) |
| SubagentStart | `agent_id`, `agent_type` |
| SubagentStop | `agent_id`, `stop_hook_active` |
| UserPromptSubmit | `prompt` |

### Step 5: Document the Plan

Before coding, write down:

```
Event: PreToolUse | PostToolUse | UserPromptSubmit | Stop | ...
Matcher: <pattern> (if applicable)
Language: Bash | Python | Node.js
Behavior: block | modify | observe
Output: systemMessage (user) | additionalContext (Claude)
Failure mode: allow-on-error | fail-closed
Performance: <target ms>
```

**Key questions:**
- Should this BLOCK (exit 2) or just OBSERVE?
- If blocking, should Claude RETRY (exit 2 + stderr) or ABANDON (permissionDecision: deny)?
- Does output go to user (`systemMessage`, 0 tokens) or Claude (`additionalContext`, costs tokens)?
- If hook fails internally, should action be BLOCKED or ALLOWED? (prefer allow)

---

## PHASE 3: IMPLEMENT

### Step 6: Create Hook Script

**Location:** `.claude/hooks/utils/{eventType}/{hook-name}.{sh|py|cjs}`

**Structure (Bash example):**

```bash
#!/usr/bin/env bash
set -euo pipefail

# ─── CONFIG ─────────────────────────────────────────────────────────────────
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../" && pwd)}"
LOG_FILE="$PROJECT_ROOT/.claude/hooks/logs/hook-name.log"

# ─── HELPERS ────────────────────────────────────────────────────────────────
json_get() { echo "$1" | jq -r "$2 // empty" 2>/dev/null; }
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"; }

# ─── MAIN ───────────────────────────────────────────────────────────────────
payload="$(cat)"  # Read stdin ONCE
tool_name=$(json_get "$payload" ".tool_name")
hook_event=$(json_get "$payload" ".hook_event_name")

# Fast-path exit for non-matching cases
[[ "$tool_name" == "ExpectedTool" ]] || exit 0

log "Processing $tool_name"

# --- Hook Logic ---
# (Your logic here)

# --- Output ---
jq -n --arg event "$hook_event" '{
  hookSpecificOutput: {
    hookEventName: $event,
    permissionDecision: "allow"
  },
  systemMessage: "✓ Hook passed"
}'
exit 0
```

### Response Patterns by Event

**PreToolUse:**
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow|deny|ask",
    "permissionDecisionReason": "Reason here",
    "updatedInput": { },
    "additionalContext": "Info for Claude"
  },
  "systemMessage": "User-only message",
  "suppressOutput": false
}
```

**PostToolUse:**
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "Guidance for next action"
  },
  "systemMessage": "User-only message",
  "suppressOutput": false
}
```

**Stop/SubagentStop (force continue):**
```json
{
  "decision": "block",
  "reason": "Not finished yet"
}
```

### Common Patterns

| Goal | Pattern |
|------|---------|
| Silent pass | `exit 0` (no output) |
| Block + retry guidance | `echo "Reason" >&2; exit 2` |
| Add context (costs tokens) | `jq -n '{hookSpecificOutput: {additionalContext: "..."}}'` |
| User message (0 tokens) | `jq -n '{systemMessage: "..."}'` |
| Modify input | `jq -n '{hookSpecificOutput: {updatedInput: {...}}}'` |
| Hide from transcript | Add `"suppressOutput": true` |

### MCP Tool Hooks: Dual-Hook Pattern

MCP tools can be called natively or via `mcp-cli`. Create **two hooks**:

1. **Native** — Matches `mcp__<server>__<tool>`
2. **mcp-cli** — Matches `Bash` and checks for `mcp-cli call <server>/<tool>` in command

**Reference:** `.claude/hooks/utils/postToolUse/track-migrations.sh` + `track-migrations-mcp-cli.sh`

---

## PHASE 4: TEST

### Step 7: Syntax Check

```bash
# Bash
bash -n .claude/hooks/utils/{eventType}/{hook-name}.sh

# Node.js
node --check .claude/hooks/utils/{eventType}/{hook-name}.cjs

# Python
python -m py_compile .claude/hooks/utils/{eventType}/{hook-name}.py
```

### Step 8: Unit Test

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

### Step 9: Integration Test

Trigger the actual hook in Claude:

| Event | How to Test |
|-------|-------------|
| `PreToolUse` | Ask Claude to use the matched tool |
| `PostToolUse` | Execute the matched tool, verify side effects |
| `UserPromptSubmit` | Submit prompt with trigger pattern |
| `Stop` | Complete a response, verify auto-fix runs |
| `SessionStart` | Start new session |

---

## PHASE 5: DOCUMENT

### Step 10: Wire in Settings

Add to `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/utils/preToolUse/hook-name.sh",
            "timeout": 5,
            "statusMessage": "Validating..."
          }
        ]
      }
    ]
  }
}
```

**Notes:**
- Timeout is in **seconds** in settings.json
- `statusMessage` shows in CLI during hook execution

### Step 11: Update Registry

Add to `.claude/hooks/hooks-config.json`:

```json
{
  "name": "hook-name",
  "script": ".claude/hooks/utils/{eventType}/hook-name.sh",
  "matcher": "Write|Edit",
  "timeout": 5000,
  "description": "One-sentence purpose",
  "performance": "<100ms",
  "version": "1.0.0"
}
```

**Note:** Timeout in hooks-config.json is **milliseconds** (documentation).

### Step 12: Update Changelog

Add to `.claude/hooks/CHANGELOG.md`:

```markdown
## [YYYY-MM-DD] - hook-name

### Added
- {EventType} hook: hook-name
- Matcher: {pattern}
- Purpose: {why}

### Behavior
- {what it does}
```

---

## Do's and Don'ts

### ✅ DO

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
| Exit 2 to block (PreToolUse) | Blocks tool, stderr → Claude |
| Quote all variables `"$var"` | Prevent injection |
| Prefer allow-on-error | Graceful degradation |
| Keep PreToolUse < 100ms | Hot path |
| Enforce strict timeouts for subprocess/network | Reliability |

### ❌ DON'T

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

---

## Environment Variables

Always available:
- `$CLAUDE_PROJECT_DIR` — Project root path
- `$CLAUDE_CODE_REMOTE` — Set to `true` in remote/web environments

SessionStart only:
- `$CLAUDE_ENV_FILE` — Write env vars to persist for session

In stdin JSON (NOT env vars):
- `hook_event_name` — Event type
- `session_id` — Current session
- `tool_name` — Tool being called (PreToolUse/PostToolUse)
- `tool_input` — Tool parameters
- `tool_response` — Tool output (PostToolUse only)

---

## Exit Code Reference

| Event | Exit 0 | Exit 1 | Exit 2 |
|-------|--------|--------|--------|
| PreToolUse | Allow (parse JSON) | Error (pass through) | Block (stderr → Claude) |
| PostToolUse | Success (parse JSON) | Error (ignore) | N/A |
| Stop | Allow stop | Error | Force continue |
| SubagentStop | Allow stop | Error | Force continue** |
| UserPromptSubmit | Process prompt | Error | Block (stderr → user) |

**SubagentStop caveat:** Always check `stop_hook_active` before exit 2 to prevent infinite loops.

**UserPromptSubmit caveat:** You cannot rewrite the prompt; `additionalContext` is appended.

---

## Troubleshooting

| Symptom | Check |
|---------|-------|
| Hook not firing | Is it in settings.json? Check global/project/local settings |
| Matcher not matching | Case-sensitive! `Write` ≠ `write` |
| JSON parse error | Is output valid JSON? Use `jq empty` to validate |
| Timeout | Is hook too slow? Check performance budget |
| Wrong behavior | Read the template for correct exit semantics |
| Can't find session_id | It's in stdin JSON, not env var |
| Script not found | Verify path under `.claude/hooks/utils/<event>/` |
| Script not running | Is it executable? Has `#!/usr/bin/env bash`? |

**Configuration sources (checked in order):**
1. `~/.claude/settings.json` (global)
2. `.claude/settings.json` (project, shareable)
3. `.claude/settings.local.json` (project, local only)

**Quick smoke test:**
```bash
bash -n .claude/hooks/utils/preToolUse/hook-name.sh
echo '{"tool_name":"Bash","tool_input":{"command":"echo hi"},"hook_event_name":"PreToolUse"}' \
  | bash .claude/hooks/utils/preToolUse/hook-name.sh
```

**Check logs:**
```bash
cat .claude/hooks/logs/hook-name.log
```

---

## Completion Checklist

- [ ] Event type chosen (Step 1)
- [ ] Matcher selected if applicable (Step 2)
- [ ] Language selected (Step 3)
- [ ] Template read (Step 4)
- [ ] Plan documented (Step 5)
- [ ] Hook script created (Step 6)
- [ ] Syntax check passes (Step 7)
- [ ] Unit test created and passes (Step 8)
- [ ] Integration test verified (Step 9)
- [ ] Wired in settings.json (Step 10)
- [ ] Registered in hooks-config.json (Step 11)
- [ ] Changelog updated (Step 12)
- [ ] Security audit passed (Step 13)
- [ ] Performance audit passed (Step 14)

---

## PHASE 6: AUDIT

After implementation, audit hooks for security, performance, and correctness.

### Step 13: Security Audit

Check for common vulnerabilities:

- Command injection (nested `$(...)` in variables)
- Unquoted variables
- Unsafe file operations (`rm -rf $var`)
- Network calls without timeout

### Step 14: Performance Audit

Measure hook execution time against budgets:
- PreToolUse: < 100ms
- PostToolUse: < 500ms
- Stop: < 30s

### Audit Checklist

- [ ] No command injection vulnerabilities
- [ ] All variables quoted
- [ ] No hardcoded paths (uses `$CLAUDE_PROJECT_DIR`)
- [ ] Graceful error handling (allow-on-error)
- [ ] Performance within budget
- [ ] Valid JSON output verified

---

## Examples

See `examples/` folder for complete implementations:

| Example | Path | Description |
|---------|------|-------------|
| Python PreToolUse | `examples/python/preToolUse-template.py` | Full Python hook with error handling |
| Node.js PreToolUse | `examples/node/preToolUse-template.cjs` | Full Node.js hook with async |
| SubagentStart | `examples/bash/subagentStart-template.sh` | Agent environment setup |
| SubagentStop | `examples/bash/subagentStop-template.sh` | Agent cleanup with stop_hook_active check |
| MCP Native Hook | `examples/patterns/mcp-dual-hook-native.sh` | Native MCP tool hook |
| MCP-CLI Hook | `examples/patterns/mcp-dual-hook-cli.sh` | mcp-cli command hook |
| Error Recovery | `examples/patterns/error-recovery.py` | Retry, circuit breaker patterns |
| Hook Composition | `examples/patterns/hook-composition.sh` | Multi-stage validation |
| Debug Mode | `examples/patterns/debug-mode.sh` | Verbose logging pattern |
