---
name: writing-skills
description: "Use when creating or updating SKILL.md files, testing skills with pressure scenarios, or learning TDD for documentation. Triggers: create skill, new skill, SKILL.md template, skill frontmatter, skill testing, CSO optimization"
context: fork
agent: [skill-creator, skill-router, hook-creator, agent-creator]
user-invocable: true
---

# Writing Skills

Skills are modular packages that extend Claude's capabilities with specialized knowledge, workflows, and tools. This skill covers creating, testing, and optimizing them.

**Core principle:** If you didn't watch an agent fail without the skill, you don't know if the skill teaches the right thing.

## Skill Creation Process

1. Understand the skill with concrete examples
2. Plan reusable contents (scripts, references, assets)
3. Initialize the skill (`scripts/init_skill.py`)
4. Edit the skill (implement resources, write SKILL.md)
5. Test with pressure scenarios (TDD)
6. Package the skill (`scripts/package_skill.py`)

## SKILL.md Structure

```
skill-name/
├── SKILL.md              # Main reference (required, <500 lines)
├── scripts/              # Executable code (Python/Bash)
├── references/           # Documentation loaded as needed
└── assets/               # Files used in output (templates, icons)
```

### Required Frontmatter

| Field | Description |
|-------|-------------|
| `name` | Lowercase, numbers, hyphens only (max 64 chars) |
| `description` | Start with "Use when..." - triggers skill loading |

### Optional Frontmatter

| Field | Description |
|-------|-------------|
| `allowed-tools` | Tools Claude can use without permission |
| `model` | Model to use (e.g., `claude-sonnet-4-20250514`) |
| `context` | Set to `fork` for isolated sub-agent context |
| `agent` | Agent type when `context: fork` is set |
| `hooks` | Lifecycle hooks: `PreToolUse`, `PostToolUse`, `Stop` |
| `user-invocable` | Controls slash command visibility (default `true`) |

## Degrees of Freedom

Match specificity to task fragility:

| Level | When to Use | Format |
|-------|-------------|--------|
| **High** | Multiple valid approaches, context-dependent | Text instructions |
| **Medium** | Preferred pattern exists, some variation OK | Pseudocode/scripts with params |
| **Low** | Fragile operations, consistency critical | Specific scripts, few params |

Think of Claude exploring a path: narrow bridge with cliffs needs guardrails (low freedom), open field allows many routes (high freedom).

## Progressive Disclosure

Keep SKILL.md lean. Split content when approaching 500 lines.

**Pattern 1: High-level guide with references**
```markdown
## Quick start
[Core workflow]

## Advanced features
- **Form filling**: See references/forms.md
- **API reference**: See references/api.md
```

**Pattern 2: Domain-specific organization**
```
bigquery-skill/
├── SKILL.md (overview + navigation)
└── references/
    ├── finance.md
    ├── sales.md
    └── product.md
```
User asks about sales → Claude only reads sales.md.

**Pattern 3: Conditional details**
```markdown
## Creating documents
Use docx-js. See references/docx-js.md.

## Editing documents
For simple edits, modify XML directly.
**For tracked changes**: See references/redlining.md
```

## What NOT to Include

Do NOT create extraneous files:
- README.md
- INSTALLATION_GUIDE.md
- CHANGELOG.md
- QUICK_REFERENCE.md

Skills are for AI agents, not human documentation.

## TDD Cycle for Skills

### RED: Baseline Test
Run pressure scenario WITHOUT skill. Document exact rationalizations.

### GREEN: Write Minimal Skill
Address specific failures from baseline. Run WITH skill—agent should comply.

### REFACTOR: Close Loopholes
New rationalization found? Add explicit counter. Re-test until bulletproof.

**Detailed methodology:** See `testing-skills-with-subagents.md`

## Claude Search Optimization (CSO)

**Description = When to Use, NOT What the Skill Does**

```yaml
# ❌ BAD: Summarizes workflow
description: Use when executing plans - dispatches subagent per task

# ✅ GOOD: Just triggering conditions
description: Use when executing implementation plans with independent tasks
```

**Keyword coverage:** Include error messages, symptoms, synonyms, tool names.

**Token targets:**
- Getting-started workflows: <150 words
- Frequently-loaded skills: <200 words
- Other skills: <500 words

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/init_skill.py <name> --path <dir>` | Initialize new skill directory |
| `scripts/package_skill.py <path>` | Validate and package .skill file |
| `scripts/quick_validate.py <path>` | Quick validation check |

## References

| File | Purpose |
|------|---------|
| `references/workflows.md` | Sequential and conditional workflow patterns |
| `references/output-patterns.md` | Template and examples patterns |
| `testing-skills-with-subagents.md` | Pressure scenario design, rationalization tables |
| `anthropic-best-practices.md` | Official Anthropic guidance |

## Skill Creation Checklist

**Use TodoWrite to track each item.**

**RED Phase:**
- [ ] Create pressure scenarios (3+ combined pressures)
- [ ] Run WITHOUT skill—document baseline behavior
- [ ] Identify rationalization patterns

**GREEN Phase:**
- [ ] Name: lowercase, numbers, hyphens only
- [ ] Description: starts with "Use when...", max 1024 chars
- [ ] Run WITH skill—verify compliance

**REFACTOR Phase:**
- [ ] Add counters for new rationalizations
- [ ] Build rationalization table
- [ ] Re-test until bulletproof

**Package:**
- [ ] Run `scripts/package_skill.py`
- [ ] Commit and push

---

## The Iron Law

```
NO SKILL WITHOUT A FAILING TEST FIRST
```

Write skill before testing? Delete it. Start over. No exceptions.
