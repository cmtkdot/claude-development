---
description: Use when creating hooks, debugging hook issues, or learning the 6-phase hook development workflow
allowed-tools: [Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite]
argument-hint: "<hook-purpose> [event-type]"
---

# Hook Development Workflow

Invoke the hook-creator agent to create or debug Claude Code hooks.

**Request:** $ARGUMENTS

## Workflow (DECIDE -> PLAN -> IMPLEMENT -> TEST -> DOCUMENT -> AUDIT)

1. **DECIDE** - Choose event type, matcher pattern, and language
2. **PLAN** - Read template, document expected behavior
3. **IMPLEMENT** - Create script in `.claude/hooks/utils/{event}/`
4. **TEST** - Syntax check, unit test, integration test
5. **DOCUMENT** - Wire in settings.json, update registry
6. **AUDIT** - Security and performance review

## Event Types Quick Reference

| Event | Can Block | Has Matcher | Use For |
|-------|-----------|-------------|---------|
| PreToolUse | Yes (exit 2) | Yes | Validate/block before tool runs |
| PostToolUse | No | Yes | Track/log after tool runs |
| Stop | Yes (exit 2) | No | Auto-fix before session ends |
| UserPromptSubmit | Yes (exit 2) | No | Enhance/validate user input |
| SessionStart | No | No | Initialize session |

## Performance Budgets

- PreToolUse: < 100ms (blocks user action)
- PostToolUse: < 500ms (tracking/logging)
- Stop: < 30s (auto-fixing)

Spawn the hook-creator agent now:

```
Task({
  subagent_type: "hook-creator",
  prompt: "Create/debug hook: $ARGUMENTS"
})
```
