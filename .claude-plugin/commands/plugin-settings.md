---
description: Configure plugin settings using local files and environment variables
allowed-tools: [Read, Write, Edit, Glob]
argument-hint: "[setting-name] [value]"
---

# Plugin Settings & Configuration

Manage plugin-specific settings and state.

**Request:** $ARGUMENTS

## Configuration Locations

### Plugin-level Settings
```
.claude-plugin/
├── plugin.json          # Manifest (version, author, components)
├── CLAUDE.md           # Plugin context (auto-loaded)
└── config.local.json   # Local overrides (gitignored)
```

### Project-level Settings
```
.claude/
├── settings.json       # Shareable settings (hooks, etc.)
├── settings.local.json # Local-only settings
└── CLAUDE.md          # Project context
```

### User-level Settings
```
~/.claude/
├── settings.json       # Global settings
└── CLAUDE.md          # Personal context
```

## Plugin Configuration Pattern

### Using .local.md Files

Store plugin-specific config in frontmatter:

```markdown
---
# my-plugin.local.md
api_endpoint: https://api.example.com
features:
  auto_format: true
  strict_mode: false
last_sync: 2025-01-14T10:00:00Z
---

# Plugin Notes

User notes and context here.
```

### Reading Configuration

```bash
# In a hook script
yq '.api_endpoint' .claude/my-plugin.local.md
```

```python
# In Python
import yaml
with open('.claude/my-plugin.local.md') as f:
    content = f.read()
    _, frontmatter, body = content.split('---', 2)
    config = yaml.safe_load(frontmatter)
```

## Settings Precedence

1. `.claude/settings.local.json` (highest - local overrides)
2. `.claude/settings.json` (project defaults)
3. `~/.claude/settings.json` (global defaults)

## Hook Configuration in Settings

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/validate.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

## Best Practices

1. **Gitignore local files**: Add `*.local.*` to `.gitignore`
2. **Document required settings**: List in plugin CLAUDE.md
3. **Provide defaults**: Ship sensible defaults in non-local files
4. **Use environment variables**: For secrets and API keys
5. **Validate on load**: Check settings in SessionStart hooks
