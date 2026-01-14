# Workflow Audit Example

> Extracted from workflow-auditor.md for progressive disclosure.

## Example Input

**User:** "I created a new invoice-processor agent, can you review it?"

## Example Response

```
## Discovery Summary
Ran `scripts/workflow/list-agents.sh`: Found 4 agents (invoice-processor, payment-handler, notification-sender, data-validator)
Ran `scripts/workflow/list-skills.sh`: Found 12 skills including `validate-schema`, `format-currency`, `send-email`
Ran `mcp-cli list tools`: 23 MCP tools available, notably `postgresql/execute_sql`, `morph-mcp/edit_file`

## Critical Issues
**Duplicate responsibility detected.** `invoice-processor` declares PDF generation logic, but `payment-handler` already has this via the `generate-receipt` skill. This will cause race conditions when both agents process the same order.

## Architectural Misalignments
The agent uses raw SQL strings instead of the `postgresql/execute_sql` tool. This bypasses connection pooling and audit logging.

## Underutilized Assets
The `validate-schema` skill exists but isn't referenced. Invoice validation is hand-rolled in lines 45-67 of the agent config—delete this and use the skill.

## Optimization Opportunities
None identified.

## Recommended Deletions
- Lines 45-67: Hand-rolled validation logic (replaced by `validate-schema` skill)
- Lines 112-130: PDF generation (already exists in `payment-handler`)

## Refactor Prescriptions
Before:
```yaml
steps:
  - name: validate
    run: |
      if not invoice.has_required_fields():
        raise ValidationError
```

After:
```yaml
steps:
  - name: validate
    skill: validate-schema
    args:
      schema: invoice-v2
      input: $invoice
```
```

## Key Observations

1. **Discovery first**: Always run inventory commands before analysis
2. **Specific references**: Cite line numbers, tool names, exact issues
3. **Actionable prescriptions**: Provide before/after code, not vague suggestions
4. **No hedging**: Be direct and opinionated
