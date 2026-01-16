# Hook Output Templates (Visible Status Messages)

Hooks should provide user-visible, non-token-costing feedback via `systemMessage`. ANSI colors are stripped, so use Unicode only.

## Quick Start

1. Copy the template for your language:
   - `.claude/hooks/hooks-user-output-templates/bash.md`
   - `.claude/hooks/hooks-user-output-templates/python.md`
   - `.claude/hooks/hooks-user-output-templates/node.md`
2. Replace only the “validation logic” section.
3. Use the provided output helper for every response (`output_message()` / `outputMessage()`).
4. For `PreToolUse` blocks: `exit 2` / `process.exit(2)` and set `permissionDecision: "deny"`.

## Required Output (all hooks)

- Always emit JSON on stdout.
- Always include `hookSpecificOutput.hookEventName` (use the value from stdin JSON: `hook_event_name`).
- Use `systemMessage` for user-only status text.
- Prefer “allow on internal error” unless the hook is explicitly a blocker.

## Common Patterns

- Allow:
  - `permissionDecision: "allow"` and exit `0`
- Deny (PreToolUse only):
  - `permissionDecision: "deny"` and exit `2`
- Warn-but-allow:
  - `permissionDecision: "allow"` + `systemMessage` with `⚠️`
- Multi-check summary:
  - Build a multi-line string and attach it to `systemMessage` (or `additionalContext` for PostToolUse)

## Do / Don’t

- Do: fast-path exit for non-matching tools/events.
- Do: keep `PreToolUse` hooks fast (< 1s); avoid network calls.
- Do: parse stdin JSON defensively (payload shapes vary by event/tool).
- Don’t: print raw text without the JSON wrapper.
- Don’t: rely on env vars for `hook_event_name` or `session_id` (they’re in stdin JSON).
- Don’t: build JSON via string concatenation; use `jq` (Bash) or native JSON (Python/Node).

