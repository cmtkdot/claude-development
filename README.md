# cmtkdot

Claude Code toolkit for creating and validating skills, agents, and hooks with TDD methodology.

## Features

- **5 Specialized Agents** - Creators with built-in audit via Stop hooks
- **3 Skills** - TDD workflows for skills, hooks, and ecosystem analysis
- **Agent-scoped validation** - Hooks run only when using creator agents

## Quick Start

```bash
git clone https://github.com/cmtkdot/cmtkdot.git
cd cmtkdot
npm run sync
```

## Usage

| Goal | Command |
|------|---------|
| Decide what to build | `spawn starter-agent` |
| Create a skill | `spawn skill-creator` |
| Create an agent | `spawn agent-creator` |
| Create a hook | `spawn hook-creator` |
| Audit architecture | `spawn workflow-auditor` |

## Directory Structure

```
cmtkdot/
├── .claude-plugin/
│   ├── plugin.json            # Plugin manifest
│   └── marketplace.json       # Marketplace catalog
├── agents/                    # 5 specialized agents
├── skills/                    # 3 skills
├── hooks/
│   ├── hooks.json             # Global hooks (logging only)
│   └── scripts/               # Hook scripts
└── README.md
```

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

## Hook Architecture

**Global hooks** (hooks.json): Empty by design - no global overhead.

**Agent-scoped hooks** (in frontmatter): Validation runs only when using creator agents.

| Agent | PreToolUse | PostToolUse | Stop |
|-------|------------|-------------|------|
| skill-creator | validate-skill-metadata.py | lint-skill.sh, check-skill-size.sh | skill-audit-report.sh |
| agent-creator | validate-agent.sh | lint-agent.sh | agent-audit-report.sh |
| hook-creator | lint-hook.sh | lint-hook.sh | hook-audit-report.sh |
| starter-agent | - | - | discovery-report.sh |
| workflow-auditor | - | - | audit-report.sh |

### Hook Format

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

## TDD Methodology

1. **RED** - Create pressure scenarios, run without skill/agent, document failures
2. **GREEN** - Write minimal skill/agent that passes scenarios
3. **REFACTOR** - Close loopholes, add rationalization counters

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
- jq (for hook scripts)
- Bash

## License

MIT

## Author

Jay (jay@cmtkdot.com)
