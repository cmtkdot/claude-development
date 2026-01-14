# plugin-dev

Complete toolkit for Claude Code plugin development - create, test, audit, and optimize skills, agents, hooks, and slash commands with TDD methodology.

## Features

- **8 Specialized Agents** - Creators, auditors, and orchestrators for all plugin components
- **4 Development Skills** - TDD workflows for skills, hooks, and ecosystem analysis
- **14+ Validation Scripts** - Pre/post tool hooks for quality enforcement
- **8 Slash Commands** - Quick access to common development workflows

## Quick Start

```bash
# Install the plugin
claude plugins install plugin-dev

# Or for local development
git clone https://github.com/cmtkdot/claude-development-plugin.git
cd claude-development-plugin
```

## Usage

### Creating Components

| Goal | Command |
|------|---------|
| Create a skill | `spawn skill-creator` or `/skill-development` |
| Create an agent | `spawn agent-creator` or `/agent-development` |
| Create a hook | `spawn hook-creator` or `/hook-development` |
| Create a command | `/command-development` |

### Auditing Components

| Goal | Command |
|------|---------|
| Audit a skill | `spawn skill-auditor` |
| Audit an agent | `spawn subagent-auditor` |
| Audit a command | `spawn slash-command-auditor` |
| Full architecture review | `spawn workflow-auditor` |
| Find integration gaps | `spawn skill-router` |

## Directory Structure

```
plugin-dev/
├── .claude-plugin/
│   ├── plugin.json           # Plugin manifest
│   ├── settings.json         # Hook configuration
│   └── commands/             # 8 slash commands
├── agents/                   # 8 specialized agents
│   ├── skill-creator.md
│   ├── agent-creator.md
│   ├── hook-creator.md
│   ├── skill-auditor.md
│   ├── subagent-auditor.md
│   ├── slash-command-auditor.md
│   ├── workflow-auditor.md
│   └── skill-router.md
├── skills/
│   ├── writing-skills/       # TDD for documentation
│   ├── hook-development/     # 6-phase hook workflow
│   ├── create-hook-structure/# Scaffold hooks directory
│   └── ecosystem-analysis/   # Integration analysis
└── hooks/
    └── scripts/              # Validation scripts
        ├── skill-tools/
        ├── agent-tools/
        └── hook-tools/
```

## Agents

### Creator Trilogy
| Agent | Purpose |
|-------|---------|
| `skill-creator` | Create SKILL.md files with TDD methodology |
| `agent-creator` | Create agent configuration files |
| `hook-creator` | Create and debug hook scripts |

### Auditor Trilogy
| Agent | Purpose |
|-------|---------|
| `skill-auditor` | Review SKILL.md quality and compliance |
| `subagent-auditor` | Review agent configuration quality |
| `slash-command-auditor` | Review slash command quality |

### Orchestrators
| Agent | Purpose |
|-------|---------|
| `workflow-auditor` | Full architecture review |
| `skill-router` | Find integration gaps and optimization opportunities |

## Skills

| Skill | Purpose |
|-------|---------|
| `writing-skills` | TDD methodology for documentation |
| `hook-development` | 6-phase hook creation workflow |
| `create-hook-structure` | Scaffold hooks directory structure |
| `ecosystem-analysis` | Analyze plugin integration patterns |

## TDD Methodology

This plugin follows Test-Driven Development for Documentation:

1. **RED** - Create pressure scenarios, run without skill/agent, document failures
2. **GREEN** - Write minimal skill/agent that passes scenarios
3. **REFACTOR** - Close loopholes, add rationalization counters

## Validation Hooks

The plugin includes automatic validation:

| Event | Hook | Purpose |
|-------|------|---------|
| PreToolUse | validate-skill-metadata.py | Block invalid SKILL.md writes |
| PreToolUse | validate-agent.sh | Block invalid agent writes |
| PostToolUse | lint-skill.sh | Quality warnings for skills |
| PostToolUse | lint-agent.sh | Quality warnings for agents |
| PostToolUse | lint-hook.sh | Quality warnings for hooks |
| Stop | *-audit-report.sh | Session summary reports |

## Local Development

1. Clone the repository
2. The plugin auto-loads from `.claude-plugin/plugin.json`
3. Validation hooks are configured in `.claude-plugin/settings.json`

### Testing Hooks

```bash
# Test skill validation
echo '{"tool": "Write", "file_path": "test/SKILL.md"}' | \
  python3 hooks/scripts/skill-tools/validate-skill-metadata.py

# Test agent validation
echo '{"tool": "Write", "file_path": "agents/test.md"}' | \
  bash hooks/scripts/agent-tools/validate-agent.sh
```

## Requirements

- Claude Code CLI
- Python 3.8+ (for validation scripts)
- Bash (for shell scripts)

## License

MIT

## Author

Jay (jay@cmtkdot.com)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.
