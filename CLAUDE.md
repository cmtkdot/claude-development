# Claude Code Development Ecosystem

**Purpose:** Tools for creating, testing, and validating Claude Code skills, agents, and hooks.

---

## Quick Start

| Task | Command |
|------|---------|
| Create a skill | Invoke `skill-creator` agent |
| Create an agent | Invoke `agent-creator` agent |
| Create a hook | Invoke `hook-creator` agent or `/hook-development` skill |
| Audit a skill | Invoke `skill-auditor` agent |
| Audit an agent | Invoke `subagent-auditor` agent |
| List skills | `.claude/hooks/scripts/list-skills.sh` |
| Scaffold hooks | `.claude/hooks/scripts/scaffold-hooks.sh` |

---

## Directory Structure

```
.claude/
├── agents/                    # Specialized subagents
│   ├── skill-creator.md       # Creates skills with TDD
│   ├── agent-creator.md       # Creates agents with skill integration
│   ├── hook-creator.md        # Creates/debugs hooks
│   ├── skill-router.md        # Finds optimal skills for tasks
│   ├── workflow-auditor.md    # Validates configurations
│   ├── skill-auditor.md       # Audits skill best practices
│   ├── subagent-auditor.md    # Audits agent configurations
│   └── slash-command-auditor.md  # Audits slash commands
├── skills/
│   ├── writing-skills/        # TDD for documentation, skill creation
│   ├── hook-development/      # Comprehensive 6-phase hook workflow
│   ├── create-hook-structure/ # Scaffold hooks directory
│   └── ecosystem-analysis/    # Audit integrations
└── hooks/scripts/
    ├── agent-tools/           # Agent validation scripts
    ├── skill-tools/           # Skill validation scripts
    ├── hook-tools/            # Hook validation scripts
    ├── ecosystem/             # Discovery and integration
    ├── list-skills.sh         # List all available skills
    └── scaffold-hooks.sh      # Create hooks directory structure
```

---

## Creator Agent Trilogy

### skill-creator
Creates skills following TDD methodology:
1. Design skill metadata (frontmatter)
2. Write SKILL.md with progressive disclosure
3. Create CLAUDE.md for memory context
4. Add validation hooks
5. Test with subagent spawning

**Invocation:** `Task({ subagent_type: "skill-creator", prompt: "..." })`

### agent-creator
Creates agents with proper skill/hook integration:
1. Define purpose and scope
2. Select appropriate tools
3. Identify skill dependencies
4. Configure lifecycle hooks
5. Write agent markdown
6. Test with Task tool
7. Document usage patterns

**Invocation:** `Task({ subagent_type: "agent-creator", prompt: "..." })`

### hook-creator
Creates and debugs Claude Code hooks:
1. Identify hook event type needed
2. Design input/output contracts
3. Implement with proper error handling
4. Test hook execution
5. Wire in settings.json
6. Verify end-to-end

**Invocation:** `Task({ subagent_type: "hook-creator", prompt: "..." })`

---

## Auditor Agents

| Agent | Purpose | Use When |
|-------|---------|----------|
| skill-auditor | Best practices compliance | Reviewing skill files |
| subagent-auditor | Agent configuration validation | Reviewing agent files |
| slash-command-auditor | Slash command evaluation | Reviewing commands |
| workflow-auditor | YAML/configuration review | Validating workflows |

---

## Validation Scripts

### Agent Tools (`hooks/scripts/agent-tools/`)

| Script | Event | Purpose |
|--------|-------|---------|
| `validate-agent.sh` | PreToolUse | Block on missing required fields |
| `lint-agent.sh` | PostToolUse | Non-blocking quality warnings |
| `agent-audit-report.sh` | Stop | Session summary of agents |

### Skill Tools (`hooks/scripts/skill-tools/`)

| Script | Event | Purpose |
|--------|-------|---------|
| `validate-skill-metadata.py` | PreToolUse | Block on metadata errors |
| `lint-skill.sh` | PostToolUse | Structure warnings |
| `check-skill-size.sh` | PostToolUse | Progressive disclosure checks |
| `skill-audit-report.sh` | Stop | Session skill summary |

### Hook Tools (`hooks/scripts/hook-tools/`)

| Script | Event | Purpose |
|--------|-------|---------|
| `lint-hook.sh` | PostToolUse | Hook quality checks |
| `hook-audit-report.sh` | Stop | Session hook summary |

---

## Skills Reference

### writing-skills
TDD for documentation. Phases:
1. RESEARCH - Understand requirements
2. SKELETON - Frontmatter + structure
3. TEST - Validate with subagent
4. DOCUMENT - Write content
5. VERIFY - Final validation

### hook-development
6-phase comprehensive workflow:
1. REQUIREMENTS - Define need
2. DESIGN - Plan implementation
3. IMPLEMENT - Write code
4. TEST - Verify behavior
5. WIRE - Configure in settings
6. AUDIT - Security + performance

Includes:
- Language guides (bash, python, node)
- Templates for all event types
- Pattern examples (debug, error-recovery, composition)

### ecosystem-analysis
Analyzes skills, agents, MCP tools, and hooks to find:
- Integration opportunities
- Missing hooks
- Optimal configurations

### create-hook-structure
Scaffolds the `.claude/hooks/` directory with:
- Standard subdirectories
- Template files
- README documentation

---

## Wiring Hooks in settings.json

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/scripts/skill-tools/validate-skill-metadata.py"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/scripts/skill-tools/lint-skill.sh"
          }
        ]
      }
    ]
  }
}
```

---

## Development Workflow

```
1. DESIGN
   - Use skill-router to find existing patterns
   - Check ecosystem-analysis for integrations

2. CREATE
   - Invoke appropriate creator agent
   - Follow TDD (write test first)

3. VALIDATE
   - Run validation scripts
   - Invoke auditor agents

4. WIRE
   - Add hooks to settings.json
   - Test end-to-end

5. DOCUMENT
   - Update CLAUDE.md files
   - Add to ecosystem discovery
```

---

## Best Practices

### Skills
- Keep SKILL.md under 300 lines (use subdirectories for reference)
- Start description with "Use when" (CSO format)
- Include frontmatter with: name, description, agent, user-invocable
- Add CLAUDE.md for memory context

### Agents
- Define clear scope in description
- List required tools explicitly
- Reference dependent skills
- Configure lifecycle hooks for validation

### Hooks
- Use appropriate language (bash for simple, python for complex)
- Handle errors gracefully (exit codes matter)
- Log to stderr for debugging
- Keep execution fast (<100ms target)

---

## Testing

### Testing Skills

**With Subagents (Recommended):**
```typescript
// Spawn a test subagent that uses the skill
Task({
  subagent_type: "general-purpose",
  prompt: `
    Load skill: /my-new-skill
    Test case 1: [describe scenario]
    Expected: [expected behavior]

    Report: Did the skill produce correct output?
  `
})
```

**Manual Validation:**
```bash
# Validate skill metadata
.claude/hooks/scripts/skill-tools/validate-skill-metadata.py .claude/skills/my-skill/SKILL.md

# Check progressive disclosure
.claude/hooks/scripts/skill-tools/check-skill-size.sh .claude/skills/my-skill/SKILL.md

# Lint for quality
.claude/hooks/scripts/skill-tools/lint-skill.sh .claude/skills/my-skill/SKILL.md
```

### Testing Agents

**Spawn Test:**
```typescript
// Test the agent with a representative task
Task({
  subagent_type: "my-new-agent",
  prompt: "Perform [typical task]. Report success/failure."
})
```

**Manual Validation:**
```bash
# Validate agent frontmatter
.claude/hooks/scripts/agent-tools/validate-agent.sh .claude/agents/my-agent.md

# Lint for quality
.claude/hooks/scripts/agent-tools/lint-agent.sh .claude/agents/my-agent.md
```

### Testing Hooks

**Dry Run (No Side Effects):**
```bash
# Create test input
echo '{"tool_name":"Write","tool_input":{"file_path":"/test/path"}}' > /tmp/test-input.json

# Run hook with test input
cat /tmp/test-input.json | .claude/hooks/scripts/my-hook.sh

# Check exit code
echo "Exit code: $?"
```

**Integration Test:**
```bash
# Enable debug mode
export CLAUDE_HOOK_DEBUG=1

# Trigger the hook via actual tool use
# Observe stderr output for hook execution trace
```

**Hook Test Checklist:**
- [ ] Exit code 0 for success (allow)
- [ ] Exit code 2 for blocking (with JSON reason)
- [ ] Handles missing input gracefully
- [ ] Handles malformed JSON
- [ ] Completes in <100ms
- [ ] No side effects on dry run

### Testing Workflow

```
1. UNIT TEST
   - Run validation scripts directly
   - Check exit codes and output

2. INTEGRATION TEST
   - Spawn subagent with skill/agent
   - Verify expected behavior

3. END-TO-END TEST
   - Wire hooks in settings.json
   - Perform actual tool use
   - Verify hooks fire correctly

4. REGRESSION TEST
   - Run audit scripts at session end
   - Check for warnings/errors
```

### Debug Mode

Enable verbose logging for hooks:
```bash
export CLAUDE_HOOK_DEBUG=1
```

All hooks should check this and log to stderr when enabled:
```bash
[[ "$CLAUDE_HOOK_DEBUG" == "1" ]] && echo "[DEBUG] Processing: $FILE" >&2
```

---

## Related Documentation

- `skills/hook-development/SKILL.md` - Comprehensive hook guide
- `skills/writing-skills/SKILL.md` - TDD for documentation
- `skills/ecosystem-analysis/SKILL.md` - Integration analysis
