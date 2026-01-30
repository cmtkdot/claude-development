# claude-toolkit

Toolkit for creating, auditing, and validating Claude Code skills, agents, and hooks with TDD methodology.

## Features

- **9 Specialized Agents** - Creators and auditors for skills, agents, hooks, and commands
- **4 Skills** - TDD workflows for skills, hooks, and ecosystem analysis
- **14+ Validation Scripts** - Pre/post tool hooks for quality enforcement
- **4 Slash Commands** - Quick access to development workflows

## Quick Start

```bash
# Clone the repository
git clone https://github.com/cmtkdot/claude-toolkit.git
cd claude-toolkit
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
claude-toolkit/
├── .claude-plugin/
│   ├── plugin.json           # Plugin manifest
│   ├── settings.json         # Hook configuration
│   ├── CLAUDE.md             # Plugin context
│   ├── commands/             # 4 slash commands
│   ├── agents/               # 9 specialized agents
│   ├── skills/               # 4 skills
│   └── hooks/                # Validation scripts
├── scripts/
│   └── sync-plugin.sh
└── README.md
```

## Agents

### Creators
| Agent | Purpose |
|-------|---------|
| `starter-agent` | Decide what to build (start here) |
| `skill-creator` | Create SKILL.md files with TDD |
| `agent-creator` | Create agent configuration files |
| `hook-creator` | Create and debug hook scripts |

### Auditors
| Agent | Purpose |
|-------|---------|
| `skill-auditor` | Review SKILL.md quality and compliance |
| `subagent-auditor` | Review agent configuration quality |
| `slash-command-auditor` | Review slash command quality |
| `workflow-auditor` | Full architecture review |
| `skill-router` | Find integration gaps and opportunities |

## Skills

| Skill | Purpose |
|-------|---------|
| `writing-skills` | TDD methodology for documentation |
| `hook-development` | 6-phase hook creation workflow |
| `create-hook-structure` | Scaffold hooks directory structure |
| `ecosystem-analysis` | Analyze integration patterns |

## TDD Methodology

This toolkit follows Test-Driven Development for Documentation:

1. **RED** - Create pressure scenarios, run without skill/agent, document failures
2. **GREEN** - Write minimal skill/agent that passes scenarios
3. **REFACTOR** - Close loopholes, add rationalization counters

## Validation Hooks

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

### Syncing to Global Plugins

After making local changes, sync to the global plugins cache:

```bash
npm run sync        # Copy plugin to ~/.claude/plugins/cache
npm run sync:check  # Check if sync is needed
```

Restart Claude Code after syncing to load the updated plugin.

## Requirements

- Claude Code CLI
- Python 3.8+ (for validation scripts)
- Bash (for shell scripts)

## License

MIT

## Author

Jay (jay@cmtkdot.com)
