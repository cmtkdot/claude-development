---
name: writing-skills
description: "Use when creating or updating SKILL.md files. Triggers: create skill, new skill, SKILL.md template, skill frontmatter"
argument-hint: "[skill-name]"
disable-model-invocation: true
---

# Writing Skills

> **Before creating skills, check latest docs:** `/docs skills` for current syntax and best practices.

Skills extend Claude's capabilities. Create a `SKILL.md` file with instructions, and Claude adds it to its toolkit.

## Quick Start

Create a skill directory with a SKILL.md:

```bash
mkdir -p ~/.claude/skills/my-skill
```

Write the SKILL.md:

```yaml
---
name: my-skill
description: Use when doing X. Triggers on Y, Z keywords.
---

Instructions for Claude when this skill is active.
```

## Skill Locations

| Location | Path | Scope |
|----------|------|-------|
| Personal | `~/.claude/skills/<name>/SKILL.md` | All your projects |
| Project | `.claude/skills/<name>/SKILL.md` | This project only |
| Plugin | `<plugin>/skills/<name>/SKILL.md` | Where plugin enabled |

## Frontmatter Reference

**Required:**
- `name`: Lowercase, numbers, hyphens (max 64 chars)
- `description`: Starts with "Use when..." - triggers automatic loading

**Optional:**
- `argument-hint`: Hint for autocomplete (e.g., `[filename]`)
- `disable-model-invocation`: `true` = only user can invoke via `/name`
- `user-invocable`: `false` = hide from slash menu, Claude-only
- `allowed-tools`: Tools Claude can use without permission
- `model`: Model to use (sonnet, opus, haiku)
- `context`: `fork` to run in isolated subagent
- `agent`: Agent type when `context: fork` (Explore, Plan, general-purpose, or custom)
- `hooks`: Lifecycle hooks (PreToolUse, PostToolUse, Stop)

## String Substitutions

| Variable | Description |
|----------|-------------|
| `$ARGUMENTS` | All arguments passed when invoking |
| `$ARGUMENTS[N]` or `$N` | Specific argument by index (0-based) |
| `${CLAUDE_SESSION_ID}` | Current session ID |

Example:
```yaml
---
name: fix-issue
description: Fix a GitHub issue
---

Fix GitHub issue #$ARGUMENTS following our coding standards.
```

## Dynamic Context Injection

Use `!`command`` to run shell commands before the skill loads:

```yaml
---
name: pr-summary
description: Summarize current PR
---

## Current state
- Diff: !`git diff main`
- Branch: !`git branch --show-current`

Summarize the changes above.
```

## Skill Structure

```
my-skill/
├── SKILL.md           # Main instructions (required, <500 lines)
├── references/        # Detailed docs loaded when needed
└── scripts/           # Scripts Claude can execute
```

Keep SKILL.md focused. Reference supporting files for details:
```markdown
For API details, see [reference.md](reference.md)
```

## Best Practices

1. **Description is key**: Claude uses it to decide when to load the skill
2. **Keep it lean**: Under 500 lines, use references for details
3. **Be specific**: Direct instructions, not general guidelines
4. **Test it**: Invoke with `/skill-name` to verify behavior

## Examples

**Read-only analysis skill:**
```yaml
---
name: code-review
description: Use when reviewing code for quality issues
allowed-tools: Read, Grep, Glob
---

Review the specified files for quality issues...
```

**Forked research skill:**
```yaml
---
name: deep-research
description: Use when researching a topic thoroughly
context: fork
agent: Explore
---

Research $ARGUMENTS thoroughly...
```

**User-only deployment skill:**
```yaml
---
name: deploy
description: Deploy to production
disable-model-invocation: true
---

Deploy the application...
```

## Related Components

- **Skills**: `hook-development`, `ecosystem-analysis`
- **Used by agents**: `skill-creator`, `agent-creator`
