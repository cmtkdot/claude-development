# Claude Development Ecosystem

> Comprehensive guide to the Claude Code development infrastructure: agents, skills, hooks, and workflows.

## Quick Reference

| Component | Location | Purpose |
|-----------|----------|---------|
| Agents | `.claude/agents/` | Specialized AI personas for specific tasks |
| Skills | `.claude/skills/` | Reusable workflows and knowledge |
| Hooks | `.claude/hooks/` | Lifecycle automation and validation |
| Rules | `.claude/rules/` | Path-scoped coding standards |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           CLAUDE CODE ECOSYSTEM                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐                 │
│  │   AGENTS     │────▶│   SKILLS     │────▶│    HOOKS     │                 │
│  │  (Personas)  │     │ (Workflows)  │     │(Automation)  │                 │
│  └──────────────┘     └──────────────┘     └──────────────┘                 │
│         │                    │                    │                          │
│         ▼                    ▼                    ▼                          │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                        WORKFLOW PHASES                               │    │
│  ├─────────┬─────────┬─────────┬─────────┬─────────┬─────────┐         │    │
│  │BRAINSTORM│ CONTEXT │  PLAN   │IMPLEMENT│ VERIFY  │ ARCHIVE │         │    │
│  │(optional)│         │         │         │         │         │         │    │
│  └─────────┴─────────┴─────────┴─────────┴─────────┴─────────┘         │    │
│                                                                          │    │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Hooks System

### Event Types

| Event | Matcher | Can Block | Purpose |
|-------|---------|-----------|---------|
| `PreToolUse` | Yes | Exit 2 | Validate before tool execution |
| `PostToolUse` | Yes | No | Track/log after tool execution |
| `UserPromptSubmit` | No | Exit 2 | Transform user prompts |
| `SessionStart` | No | No | Load context on session start |
| `SessionEnd` | No | No | Cleanup on session end |
| `Stop` | No | Exit 2 | Validate before Claude stops |
| `SubagentStart` | No | No | Inject context to subagents |
| `SubagentStop` | No | Exit 2 | Aggregate subagent results |

### Hook Directory Structure

```
.claude/hooks/
├── hooks-config.json          # Hook registry and documentation
├── hooks-templates/           # Event-specific templates
│   ├── preToolUse.sh
│   ├── postToolUse.sh
│   ├── sessionStart.sh
│   ├── sessionEnd.sh
│   ├── stop.sh
│   ├── subagentStart.sh
│   ├── subagentStop.sh
│   └── userPromptSubmit.sh
├── hooks-language-guide/      # Language-specific best practices
│   ├── bash.md
│   ├── node.md
│   └── python.md
├── scripts/                   # Reusable validation scripts
│   ├── agent-tools/           # Agent validation
│   │   ├── validate-agent.sh
│   │   ├── lint-agent.sh
│   │   └── agent-audit-report.sh
│   ├── skill-tools/           # Skill validation
│   │   ├── validate-skill-metadata.py
│   │   ├── lint-skill.sh
│   │   ├── check-skill-size.sh
│   │   └── skill-audit-report.sh
│   ├── hook-tools/            # Hook validation
│   │   ├── lint-hook.sh
│   │   └── hook-audit-report.sh
│   ├── ecosystem/             # Discovery and integration
│   │   ├── discover-ecosystem.py
│   │   └── generate-integrations.py
│   └── workflow/              # Workflow automation
│       └── smart_commit.sh
├── utils/                     # Active hooks (wired in settings.json)
│   ├── preToolUse/
│   │   ├── background-agent-enforcer.sh
│   │   ├── prevent-file-versioning.sh
│   │   ├── postgresql-skill-guide.sh
│   │   ├── search-tools-redirect.cjs
│   │   ├── edit-tools-redirect.cjs
│   │   └── web-tools-redirect.cjs
│   ├── postToolUse/
│   │   ├── track-touched-files.sh
│   │   ├── track-migrations.sh
│   │   ├── bd-close-archive-reminder.sh
│   │   └── opus-code-review.sh
│   ├── sessionEnd/
│   │   ├── background-agent-cleanup.sh
│   │   └── doc-maintenance-trigger.sh
│   ├── stop/
│   │   ├── ultracite-lint.sh
│   │   └── qlty-lint.sh
│   ├── subagentStop/
│   │   └── background-agent-aggregator.sh
│   └── userPromptSubmit/
│       └── prompt-optimizer.sh
└── tests/                     # Hook tests
    ├── run-all-tests.sh
    └── test-helper.sh
```

### Active Hooks Summary

#### PreToolUse (5 hooks)

| Hook | Matcher | Purpose |
|------|---------|---------|
| `plan-review-gate` | `ExitPlanMode` | Smart plan review with PAL |
| `prevent-file-versioning` | `Write\|Edit\|mcp__morph-mcp__.*` | Fix-forward enforcement |
| `postgresql-skill-guide` | `mcp__postgresql__.*` | Database tool optimization |
| `subagent-orchestrator` | `Task` | Token cost optimization |
| `background-agent-enforcer` | `Task` | Max 5 concurrent agents |

#### PostToolUse (5 hooks)

| Hook | Matcher | Purpose |
|------|---------|---------|
| `track-touched-files` | `Write\|Edit\|mcp__morph-mcp__edit_file` | Session-aware file tracking |
| `track-migrations` | `mcp__postgresql__execute_sql` | Auto-save DDL operations |
| `track-migrations-mcp-cli` | `Bash` | Track mcp-cli DDL calls |
| `track-touched-files-mcp-cli` | `Bash` | Track mcp-cli edits |
| `bd-close-archive-reminder` | `Bash` | Auto-archive after bd close |

#### SessionEnd (3 hooks)

| Hook | Purpose |
|------|---------|
| `background-agent-cleanup` | Reset agent count |
| `qlty-lint` | Lint non-JS files |
| `doc-maintenance-trigger` | Documentation change detection |

#### Stop (1 hook)

| Hook | Purpose |
|------|---------|
| `ultracite-lint` | Auto-fix JS/TS lint issues |

---

## Agents

### Workflow Phase Agents

| Phase | Agent | Purpose |
|-------|-------|---------|
| BRAINSTORM | `brainstormer` | Creative design exploration |
| CONTEXT | `code-reviewer`, `librarian-researcher` | Gather context |
| PLAN | `planner` | Create implementation plans |
| IMPLEMENT | `implementer` | Execute plans with TDD |
| VERIFY | `verify-gatekeeper`, `code-skeptic` | Quality validation |
| ARCHIVE | `archiver` | Archive completed work |

### Specialized Agents

| Agent | Purpose | Skills |
|-------|---------|--------|
| `agent-creator` | Create new agents | writing-skills, hook-development |
| `skill-creator` | Create new skills | writing-skills |
| `hook-creator` | Create new hooks | hook-development |
| `skill-router` | Optimize ecosystem | ecosystem-analysis |
| `ui-engineer` | Frontend UI work | tamagui-ui |
| `frontend-designer` | Visual UI design | - |
| `supabase-agent` | Database operations | database-operations |
| `git-expert` | Git workflows | - |

### Agent Structure

```yaml
---
name: agent-name
description: Use when [triggering conditions]
tools: [Read, Write, Edit, Bash]
model: sonnet
skills: [skill-one, skill-two]
hooks:
  PreToolUse:
    - matcher: "Pattern"
      hooks:
        - type: command
          command: "$HOME/.claude/hooks/scripts/validate.sh"
---

# Agent Name

## Purpose
[What this agent does]

## When to Use
- [Scenario 1]
- [Scenario 2]
```

---

## Skills

### Skill Categories

| Category | Skills | Purpose |
|----------|--------|---------|
| **Workflow** | context-first, plan, implement, verify | Phase execution |
| **Testing** | test-specialist, testing-anti-patterns | TDD enforcement |
| **Database** | database-operations, schema-discovery | DB operations |
| **UI** | tamagui-ui, shadcn-web-components, web-ui-review | Frontend work |
| **Documentation** | writing-skills, docs-review | Documentation |
| **Tools** | pal-tools, serena-symbols, edit-tools-redirect | Tool optimization |
| **Research** | external-docs, github-researcher, code-patterns | Information gathering |

### Skill Structure

```yaml
---
name: skill-name
description: Use when [triggering conditions]
allowed-tools: [Read, Grep, Glob]
context: fork
agent: custom-agent
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate.sh"
---

# Skill Name

## Quick Start
[Essential workflow]

## Core Workflow
[Detailed steps]
```

---

## Creator Tools

### Agent Creator

```bash
# Invoke via Task tool or @agent-creator
@agent-creator Create an agent for reviewing database migrations
```

**Validation Scripts:**
- `validate-agent.sh` - PreToolUse frontmatter validation
- `lint-agent.sh` - PostToolUse structure linting
- `agent-audit-report.sh` - Stop hook session summary

### Skill Creator

```bash
# Invoke via /writing-skills or @skill-creator
/writing-skills
@skill-creator Create a skill for API documentation
```

**Validation Scripts:**
- `validate-skill-metadata.py` - PreToolUse validation
- `lint-skill.sh` - PostToolUse linting
- `check-skill-size.sh` - Progressive disclosure checks
- `skill-audit-report.sh` - Stop hook summary

### Hook Creator

```bash
# Invoke via @hook-creator
@hook-creator Create a PreToolUse hook to validate SQL queries
```

**Reference:**
- Templates: `.claude/hooks/hooks-templates/`
- Language guides: `.claude/hooks/hooks-language-guide/`

---

## Hook Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              HOOK LIFECYCLE                                  │
└─────────────────────────────────────────────────────────────────────────────┘

SessionStart                                                      SessionEnd
    │                                                                  │
    ▼                                                                  ▼
┌─────────┐                                                    ┌─────────────┐
│ Load    │                                                    │ Cleanup     │
│ Context │                                                    │ Agent Count │
│ Prime   │                                                    │ Doc Trigger │
│ Beads   │                                                    │ qlty Lint   │
└─────────┘                                                    └─────────────┘
    │                                                                  ▲
    │                                                                  │
    ▼                                                                  │
┌─────────────────────────────────────────────────────────────────────────────┐
│                           USER INTERACTION LOOP                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  UserPromptSubmit                                                            │
│       │                                                                      │
│       ▼                                                                      │
│  ┌──────────────┐                                                           │
│  │ // prefix?   │──Yes──▶ Prompt Optimizer (Haiku transform)                │
│  └──────────────┘                                                           │
│       │ No                                                                   │
│       ▼                                                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                        TOOL EXECUTION                                │    │
│  ├─────────────────────────────────────────────────────────────────────┤    │
│  │                                                                      │    │
│  │  PreToolUse ─────────▶ Tool Executes ─────────▶ PostToolUse         │    │
│  │       │                      │                       │               │    │
│  │       ▼                      ▼                       ▼               │    │
│  │  • Validate agent     • Read/Write/Edit       • Track files         │    │
│  │  • Prevent versioning • Bash/Grep/Glob        • Track migrations    │    │
│  │  • Guide DB tools     • Task (subagent)       • Archive reminder    │    │
│  │  • Enforce limits                                                    │    │
│  │                                                                      │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│       │                                                                      │
│       ▼                                                                      │
│  ┌──────────────┐                                                           │
│  │ Task tool?   │──Yes──▶ SubagentStart ──▶ Subagent ──▶ SubagentStop      │
│  └──────────────┘                                │              │           │
│       │ No                                       │              ▼           │
│       │                                          │         • Decrement      │
│       │                                          │         • Summarize      │
│       ▼                                          │         • ultracite      │
│  ┌──────────────┐                                │                          │
│  │ Claude done? │──Yes──▶ Stop Hook ─────────────┘                          │
│  └──────────────┘              │                                            │
│       │ No                     ▼                                            │
│       │                   • ultracite-lint                                  │
│       │                   • Verify checklist                                │
│       │                                                                      │
│       └────────────────────────────────────────────────────────────────────┘│
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Script Reference

### Validation Scripts

| Script | Event | Input | Output |
|--------|-------|-------|--------|
| `validate-agent.sh` | PreToolUse | `{tool_input: {file_path}}` | Exit 0 or 2 |
| `lint-agent.sh` | PostToolUse | `{tool_input: {file_path}}` | Warnings |
| `validate-skill-metadata.py` | PreToolUse | `{tool_input: {file_path}}` | Exit 0 or 2 |
| `lint-skill.sh` | PostToolUse | `{tool_input: {file_path}}` | Warnings |
| `check-skill-size.sh` | PostToolUse | `{tool_input: {file_path}}` | Size warnings |

### Exit Code Reference

| Code | PreToolUse | PostToolUse | Stop |
|------|------------|-------------|------|
| 0 | Allow | Success | Allow stop |
| 1 | Error (pass through) | Error (ignore) | Error |
| 2 | Block (stderr → Claude) | N/A | Force continue |

### Script Template (Bash)

```bash
#!/bin/bash
set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Your validation logic
if [[ -z "$FILE_PATH" ]]; then
    exit 0
fi

# Block on error
echo "ERROR: Description" >&2
exit 2

# Or allow
exit 0
```

---

## Global vs Project Scope

| Scope | Location | Shared |
|-------|----------|--------|
| Global (User) | `~/.claude/agents/`, `~/.claude/skills/` | No |
| Project | `.claude/agents/`, `.claude/skills/` | Yes (git) |
| Local | `.claude/*.local.*` | No (gitignored) |

### Portable Script Paths

```bash
# Use $HOME for global scripts
command: 'bash "$HOME/.claude/hooks/scripts/validate.sh"'

# Use $CLAUDE_PROJECT_DIR for project scripts
command: 'bash "$CLAUDE_PROJECT_DIR/.claude/hooks/scripts/validate.sh"'

# Use ${CLAUDE_PLUGIN_ROOT} for plugin scripts
command: 'bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/validate.sh"'
```

---

## Workflow Integration

### Standard Workflow

```
/context-first "task"  →  /plan  →  /implement  →  /verify  →  /archive
```

### With Hooks

```
SessionStart
    │ → Load context, prime beads
    ▼
User Prompt
    │ → // prefix triggers optimizer
    ▼
PreToolUse
    │ → Validate, guide, enforce limits
    ▼
Tool Execution
    │
    ▼
PostToolUse
    │ → Track files, migrations, archive
    ▼
Stop
    │ → Lint, verify checklist
    ▼
SessionEnd
    │ → Cleanup, doc trigger
```

---

## Testing

### Run All Hook Tests

```bash
bash .claude/hooks/tests/run-all-tests.sh
```

### Test Individual Hooks

```bash
# Validate agent script
echo '{"tool_input": {"file_path": ".claude/agents/agent-creator.md"}}' | \
  bash .claude/hooks/scripts/agent-tools/validate-agent.sh

# Validate skill script
echo '{"tool_input": {"file_path": ".claude/skills/writing-skills/SKILL.md"}}' | \
  python3 .claude/hooks/scripts/skill-tools/validate-skill-metadata.py
```

---

## Quick Commands

```bash
# List agents
ls .claude/agents/*.md | xargs -I{} basename {} .md

# List skills
find .claude/skills -name "SKILL.md" | xargs -I{} dirname {} | xargs -I{} basename {}

# List active hooks
jq '.hooks | keys' .claude/settings.json

# Discover ecosystem
python3 .claude/hooks/scripts/ecosystem/discover-ecosystem.py | jq

# Audit all creators
bash ~/.claude/hooks/scripts/agent-tools/agent-audit-report.sh
bash ~/.claude/hooks/scripts/skill-tools/skill-audit-report.sh
```

---

## Related Documentation

| Document | Location | Purpose |
|----------|----------|---------|
| Hooks Config | `.claude/hooks/hooks-config.json` | Full hook registry |
| Coding Standards | `.claude/rules/standard/coding-standards.md` | Code conventions |
| Background Protocol | `.claude/rules/standard/background-agent-protocol.md` | Agent limits |
| TODO Conventions | `.claude/rules/standard/todo-conventions.md` | TODO format |
| Workflows | `docs/context/workflows.md` | Phase details |

---

**Version:** 1.0.0 | **Updated:** 2026-01-14
