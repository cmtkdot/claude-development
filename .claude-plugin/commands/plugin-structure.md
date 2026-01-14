---
description: Understand and scaffold Claude Code plugin directory structure and manifest
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep]
argument-hint: "[plugin-name]"
---

# Claude Code Plugin Structure

Understand and scaffold Claude Code plugin architecture.

**Request:** $ARGUMENTS

## Standard Plugin Layout

```
.claude-plugin/
├── plugin.json              # Manifest (required)
├── CLAUDE.md               # Plugin context/memory
├── commands/               # Slash commands
│   ├── my-command.md
│   └── another-command.md
└── .claude/
    ├── agents/             # Custom subagents
    │   └── my-agent.md
    ├── skills/             # Custom skills
    │   └── my-skill/
    │       └── SKILL.md
    └── hooks/              # Lifecycle hooks
        └── scripts/
            └── my-hook.sh
```

## plugin.json Manifest

```json
{
  "name": "plugin-name",
  "version": "1.0.0",
  "description": "What the plugin does",
  "author": {
    "name": "Your Name",
    "email": "you@example.com"
  },
  "repository": "https://github.com/user/repo",
  "license": "MIT",
  "keywords": ["claude-code", "your", "keywords"],
  "agents": [
    "./.claude/agents/agent-one.md",
    "./.claude/agents/agent-two.md"
  ],
  "skills": [
    "./.claude/skills/skill-one",
    "./.claude/skills/skill-two"
  ],
  "commands": "./commands",
  "hooks": "./.claude/hooks"
}
```

## Path Variables

Use these in hook commands for portability:
- `${CLAUDE_PLUGIN_ROOT}` - Plugin root directory
- `${CLAUDE_PROJECT_DIR}` - Project root directory

## Component Discovery

Claude Code auto-discovers:
- **Commands**: All `.md` files in `commands/` directory
- **Agents**: Files listed in `plugin.json` `agents` array
- **Skills**: Directories listed in `plugin.json` `skills` array
- **Hooks**: Scripts referenced in `settings.json`

## Best Practices

1. **Naming**: Use lowercase-with-hyphens for all identifiers
2. **Descriptions**: Start with "Use when..." for discoverability
3. **Tools**: Restrict to minimum necessary
4. **Hooks**: Use `${CLAUDE_PLUGIN_ROOT}` for portable paths
5. **Testing**: Test all components before publishing
