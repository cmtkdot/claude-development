---
name: create-hook-structure
description: "Scaffold the complete Claude Code hooks directory structure. Use when setting up hooks in a new project or resetting hooks organization. Triggers: scaffold hooks, init hooks, create hooks structure, setup hooks"
---

# Create Hook Structure

Scaffolds the complete `.claude/hooks/` directory structure for Claude Code projects.

## Usage

```bash
# In current project
/create-hook-structure

# In specific directory
/create-hook-structure /path/to/project
```

## What Gets Created

```
.claude/hooks/
├── CHANGELOG.md              # Hook change history
├── CLAUDE.md                 # Memory context file
├── hooks-config.json         # Hook registry and documentation
├── hooks-language-guide/     # Language selection guides
│   ├── README.md
│   ├── bash.md
│   ├── python.md
│   └── node.md
├── hooks-templates/          # Event-specific templates
│   ├── preToolUse.sh
│   ├── postToolUse.sh
│   ├── sessionStart.sh
│   ├── sessionEnd.sh
│   ├── stop.sh
│   ├── subagentStart.sh
│   ├── subagentStop.sh
│   ├── userPromptSubmit.sh
│   ├── preCompact.sh
│   └── notification.sh
├── hooks-user-output-templates/  # Output pattern guides
│   └── README.md
├── logs/                     # Runtime logs
├── scripts/                  # Utility scripts
│   ├── logs/
│   └── reports/
├── tests/                    # Test infrastructure
│   ├── TESTING.md
│   ├── run-all-tests.sh
│   └── test-helper.sh
└── utils/                    # Hook implementations
    ├── preToolUse/
    ├── postToolUse/
    ├── sessionStart/
    ├── sessionEnd/
    ├── stop/
    ├── subagentStart/
    ├── subagentStop/
    └── userPromptSubmit/
```

## Workflow

1. **Run the scaffold script:**
   ```bash
   bash .claude/hooks/scripts/scaffold-hooks.sh [target_dir]
   ```

2. **Verify structure:**
   ```bash
   ls -la .claude/hooks/
   ```

3. **Start creating hooks:**
   - Copy template from `hooks-templates/{event}.sh`
   - Place in `utils/{event}/your-hook.sh`
   - Add to `.claude/settings.json`
   - Document in `hooks-config.json`

## Idempotent

The script is safe to run multiple times. Existing files are preserved.

## Plugin Integration

This structure is designed to be bundled into a reusable plugin:

```bash
# Export hooks as plugin
tar -czf claude-hooks-plugin.tar.gz .claude/hooks/

# Import into another project
tar -xzf claude-hooks-plugin.tar.gz -C /path/to/project/
```

## Execute

Run the scaffolding now:

```bash
bash "$CLAUDE_PROJECT_DIR/.claude/hooks/scripts/scaffold-hooks.sh"
```
