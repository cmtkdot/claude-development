# claude-toolkit

Toolkit for creating and validating Claude Code skills, agents, and hooks with TDD methodology.

## Features

- **5 Specialized Agents** - Creators with built-in audit functionality
- **3 Skills** - TDD workflows for skills, hooks, and ecosystem analysis
- **14+ Validation Scripts** - Pre/post tool hooks for quality enforcement

## Quick Start

```bash
git clone https://github.com/cmtkdot/claude-toolkit.git
cd claude-toolkit
```

## Usage

| Goal | Command |
|------|---------|
| Decide what to build | `spawn starter-agent` |
| Create a skill | `spawn skill-creator` |
| Create an agent | `spawn agent-creator` |
| Create a hook | `spawn hook-creator` |
| Audit architecture | `spawn workflow-auditor` |

Note: Creators include audit functionality via Stop hooks. No separate auditor agents needed.

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
├── scripts/
│   └── sync-plugin.sh
└── README.md
```

Per official docs: Only `plugin.json` goes in `.claude-plugin/`. All other directories at plugin root.

## Agents

| Agent | Purpose | Triggers |
|-------|---------|----------|
| `starter-agent` | Decide what to build | "where do I start", "hook or skill" |
| `skill-creator` | Create + audit skills | "create skill", "audit skill" |
| `agent-creator` | Create + audit agents | "create agent", "audit agent" |
| `hook-creator` | Create + debug hooks | "create hook", "hook not working" |
| `workflow-auditor` | Architecture review | "audit workflow", "find gaps" |

## Skills

| Skill | Purpose |
|-------|---------|
| `writing-skills` | TDD methodology for skill documentation |
| `hook-development` | Hook creation workflow + scaffolding |
| `ecosystem-analysis` | Analyze integration patterns |

## TDD Methodology

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
| PostToolUse | check-skill-size.sh | Size warnings (>500 lines) |

## Syncing

After making changes, sync to global plugins cache:

```bash
npm run sync        # Sync plugin to ~/.claude/plugins/cache
npm run sync:check  # Check if sync needed
```

Restart Claude Code after syncing to load changes.

## Requirements

- Claude Code CLI
- Python 3.8+ (for validation scripts)
- Bash (for shell scripts)

## License

MIT

## Author

Jay (jay@cmtkdot.com)
