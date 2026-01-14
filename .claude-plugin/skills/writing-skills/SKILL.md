---
name: writing-skills
description: "Use when writing SKILL.md files, creating skill frontmatter/YAML, testing skills with pressure scenarios, learning TDD for documentation, or understanding skill metadata fields. Triggers: create skill, SKILL.md template, skill frontmatter, skill testing, CSO optimization, skill hooks"
context: fork
agent: [skill-creator, skill-router, hook-creator, agent-creator]
user-invocable: true
---

# Writing Skills

## Overview

**Writing skills IS Test-Driven Development applied to process documentation.**

Write test cases (pressure scenarios with subagents), watch them fail (baseline behavior), write the skill (documentation), watch tests pass (agents comply), and refactor (close loopholes).

**Core principle:** If you didn't watch an agent fail without the skill, you don't know if the skill teaches the right thing.

## SKILL.md Structure & Metadata

### Required Fields

| Field         | Description                                                                         |
| ------------- | ----------------------------------------------------------------------------------- |
| `name`        | Lowercase letters, numbers, hyphens only (max 64 chars). Must match directory name. |
| `description` | What it does and when to use it (max 1024 chars). Start with "Use when..."          |

### Optional Fields

| Field            | Description                                                                              |
| ---------------- | ---------------------------------------------------------------------------------------- |
| `allowed-tools`  | Tools Claude can use without permission when skill is active                             |
| `model`          | Model to use (e.g., `claude-sonnet-4-20250514`)                                          |
| `context`        | Set to `fork` to run in isolated sub-agent context                                       |
| `agent`          | Agent type when `context: fork` is set (`Explore`, `Plan`, `general-purpose`, or custom) |
| `hooks`          | Lifecycle hooks: `PreToolUse`, `PostToolUse`, `Stop`                                     |
| `user-invocable` | Controls slash command menu visibility (default `true`)                                  |
| `disable-model-invocation` | Blocks programmatic Skill tool invocation (default `false`)                   |

### Example with All Features

```yaml
---
name: secure-code-review
description: Use when reviewing code for security vulnerabilities, checking PRs for security issues, or auditing authentication flows.
allowed-tools: Read, Grep, Glob
model: claude-sonnet-4-20250514
context: fork
agent: code-reviewer
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/security-check.sh $TOOL_INPUT"
          once: true
  PostToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "./scripts/run-linter.sh"
---
```

## Directory Structure

```
skills/
  skill-name/
    SKILL.md              # Main reference (required)
    reference.md          # Heavy docs (loaded when needed)
    scripts/
      helper.py           # Executed, not loaded into context
```

**Progressive disclosure:** Keep `SKILL.md` under 500 lines. Link to supporting files for detailed reference.

## Skills and Subagents Integration

### Give Subagents Access to Skills

Subagents don't inherit skills automatically. Use the `skills` field in agent definition:

```yaml
# .claude/agents/code-reviewer.md
---
name: code-reviewer
description: Review code for quality and best practices
skills: [pr-review, security-check, pal-tools]
---
```

### Run Skills in Forked Context

Use `context: fork` for isolated execution:

```yaml
---
name: code-analysis
description: Analyze code quality and generate detailed reports
context: fork
agent: code-reviewer
---
```

## Hooks in Skills

Define lifecycle hooks scoped to the skill's execution:

```yaml
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate.sh $TOOL_INPUT"
          once: true # Run only once per session
  PostToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "./scripts/lint.sh"
  Stop:
    - hooks:
        - type: prompt
          prompt: "Before stopping: verify all checklist items complete."
```

**Supported events:** `PreToolUse`, `PostToolUse`, `Stop`

**Hook types:**

- `command` — Run shell command
- `prompt` — Inject prompt guidance

**`once: true`:** Hook runs only once per session, then is removed.

## Where Skills Live

| Location   | Path                | Scope                        |
| ---------- | ------------------- | ---------------------------- |
| Enterprise | Managed settings    | All users in org             |
| Personal   | `~/skills/` | You, across all projects     |
| Project    | `skills/`   | Anyone in this repo          |
| Plugin     | Bundled with plugin | Anyone with plugin installed |

## TDD Cycle for Skills

### RED: Baseline Test

Run pressure scenario WITHOUT skill. Document exact rationalizations.

### GREEN: Write Minimal Skill

Address specific failures from baseline. Run WITH skill—agent should comply.

### REFACTOR: Close Loopholes

New rationalization found? Add explicit counter. Re-test until bulletproof.

**Detailed methodology:** See `testing-skills-with-subagents.md` for pressure scenario design, rationalization tables, and meta-testing techniques.

## The Iron Law

```
NO SKILL WITHOUT A FAILING TEST FIRST
```

Write skill before testing? Delete it. Start over. No exceptions.

---

## Claude Search Optimization (CSO)

**Critical for discovery:** Future Claude needs to FIND your skill.

### Description Field

**Purpose:** Claude reads description to decide which skills to load. Make it answer: "Should I read this skill right now?"

**Format:** Start with "Use when..." to focus on triggering conditions.

**CRITICAL: Description = When to Use, NOT What the Skill Does**

```yaml
# ❌ BAD: Summarizes workflow - Claude may follow this instead of reading skill
description: Use when executing plans - dispatches subagent per task with code review between tasks

# ✅ GOOD: Just triggering conditions, no workflow summary
description: Use when executing implementation plans with independent tasks in the current session
```

### Keyword Coverage

Use words Claude would search for:

- Error messages: "Hook timed out", "ENOTEMPTY", "race condition"
- Symptoms: "flaky", "hanging", "zombie", "pollution"
- Synonyms: "timeout/hang/freeze", "cleanup/teardown/afterEach"
- Tools: Actual commands, library names, file types

### Token Efficiency

**Target word counts:**

- getting-started workflows: <150 words each
- Frequently-loaded skills: <200 words total
- Other skills: <500 words (still be concise)

---

## Testing Skill Types

### Discipline-Enforcing Skills (rules/requirements)

**Examples:** TDD, verification-before-completion
**Test with:** Pressure scenarios, combined pressures (time + sunk cost + exhaustion)
**Success:** Agent follows rule under maximum pressure

### Technique Skills (how-to guides)

**Examples:** condition-based-waiting, root-cause-tracing
**Test with:** Application scenarios, edge cases, missing information tests
**Success:** Agent successfully applies technique

### Pattern Skills (mental models)

**Examples:** reducing-complexity, information-hiding
**Test with:** Recognition scenarios, counter-examples
**Success:** Agent correctly identifies when/how to apply pattern

### Reference Skills (documentation/APIs)

**Examples:** API docs, command references
**Test with:** Retrieval and application scenarios
**Success:** Agent finds and correctly applies reference

---

## Bulletproofing Against Rationalization

### Close Every Loophole Explicitly

```markdown
Write code before test? Delete it. Start over.

**No exceptions:**

- Don't keep it as "reference"
- Don't "adapt" it while writing tests
- Delete means delete
```

### Build Rationalization Table

| Excuse                           | Reality                                                                 |
| -------------------------------- | ----------------------------------------------------------------------- |
| "Too simple to test"             | Simple code breaks. Test takes 30 seconds.                              |
| "I'll test after"                | Tests passing immediately prove nothing.                                |
| "Tests after achieve same goals" | Tests-after = "what does this do?" Tests-first = "what should this do?" |

### Create Red Flags List

```markdown
## Red Flags - STOP and Start Over

- Code before test
- "I already manually tested it"
- "Tests after achieve the same purpose"
- "This is different because..."

**All of these mean: Delete code. Start over with TDD.**
```

---

## Skill Creation Checklist

**IMPORTANT: Use TodoWrite to create todos for EACH checklist item.**

**RED Phase:**

- [ ] Create pressure scenarios (3+ combined pressures)
- [ ] Run WITHOUT skill—document baseline behavior
- [ ] Identify rationalization patterns

**GREEN Phase:**

- [ ] Name: lowercase, numbers, hyphens only
- [ ] Description: starts with "Use when...", max 1024 chars
- [ ] Run WITH skill—verify compliance

**REFACTOR Phase:**

- [ ] Add counters for new rationalizations
- [ ] Build rationalization table
- [ ] Re-test until bulletproof

**Deployment:**

- [ ] Commit and push
- [ ] Consider contributing via PR

---

## Anti-Patterns

| Pattern                         | Why Bad                              |
| ------------------------------- | ------------------------------------ |
| Narrative storytelling          | Too specific, not reusable           |
| Multi-language examples         | Mediocre quality, maintenance burden |
| Code in flowcharts              | Can't copy-paste                     |
| Generic labels (step1, helper2) | No semantic meaning                  |

---

## The Bottom Line

**Creating skills IS TDD for process documentation.**

Same Iron Law: No skill without failing test first.
Same cycle: RED (baseline) → GREEN (write skill) → REFACTOR (close loopholes).
Same benefits: Better quality, fewer surprises, bulletproof results.

If you follow TDD for code, follow it for skills.
