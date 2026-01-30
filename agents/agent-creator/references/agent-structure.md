# Agent Structure Reference

> Extracted from agent-creator.md for progressive disclosure.

## Required Frontmatter

```yaml
---
name: agent-name          # lowercase, hyphens, numbers only
description: Use when...  # Start with triggering conditions
---
```

## Optional Frontmatter

| Field | Purpose | Example |
|-------|---------|---------|
| `tools` | Restrict tool access | `[Read, Write, Edit, Bash]` |
| `model` | Execution model | `haiku`, `sonnet`, `opus` |
| `skills` | Skills to load | `[skill-one, skill-two]` |
| `context` | Isolation mode | `fork` for isolated execution |
| `hooks` | Lifecycle hooks | `PreToolUse`, `PostToolUse`, `Stop` |

## Full Example

```yaml
---
name: code-reviewer
description: Use when reviewing code for quality, security vulnerabilities, or PR checks. Triggers review, audit, check.
tools: [Read, Grep, Glob]
model: sonnet
skills: [code-review, security-check, pal-tools]
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-safe-commands.sh"
          once: true
  PostToolUse:
    - matcher: "Read"
      hooks:
        - type: command
          command: "./scripts/log-file-access.sh"
  Stop:
    - hooks:
        - type: prompt
          prompt: "Before stopping: verify all checklist items complete."
---

# Code Reviewer Agent

## Purpose
Reviews code for quality and security issues.

## When to Use
- PR reviews
- Security audits
- Code quality checks

## Workflow
1. Load relevant files
2. Apply review checklist
3. Generate report

## Integration Points
- Uses skills: code-review, security-check
- Works with: implementer, verifier agents
```
