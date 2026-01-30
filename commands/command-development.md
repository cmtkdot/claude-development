---
description: Use when creating slash commands, adding YAML frontmatter, or configuring command arguments and tools
allowed-tools: [Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite]
argument-hint: "<command-name> [description]"
---

# Slash Command Development

Create or improve a Claude Code slash command.

**Request:** $ARGUMENTS

## Command Structure

```yaml
---
description: Clear description of what the command does
allowed-tools: [Tool1, Tool2]  # Optional: restrict available tools
argument-hint: "<required> [optional]"  # Shown in command menu
---

# Command Title

Your command prompt here.

Use $ARGUMENTS for user input.
Use $1, $2, $3 for positional arguments.
```

## Key Features

### Dynamic Context
Load real-time state using backticks:
```markdown
Current git status:
`git status --short`
```

### File References
Include file content with @:
```markdown
Review this file: @$ARGUMENTS
```

### Tool Restrictions
Limit what tools the command can use:
```yaml
allowed-tools: [Read, Grep, Glob]  # Read-only
allowed-tools: [Task]  # Delegation only
allowed-tools: [Bash(git *)]  # Bash with git commands only
```

## Examples

### Simple Command
```yaml
---
description: Run project tests
---
Run the test suite and report results.
```

### With Arguments
```yaml
---
description: Review a specific file
argument-hint: "<file-path>"
---
Review @$ARGUMENTS for quality and best practices.
```

### With Tool Restrictions
```yaml
---
description: Safe git operations only
allowed-tools: [Bash(git status:*), Bash(git diff:*), Bash(git log:*)]
---
Show git status and recent changes.
```

Create the command now based on the request.
