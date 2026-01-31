---
name: ecosystem-analysis
description: "Use when auditing Claude Code configurations, finding what skills/agents/hooks exist, checking for integration gaps, or optimizing plugin architecture. Triggers: audit config, what exists, list components, find gaps, integration check"
argument-hint: "[scope]"
disable-model-invocation: true
---

# Ecosystem Analysis

> **Check latest docs:** `/docs plugins` or `/docs skills` for current syntax before making changes.

Analyze Claude Code configurations to find skills, agents, hooks, and MCP tools. Use this skill to understand what exists and identify integration opportunities.

## Quick Discovery Commands

```bash
# Find all skills (project, personal, plugins)
ls .claude/skills/*/SKILL.md ~/.claude/skills/*/SKILL.md 2>/dev/null
find ~/.claude/plugins -name "SKILL.md" 2>/dev/null

# Find all agents
ls .claude/agents/*.md ~/.claude/agents/*.md 2>/dev/null
find ~/.claude/plugins -name "*.md" -path "*/agents/*" 2>/dev/null

# List MCP servers
cat .mcp.json 2>/dev/null | jq -r '.mcpServers | keys[]'
cat ~/.claude/.mcp.json 2>/dev/null | jq -r '.mcpServers | keys[]'

# Show configured hooks
cat .claude/settings.json 2>/dev/null | jq '.hooks'
cat ~/.claude/settings.json 2>/dev/null | jq '.hooks'
```

## Configuration Locations

| Component | Project | Personal | Plugin |
|-----------|---------|----------|--------|
| Skills | `.claude/skills/` | `~/.claude/skills/` | `<plugin>/skills/` |
| Agents | `.claude/agents/` | `~/.claude/agents/` | `<plugin>/agents/` |
| Hooks | `.claude/settings.json` | `~/.claude/settings.json` | `<plugin>/hooks/hooks.json` |
| MCP | `.mcp.json` | `~/.claude/.mcp.json` | `<plugin>/.mcp.json` |

## Analysis Workflow

### Phase 1: Inventory

Run discovery commands to build a complete picture:

1. **Skills**: Count, names, descriptions, tools used
2. **Agents**: Count, names, which skills they use, hooks configured
3. **Hooks**: Events covered, matchers, scripts called
4. **MCP**: Servers available, tools exposed

### Phase 2: Dependency Mapping

Create a dependency graph:

```
Agent A
├── uses skills: [skill-1, skill-2]
├── hooks: PreToolUse, Stop
└── calls MCP: database, memory

Skill-1
├── allowed-tools: [Read, Grep]
└── no hooks

Skill-2
├── allowed-tools: [Read, Write, Edit]
└── hooks: PostToolUse (lint)
```

### Phase 3: Gap Analysis

Check for:

| Gap Type | Check | Fix |
|----------|-------|-----|
| Skills without hooks | Skill has Write/Edit in allowed-tools but no PostToolUse hook | Add validation/lint hook |
| Agents without skills | Agent has empty skills array | Add relevant skills |
| MCP without audit | MCP tools used but no PreToolUse validation | Add input validation hook |
| Duplicate configs | Same hook in both project and personal | Consolidate to one location |
| Orphan scripts | Scripts in hooks/ not referenced | Delete or wire up |

### Phase 4: Optimization

Look for:

- **Tool reduction**: Agents with unused tools declared
- **Model optimization**: Agents using opus for simple tasks
- **Hook consolidation**: Multiple hooks that could be combined
- **Description improvement**: Agents/skills with poor CSO (discovery keywords)

## Integration Patterns

### Skill + Hook

Add validation hooks for skills that modify files. Note: hooks receive file info via JSON stdin, not environment variables:

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{
        "type": "command",
        "command": "bash .claude/hooks/lint-on-write.sh"
      }]
    }]
  }
}
```

The hook script extracts the file path from stdin:
```bash
#!/usr/bin/env bash
FILE=$(cat | jq -r '.tool_input.file_path // empty')
[[ -n "$FILE" ]] && npm run lint:fix "$FILE"
```

### Agent + Skills

Preload skills into agents for consistent behavior:

```yaml
---
name: my-agent
skills:
  - api-conventions
  - error-handling
  - testing-standards
---
```

### Agent + Stop Hook

Add completion reports to agents:

```yaml
hooks:
  Stop:
    - hooks:
        - type: command
          command: 'bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/completion-report.sh"'
```

### MCP + PreToolUse Hook

Validate MCP tool inputs before execution:

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

## Output Format

When presenting analysis, use this structure:

```markdown
## Ecosystem Summary

### Inventory
- Skills: X (names)
- Agents: X (names)
- Hooks: X events covered
- MCP: X servers

### Dependency Graph
[ASCII diagram]

### Gaps Found
1. [Gap type]: [specific issue] -> [recommended fix]

### Optimization Opportunities
1. [Opportunity]: [benefit]

### Recommended Actions
1. [ ] Action with file path
2. [ ] Action with file path
```

## Common Issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| Agent not discovered | Poor description keywords | Add "Use when..." and triggers |
| Skill not loading | Description missing trigger words | Add error messages, tool names |
| Hook not firing | Wrong matcher pattern | Use regex: `Write\|Edit` not `Write,Edit` |
| Config conflicts | Duplicate in project + personal | Remove one, prefer project-level |

## Related Components

- **Skills**: `writing-skills`, `hook-development`
- **Used by agents**: `starter-agent`, `workflow-auditor`
