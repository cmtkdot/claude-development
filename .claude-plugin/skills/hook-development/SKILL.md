---
name: hook-development
description: "Use when creating hook scripts, configuring settings.json hooks, debugging hook not firing issues, choosing hook event types, understanding exit codes, or writing PreToolUse/PostToolUse/Stop handlers. Triggers: create hook, hook not working, exit code, block tool, intercept, settings.json hooks, hook template, hook event"
context: fork
user-invocable: true
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

**Workflow:** DECIDE -> PLAN -> IMPLEMENT -> TEST -> DOCUMENT -> AUDIT

Create, modify, or debug project-level hooks in `.claude/hooks/utils/` wired via `.claude/settings.json`.

---

## Local Resources

| Resource | Path | Purpose |
|----------|------|---------|
| **Language Guide** | `hooks-language-guide/README.md` | Which language to use |
| **Bash Guide** | `hooks-language-guide/bash.md` | Bash patterns |
| **Python Guide** | `hooks-language-guide/python.md` | Python patterns |
| **Node Guide** | `hooks-language-guide/node.md` | Node.js patterns |
| **Output Templates** | `hooks-user-output-templates/README.md` | User feedback patterns |
| **Event Templates** | `hooks-templates/{event}.sh` | Event-specific patterns |
| **Testing Guide** | `references/testing-guide.md` | Unit and integration testing |
| **Best Practices** | `references/best-practices.md` | Do's and don'ts |
| **Troubleshooting** | `references/troubleshooting.md` | Debug common issues |
| **Audit Guide** | `references/audit-guide.md` | Security and performance |

Project files:
- `.claude/settings.json` - Hook wiring (shareable)
- `.claude/settings.local.json` - Hook wiring (local only)
- `~/.claude/settings.json` - Global hooks (all projects)

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
| "before tool runs", "validate", "prevent" | `PreToolUse` | Exit 2 | Yes |
| "after tool runs", "track", "log result" | `PostToolUse` | No | Yes |
| "tool failed", "handle error" | `PostToolUseFailure` | No | No |
| "check permission", "approve/deny dialog" | `PermissionRequest` | deny | Yes |
| "enhance prompt", "add context" | `UserPromptSubmit` | Exit 2 | No |
| "session startup", "initialize" | `SessionStart` | No | No |
| "session end", "cleanup" | `SessionEnd` | No | No |
| "after response", "auto-fix" | `Stop` | Exit 2 | No |
| "subagent starts" | `SubagentStart` | No* | No |
| "subagent completes" | `SubagentStop` | Exit 2 | No |
| "before compaction" | `PreCompact` | Exit 2 | No |

*SubagentStart: blocking errors are ignored; stdout goes to the **subagent**, not the main conversation.

**Read the template:** `hooks-templates/{eventType}.sh` for payload fields and exit semantics.

### Step 2: Choose Matcher (If Supported)

Only `PreToolUse`, `PostToolUse`, `PermissionRequest` support matchers:

| Pattern | Scope | Performance |
|---------|-------|-------------|
| `"Write"` | One native tool | Optimal |
| `"Write\|Edit"` | Few tools | Good |
| `"mcp__postgresql__execute_sql"` | One MCP tool | Optimal |
| `"mcp__postgresql__.*"` | One MCP server | Good |
| `"mcp__.*"` | All MCP | Broad |
| `".*"` | Everything | Avoid |

**Matchers are case-sensitive.**

**Discover MCP tools:**
```bash
mcp-cli tools                    # List all available
mcp-cli tools postgresql         # Filter by server
```

### Step 3: Choose Language

| Complexity | Language | Use When |
|------------|----------|----------|
| Simple gating | **Bash** | Fast checks, allowlist/denylist |
| Complex logic | **Python** | Multi-stage transforms, structured data |
| Async I/O | **Node.js** | HTTP calls, parallel reads |

**Performance budgets:**
- `PreToolUse`: < 100ms (blocks user)
- `PostToolUse`: < 500ms (tracking)
- `Stop`: < 30s (auto-fixing)

---

## PHASE 2: PLAN

### Step 4: Read the Event Template

Open `hooks-templates/{eventType}.sh` and extract:

1. **Payload fields** - What stdin JSON provides
2. **Exit semantics** - What each exit code does
3. **Response options** - `additionalContext`, `systemMessage`, `updatedInput`

### Event Stdin Fields

| Event | Key Fields |
|-------|------------|
| PreToolUse | `tool_name`, `tool_input`, `session_id`, `permission_mode` |
| PostToolUse | `tool_name`, `tool_input`, `tool_response`, `session_id` |
| SessionStart | `source` (startup\|resume\|clear\|compact) |
| SubagentStart | `agent_id`, `agent_type` |
| SubagentStop | `agent_id`, `stop_hook_active` |
| UserPromptSubmit | `prompt` |

### Step 5: Document the Plan

```
Event: PreToolUse | PostToolUse | UserPromptSubmit | Stop | ...
Matcher: <pattern> (if applicable)
Language: Bash | Python | Node.js
Behavior: block | modify | observe
Output: systemMessage (user) | additionalContext (Claude)
Failure mode: allow-on-error | fail-closed
```

**Key questions:**
- Should this BLOCK (exit 2) or just OBSERVE?
- If blocking, should Claude RETRY (exit 2 + stderr) or ABANDON (permissionDecision: deny)?
- Does output go to user (`systemMessage`, 0 tokens) or Claude (`additionalContext`, costs tokens)?

---

## PHASE 3: IMPLEMENT

### Step 6: Create Hook Script

**Location:** `.claude/hooks/utils/{eventType}/{hook-name}.{sh|py|cjs}`

**Structure (Bash):**

```bash
#!/usr/bin/env bash
set -euo pipefail

# --- CONFIG ---
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../" && pwd)}"
LOG_FILE="$PROJECT_ROOT/.claude/hooks/logs/hook-name.log"

# --- HELPERS ---
json_get() { echo "$1" | jq -r "$2 // empty" 2>/dev/null; }
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"; }

# --- MAIN ---
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
  systemMessage: "Hook passed"
}'
exit 0
```

### Response Patterns

**PreToolUse:**
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow|deny|ask",
    "updatedInput": { },
    "additionalContext": "Info for Claude"
  },
  "systemMessage": "User-only message"
}
```

**PostToolUse:**
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "Guidance for next action"
  },
  "systemMessage": "User-only message"
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

### MCP Tool Hooks: Dual-Hook Pattern

MCP tools can be called natively or via `mcp-cli`. Create **two hooks**:

1. **Native** - Matches `mcp__<server>__<tool>`
2. **mcp-cli** - Matches `Bash` and checks for `mcp-cli call <server>/<tool>`

---

## PHASE 4: TEST

**Full guide:** `references/testing-guide.md`

Quick checks:
```bash
# Syntax
bash -n .claude/hooks/utils/{eventType}/{hook-name}.sh

# Functional
echo '{"tool_name":"Write","hook_event_name":"PreToolUse"}' | bash hook.sh
```

Integration: Ask Claude to use the matched tool and verify behavior.

---

## PHASE 5: DOCUMENT

### Step 10: Wire in Settings

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

### Step 11: Update Registry

Add to `.claude/hooks/hooks-config.json`:

```json
{
  "name": "hook-name",
  "script": ".claude/hooks/utils/{eventType}/hook-name.sh",
  "matcher": "Write|Edit",
  "timeout": 5000,
  "description": "One-sentence purpose"
}
```

### Step 12: Update Changelog

```markdown
## [YYYY-MM-DD] - hook-name

### Added
- {EventType} hook: hook-name
- Purpose: {why}
```

---

## PHASE 6: AUDIT

**Full guide:** `references/audit-guide.md`

Quick checks:
- [ ] No command injection (no `eval "$var"`)
- [ ] All variables quoted
- [ ] Uses `$CLAUDE_PROJECT_DIR` (no hardcoded paths)
- [ ] PreToolUse < 100ms

---

## Quick Reference

### Exit Codes

| Event | Exit 0 | Exit 2 |
|-------|--------|--------|
| PreToolUse | Allow (parse JSON) | Block (stderr -> Claude) |
| PostToolUse | Success (parse JSON) | N/A |
| Stop | Allow stop | Force continue |
| UserPromptSubmit | Process prompt | Block (stderr -> user) |

### Environment Variables

Always available:
- `$CLAUDE_PROJECT_DIR` - Project root
- `$CLAUDE_CODE_REMOTE` - `true` in remote environments

In stdin JSON (NOT env vars):
- `hook_event_name`, `session_id`, `tool_name`, `tool_input`, `tool_response`

**Full reference:** `references/troubleshooting.md`

---

## Completion Checklist

- [ ] Event type chosen (Phase 1)
- [ ] Matcher selected if applicable (Phase 1)
- [ ] Language selected (Phase 1)
- [ ] Template read (Phase 2)
- [ ] Plan documented (Phase 2)
- [ ] Hook script created (Phase 3)
- [ ] Tests pass (Phase 4) - See `references/testing-guide.md`
- [ ] Wired in settings.json (Phase 5)
- [ ] Registered in hooks-config.json (Phase 5)
- [ ] Changelog updated (Phase 5)
- [ ] Security audit passed (Phase 6) - See `references/audit-guide.md`
- [ ] Performance audit passed (Phase 6)
