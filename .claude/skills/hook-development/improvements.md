---
# Updated Hook Development Skill

Save as `.claude/skills/hook-development/SKILL.md`

````markdown
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
- mcp**morph-mcp**edit_file
  hooks:
  PostToolUse: - matcher: "Write|Edit"
  hooks: - type: command
  command: 'bash "$CLAUDE_PROJECT_DIR"/.claude/hooks/utils/postToolUse/validate-hook-syntax.sh'
  once: true

---

# Hook Development Skill

**Workflow:** DECIDE → PLAN → IMPLEMENT → TEST → DOCUMENT

Create, modify, or debug project-level hooks in `.claude/hooks/utils/` wired via `.claude/settings.json`.

This skill can be invoked by agents or used directly. When an agent references this skill, the full skill content is injected into the agent's context at startup[(1)](https://code.claude.com/docs/en/skills#configure-skills)[(2)](https://code.claude.com/docs/en/sub-agents#configure-subagents).

---

## Agent & Hook Integration

### How Agents Use This Skill

Agents can reference this skill in their frontmatter[(1)](https://code.claude.com/docs/en/skills#configure-skills)[(2)](https://code.claude.com/docs/en/sub-agents#configure-subagents):

```yaml
---
name: hook-creator
description: Creates and tests Claude Code hooks
skills: hook-development
---
```

````

When `skills: hook-development` is specified, the **full content** of this SKILL.md is loaded into the agent's context at startup[(1)](https://code.claude.com/docs/en/skills#configure-skills)[(2)](https://code.claude.com/docs/en/sub-agents#configure-subagents). The agent doesn't invoke the skill dynamically—it has all the knowledge from the start.

### How Hooks Reference Agents

Hooks can define lifecycle events that trigger agents[(2)](https://code.claude.com/docs/en/sub-agents#configure-subagents):

```json
{
  "hooks": {
    "SubagentStart": [
      {
        "matcher": "hook-creator",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/utils/subagentStart/setup-hook-env.sh"
          }
        ]
      }
    ],
    "SubagentStop": [
      {
        "matcher": "hook-creator",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/utils/subagentStop/cleanup-hook-env.sh"
          }
        ]
      }
    ]
  }
}
```

The `matcher` field targets specific agent types by name[(2)](https://code.claude.com/docs/en/sub-agents#configure-subagents).

### Skill-Scoped Hooks

This skill defines its own hooks that only run when the skill is active[(1)](https://code.claude.com/docs/en/skills#configure-skills):

```yaml
hooks:
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: 'bash "$CLAUDE_PROJECT_DIR"/.claude/hooks/utils/postToolUse/validate-hook-syntax.sh'
          once: true
```

The `once: true` option runs the hook only once per session[(1)](https://code.claude.com/docs/en/skills#configure-skills). After the first successful execution, the hook is removed.

---

## Local Resources (Read These)

All resources are in this skill folder:

| Resource             | Path                                    | Purpose                                |
| -------------------- | --------------------------------------- | -------------------------------------- |
| **Language Guide**   | `hooks-language-guide/README.md`        | Which language to use                  |
| **Bash Guide**       | `hooks-language-guide/bash.md`          | Bash patterns and examples             |
| **Python Guide**     | `hooks-language-guide/python.md`        | Python patterns and examples           |
| **Node Guide**       | `hooks-language-guide/node.md`          | Node.js patterns and examples          |
| **Output Templates** | `hooks-user-output-templates/README.md` | User-visible feedback patterns         |
| **Event Templates**  | `hooks-templates/{event}.sh`            | Event-specific implementation patterns |

Project registry files:

- `.claude/settings.json` — Hook wiring (shareable)
- `.claude/settings.local.json` — Hook wiring (local only)
- `.claude/hooks/hooks-config.json` — Hook documentation registry
- `.claude/hooks/CHANGELOG.md` — Change history

---

## PHASE 1: DECIDE (Event + Matcher + Language)

### Step 1: Choose Hook Event

Available hook events[(3)](https://platform.claude.com/docs/en/agent-sdk/python#hook-types):

| User Says                                 | Event Type         | Can Block | Has Matcher |
| ----------------------------------------- | ------------------ | --------- | ----------- |
| "before tool runs", "validate", "prevent" | `PreToolUse`       | ✅ Exit 2 | ✅          |
| "after tool runs", "track", "log result"  | `PostToolUse`      | ✅ Exit 2 | ✅          |
| "enhance prompt", "add context"           | `UserPromptSubmit` | ✅ Exit 2 | ❌          |
| "session end", "cleanup"                  | `SessionEnd`       | ❌        | ❌          |
| "after response", "auto-fix"              | `Stop`             | ✅ Exit 2 | ❌          |
| "subagent starts"                         | `SubagentStart`    | ❌        | ✅          |
| "subagent completes"                      | `SubagentStop`     | ✅ Exit 2 | ✅          |
| "before compaction"                       | `PreCompact`       | ✅ Exit 2 | ❌          |

**Note:** Due to Python SDK limitations, `SessionStart`, `SessionEnd`, and `Notification` hooks are not supported in Python[(3)](https://platform.claude.com/docs/en/agent-sdk/python#hook-types).

**Read the template:** `hooks-templates/{eventType}.sh` for payload fields and exit semantics.

### Step 2: Choose Matcher (If Supported)

Only `PreToolUse`, `PostToolUse`, `SubagentStart`, and `SubagentStop` support matchers[(3)](https://platform.claude.com/docs/en/agent-sdk/python#hook-types)[(2)](https://code.claude.com/docs/en/sub-agents#configure-subagents).

For tool hooks, choose narrowest scope:

| Pattern                 | Scope           | Performance |
| ----------------------- | --------------- | ----------- |
| `"Write"`               | One native tool | ✅ Optimal  |
| `"Write\|Edit"`         | Few tools       | ✅ Good     |
| `"mcp__postgresql__.*"` | One MCP server  | ✅ Good     |
| `"mcp__.*"`             | All MCP         | ⚠️ Broad    |
| `".*"`                  | Everything      | ❌ Avoid    |

For agent lifecycle hooks, match agent names[(2)](https://code.claude.com/docs/en/sub-agents#configure-subagents):

```json
{
  "matcher": "hook-creator"
}
```

**Matchers are case-sensitive** and match tool/agent names exactly.

### Step 3: Choose Language

Read `hooks-language-guide/README.md` first. Quick decision:

| Complexity    | Language    | Use When                                            |
| ------------- | ----------- | --------------------------------------------------- |
| Simple gating | **Bash**    | Fast checks, allowlist/denylist, PreToolUse default |
| Complex logic | **Python**  | Multi-stage transforms, structured data, scoring    |
| Async I/O     | **Node.js** | HTTP calls, parallel reads, JS/TS ecosystem         |

**Performance budgets:**

- `PreToolUse`: < 100ms (blocks user action)
- `PostToolUse`: < 500ms (tracking/logging)
- `Stop`: < 30s (auto-fixing)

**Default timeout:** 60 seconds for all hooks[(3)](https://platform.claude.com/docs/en/agent-sdk/python#hook-types). Configure with `timeout` field[(1)](https://code.claude.com/docs/en/skills#configure-skills)[(2)](https://code.claude.com/docs/en/sub-agents#configure-subagents):

```yaml
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./validate.sh"
          timeout: 30
```

---

## PHASE 2: PLAN

### Step 4: Read the Event Template

Open `hooks-templates/{eventType}.sh` and extract:

1. **Payload fields** — What stdin JSON provides (`tool_name`, `tool_input`, `session_id`, etc.)
2. **Exit semantics** — What each exit code does
3. **Response options** — `additionalContext`, `systemMessage`, `updatedInput`
4. **Example patterns** — Copy and adapt

### Step 5: Document the Plan

Before coding, write down:

```
Event: PreToolUse | PostToolUse | UserPromptSubmit | Stop | SubagentStart | SubagentStop | PreCompact
Matcher: <pattern> (if applicable)
Language: Bash | Python | Node.js
Behavior: block | modify | observe
Output: systemMessage (user) | additionalContext (Claude)
Failure mode: allow-on-error | fail-closed
Performance: <target ms>
Timeout: <seconds>
Once: true | false (run only once per session?)
```

**Key questions:**

- Should this BLOCK (exit 2) or just OBSERVE?
- If blocking, should Claude RETRY (exit 2 + stderr) or ABANDON (permissionDecision: deny)?
- Does output go to user (`systemMessage`, 0 tokens) or Claude (`additionalContext`, costs tokens)?
- Should this hook run only once per session (`once: true`)?[(1)](https://code.claude.com/docs/en/skills#configure-skills)

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

# ─── HELPERS ────────────────────────────────────────────────────────────────
json_get() { echo "$1" | jq -r "$2 // empty" 2>/dev/null; }

# ─── MAIN ───────────────────────────────────────────────────────────────────
payload="$(cat)"  # Read stdin ONCE
tool_name=$(json_get "$payload" ".tool_name")
hook_event=$(json_get "$payload" ".hook_event_name")

# Fast-path exit for non-matching cases
[[ "$tool_name" == "ExpectedTool" ]] || exit 0

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

**Python structure:**[(3)](https://platform.claude.com/docs/en/agent-sdk/python#hook-types)

```python
#!/usr/bin/env python3
import sys
import json

def main():
    try:
        input_data = json.load(sys.stdin)
        hook_event = input_data.get('hook_event_name', 'PreToolUse')
        tool_name = input_data.get('tool_name', '')

        # Your validation logic here
        if should_block(input_data):
            output = {
                'systemMessage': '🚫 Blocked',
                'hookSpecificOutput': {
                    'hookEventName': hook_event,
                    'permissionDecision': 'deny',
                    'permissionDecisionReason': 'Reason here'
                }
            }
            print(json.dumps(output))
            sys.exit(2)

        # Success
        output = {
            'systemMessage': '✅ Validated',
            'hookSpecificOutput': {
                'hookEventName': hook_event,
                'permissionDecision': 'allow'
            }
        }
        print(json.dumps(output))
        sys.exit(0)

    except Exception as e:
        output = {'systemMessage': f'⚠️  Hook error: {str(e)}'}
        print(json.dumps(output))
        sys.exit(0)

if __name__ == '__main__':
    main()
```

**Node.js structure:**[(3)](https://platform.claude.com/docs/en/agent-sdk/python#hook-types)

```javascript
#!/usr/bin/env node

function outputMessage(
  icon,
  message,
  decision = "allow",
  reason = null,
  hookEvent = "PreToolUse",
) {
  const output = {
    systemMessage: `${icon} ${message}`,
    hookSpecificOutput: {
      hookEventName: hookEvent,
      permissionDecision: decision,
    },
  };

  if (reason) {
    output.hookSpecificOutput.permissionDecisionReason = reason;
  }

  console.log(JSON.stringify(output));
}

async function processHook() {
  let input = "";

  for await (const chunk of process.stdin) {
    input += chunk;
  }

  try {
    const data = JSON.parse(input);
    const hookEvent = data.hook_event_name;

    // Your logic here

    outputMessage("✅", "Validated", "allow", null, hookEvent);
    process.exit(0);
  } catch (error) {
    outputMessage("⚠️", `Hook error: ${error.message}`, "allow");
    process.exit(0);
  }
}

processHook();
```

**Common response patterns:**

| Goal                       | Pattern                                                    |
| -------------------------- | ---------------------------------------------------------- |
| Silent pass                | `exit 0` (no output)                                       |
| Block + retry guidance     | `echo "Reason" >&2; exit 2`                                |
| Add context (costs tokens) | `jq -n '{hookSpecificOutput: {additionalContext: "..."}}'` |
| User message (0 tokens)    | `jq -n '{systemMessage: "..."}'`                           |
| Modify input               | `jq -n '{hookSpecificOutput: {updatedInput: {...}}}'`      |

### Agent-Specific Hook Pattern

To create hooks that only run for specific agents, use the `SubagentStart` and `SubagentStop` events with matchers[(2)](https://code.claude.com/docs/en/sub-agents#configure-subagents):

```bash
#!/usr/bin/env bash
set -euo pipefail

payload="$(cat)"
agent_type=$(echo "$payload" | jq -r '.agent_type // "unknown"')

# Only run for hook-creator agent
[[ "$agent_type" == "hook-creator" ]] || exit 0

# Setup environment for hook development
export HOOK_DEV_MODE=1
echo "HOOK_DEV_MODE=1" >> "$CLAUDE_ENV_FILE"

jq -n '{
  systemMessage: "🔧 Hook development environment activated"
}'
exit 0
```

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

### Step 9: Integration Test

Trigger the actual hook in Claude:

| Event              | How to Test                                   |
| ------------------ | --------------------------------------------- |
| `PreToolUse`       | Ask Claude to use the matched tool            |
| `PostToolUse`      | Execute the matched tool, verify side effects |
| `UserPromptSubmit` | Submit prompt with trigger pattern            |
| `Stop`             | Complete a response, verify auto-fix runs     |
| `SubagentStart`    | Invoke the matched agent                      |
| `SubagentStop`     | Wait for matche                               |
Yes, Step 9 was cut off. Here's the complete **Step 9: Integration Test** section with additional missing pieces:

---

## PHASE 4: TEST (Complete)

### Step 9: Integration Test

Trigger the actual hook in Claude Code to verify end-to-end behavior[(1)](https://code.claude.com/docs/en/hooks#hook-events)[(2)](https://code.claude.com/docs/en/hooks#configuration):

| Event | How to Test | Expected Behavior |
|-------|-------------|-------------------|
| `PreToolUse` | Ask Claude to use the matched tool | Hook fires before tool execution; exit 2 blocks tool |
| `PostToolUse` | Execute the matched tool, verify side effects | Hook fires after successful tool execution |
| `UserPromptSubmit` | Submit prompt with trigger pattern | Hook fires before Claude processes prompt |
| `Stop` | Complete a response, verify auto-fix runs | Hook fires when Claude attempts to stop |
| `SubagentStart` | Invoke the matched agent: `Use the hook-creator agent to...` | Hook fires when subagent initializes |
| `SubagentStop` | Wait for matched agent to complete its task | Hook fires when subagent finishes |
| `PreCompact` | Trigger compaction with `/compact` or wait for auto-compact | Hook fires before conversation history is compacted |
| `SessionStart` | Start new session with `claude` or `/clear` | Hook fires at session initialization |
| `SessionEnd` | Exit Claude Code with Ctrl+D or `/logout` | Hook fires at session termination |

### Integration Test Examples

#### Test PreToolUse Hook (Bash Command Blocker)

**Hook configuration:**
```json
{
 "hooks": {
   "PreToolUse": [
     {
       "matcher": "Bash",
       "hooks": [
         {
           "type": "command",
           "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/utils/preToolUse/block-dangerous-commands.sh",
           "timeout": 5
         }
       ]
     }
   ]
 }
}
```

**Test cases:**

1. **Test blocking (should fail):**
  ```
  User: Run this command: rm -rf /tmp/test
  Expected: Hook blocks with exit 2, Claude sees stderr message
  ```

2. **Test allowing (should pass):**
  ```
  User: Run this command: echo "hello world"
  Expected: Hook exits 0, command executes normally
  ```

3. **Verify hook output appears:**
  ```
  Expected in transcript: 🚫 Blocked dangerous command: rm -rf
  ```

#### Test PostToolUse Hook (File Change Logger)

**Hook configuration:**
```json
{
 "hooks": {
   "PostToolUse": [
     {
       "matcher": "Write|Edit",
       "hooks": [
         {
           "type": "command",
           "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/utils/postToolUse/log-file-changes.sh",
           "timeout": 10
         }
       ]
     }
   ]
 }
}
```

**Test cases:**

1. **Trigger file write:**
  ```
  User: Create a new file called test.txt with content "hello"
  Expected: Hook fires after Write tool completes
  ```

2. **Verify side effects:**
  ```bash
  # Check log file was created
  cat .claude/hooks/logs/file-changes.log

  # Should contain:
  # [2024-01-15 10:30:45] Write: test.txt
  ```

3. **Verify systemMessage appears:**
  ```
  Expected in transcript: ✅ File change logged: test.txt
  ```

#### Test SubagentStart Hook (Environment Setup)

**Hook configuration:**
```json
{
 "hooks": {
   "SubagentStart": [
     {
       "matcher": "hook-creator",
       "hooks": [
         {
           "type": "command",
           "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/utils/subagentStart/setup-hook-env.sh",
           "timeout": 10
         }
       ]
     }
   ]
 }
}
```

**Test cases:**

1. **Invoke the agent:**
  ```
  User: Use the hook-creator agent to create a new PreToolUse hook
  Expected: SubagentStart hook fires before agent begins
  ```

2. **Verify environment setup:**
  ```bash
  # Inside the agent's context, check environment
  echo $HOOK_DEV_MODE
  # Should output: 1
  ```

3. **Verify systemMessage appears:**
  ```
  Expected in transcript: 🔧 Hook development environment activated
  ```

#### Test SubagentStop Hook (Cleanup)

**Hook configuration:**
```json
{
 "hooks": {
   "SubagentStop": [
     {
       "matcher": "hook-creator",
       "hooks": [
         {
           "type": "command",
           "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/utils/subagentStop/cleanup-hook-env.sh",
           "timeout": 10
         }
       ]
     }
   ]
 }
}
```

**Test cases:**

1. **Wait for agent completion:**
  ```
  User: Use the hook-creator agent to create a hook
  [Wait for agent to finish]
  Expected: SubagentStop hook fires when agent completes
  ```

2. **Verify cleanup occurred:**
  ```bash
  # Check temporary files were removed
  ls -la /tmp/hook-dev-*
  # Should be empty or not exist
  ```

3. **Check stop_hook_active flag:**
  ```bash
  # In your hook, log the flag
  echo "stop_hook_active: $stop_hook_active" >> /tmp/debug.log
  # Verify it's false (safe to use exit 2 if needed)
  ```

#### Test UserPromptSubmit Hook (Context Injection)

**Hook configuration:**
```json
{
 "hooks": {
   "UserPromptSubmit": [
     {
       "hooks": [
         {
           "type": "command",
           "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/utils/userPromptSubmit/inject-context.sh",
           "timeout": 5
         }
       ]
     }
   ]
 }
}
```

**Test cases:**

1. **Submit any prompt:**
  ```
  User: What files are in this project?
  Expected: Hook fires before Claude processes prompt
  ```

2. **Verify context injection:**
  ```
  Expected: Claude's response includes injected context
  Example: "Based on the current sprint (Sprint 23)..."
  ```

3. **Verify additionalContext field:**[(3)](https://platform.claude.com/docs/en/agent-sdk/hooks#configure-hooks)
  ```bash
  # In your hook, output:
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "UserPromptSubmit",
      additionalContext: "Current sprint: Sprint 23"
    }
  }'
  ```

#### Test Stop Hook (Auto-fix)

**Hook configuration:**
```json
{
 "hooks": {
   "Stop": [
     {
       "hooks": [
         {
           "type": "command",
           "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/utils/stop/auto-format.sh",
           "timeout": 30
         }
       ]
     }
   ]
 }
}
```

**Test cases:**

1. **Complete a response:**
  ```
  User: Create a Python file with some code
  [Wait for Claude to finish]
  Expected: Stop hook fires when Claude attempts to stop
  ```

2. **Verify auto-fix ran:**
  ```bash
  # Check that formatter was applied
  git diff
  # Should show formatted changes
  ```

3. **Test exit 2 behavior:**
  ```bash
  # In your hook, exit 2 to force continue
  exit 2

  Expected: Claude continues working instead of stopping
  ```

### Integration Test Checklist

- [ ] Hook fires at correct event
- [ ] Matcher correctly filters tools/agents
- [ ] Exit 0 allows operation and parses JSON output
- [ ] Exit 2 blocks operation (for PreToolUse) or forces continue (for Stop)
- [ ] systemMessage appears in transcript (user-visible)
- [ ] additionalContext is injected into conversation (Claude-visible)[(3)](https://platform.claude.com/docs/en/agent-sdk/hooks#configure-hooks)
- [ ] updatedInput modifies tool parameters correctly[(3)](https://platform.claude.com/docs/en/agent-sdk/hooks#configure-hooks)
- [ ] Timeout is respected (hook terminates if exceeded)
- [ ] Error handling works (hook doesn't crash Claude)
- [ ] Performance meets budget (< 100ms for PreToolUse, etc.)

### Manual Testing Script

Create `.claude/hooks/tests/integration-test.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "🧪 Integration Test Suite"
echo "========================"

# Test 1: PreToolUse hook blocks dangerous command
echo -e "\n📝 Test 1: Block dangerous command"
claude --non-interactive << 'EOF'
Run this command: rm -rf /
EOF

if [[ $? -eq 0 ]]; then
 echo "❌ FAIL: Command should have been blocked"
 exit 1
else
 echo "✅ PASS: Command blocked as expected"
fi

# Test 2: PostToolUse hook logs file changes
echo -e "\n📝 Test 2: Log file changes"
claude --non-interactive << 'EOF'
Create a file called test-integration.txt with content "test"
EOF

if [[ -f .claude/hooks/logs/file-changes.log ]]; then
 if grep -q "test-integration.txt" .claude/hooks/logs/file-changes.log; then
   echo "✅ PASS: File change logged"
 else
   echo "❌ FAIL: File change not logged"
   exit 1
 fi
else
 echo "❌ FAIL: Log file not created"
 exit 1
fi

# Test 3: SubagentStart hook sets environment
echo -e "\n📝 Test 3: Agent environment setup"
claude --non-interactive << 'EOF'
Use the hook-creator agent to check if HOOK_DEV_MODE is set
EOF

# Verify from agent output
if grep -q "HOOK_DEV_MODE=1" /tmp/agent-env-check.log 2>/dev/null; then
 echo "✅ PASS: Agent environment configured"
else
 echo "⚠️  SKIP: Cannot verify agent environment (requires manual check)"
fi

echo -e "\n✅ Integration tests complete"
```

Run with:
```bash
bash .claude/hooks/tests/integration-test.sh
```

---

## Additional Missing Pieces

### Step 9.1: Verify Hook Execution Order

When multiple hooks match the same event, they execute sequentially[(2)](https://code.claude.com/docs/en/hooks#configuration). Test this:

```bash
#!/usr/bin/env bash
# .claude/hooks/tests/test-execution-order.sh

echo "Testing hook execution order..."

# Create three test hooks that log execution order
for i in 1 2 3; do
 cat > ".claude/hooks/utils/preToolUse/order-test-$i.sh" << EOF
#!/usr/bin/env bash
echo "Hook $i executed at \$(date +%s%N)" >> /tmp/hook-order.log
exit 0
EOF
 chmod +x ".claude/hooks/utils/preToolUse/order-test-$i.sh"
done

# Configure all three in settings.json
jq '.hooks.PreToolUse += [{
 "matcher": "Bash",
 "hooks": [
   {"type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/utils/preToolUse/order-test-1.sh"},
   {"type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/utils/preToolUse/order-test-2.sh"},
   {"type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/utils/preToolUse/order-test-3.sh"}
 ]
}]' .claude/settings.json > /tmp/settings.json && mv /tmp/settings.json .claude/settings.json

# Trigger the hooks
rm -f /tmp/hook-order.log
claude --non-interactive << 'EOF'
Run: echo "test"
EOF

# Verify execution order
if [[ -f /tmp/hook-order.log ]]; then
 echo "Execution order:"
 cat /tmp/hook-order.log

 # Check that hooks executed in order 1, 2, 3
 if grep -q "Hook 1.*Hook 2.*Hook 3" /tmp/hook-order.log; then
   echo "✅ Hooks executed in correct order"
 else
   echo "❌ Hooks executed out of order"
 fi
else
 echo "❌ No hooks executed"
fi
```

### Step 9.2: Test Hook Timeout Behavior

Verify that hooks respect timeout settings[(4)](https://platform.claude.com/docs/en/agent-sdk/python#hook-types):

```bash
#!/usr/bin/env bash
# .claude/hooks/utils/preToolUse/slow-hook.sh

# Simulate slow operation
sleep 10

jq -n '{
 systemMessage: "✅ Slow hook completed"
}'
exit 0
```

**Configuration with short timeout:**
```json
{
 "hooks": {
   "PreToolUse": [
     {
       "matcher": "Bash",
       "hooks": [
         {
           "type": "command",
           "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/utils/preToolUse/slow-hook.sh",
           "timeout": 5
         }
       ]
     }
   ]
 }
}
```

**Test:**
```
User: Run echo "test"
Expected: Hook times out after 5 seconds, tool execution continues
```

### Step 9.3: Test Hook Failure Modes

Test different failure scenarios:

**Test 1: Hook exits 1 (error)**
```bash
#!/usr/bin/env bash
echo "Hook encountered an error" >&2
exit 1
```

Expected: Error is logged, tool execution continues[(1)](https://code.claude.com/docs/en/hooks#hook-events)

**Test 2: Hook exits 2 (block)**
```bash
#!/usr/bin/env bash
echo "Operation blocked" >&2
exit 2
```

Expected: Tool execution is blocked, stderr message shown to Claude[(1)](https://code.claude.com/docs/en/hooks#hook-events)

**Test 3: Hook crashes**
```bash
#!/usr/bin/env bash
# Intentional crash
kill -9 $$
```

Expected: Hook failure is handled gracefully, tool execution continues

**Test 4: Hook outputs invalid JSON**
```bash
#!/usr/bin/env bash
echo "This is not JSON"
exit 0
```

Expected: JSON parse error, hook output ignored

---

This completes Step 9 with comprehensive integration testing guidance. The key additions are:

1. **Complete event testing table** with all hook types
2. **Detailed test cases** for each hook type with expected behavior
3. **Integration test script** for automated testing
4. **Execution order verification** for multiple hooks
5. **Timeout behavior testing**
6. **Failure mode testing** for different exit codes and errors
````

No, the current hook-development skill does **not** include instructions on auditing or improving hooks. However, the available sources provide excellent guidance on both topics that should be added.

## Missing Audit & Improvement Sections

Based on the documentation, here are the sections that should be added to make the skill complete:

---

# PHASE 6: AUDIT (Add to skill after PHASE 5: DOCUMENT)

## Hook Auditing Process

Hooks can be audited using techniques from Anthropic's alignment research[(1)](https://www.anthropic.com/research/auditing-hidden-objectives). The auditing process helps identify hidden issues, performance problems, and security vulnerabilities.

### Step 13: Security Audit

**Check for common vulnerabilities:**

```bash
#!/usr/bin/env bash
# .claude/hooks/utils/audit/security-audit.sh

HOOK_FILE="$1"

echo "🔍 Security Audit: $HOOK_FILE"

# Check 1: Command injection vulnerabilities
if grep -E '\$\([^)]*\$' "$HOOK_FILE" | grep -v '^#'; then
 echo "❌ CRITICAL: Potential command injection (nested command substitution)"
fi

# Check 2: Unquoted variables
if grep -E '\$[A-Z_]+[^"]' "$HOOK_FILE" | grep -v '^#' | grep -v 'jq'; then
 echo "⚠️  WARNING: Unquoted variables found"
fi

# Check 3: SQL injection patterns (for hooks that query databases)
if grep -iE '(mysql|psql|sqlite3).*\$' "$HOOK_FILE"; then
 echo "⚠️  WARNING: Potential SQL injection - verify parameterization"
fi

# Check 4: Unsafe file operations
if grep -E 'rm -rf.*\$|> /dev/' "$HOOK_FILE"; then
 echo "❌ CRITICAL: Dangerous file operations detected"
fi

# Check 5: Network calls without timeout
if grep -E '(curl|wget|http)' "$HOOK_FILE" | grep -v 'timeout'; then
 echo "⚠️  WARNING: Network calls without timeout"
fi

echo "✅ Security audit complete"
```

### Step 14: Performance Audit

**Measure hook execution time:**

```bash
#!/usr/bin/env bash
# .claude/hooks/utils/audit/performance-audit.sh

HOOK_FILE="$1"
TEST_PAYLOAD='{"tool_name":"Bash","hook_event_name":"PreToolUse","tool_input":{"command":"echo test"}}'

echo "⏱️  Performance Audit: $HOOK_FILE"

# Run 10 times and calculate average
total=0
for i in {1..10}; do
 start=$(date +%s%N)
 echo "$TEST_PAYLOAD" | bash "$HOOK_FILE" > /dev/null 2>&1
 end=$(date +%s%N)
 duration=$(( (end - start) / 1000000 ))  # Convert to milliseconds
 total=$((total + duration))
done

avg=$((total / 10))

echo "Average execution time: ${avg}ms"

# Check against performance budgets
if [[ "$HOOK_FILE" == *"preToolUse"* ]] && [[ $avg -gt 100 ]]; then
 echo "❌ FAIL: PreToolUse hooks should be < 100ms (got ${avg}ms)"
elif [[ "$HOOK_FILE" == *"postToolUse"* ]] && [[ $avg -gt 500 ]]; then
 echo "⚠️  WARNING: PostToolUse hooks should be < 500ms (got ${avg}ms)"
else
 echo "✅ PASS: Performance within budget"
fi
```

### Step 15: Logic Audit

**Verify hook behavior using test cases:**

```python
#!/usr/bin/env python3
# .claude/hooks/utils/audit/logic-audit.py

import sys
import json
import subprocess

def audit_hook(hook_path, test_cases):
   """Audit hook logic with multiple test cases."""
   results = []

   for test in test_cases:
       try:
           result = subprocess.run(
               ['bash', hook_path],
               input=json.dumps(test['input']),
               capture_output=True,
               text=True,
               timeout=5
           )

           actual = {
               'exit_code': result.returncode,
               'stdout': result.stdout,
               'stderr': result.stderr
           }

           # Check expectations
           passed = True
           if test['expect']['exit_code'] != actual['exit_code']:
               passed = False

           results.append({
               'name': test['name'],
               'passed': passed,
               'expected': test['expect'],
               'actual': actual
           })

       except subprocess.TimeoutExpired:
           results.append({
               'name': test['name'],
               'passed': False,
               'error': 'Timeout'
           })

   return results

# Example test cases
test_cases = [
   {
       'name': 'Allow safe command',
       'input': {
           'tool_name': 'Bash',
           'hook_event_name': 'PreToolUse',
           'tool_input': {'command': 'echo hello'}
       },
       'expect': {'exit_code': 0}
   },
   {
       'name': 'Block dangerous command',
       'input': {
           'tool_name': 'Bash',
           'hook_event_name': 'PreToolUse',
           'tool_input': {'command': 'rm -rf /'}
       },
       'expect': {'exit_code': 2}
   }
]

if __name__ == '__main__':
   hook_path = sys.argv[1]
   results = audit_hook(hook_path, test_cases)

   for result in results:
       status = '✅' if result['passed'] else '❌'
       print(f"{status} {result['name']}")
```

### Step 16: Alignment Audit

Based on Anthropic's research on auditing AI systems[(1)](https://www.anthropic.com/research/auditing-hidden-objectives), hooks should be audited for alignment with intended behavior:

**Check for hidden objectives:**

```python
#!/usr/bin/env python3
# .claude/hooks/utils/audit/alignment-audit.py

import sys
import json
import re

def check_alignment(hook_content):
   """Check if hook behavior aligns with stated purpose."""
   issues = []

   # Check 1: Does hook have clear purpose documentation?
   if '# Purpose:' not in hook_content and '# Description:' not in hook_content:
       issues.append('Missing purpose documentation')

   # Check 2: Does hook modify behavior beyond stated purpose?
   if 'updatedInput' in hook_content:
       # Verify modification is documented
       if 'modifies input' not in hook_content.lower():
           issues.append('Undocumented input modification')

   # Check 3: Does hook have side effects?
   side_effect_patterns = [
       r'>\s*[^&]',  # File writes
       r'curl|wget',  # Network calls
       r'export\s+',  # Environment changes
   ]

   for pattern in side_effect_patterns:
       if re.search(pattern, hook_content):
           if 'side effects' not in hook_content.lower():
               issues.append(f'Undocumented side effect: {pattern}')

   # Check 4: Does hook always behave consistently?
   if 'random' in hook_content.lower() or 'rand(' in hook_content:
       issues.append('Non-deterministic behavior detected')

   return issues

if __name__ == '__main__':
   hook_path = sys.argv[1]
   with open(hook_path, 'r') as f:
       content = f.read()

   issues = check_alignment(content)

   if issues:
       print('⚠️  Alignment Issues:')
       for issue in issues:
           print(f'  • {issue}')
   else:
       print('✅ Hook aligned with stated purpose')
```

---

# PHASE 7: IMPROVE (Add to skill after PHASE 6: AUDIT)

## Hook Improvement Process

Use the prompt improver techniques[(2)](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompt-improver) to enhance hook quality and reliability.

### Step 17: Use Prompt Improver for Hook Documentation

The prompt improver can optimize hook documentation[(2)](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompt-improver):

```bash
# Save hook documentation to a file
cat > /tmp/hook-doc.md << 'EOF'
This hook validates bash commands before execution.
It blocks dangerous patterns like rm -rf.
EOF

# Use Claude to improve the documentation
claude --thinking << 'PROMPT'
Improve this hook documentation using best practices:

$(cat /tmp/hook-doc.md)

Make it:
1. More specific about what patterns are blocked
2. Include examples of blocked vs allowed commands
3. Add troubleshooting guidance
4. Specify performance characteristics
PROMPT
```

### Step 18: Refactor for Performance

**Before (slow):**

```bash
#!/usr/bin/env bash
payload="$(cat)"

# Slow: Multiple jq calls
tool_name=$(echo "$payload" | jq -r '.tool_name')
command=$(echo "$payload" | jq -r '.tool_input.command')
hook_event=$(echo "$payload" | jq -r '.hook_event_name')
```

**After (fast):**

```bash
#!/usr/bin/env bash
payload="$(cat)"

# Fast: Single jq call with multiple outputs
read -r tool_name command hook_event < <(
 echo "$payload" | jq -r '[.tool_name, .tool_input.command, .hook_event_name] | @tsv'
)
```

### Step 19: Add Chain-of-Thought Reasoning

The prompt improver adds chain-of-thought instructions[(2)](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompt-improver). Apply this to hooks:

```python
#!/usr/bin/env python3
import sys
import json

def validate_with_reasoning(input_data):
   """Validate with explicit reasoning steps."""
   reasoning = []

   # Step 1: Identify command type
   command = input_data.get('tool_input', {}).get('command', '')
   reasoning.append(f"Command type: {'destructive' if 'rm' in command else 'safe'}")

   # Step 2: Check against patterns
   if 'rm -rf' in command:
       reasoning.append("Pattern matched: rm -rf (destructive)")
       reasoning.append("Decision: BLOCK")
       return {
           'decision': 'deny',
           'reasoning': reasoning
       }

   reasoning.append("No dangerous patterns found")
   reasoning.append("Decision: ALLOW")

   return {
       'decision': 'allow',
       'reasoning': reasoning
   }

def main():
   input_data = json.load(sys.stdin)
   result = validate_with_reasoning(input_data)

   # Include reasoning in systemMessage for transparency
   reasoning_text = '\n'.join(f"  {i+1}. {step}" for i, step in enumerate(result['reasoning']))

   output = {
       'systemMessage': f"🔍 Validation reasoning:\n{reasoning_text}",
       'hookSpecificOutput': {
           'hookEventName': input_data.get('hook_event_name', 'PreToolUse'),
           'permissionDecision': result['decision']
       }
   }

   print(json.dumps(output))
   sys.exit(0 if result['decision'] == 'allow' else 2)

if __name__ == '__main__':
   main()
```

### Step 20: Implement Graceful Degradation

Hooks should handle errors gracefully[(3)](https://platform.claude.com/docs/en/agent-sdk/hooks#handle-advanced-scenarios):

```bash
#!/usr/bin/env bash
set -euo pipefail

payload="$(cat)"

# Try primary validation method
if command -v advanced-validator &> /dev/null; then
 result=$(echo "$payload" | advanced-validator 2>&1) || {
   # Fallback to basic validation
   echo '{"systemMessage":"⚠️  Advanced validation unavailable, using basic checks"}' >&2
   result=$(echo "$payload" | basic-validator)
 }
else
 # Graceful degradation
 result=$(echo "$payload" | basic-validator)
fi

echo "$result"
```

### Step 21: Add Telemetry

Track hook performance and decisions:

```python
#!/usr/bin/env python3
import sys
import json
import time
from pathlib import Path

def log_telemetry(hook_name, duration_ms, decision, reason=None):
   """Log hook execution metrics."""
   log_file = Path(os.environ['CLAUDE_PROJECT_DIR']) / '.claude/hooks/telemetry.jsonl'

   entry = {
       'timestamp': time.time(),
       'hook': hook_name,
       'duration_ms': duration_ms,
       'decision': decision,
       'reason': reason
   }

   with open(log_file, 'a') as f:
       f.write(json.dumps(entry) + '\n')

def main():
   start = time.time()
   input_data = json.load(sys.stdin)

   # Your validation logic
   decision = 'allow'
   reason = None

   # Log metrics
   duration_ms = (time.time() - start) * 1000
   log_telemetry('my-hook', duration_ms, decision, reason)

   output = {
       'systemMessage': f'✅ Validated ({duration_ms:.1f}ms)',
       'hookSpecificOutput': {
           'hookEventName': input_data.get('hook_event_name'),
           'permissionDecision': decision
       }
   }

   print(json.dumps(output))
   sys.exit(0)

if __name__ == '__main__':
   main()
```

---

## Audit & Improvement Checklist

Add to the completion checklist:

- [ ] Security audit passed (Step 13)
- [ ] Performance audit passed (Step 14)
- [ ] Logic audit passed (Step 15)
- [ ] Alignment audit passed (Step 16)
- [ ] Documentation improved with prompt improver (Step 17)
- [ ] Refactored for performance (Step 18)
- [ ] Chain-of-thought reasoning added (Step 19)
- [ ] Graceful degradation implemented (Step 20)
- [ ] Telemetry added (Step 21)

---

**Summary:** The current skill lacks audit and improvement phases. Adding these sections would make it complete, covering the full lifecycle: DECIDE → PLAN → IMPLEMENT → TEST → DOCUMENT → **AUDIT → IMPROVE**.
Yes, there are several critical missing pieces and improvements needed. Let me break them down:

---

## Critical Missing Sections

### 1. **Hook Discovery & Skill Loading Mechanism**

The skill doesn't explain how Claude discovers and loads hooks at runtime[(1)](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills). Add this section:

````markdown
## Hook Discovery & Loading

### How Claude Loads Hooks at Startup

When Claude Code starts, it loads hooks in this order[(1)](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills):

1. **Skill-level hooks** — Defined in skill frontmatter (`skills/*/SKILL.md`)
2. **Project-level hooks** — Defined in `.claude/settings.json`
3. **Local-only hooks** — Defined in `.claude/settings.local.json`

### Progressive Disclosure Pattern

Skills use progressive disclosure to minimize context usage[(1)](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills):

**Level 1: Metadata (always loaded)**

```yaml
---
name: hook-development
description: "Create, modify, or debug hooks"
---
```
````

**Level 2: Full content (loaded when skill is invoked)**
The entire SKILL.md content is injected into context[(1)](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills).

**Level 3: Linked resources (loaded on-demand)**
Additional files referenced from SKILL.md are read only when needed[(1)](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills).

### Skill Directory Structure

```
.claude/skills/hook-development/
├── SKILL.md                          # Core skill definition
├── hooks-language-guide/
│   ├── README.md                     # Level 3: Linked resource
│   ├── bash.md                       # Level 3: Linked resource
│   ├── python.md                     # Level 3: Linked resource
│   └── node.md                       # Level 3: Linked resource
├── hooks-templates/
│   ├── PreToolUse.sh                 # Level 3: Template
│   ├── PostToolUse.sh                # Level 3: Template
│   └── SubagentStart.sh              # Level 3: Template
└── hooks-user-output-templates/
   └── README.md                     # Level 3: Output patterns
```

````

### 2. **MCP Integration Patterns**

The skill mentions MCP tools but doesn't explain how to hook them properly. Add:

```markdown
## MCP Tool Hook Patterns

### Native MCP Tool Calls

MCP tools are called natively with this naming pattern:

```json
{
 "tool_name": "mcp__<server>__<tool>",
 "tool_input": {
   "param1": "value1"
 }
}
````

Example hook for Linear MCP server:

```bash
#!/usr/bin/env bash
set -euo pipefail

payload="$(cat)"
tool_name=$(echo "$payload" | jq -r '.tool_name // ""')

# Match Linear MCP tools
if [[ "$tool_name" =~ ^mcp__linear__ ]]; then
 # Extract the specific Linear tool
 linear_tool="${tool_name#mcp__linear__}"

 case "$linear_tool" in
   create_issue|update_issue)
     # Validate issue creation/updates
     ;;
   delete_issue)
     # Block destructive operations
     echo '{"systemMessage":"🚫 Issue deletion blocked","hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny"}}' >&2
     exit 2
     ;;
 esac
fi

exit 0
```

### MCP-CLI Pattern

Some users call MCP tools via `mcp-cli` bash command. Create a second hook:

```bash
#!/usr/bin/env bash
set -euo pipefail

payload="$(cat)"
command=$(echo "$payload" | jq -r '.tool_input.command // ""')

# Match mcp-cli calls
if [[ "$command" =~ mcp-cli\ call\ ([^/]+)/([^\ ]+) ]]; then
 server="${BASH_REMATCH[1]}"
 tool="${BASH_REMATCH[2]}"

 # Apply same validation as native MCP hook
 if [[ "$server" == "linear" ]] && [[ "$tool" == "delete_issue" ]]; then
   echo '{"systemMessage":"🚫 Issue deletion blocked"}' >&2
   exit 2
 fi
fi

exit 0
```

### Dual-Hook Configuration

Wire both patterns in settings.json:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "mcp__linear__.*",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/utils/preToolUse/linear-native.sh"
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/utils/preToolUse/linear-cli.sh"
          }
        ]
      }
    ]
  }
}
```

````

### 3. **Agent Lifecycle Hooks Missing Context**

The skill mentions `SubagentStart` and `SubagentStop` but doesn't explain the payload structure. Add:

```markdown
## Agent Lifecycle Hook Payloads

### SubagentStart Payload

```json
{
 "hook_event_name": "SubagentStart",
 "session_id": "abc123",
 "agent_type": "hook-creator",
 "parent_agent_type": "main",
 "agent_config": {
   "name": "hook-creator",
   "description": "Creates hooks",
   "allowed_tools": ["Read", "Write", "Edit"]
 }
}
````

**Available fields:**

- `agent_type` — Name of the agent being started
- `parent_agent_type` — Name of the parent agent (or "main")
- `agent_config` — Full agent configuration from AGENT.md

### SubagentStop Payload

```json
{
  "hook_event_name": "SubagentStop",
  "session_id": "abc123",
  "agent_type": "hook-creator",
  "stop_hook_active": true,
  "result": {
    "success": true,
    "output": "Hook created successfully"
  }
}
```

**Critical field: `stop_hook_active`**

Always check this field before using exit 2:

```bash
stop_hook_active=$(echo "$payload" | jq -r '.stop_hook_active // false')

if [[ "$stop_hook_active" == "true" ]]; then
 # DO NOT exit 2 - will cause infinite loop
 echo '{"systemMessage":"⚠️  Cannot force continue - Stop hook active"}' >&2
 exit 0
fi

# Safe to exit 2 if needed
exit 2
```

### Agent Environment Setup Pattern

Use `SubagentStart` to configure agent-specific environment:

```bash
#!/usr/bin/env bash
set -euo pipefail

payload="$(cat)"
agent_type=$(echo "$payload" | jq -r '.agent_type // ""')

case "$agent_type" in
 hook-creator)
   # Set up hook development environment
   echo "HOOK_DEV_MODE=1" >> "$CLAUDE_ENV_FILE"
   echo "HOOK_TEMPLATE_DIR=$CLAUDE_PROJECT_DIR/.claude/skills/hook-development/hooks-templates" >> "$CLAUDE_ENV_FILE"
   ;;

 code-reviewer)
   # Set up code review environment
   echo "REVIEW_MODE=1" >> "$CLAUDE_ENV_FILE"
   echo "LINT_STRICT=1" >> "$CLAUDE_ENV_FILE"
   ;;
esac

jq -n --arg agent "$agent_type" '{
 systemMessage: ("🔧 Environment configured for " + $agent)
}'
exit 0
```

````

### 4. **Error Recovery Patterns**

Missing guidance on handling hook failures gracefully:

```markdown
## Error Recovery & Resilience

### Retry Logic with Exponential Backoff

For hooks that call external services:

```python
#!/usr/bin/env python3
import sys
import json
import time

def call_external_service(data, max_retries=3):
   """Call external service with exponential backoff."""
   for attempt in range(max_retries):
       try:
           # Your external call here
           result = external_api.validate(data)
           return {'success': True, 'result': result}
       except Exception as e:
           if attempt == max_retries - 1:
               return {'success': False, 'error': str(e)}

           # Exponential backoff: 1s, 2s, 4s
           time.sleep(2 ** attempt)

   return {'success': False, 'error': 'Max retries exceeded'}

def main():
   input_data = json.load(sys.stdin)

   result = call_external_service(input_data)

   if not result['success']:
       # Graceful degradation - allow with warning
       output = {
           'systemMessage': f"⚠️  External validation unavailable: {result['error']}",
           'hookSpecificOutput': {
               'hookEventName': input_data.get('hook_event_name'),
               'permissionDecision': 'allow'
           }
       }
       print(json.dumps(output))
       sys.exit(0)

   # Success
   output = {
       'systemMessage': '✅ Validated',
       'hookSpecificOutput': {
           'hookEventName': input_data.get('hook_event_name'),
           'permissionDecision': 'allow'
       }
   }
   print(json.dumps(output))
   sys.exit(0)

if __name__ == '__main__':
   main()
````

### Circuit Breaker Pattern

Prevent cascading failures:

```python
#!/usr/bin/env python3
import sys
import json
import time
from pathlib import Path

class CircuitBreaker:
   def __init__(self, failure_threshold=5, timeout=60):
       self.failure_threshold = failure_threshold
       self.timeout = timeout
       self.state_file = Path(os.environ['CLAUDE_PROJECT_DIR']) / '.claude/hooks/.circuit-breaker-state'

   def get_state(self):
       """Get current circuit breaker state."""
       if not self.state_file.exists():
           return {'failures': 0, 'opened_at': None}

       with open(self.state_file, 'r') as f:
           return json.load(f)

   def record_failure(self):
       """Record a failure."""
       state = self.get_state()
       state['failures'] += 1

       if state['failures'] >= self.failure_threshold:
           state['opened_at'] = time.time()

       with open(self.state_file, 'w') as f:
           json.dump(state, f)

   def is_open(self):
       """Check if circuit is open."""
       state = self.get_state()

       if state['opened_at'] is None:
           return False

       # Check if timeout has passed
       if time.time() - state['opened_at'] > self.timeout:
           # Reset circuit
           self.state_file.unlink()
           return False

       return True

def main():
   input_data = json.load(sys.stdin)
   breaker = CircuitBreaker()

   if breaker.is_open():
       output = {
           'systemMessage': '⚠️  Hook circuit breaker open - allowing by default',
           'hookSpecificOutput': {
               'hookEventName': input_data.get('hook_event_name'),
               'permissionDecision': 'allow'
           }
       }
       print(json.dumps(output))
       sys.exit(0)

   try:
       # Your validation logic
       result = validate(input_data)

       if not result['success']:
           breaker.record_failure()

       # Continue with normal flow

   except Exception as e:
       breaker.record_failure()
       # Allow on error
       output = {'systemMessage': f'⚠️  Error: {str(e)}'}
       print(json.dumps(output))
       sys.exit(0)

if __name__ == '__main__':
   main()
```

````

### 5. **Hook Composition Patterns**

Missing guidance on composing multiple hooks:

```markdown
## Hook Composition

### Sequential Hook Execution

Hooks for the same event/matcher run sequentially. Use this for multi-stage validation:

```json
{
 "hooks": {
   "PreToolUse": [
     {
       "matcher": "Bash",
       "hooks": [
         {
           "type": "command",
           "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/utils/preToolUse/01-syntax-check.sh",
           "timeout": 5
         },
         {
           "type": "command",
           "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/utils/preToolUse/02-security-check.sh",
           "timeout": 10
         },
         {
           "type": "command",
           "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/utils/preToolUse/03-policy-check.sh",
           "timeout": 15
         }
       ]
     }
   ]
 }
}
````

**Execution order:**

1. `01-syntax-check.sh` runs first
2. If it exits 0, `02-security-check.sh` runs
3. If it exits 0, `03-policy-check.sh` runs
4. If any exits 2, execution stops and tool is blocked

### Hook Communication via Shared State

Hooks can share state through files:

```bash
#!/usr/bin/env bash
# 01-syntax-check.sh
set -euo pipefail

payload="$(cat)"
STATE_FILE="$CLAUDE_PROJECT_DIR/.claude/hooks/.hook-state-$$"

# Perform validation
complexity_score=75

# Save state for next hook
jq -n --arg score "$complexity_score" '{
 complexity_score: ($score | tonumber)
}' > "$STATE_FILE"

exit 0
```

```bash
#!/usr/bin/env bash
# 02-security-check.sh
set -euo pipefail

payload="$(cat)"
STATE_FILE="$CLAUDE_PROJECT_DIR/.claude/hooks/.hook-state-$$"

# Load state from previous hook
if [[ -f "$STATE_FILE" ]]; then
 complexity=$(jq -r '.complexity_score' "$STATE_FILE")

 # Adjust security checks based on complexity
 if [[ $complexity -gt 80 ]]; then
   # Stricter checks for complex commands
   :
 fi
fi

exit 0
```

### Conditional Hook Chains

Use environment variables to enable/disable hook chains:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Only run if previous hook set this flag
if [[ "${HOOK_REQUIRE_DEEP_SCAN:-}" != "1" ]]; then
 exit 0
fi

# Perform deep security scan
# ...
```

````

### 6. **Debugging & Troubleshooting Guide**

Missing comprehensive debugging section:

```markdown
## Debugging Hooks

### Enable Debug Mode

Set environment variable to enable verbose logging:

```bash
export CLAUDE_HOOK_DEBUG=1
````

Update your hooks to check this:

```bash
#!/usr/bin/env bash
set -euo pipefail

DEBUG="${CLAUDE_HOOK_DEBUG:-0}"

debug_log() {
 if [[ "$DEBUG" == "1" ]]; then
   echo "[DEBUG] $*" >&2
 fi
}

payload="$(cat)"
debug_log "Received payload: $payload"

# Your logic here
debug_log "Validation complete"
```

### Common Issues & Solutions

| Symptom          | Cause                           | Solution                                       |
| ---------------- | ------------------------------- | ---------------------------------------------- |
| Hook not firing  | Matcher doesn't match tool name | Check exact tool name with `echo "$tool_name"` |
| JSON parse error | Invalid JSON output             | Validate with `jq empty` before exit 0         |
| Timeout          | Hook too slow                   |
