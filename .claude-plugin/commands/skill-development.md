---
description: This skill should be used when the user wants to "create a skill", "add a skill to plugin", "write a new skill", "improve skill description", "organize skill content", or needs guidance on skill structure, progressive disclosure, or skill development best practices for Claude Code plugins.
allowed-tools: [Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite]
argument-hint: "<skill-name> [description]"
---

# Skill Development Workflow

Invoke the skill-creator agent to create or improve a Claude Code skill.

**Request:** $ARGUMENTS

## Workflow

1. **Research** - Understand the skill's purpose and target users
2. **Design** - Plan metadata, structure, and progressive disclosure
3. **Implement** - Write SKILL.md with proper frontmatter
4. **Test** - Validate with pressure scenarios using subagents
5. **Audit** - Run skill-auditor for quality check

## Key Principles

- **CSO (Claude Search Optimization)**: Description starts with "Use when..." and includes triggering conditions, not workflow summaries
- **Progressive Disclosure**: SKILL.md under 500 lines, heavy reference in separate files
- **TDD for Documentation**: Write failing test first, then skill to pass it

Spawn the skill-creator agent now:

```
Task({
  subagent_type: "skill-creator",
  prompt: "Create/improve skill: $ARGUMENTS. Follow TDD methodology."
})
```
