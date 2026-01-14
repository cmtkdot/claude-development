---
description: "Prime session with plugin-dev toolkit overview - shows optimal workflows for creating skills, agents, hooks, and commands with quick reference guides"
allowed-tools: [Read, Glob, Task]
---

# plugin-dev: Claude Code Plugin Development Toolkit

You have the **plugin-dev** toolkit loaded. Here's everything you need to build Claude Code plugins.

---

## Component Quick Reference

### When to Use What

| You want to... | Use Agent | Or Skill |
|----------------|-----------|----------|
| **Create a skill** | `skill-creator` | `/writing-skills` |
| **Create an agent** | `agent-creator` | - |
| **Create a hook** | `hook-creator` | `/hook-development` |
| **Create a command** | - | (see Command Template below) |
| **Audit a skill** | `skill-auditor` | - |
| **Audit an agent** | `subagent-auditor` | - |
| **Audit a command** | `slash-command-auditor` | - |
| **Audit architecture** | `workflow-auditor` | `/ecosystem-analysis` |
| **Find integrations** | `skill-router` | `/ecosystem-analysis` |
| **Scaffold hooks dir** | - | `/create-hook-structure` |

---

## Optimal Workflows

### Creating a Skill (TDD Methodology)

```
1. RED PHASE
   └─ Create pressure scenarios
   └─ Run WITHOUT skill → document baseline failures
   └─ Identify rationalization patterns

2. GREEN PHASE
   └─ Invoke: Task({ subagent_type: "skill-creator", prompt: "Create skill: [name] - [purpose]" })
   └─ Write SKILL.md with CSO-optimized description
   └─ Run WITH skill → verify compliance

3. REFACTOR PHASE
   └─ Invoke: Task({ subagent_type: "skill-auditor", prompt: "Audit skills/[name]/SKILL.md" })
   └─ Close loopholes, add counters
   └─ Re-test until bulletproof
```

### Creating an Agent

```
1. DEFINE
   └─ Purpose: What specialized task does it do?
   └─ Tools: Minimum necessary tools
   └─ Skills: Which skills does it need? (agents don't inherit)

2. CREATE
   └─ Invoke: Task({ subagent_type: "agent-creator", prompt: "Create agent: [name] - [purpose]" })
   └─ Write agent .md with proper frontmatter
   └─ Configure hooks if needed

3. VALIDATE
   └─ Invoke: Task({ subagent_type: "subagent-auditor", prompt: "Audit agents/[name].md" })
   └─ Test with representative task
```

### Creating a Hook

```
1. DECIDE
   └─ Event: PreToolUse | PostToolUse | Stop | SessionStart | UserPromptSubmit
   └─ Matcher: Tool pattern (e.g., "Write|Edit", "mcp__server__.*")
   └─ Language: Bash (simple) | Python (complex) | Node.js (async)

2. IMPLEMENT
   └─ Invoke: Task({ subagent_type: "hook-creator", prompt: "Create hook: [event] - [purpose]" })
   └─ Or load skill: /hook-development
   └─ Place script in hooks/scripts/{event}/

3. WIRE & TEST
   └─ Add to .claude/settings.json
   └─ Test: syntax check → unit test → integration test
```

### Creating a Command

```yaml
# commands/my-command.md
---
description: "Clear description of what this command does"
allowed-tools: [Tool1, Tool2]  # Optional restrictions
argument-hint: "<required> [optional]"
---

# Command prompt here

Use $ARGUMENTS for user input.
Use @filename for file references.
Use `command` for dynamic context.
```

---

## Agent Skill Dependencies

| Agent | Loads Skills |
|-------|--------------|
| `agent-creator` | writing-skills, hook-development, ecosystem-analysis |
| `hook-creator` | hook-development |
| `skill-creator` | writing-skills |
| `skill-router` | writing-skills, ecosystem-analysis, hook-development |
| `workflow-auditor` | ecosystem-analysis, writing-skills |
| `skill-auditor` | (read-only, no skills) |
| `subagent-auditor` | (read-only, no skills) |
| `slash-command-auditor` | (read-only, no skills) |

---

## Key Principles

### CSO (Claude Search Optimization)
Descriptions MUST start with "Use when..." and include **triggering conditions**, NOT workflow summaries.

```yaml
# ❌ BAD - describes workflow
description: Creates skills using TDD methodology with pressure testing

# ✅ GOOD - describes when to use
description: "Use when creating SKILL.md files, writing skill frontmatter, or debugging skill discovery issues. Triggers: create skill, new skill, SKILL.md"
```

### Progressive Disclosure
- SKILL.md: Under 500 lines
- Heavy reference: Separate files in skill directory
- Keep what's loaded minimal

### Hooks for Edge Cases Only
Use hooks for what CAN'T be expressed in metadata:
- Blocking dangerous operations
- Tool gating/validation
- Session boundary automation

DON'T use hooks for:
- Workflow enforcement (use skills)
- Model selection (use frontmatter)

---

## Directory Structure (Auto-Discovery)

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json      # Manifest only
├── agents/              # Auto-discovered
├── skills/              # Auto-discovered
├── hooks/               # Scripts here
├── commands/            # Auto-discovered
└── CLAUDE.md           # Plugin context
```

---

## Quick Commands

```bash
# List all skills
ls skills/*/SKILL.md

# List all agents
ls agents/*.md

# Run ecosystem discovery
python3 hooks/scripts/ecosystem/discover-ecosystem.py

# Validate a skill
python3 hooks/scripts/skill-tools/validate-skill-metadata.py skills/[name]/SKILL.md
```

---

**Ready to build.** What would you like to create?
