# claude-toolkit: Skills, Agents & Hooks

Toolkit for creating and validating Claude Code skills, agents, and hooks with TDD methodology.

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
claude-toolkit/
├── .claude-plugin/
│   └── plugin.json            # Plugin manifest (ONLY this goes here)
├── agents/                    # 5 specialized agents
├── skills/                    # 3 skills
├── hooks/
│   ├── hooks.json             # Hook configuration
│   └── scripts/               # Validation scripts
└── README.md
```

Per official docs: Only `plugin.json` goes in `.claude-plugin/`. All other directories at plugin root.

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

## Validation Hooks

| Script | Event | Purpose |
|--------|-------|---------|
| `validate-skill-metadata.py` | PreToolUse | Block invalid SKILL.md |
| `validate-agent.sh` | PreToolUse | Block invalid agents |
| `lint-skill.sh` | PostToolUse | Quality warnings |
| `lint-agent.sh` | PostToolUse | Quality warnings |
| `lint-hook.sh` | PostToolUse | Hook quality checks |
| `check-skill-size.sh` | PostToolUse | Size warnings |

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
