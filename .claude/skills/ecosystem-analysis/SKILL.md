---
name: ecosystem-analysis
description: Use when analyzing Claude Code configurations, finding integration opportunities between skills/agents/MCP/hooks, or optimizing your development environment setup. Triggers on audit, optimize, integration, ecosystem, hooks analysis.
allowed-tools: Read, Grep, Glob, Bash
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: ".claude/hooks/scripts/validate-safe-commands.sh"
  PostToolUse:
    - matcher: "Read"
      hooks:
        - type: command
          command: ".claude/hooks/scripts/log-discovery.sh"
  Stop:
    - hooks:
        - type: command
          command: ".claude/hooks/scripts/generate-report.sh"
---

# Ecosystem Analysis Skill

Analyze and optimize Claude Code configurations across skills, agents, MCP tools, and hooks.

## Quick Commands

| Command | Purpose |
|---------|---------|
| `python3 .claude/hooks/scripts/discover-ecosystem.py` | Full ecosystem inventory |
| `find .claude/skills -name "SKILL.md"` | Find all project skills |
| `find .claude/agents -name "*.md"` | Find project agents |
| `cat .mcp.json \| jq '.mcpServers \| keys'` | List MCP servers |
| `jq '.hooks' .claude/settings.json` | View configured hooks |

## Discovery Workflow

1. **Inventory** - Run discover-ecosystem.py to collect all components
2. **Analyze** - Identify gaps, redundancies, integration opportunities
3. **Report** - Generate optimization recommendations
4. **Implement** - Create missing hooks, update agent skills

## Integration Patterns

### Skill → Hook Integration
```yaml
hooks:
  PreToolUse:
    - matcher: "ToolName"
      hooks:
        - type: command
          command: ".claude/hooks/scripts/validate.sh"
```

### Skill → MCP Integration
```yaml
hooks:
  PreToolUse:
    - matcher: "mcp__servername__.*"
      hooks:
        - type: command
          command: ".claude/hooks/scripts/mcp-audit.sh"
```

### Skill → Subagent Integration
```yaml
# In agent definition
skills: skill-one, skill-two
```

## Gap Analysis Checklist

- [ ] Skills without hooks → Add validation hooks
- [ ] Agents without skills → Add relevant skills to `skills:` field
- [ ] MCP servers without hooks → Add `mcp__server__*` matchers
- [ ] Redundant configurations → Consolidate

## Output Format

```markdown
## Ecosystem Report

### Inventory
- Skills: X
- Agents: Y
- MCP Servers: Z
- Hooks Configured: W

### Gaps Found
1. [gap with recommendation]

### Generated Configurations
[hook/skill/agent configs]
```
