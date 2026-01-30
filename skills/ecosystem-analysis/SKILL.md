---
name: ecosystem-analysis
description: "Use when auditing Claude Code configurations, finding what skills/agents/hooks exist, or checking for integration gaps. Triggers: audit config, what exists, list components"
argument-hint: "[scope]"
---

# Ecosystem Analysis

Analyze Claude Code configurations to find skills, agents, hooks, and MCP tools.

## Quick Discovery

```bash
# Find all skills
find . ~/.claude -name "SKILL.md" 2>/dev/null

# Find all agents
find . ~/.claude -name "*.md" -path "*/agents/*" 2>/dev/null

# List MCP servers
cat .mcp.json 2>/dev/null | jq -r '.mcpServers | keys[]'

# Show configured hooks
cat .claude/settings.json 2>/dev/null | jq '.hooks'
```

## Configuration Locations

| Component | Project | Personal | Plugin |
|-----------|---------|----------|--------|
| Skills | `.claude/skills/` | `~/.claude/skills/` | `<plugin>/skills/` |
| Agents | `.claude/agents/` | `~/.claude/agents/` | `<plugin>/agents/` |
| Hooks | `.claude/settings.json` | `~/.claude/settings.json` | `<plugin>/hooks/hooks.json` |
| MCP | `.mcp.json` | `~/.claude/.mcp.json` | `<plugin>/.mcp.json` |

## Integration Opportunities

### Skill + Hook

Add validation hooks for skills that modify files:
```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{
        "type": "command",
        "command": "npm run lint:fix"
      }]
    }]
  }
}
```

### Agent + Skills

Preload skills into agents:
```yaml
---
name: my-agent
skills:
  - api-conventions
  - error-handling
---
```

### MCP + Hooks

Add hooks for MCP tool validation:
```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "mcp__database__.*",
      "hooks": [{
        "type": "command",
        "command": "./validate-query.sh"
      }]
    }]
  }
}
```

## Gap Analysis

Check for:
- Skills without validation hooks
- Agents without relevant skills preloaded
- MCP servers without audit hooks
- Duplicate configurations across locations
