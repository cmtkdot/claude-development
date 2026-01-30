# Common Agent Patterns

> Extracted from agent-creator.md for progressive disclosure.

## Research Agent

Low-cost, parallel execution for information gathering.

```yaml
---
name: researcher
description: Use when gathering information, analyzing documentation, or exploring codebases
tools: [Read, Grep, Glob, Bash]
model: haiku
skills: [ecosystem-analysis, docs-lookup]
---
```

## Implementation Agent

Balanced speed and quality for coding tasks.

```yaml
---
name: implementer
description: Use when implementing features, fixing bugs, or refactoring code
tools: [Read, Write, Edit, Bash]
model: sonnet
skills: [writing-skills, verification-before-completion]
context: fork
---
```

## Review Agent

Focused on analysis without modification.

```yaml
---
name: reviewer
description: Use when reviewing code, checking PRs, or auditing changes
tools: [Read, Grep, Glob]
model: sonnet
skills: [code-review, security-check]
---
```

## Model Selection Rationale

| Use Case | Model | Rationale |
|----------|-------|-----------|
| Research/context | `haiku` | Low cost, parallel execution |
| Implementation | `sonnet` | Balance of speed and quality |
| Architecture decisions | `opus` | Critical reasoning required |
