---
description: Use when creating agents, writing subagent configs, or improving agent frontmatter and system prompts
allowed-tools: [Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite]
argument-hint: "<agent-name> [description]"
---

# Agent Development Workflow

Invoke the agent-creator agent to create or improve a Claude Code subagent.

**Request:** $ARGUMENTS

## Workflow

1. **Purpose** - Define what the agent does and when to use it
2. **Tools** - Select minimum necessary tools
3. **Skills** - Identify skill dependencies (agents don't inherit skills)
4. **Hooks** - Configure lifecycle hooks if needed
5. **Prompt** - Write clear system prompt with role, constraints, workflow
6. **Test** - Validate with representative tasks
7. **Audit** - Run subagent-auditor for quality check

## Key Frontmatter Fields

```yaml
---
name: agent-name
description: "Use when... Triggers: keyword1, keyword2"
tools: [Read, Write, Edit, Bash]
model: sonnet  # haiku, sonnet, or opus
skills: [skill-one, skill-two]
---
```

Spawn the agent-creator agent now:

```
Task({
  subagent_type: "agent-creator",
  prompt: "Create/improve agent: $ARGUMENTS"
})
```
