# claude-toolkit: Skills, Agents & Hooks

Toolkit for creating, auditing, and validating Claude Code skills, agents, and hooks.

## Quick Start

| Goal | Agent |
|------|-------|
| Create a skill | Spawn `skill-creator` |
| Create an agent | Spawn `agent-creator` |
| Create a hook | Spawn `hook-creator` |
| Audit skill | Spawn `skill-auditor` |
| Audit agent | Spawn `subagent-auditor` |
| Audit command | Spawn `slash-command-auditor` |
| Audit architecture | Spawn `workflow-auditor` |
| Find integrations | Spawn `skill-router` |

## Workflow: Create -> Test -> Audit

```
1. CREATE           2. TEST               3. AUDIT
   ┌──────────┐       ┌──────────┐         ┌──────────┐
   │ skill-   │       │ Pressure │         │ skill-   │
   │ creator  │──────▶│ Scenarios│────────▶│ auditor  │
   │ agent-   │       │ with     │         │ subagent-│
   │ creator  │       │ subagents│         │ auditor  │
   │ hook-    │       │          │         │ workflow-│
   │ creator  │       │          │         │ auditor  │
   └──────────┘       └──────────┘         └──────────┘
```

## Agents (9 total)

| Agent | Purpose | Invoke When |
|-------|---------|-------------|
| `starter-agent` | **Start here** - Decide what to build | "where do I start", "what should I build" |
| `skill-creator` | Create SKILL.md files with TDD | "create skill", "new skill" |
| `agent-creator` | Create agent .md files | "create agent", "new subagent" |
| `hook-creator` | Create/debug hook scripts | "create hook", "hook not working" |
| `skill-auditor` | Review skill quality | "audit skill", "review SKILL.md" |
| `subagent-auditor` | Review agent quality | "audit agent", "review agent" |
| `slash-command-auditor` | Review command quality | "audit command" |
| `workflow-auditor` | Architecture review | "audit workflow", "optimize config" |
| `skill-router` | Find integration gaps | "list skills", "what exists" |

## Skills (4 total)

| Skill | Purpose | Invoke When |
|-------|---------|-------------|
| `/writing-skills` | TDD for documentation | Writing SKILL.md files |
| `/hook-development` | 6-phase hook workflow | Creating hooks |
| `/create-hook-structure` | Scaffold hooks directory | New project setup |
| `/ecosystem-analysis` | Find integration opportunities | Auditing configurations |

## Commands (4 total)

| Command | Purpose |
|---------|---------|
| `/skill-development` | Create/improve skills |
| `/agent-development` | Create/improve agents |
| `/hook-development` | Create/debug hooks |
| `/command-development` | Create slash commands |

## TDD Methodology

1. **RED**: Create pressure scenarios, run WITHOUT skill/agent, document failures
2. **GREEN**: Write minimal skill/agent that passes scenarios
3. **REFACTOR**: Close loopholes, add counters for rationalizations

## Key Principles

- **CSO (Claude Search Optimization)**: Descriptions start with "Use when..." and include triggering conditions
- **Progressive Disclosure**: SKILL.md under 500 lines, heavy reference in separate files
- **Hooks for Edge Cases**: Use hooks only for what can't be expressed in metadata
- **Minimum Tools**: Restrict tools to only what's necessary
