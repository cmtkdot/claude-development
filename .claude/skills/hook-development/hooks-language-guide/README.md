# Hook Language Selection Guide

This repo’s hooks run as small, local programs that receive JSON on stdin and must respond quickly and reliably. Choose the simplest language that satisfies the hook’s requirements.

## Quick Decision Tree

1. Does this hook need to block/allow fast in `PreToolUse`?
   - Yes -> Bash (default)
2. Does it need complex parsing, multi-stage logic, or rich data transforms?
   - Yes -> Python
3. Does it need async I/O (HTTP calls, parallel reads), or should it match a JS/TS-heavy workflow?
   - Yes -> Node.js
4. Does it need LLM reasoning (Opus + thinking) via `claude` CLI?
   - Yes -> Python or Node.js (prefer PostToolUse), never on the hot path

## Language Matrix (practical)

| Dimension | Bash | Python | Node.js |
|---|---|---|---|
| Best at | Fast gating, shell pipelines | Complex logic, structured data | Async I/O, JS ecosystem |
| JSON | `jq` required | Native | Native |
| Startup cost | Lowest | Medium | Medium/High |
| Error handling | Verbose | Strong | Strong |
| Avoid when | Logic gets complex | Must be <1s always | Purely synchronous gating |

## Hook-Event Defaults

- `PreToolUse`: default to Bash; keep < 1s; avoid network; prefer allow-on-error.
- `PostToolUse`: Python or Node.js when parsing `tool_response` or generating structured reports.
- `UserPromptSubmit`: Bash for simple flags; Python/Node.js if transforming/deriving context requires parsing.
- `Stop` / `SessionEnd`: Bash unless you need richer analysis.
- `PreCompact`: Python if you need structured analysis.

## Non-Negotiables (all languages)

- Read input from stdin JSON; do not assume env vars for `session_id` or `hook_event_name`.
- Always emit valid JSON output on stdout.
- Use exit code semantics from templates:
  - `PreToolUse`: `exit 2` to block.
- Prefer fast-path exits for non-matching cases.
- Use user-facing `systemMessage` templates from `.claude/hooks/hooks-user-output-templates`.

## Hard Rules for “LLM-in-the-loop” Hooks (Opus + thinking)

- Only use for high-value analysis (security review, risky diffs, policy decisions).
- Put it in `PostToolUse` or a non-blocking phase; never make `PreToolUse` depend on a network call.
- Enforce strict timeouts; on failure, degrade gracefully (allow + warning).
- Cache aggressively if possible (by `session_id` or content hash).

## Next: Language Guides

- `.claude/hooks/hooks-language-guide/bash.md`
- `.claude/hooks/hooks-language-guide/python.md`
- `.claude/hooks/hooks-language-guide/node.md`

