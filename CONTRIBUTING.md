# Contributing to plugin-dev

Thank you for your interest in contributing to the Claude Code Plugin Development Toolkit.

## Development Workflow

This project follows TDD for Documentation methodology:

1. **RED** - Write failing pressure scenarios first
2. **GREEN** - Implement minimal solution that passes
3. **REFACTOR** - Improve while keeping tests green

## Creating Components

### Skills
Use `spawn skill-creator` or follow `skills/writing-skills/SKILL.md`

Requirements:
- Keep SKILL.md under 500 lines
- Description starts with "Use when..."
- Include triggering phrases
- Use progressive disclosure for large content

### Agents
Use `spawn agent-creator` or follow agent structure in `agents/`

Requirements:
- YAML frontmatter with name, description, tools, model
- Pure XML structure in body (no markdown headings)
- Clear role definition with constraints
- Use `${CLAUDE_PLUGIN_ROOT}` for portability

### Hooks
Use `spawn hook-creator` or follow `skills/hook-development/SKILL.md`

Requirements:
- Exit 0 = allow, Exit 2 = block
- Target <100ms execution
- Use `${CLAUDE_PLUGIN_ROOT}` in paths
- Handle stdin JSON properly

## Pull Request Guidelines

1. Run all auditors before submitting:
   - `spawn skill-auditor` for skills
   - `spawn subagent-auditor` for agents
   - `spawn slash-command-auditor` for commands

2. Ensure hooks pass validation:
   - No hardcoded paths
   - Proper exit codes
   - Syntax validation passes

3. Update documentation if adding new components

## Code of Conduct

Be respectful, constructive, and focused on improving the toolkit.

## Questions?

Open an issue or reach out to the maintainers.
