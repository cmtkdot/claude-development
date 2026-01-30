---
name: create-hook-structure
description: "Use when setting up hooks in a new project or scaffolding .claude/ directory. Triggers: scaffold hooks, init hooks, setup hooks directory"
argument-hint: "[target-dir]"
disable-model-invocation: true
---

# Create Hook Structure

Set up the minimal hooks directory structure for Claude Code projects.

## Minimal Structure

```
.claude/
├── settings.json        # Hook configuration
└── hooks/               # Hook scripts
    └── your-hook.sh
```

That's it. Hooks are just scripts referenced in settings.json.

## Quick Setup

```bash
# Create structure
mkdir -p .claude/hooks

# Create settings.json with hooks
cat > .claude/settings.json << 'EOF'
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/lint.sh",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
EOF
```

## Example Hook Script

`.claude/hooks/lint.sh`:
```bash
#!/bin/bash
set -euo pipefail

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only lint code files
[[ "$FILE" =~ \.(js|ts|py)$ ]] || exit 0

# Run linter
npm run lint --fix "$FILE" 2>/dev/null || true
exit 0
```

Make executable: `chmod +x .claude/hooks/lint.sh`

## Settings Locations

| File | Scope |
|------|-------|
| `~/.claude/settings.json` | All projects |
| `.claude/settings.json` | This project (commit to git) |
| `.claude/settings.local.json` | This project (don't commit) |

## Plugin Hooks

For plugins, put hooks in `hooks/hooks.json` at plugin root:
```json
{
  "hooks": {
    "PostToolUse": [...]
  }
}
```

Use `${CLAUDE_PLUGIN_ROOT}` instead of `$CLAUDE_PROJECT_DIR`.
