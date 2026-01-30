# claude-toolkit: Skills, Agents & Hooks

Toolkit for creating, auditing, and validating Claude Code skills, agents, and hooks with TDD methodology.

---

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

---

## Directory Structure

```
claude-toolkit/
├── .claude-plugin/
│   ├── plugin.json           # Plugin manifest
│   ├── settings.json         # Hook configuration
│   ├── CLAUDE.md             # Plugin context
│   ├── agents/               # 9 specialized agents
│   ├── skills/               # 4 skills
│   ├── hooks/                # Validation scripts
│   └── commands/             # Slash commands
├── scripts/
│   └── sync-plugin.sh
└── README.md
```

---

## Agents

### Creators

| Agent | Purpose | Invoke When |
|-------|---------|-------------|
| `starter-agent` | Decide what to build | "where do I start", "what should I build" |
| `skill-creator` | Create SKILL.md with TDD | "create skill", "new skill" |
| `agent-creator` | Create agent .md files | "create agent", "new subagent" |
| `hook-creator` | Create/debug hooks | "create hook", "hook not working" |

### Auditors

| Agent | Purpose | Invoke When |
|-------|---------|-------------|
| `skill-auditor` | Review skill quality | "audit skill", "review SKILL.md" |
| `subagent-auditor` | Review agent config | "audit agent", "review agent" |
| `slash-command-auditor` | Review command quality | "audit command" |
| `workflow-auditor` | Architecture review | "audit workflow", "optimize config" |
| `skill-router` | Find integration gaps | "list skills", "what exists" |

---

## Skills

| Skill | Purpose |
|-------|---------|
| `/writing-skills` | TDD for documentation |
| `/hook-development` | 6-phase hook workflow |
| `/create-hook-structure` | Scaffold hooks directory |
| `/ecosystem-analysis` | Find integration opportunities |

---

## Validation Scripts

### Skill Tools (`hooks/scripts/skill-tools/`)

| Script | Event | Purpose |
|--------|-------|---------|
| `validate-skill-metadata.py` | PreToolUse | Block invalid SKILL.md |
| `lint-skill.sh` | PostToolUse | Quality warnings |
| `check-skill-size.sh` | PostToolUse | Size checks |

### Agent Tools (`hooks/scripts/agent-tools/`)

| Script | Event | Purpose |
|--------|-------|---------|
| `validate-agent.sh` | PreToolUse | Block on missing fields |
| `lint-agent.sh` | PostToolUse | Quality warnings |

### Hook Tools (`hooks/scripts/hook-tools/`)

| Script | Event | Purpose |
|--------|-------|---------|
| `lint-hook.sh` | PostToolUse | Hook quality checks |

---

## TDD Methodology

1. **RED**: Create pressure scenarios, run WITHOUT skill/agent, document failures
2. **GREEN**: Write minimal skill/agent that passes scenarios
3. **REFACTOR**: Close loopholes, add counters for rationalizations

---

## Best Practices

### Skills
- Keep SKILL.md under 500 lines
- Description starts with "Use when..."
- Progressive disclosure (references/, examples/)

### Agents
- Description with triggering examples
- Tools array: `["Read", "Write"]`
- Use `${CLAUDE_PLUGIN_ROOT}` for portability

### Hooks
- Use `${CLAUDE_PLUGIN_ROOT}` in commands
- Exit 0 = allow, Exit 2 = block
- Target <100ms execution

---

## Syncing

After making changes, sync to global plugins cache:

```bash
npm run sync        # Sync plugin to ~/.claude/plugins/cache
npm run sync:check  # Check if sync needed
```

Restart Claude Code after syncing to load changes.
