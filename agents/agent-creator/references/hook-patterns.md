# Hook Integration Patterns

> Extracted from agent-creator.md for progressive disclosure.

## Validation Hook (runs once per session)

```yaml
hooks:
  PreToolUse:
    - matcher: "Bash|Edit|Write"
      hooks:
        - type: command
          command: "./scripts/validate.sh"
          once: true
```

## Continuous Verification

```yaml
hooks:
  PostToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "./scripts/lint.sh"
```

## Completion Checklist

```yaml
hooks:
  Stop:
    - hooks:
        - type: prompt
          prompt: |
            Before stopping, verify:
            - [ ] All tests pass
            - [ ] Documentation updated
            - [ ] No TODOs left
```

## Skill Integration Notes

**Explicit skill dependencies**: Subagents don't inherit skills automatically. Declare them:

```yaml
skills: [verification-before-completion, pal-tools, hook-development]
```

**Match skills to purpose**:
- Code agents: `code-review`, `testing-patterns`
- Documentation agents: `writing-skills`, `docs-generation`
- Deployment agents: `deployment-checklist`, `rollback-procedures`
