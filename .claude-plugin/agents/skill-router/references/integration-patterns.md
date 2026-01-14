# Integration Patterns

> Extracted from skill-router.md for progressive disclosure.

## Skill → Hook Integration

```yaml
hooks:
  PreToolUse:
    - matcher: "ToolName"
      hooks:
        - type: command
          command: "hooks/scripts/validate.sh"
```

## Skill → MCP Integration

```yaml
hooks:
  PreToolUse:
    - matcher: "mcp__servername__.*"
      hooks:
        - type: command
          command: "hooks/scripts/mcp-audit.sh"
```

## Skill → Subagent Integration

```yaml
# In agent definition
skills: skill-one, skill-two
```

## Analysis Matrix Template

For each discovered component, evaluate:

| Component  | Has Hooks? | MCP Integration? | Subagent Access? | Scripts? |
|------------|------------|------------------|------------------|----------|
| skill-name | ✓/✗        | ✓/✗              | ✓/✗              | ✓/✗      |

## Integration Opportunities Checklist

Look for:

- **Skills without hooks** → Add PreToolUse/PostToolUse validation
- **Agents without skills** → Add relevant skills to `skills:` field
- **MCP tools without hooks** → Add `mcp__server__*` matchers
- **Redundant configurations** → Consolidate into plugins
