# plugin-dev: Claude Code Plugin Development Toolkit

Complete toolkit for creating, testing, auditing, and optimizing Claude Code plugins with TDD methodology.

## Installation

```bash
# Clone the repository
git clone https://github.com/cmtkdot/claude-development-plugin.git

# Or add as a Claude Code plugin
claude plugin add https://github.com/cmtkdot/claude-development-plugin
```

## Quick Start

| Goal | Command/Agent |
|------|---------------|
| Create a skill | `/skill-development <name>` or spawn `skill-creator` |
| Create an agent | `/agent-development <name>` or spawn `agent-creator` |
| Create a hook | `/hook-development <purpose>` or spawn `hook-creator` |
| Create a command | `/command-development <name>` |
| Scaffold plugin | `/create-plugin <name>` |
| Audit skill | Spawn `skill-auditor` |
| Audit agent | Spawn `subagent-auditor` |
| Audit command | Spawn `slash-command-auditor` |
| Audit architecture | Spawn `workflow-auditor` |

## Components

### Agents (8)

| Agent | Purpose |
|-------|---------|
| `skill-creator` | Create SKILL.md files with TDD |
| `agent-creator` | Create agent .md files |
| `hook-creator` | Create/debug hook scripts |
| `skill-auditor` | Review skill quality |
| `subagent-auditor` | Review agent quality |
| `slash-command-auditor` | Review command quality |
| `workflow-auditor` | Architecture review |
| `skill-router` | Find integration gaps |

### Skills (4)

| Skill | Purpose |
|-------|---------|
| `/writing-skills` | TDD for documentation |
| `/hook-development` | 6-phase hook workflow |
| `/create-hook-structure` | Scaffold hooks directory |
| `/ecosystem-analysis` | Find integration opportunities |

### Commands (8)

| Command | Purpose |
|---------|---------|
| `/create-plugin` | End-to-end plugin creation |
| `/skill-development` | Create/improve skills |
| `/agent-development` | Create/improve agents |
| `/hook-development` | Create/debug hooks |
| `/command-development` | Create slash commands |
| `/plugin-structure` | Understand plugin layout |
| `/mcp-integration` | Add MCP servers |
| `/plugin-settings` | Configure plugin settings |

## Directory Structure

```
plugin-dev/
├── .claude-plugin/
│   ├── plugin.json           # Plugin manifest
│   ├── settings.json         # Hooks configuration
│   └── commands/             # Slash commands
├── agents/                   # 8 specialized subagents
├── skills/                   # 4 skills with references
└── hooks/
    └── scripts/              # Validation scripts
        ├── agent-tools/
        ├── skill-tools/
        ├── hook-tools/
        └── ecosystem/
```

## TDD Methodology

This plugin follows **Test-Driven Development for Documentation**:

1. **RED**: Create pressure scenarios, run WITHOUT skill/agent, document failures
2. **GREEN**: Write minimal skill/agent that passes scenarios
3. **REFACTOR**: Close loopholes, add counters for rationalizations

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

## Development

```bash
# Validate plugin structure
python3 hooks/scripts/ecosystem/discover-ecosystem.py

# Run skill validation
./hooks/scripts/skill-tools/validate-skill-metadata.py
```

## License

MIT License - see [LICENSE](LICENSE) for details.

## Author

Jay (jay@cmtkdot.com)
