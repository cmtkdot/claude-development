# cmtkdot: Skills, Agents & Hooks

Claude Code toolkit for creating and validating skills, agents, and hooks with TDD methodology.

---

## Quick Start

| Goal | Agent |
|------|-------|
| Decide what to build | Spawn `starter-agent` |
| Create a skill | Spawn `skill-creator` |
| Create an agent | Spawn `agent-creator` |
| Create a hook | Spawn `hook-creator` |
| Audit architecture | Spawn `workflow-auditor` |

---

## Directory Structure

```
cmtkdot/
├── .claude-plugin/
│   ├── plugin.json            # Plugin manifest
│   └── marketplace.json       # Marketplace catalog
├── agents/                    # 5 specialized agents
├── skills/                    # 3 skills
├── hooks/
│   ├── hooks.json             # Global hooks (logging, lifecycle)
│   └── scripts/               # Hook scripts
└── README.md
```

---

## Agents

| Agent | Purpose | Triggers |
|-------|---------|----------|
| `starter-agent` | Decide what to build | "where do I start", "what should I build" |
| `skill-creator` | Create + audit SKILL.md | "create skill", "audit skill" |
| `agent-creator` | Create + audit agents | "create agent", "audit agent" |
| `hook-creator` | Create + debug hooks | "create hook", "hook not working" |
| `workflow-auditor` | Architecture review | "audit workflow", "find gaps", "optimize" |

Note: Creators include audit functionality via Stop hooks. No separate auditor agents needed.

---

## Skills

| Skill | Purpose |
|-------|---------|
| `/writing-skills` | TDD for skill documentation |
| `/hook-development` | Hook creation + scaffolding |
| `/ecosystem-analysis` | Find integration gaps |

---

## Hook Architecture

**Global hooks** (hooks.json) - logging and lifecycle only:
- `SubagentStart` / `SubagentStop` - log agent activity
- `PostToolUseFailure` - log tool failures

**Agent-scoped hooks** (in agent frontmatter) - validation runs only when agent is active:

| Agent | Hooks |
|-------|-------|
| `skill-creator` | validate-skill-metadata.py, lint-skill.sh, check-skill-size.sh |
| `agent-creator` | validate-agent.sh, lint-agent.sh |
| `hook-creator` | lint-hook.sh |

---

## Hook Format (Flat Structure)

```yaml
hooks:
  PreToolUse:
    - matcher: "Write|Edit"
      type: command
      command: 'bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/validate.sh"'
      once: true
  Stop:
    - type: command
      command: 'bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/report.sh"'
```

Key: `matcher`, `type`, `command`, `once` all at same level (no nested `hooks:` array).

---

## Best Practices

**Skills**: Under 500 lines, description starts "Use when...", use references/ for depth

**Agents**: Description with triggers, minimal tools, use `${CLAUDE_PLUGIN_ROOT}`

**Hooks**: Exit 0 = success, Exit 2 = block (PreToolUse only), target <100ms

---

## Syncing

```bash
npm run sync        # Sync plugin to ~/.claude/plugins/cache
npm run sync:check  # Check if sync needed
```

Restart Claude Code after syncing to load changes.
