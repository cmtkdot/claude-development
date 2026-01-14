---
description: Guided end-to-end plugin creation workflow with component design, implementation, and validation
allowed-tools: [Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite]
argument-hint: "<plugin-name> [description]"
---

# Create New Claude Code Plugin

You're creating a new Claude Code plugin. Follow this structured workflow:

## Step 1: Gather Requirements

Ask the user about:
1. **Plugin name**: What should the plugin be called?
2. **Purpose**: What problem does it solve?
3. **Components needed**: Which of these does it need?
   - Skills (reusable procedures)
   - Agents (specialized subagents)
   - Hooks (lifecycle automation)
   - Commands (slash commands)

## Step 2: Initialize Structure

Create the plugin directory structure:

```
.claude-plugin/
├── plugin.json           # Manifest
├── commands/             # Slash commands
├── CLAUDE.md            # Plugin context
└── .claude/
    ├── agents/          # Custom agents
    ├── skills/          # Custom skills
    └── hooks/           # Custom hooks
```

## Step 3: Create Components

For each component type the user needs:

### Skills
Use the `skill-creator` agent:
```
Task({ subagent_type: "skill-creator", prompt: "Create skill: [name] - [purpose]" })
```

### Agents
Use the `agent-creator` agent:
```
Task({ subagent_type: "agent-creator", prompt: "Create agent: [name] - [purpose]" })
```

### Hooks
Use the `hook-creator` agent:
```
Task({ subagent_type: "hook-creator", prompt: "Create hook: [event] - [purpose]" })
```

## Step 4: Validate

Run auditors on created components:
- `skill-auditor` for skills
- `subagent-auditor` for agents
- `workflow-auditor` for overall architecture

## Step 5: Test

Test each component with representative tasks before finalizing.

---

**User requested:** $ARGUMENTS

Begin by asking clarifying questions about the plugin requirements.
