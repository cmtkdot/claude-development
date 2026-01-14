# Plugin-Dev Ecosystem Optimization Report

**Generated:** 2026-01-14
**Plugin:** plugin-dev v1.0.0
**Analysis:** Complete integration gap analysis

---

## Executive Summary

**Current State:**
- 8 agents (5 with skills, 3 missing)
- 4 skills (0 have validation hooks)
- 14+ validation scripts (not wired to hooks)
- 8 slash commands
- 15 MCP servers (0 have audit hooks)

**Priority Gaps:**
1. **CRITICAL:** 3 auditor agents missing skills they depend on
2. **HIGH:** Skills lack validation hooks (scripts exist but not wired)
3. **MEDIUM:** MCP tools lack audit hooks for usage tracking
4. **LOW:** Missing slash commands for common workflows

---

## 1. Skills Without Hooks

All 4 skills are missing validation hooks, despite having validation scripts ready:

| Skill | Missing Hooks | Impact | Scripts Available |
|-------|---------------|--------|-------------------|
| writing-skills | PreToolUse, PostToolUse | No SKILL.md validation | validate-skill-metadata.py, lint-skill.sh, check-skill-size.sh |
| hook-development | PreToolUse, PostToolUse | No hook script validation | lint-hook.sh |
| ecosystem-analysis | PostToolUse | No audit logging | N/A (could add discovery logging) |
| create-hook-structure | PostToolUse | No structure validation | N/A (could add) |

**Severity:** HIGH - Validation scripts exist but are unused

---

## 2. Agents Without Skills

3 auditor agents are missing skills they should load:

### 2.1 skill-auditor (CRITICAL)

**Current:**
```yaml
name: skill-auditor
tools: [Read, Grep, Glob]
model: sonnet
# NO SKILLS FIELD
```

**Should Be:**
```yaml
name: skill-auditor
tools: [Read, Grep, Glob]
model: sonnet
skills: [writing-skills, ecosystem-analysis]
```

**Why It Matters:**
- skill-auditor needs `writing-skills` for SKILL.md structure knowledge
- Needs `ecosystem-analysis` to understand component relationships
- Currently relies on memory instead of explicit skill context

---

### 2.2 subagent-auditor (CRITICAL)

**Current:**
```yaml
name: subagent-auditor
tools: [Read, Grep, Glob]
model: sonnet
# NO SKILLS FIELD
```

**Should Be:**
```yaml
name: subagent-auditor
tools: [Read, Grep, Glob]
model: sonnet
skills: [writing-skills, ecosystem-analysis]
```

**Why It Matters:**
- Audits agents that have skills, needs same context
- Should understand ecosystem patterns
- Currently inconsistent with other creator agents

---

### 2.3 slash-command-auditor (CRITICAL)

**Current:**
```yaml
name: slash-command-auditor
tools: [Read, Grep, Glob]
model: sonnet
# NO SKILLS FIELD
```

**Should Be:**
```yaml
name: slash-command-auditor
tools: [Read, Grep, Glob]
model: sonnet
skills: [writing-skills]
```

**Why It Matters:**
- Commands share structure patterns with skills
- Needs TDD and documentation best practices
- Currently weaker than other auditors

**Severity:** CRITICAL - All 3 auditors are missing essential context

---

## 3. Missing Hook Coverage

### 3.1 Skill Validation Hooks (HIGH PRIORITY)

**Configuration to Add:**

Create `/Users/jay/development/claude-development/.claude-plugin/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "/Users/jay/development/claude-development/hooks/scripts/skill-tools/validate-skill-metadata.py",
            "description": "Validate SKILL.md frontmatter before writing"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "/Users/jay/development/claude-development/hooks/scripts/skill-tools/lint-skill.sh",
            "description": "Lint SKILL.md structure after write/edit"
          },
          {
            "type": "command",
            "command": "/Users/jay/development/claude-development/hooks/scripts/skill-tools/check-skill-size.sh",
            "description": "Verify progressive disclosure compliance"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "/Users/jay/development/claude-development/hooks/scripts/skill-tools/skill-audit-report.sh",
            "description": "Generate skill audit summary on session end"
          },
          {
            "type": "command",
            "command": "/Users/jay/development/claude-development/hooks/scripts/agent-tools/agent-audit-report.sh",
            "description": "Generate agent audit summary on session end"
          },
          {
            "type": "command",
            "command": "/Users/jay/development/claude-development/hooks/scripts/hook-tools/hook-audit-report.sh",
            "description": "Generate hook audit summary on session end"
          }
        ]
      }
    ]
  }
}
```

**Impact:** Activates all existing validation scripts

---

### 3.2 Agent Validation Hooks

**Already Configured in Agent Files:**
- skill-creator has PreToolUse hooks for Write|Edit
- agent-creator has PreToolUse hooks for Write|Edit
- hook-creator has PreToolUse hooks for Write|Edit

**Good:** Agents self-validate, no plugin-level hooks needed

---

### 3.3 MCP Tool Audit Hooks (MEDIUM PRIORITY)

15 MCP servers have zero audit hooks. Recommended pattern:

**Create:** `/Users/jay/development/claude-development/hooks/scripts/mcp-tools/audit-mcp-usage.sh`

```bash
#!/usr/bin/env bash
# Log MCP tool usage for analytics

TOOL_NAME="${TOOL_NAME:-unknown}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
LOG_FILE="${HOME}/.claude/logs/mcp-usage.log"

mkdir -p "$(dirname "$LOG_FILE")"
echo "${TIMESTAMP} | ${TOOL_NAME}" >> "$LOG_FILE"

# Allow the call to proceed
exit 0
```

**Wire in settings.json:**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "mcp__.*",
        "hooks": [
          {
            "type": "command",
            "command": "/Users/jay/development/claude-development/hooks/scripts/mcp-tools/audit-mcp-usage.sh",
            "description": "Track MCP tool usage"
          }
        ]
      }
    ]
  }
}
```

**Benefit:** Analytics on which MCP tools are actually used

---

## 4. Command Gaps

Current commands cover main workflows well. Potential additions:

### 4.1 Missing: /audit-plugin

**Purpose:** Run all auditors on the entire plugin

**File:** `.claude-plugin/commands/audit-plugin.md`

```yaml
---
description: Run complete plugin audit - checks all skills, agents, commands, and hooks for quality and integration gaps
allowed-tools: [Task, Read, Grep, Glob]
---

# Complete Plugin Audit

Run comprehensive quality checks across the entire plugin.

## Phase 1: Component Audits

Spawn auditors in parallel:
1. skill-auditor for each SKILL.md
2. subagent-auditor for each agent
3. slash-command-auditor for each command

## Phase 2: Integration Analysis

Spawn skill-router to:
- Find integration gaps
- Generate optimization report
- Identify missing hooks

## Phase 3: Report

Consolidate findings into:
- Critical issues (blocking release)
- Recommendations (improve quality)
- Strengths (what's working)
- Next steps
```

**Impact:** One-command full plugin validation

---

### 4.2 Missing: /test-skill

**Purpose:** Run TDD pressure scenarios on a skill

**File:** `.claude-plugin/commands/test-skill.md`

```yaml
---
description: Test a skill with pressure scenarios - spawns subagent to validate skill behavior under realistic conditions
allowed-tools: [Task, Read]
argument-hint: "<skill-name>"
---

# Test Skill with Pressure Scenarios

Test skill: $ARGUMENTS

## Test Protocol

1. Read @skills/$ARGUMENTS/SKILL.md
2. Identify 3-5 pressure scenarios from skill description
3. Spawn general-purpose subagent with skill loaded
4. Run scenarios and document:
   - Expected behavior
   - Actual behavior
   - Pass/Fail per scenario
5. Report findings

## Success Criteria

- All scenarios attempted
- Clear pass/fail per scenario
- Concrete examples of failures (if any)
- Recommendations for skill improvements
```

**Impact:** Formalize TDD testing from writing-skills

---

### 4.3 Missing: /wire-hooks

**Purpose:** Add hook configuration to settings.json

**File:** `.claude-plugin/commands/wire-hooks.md`

```yaml
---
description: Configure hooks in settings.json - wire validation scripts to lifecycle events
allowed-tools: [Read, Write, Edit, Glob]
argument-hint: "<event-type> <matcher> <script-path>"
---

# Wire Hooks to Settings

Configure hook: $ARGUMENTS

## Steps

1. Read current settings.json (or create if missing)
2. Parse arguments:
   - Event type: PreToolUse, PostToolUse, Stop, etc.
   - Matcher: Tool name pattern
   - Script path: Absolute path to hook script
3. Add hook configuration to appropriate event
4. Validate JSON structure
5. Write updated settings.json
6. Test hook fires correctly

## Validation

- JSON is valid
- Script path exists and is executable
- Matcher pattern is valid regex
- No duplicate hook entries
```

**Impact:** Simplifies hook wiring process

---

## 5. Generated Configurations

### 5.1 Fix Agent Skills (IMMEDIATE ACTION)

```bash
# Update skill-auditor.md
cd /Users/jay/development/claude-development/agents

# Add skills field to line 6 (after model: sonnet)
```

**skill-auditor.md:**
```diff
---
name: skill-auditor
description: "Use when reviewing SKILL.md files..."
tools: [Read, Grep, Glob]
model: sonnet
+skills: [writing-skills, ecosystem-analysis]
---
```

**subagent-auditor.md:**
```diff
---
name: subagent-auditor
description: "Use when reviewing agent .md configuration files..."
tools: [Read, Grep, Glob]
model: sonnet
+skills: [writing-skills, ecosystem-analysis]
---
```

**slash-command-auditor.md:**
```diff
---
name: slash-command-auditor
description: "Use when reviewing slash command .md files..."
tools: [Read, Grep, Glob]
model: sonnet
+skills: [writing-skills]
---
```

---

### 5.2 Create Plugin Settings (IMMEDIATE ACTION)

**File:** `/Users/jay/development/claude-development/.claude-plugin/settings.json`

See section 3.1 above for complete configuration.

---

### 5.3 Create Missing Hook Scripts

**File:** `/Users/jay/development/claude-development/hooks/scripts/mcp-tools/audit-mcp-usage.sh`

See section 3.3 above for implementation.

---

## 6. Integration Matrix

| Component | Has Hooks? | Has Skills? | Wired? | Status |
|-----------|-----------|-------------|--------|---------|
| writing-skills | Scripts exist | N/A | NO | **FIX: Wire hooks** |
| hook-development | Scripts exist | N/A | NO | **FIX: Wire hooks** |
| ecosystem-analysis | None | N/A | N/A | OK (no validation needed) |
| create-hook-structure | None | N/A | N/A | CONSIDER: Add structure validator |
| skill-creator | Self-validates | YES | YES | **GOOD** |
| agent-creator | Self-validates | YES | YES | **GOOD** |
| hook-creator | Self-validates | YES | YES | **GOOD** |
| skill-router | None | YES | N/A | **GOOD** |
| workflow-auditor | None | YES | N/A | **GOOD** |
| skill-auditor | None | NO | N/A | **FIX: Add skills** |
| subagent-auditor | None | NO | N/A | **FIX: Add skills** |
| slash-command-auditor | None | NO | N/A | **FIX: Add skills** |

---

## 7. Prioritized Action Plan

### Phase 1: CRITICAL (Do Now)

1. **Add skills to auditor agents** (5 min)
   - skill-auditor: add `skills: [writing-skills, ecosystem-analysis]`
   - subagent-auditor: add `skills: [writing-skills, ecosystem-analysis]`
   - slash-command-auditor: add `skills: [writing-skills]`

2. **Create plugin settings.json** (10 min)
   - Wire skill validation hooks (PreToolUse, PostToolUse)
   - Wire audit report hooks (Stop)
   - Test hooks fire correctly

### Phase 2: HIGH (This Week)

3. **Create /audit-plugin command** (15 min)
   - Spawns all auditors
   - Generates integration report
   - One-command validation

4. **Create /test-skill command** (15 min)
   - Formalizes TDD pressure testing
   - Documents in skill-development workflow

### Phase 3: MEDIUM (This Month)

5. **Add MCP audit hooks** (20 min)
   - Create audit-mcp-usage.sh script
   - Wire for all mcp__* tools
   - Track usage analytics

6. **Create /wire-hooks command** (20 min)
   - Simplify hook configuration
   - Reduce settings.json editing friction

### Phase 4: LOW (Nice to Have)

7. **Add structure validator for create-hook-structure**
   - Verify all required directories created
   - Check template files present

---

## 8. Metrics

### Before Optimization

- Skills with hooks: 0/4 (0%)
- Agents with skills: 5/8 (62.5%)
- MCP tools with hooks: 0/15 (0%)
- Commands for workflows: 8
- Validation scripts: 14
- Wired scripts: 0

### After Phase 1

- Skills with hooks: 4/4 (100%)
- Agents with skills: 8/8 (100%)
- MCP tools with hooks: 0/15 (0%)
- Commands for workflows: 8
- Validation scripts: 14
- Wired scripts: 14

### After Phase 2

- Skills with hooks: 4/4 (100%)
- Agents with skills: 8/8 (100%)
- MCP tools with hooks: 0/15 (0%)
- Commands for workflows: 10 (+2)
- Validation scripts: 14
- Wired scripts: 14

### After Phase 3

- Skills with hooks: 4/4 (100%)
- Agents with skills: 8/8 (100%)
- MCP tools with hooks: 15/15 (100%)
- Commands for workflows: 11 (+3)
- Validation scripts: 15 (+1)
- Wired scripts: 15

---

## 9. Risk Assessment

| Gap | Current Risk | After Fix | Mitigation |
|-----|-------------|-----------|------------|
| Auditors missing skills | **HIGH** - Inconsistent quality | LOW | Add skills field |
| Skills without hooks | **MEDIUM** - No validation | LOW | Wire existing scripts |
| MCP without hooks | **LOW** - No analytics | LOW | Add audit hooks |
| Missing commands | **LOW** - Manual workflows | LOW | Create commands |

---

## 10. Next Steps

1. Review this report
2. Approve Phase 1 fixes
3. I can implement all Phase 1 changes automatically
4. Test the wired hooks
5. Move to Phase 2

**Ready to implement Phase 1 fixes?**
