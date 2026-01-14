# Python Hook Guide

## Use Python When

- You need multi-stage validation (branchy logic, scoring, policy).
- You need structured transforms on `tool_input` / `tool_response`.
- You need robust parsing (regex, AST, diff inspection) with good error handling.
- You want a “smart but reliable” hook with graceful degradation.

## Avoid Python When

- The hook is a hot-path `PreToolUse` gate that must be consistently < 1s.
- The logic is just a couple of string checks (use Bash).

## Skeleton (recommended)

Use the output helper style from `.claude/hooks/hooks-user-output-templates/python.md`.

```python
#!/usr/bin/env python3
import json
import sys

def emit(message: str, hook_event: str, decision: str = "allow", reason: str | None = None):
    out = {
        "systemMessage": message,
        "hookSpecificOutput": {
            "hookEventName": hook_event,
            "permissionDecision": decision,
        },
    }
    if reason:
        out["hookSpecificOutput"]["permissionDecisionReason"] = reason
    print(json.dumps(out))

def main() -> int:
    try:
        data = json.load(sys.stdin)
    except Exception:
        return 0

    hook_event = data.get("hook_event_name", "PreToolUse")
    tool_name = data.get("tool_name", "")

    # Fast-path exits
    if tool_name != "Bash":
        return 0

    # ... validation logic ...
    emit("✅ Validation passed", hook_event, "allow")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
```

## Example (high-value): PostToolUse “Opus + thinking” Risk Review

Use when a hook should provide expert guidance, not block execution. This is a good fit for `PostToolUse` after `Edit`/`Write` or after generating a diff.

Design goals:
- Never blocks on LLM failure (degrades gracefully).
- Enforces strict timeout.
- Avoids spamming (simple hash-based cache).

```python
#!/usr/bin/env python3
import hashlib
import json
import os
import subprocess
import sys
from pathlib import Path

ICONS = {"OK": "✅", "WARN": "⚠️", "INFO": "ℹ️"}

def emit(system_message: str, hook_event: str, decision: str = "allow", reason: str | None = None, additional: str | None = None) -> None:
    out: dict = {
        "systemMessage": system_message,
        "hookSpecificOutput": {
            "hookEventName": hook_event,
            "permissionDecision": decision,
        },
    }
    if reason:
        out["hookSpecificOutput"]["permissionDecisionReason"] = reason
    if additional:
        out["hookSpecificOutput"]["additionalContext"] = additional
    print(json.dumps(out))

def sha256(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()

def load_stdin() -> dict | None:
    try:
        return json.load(sys.stdin)
    except Exception:
        return None

def read_path_str(data: dict) -> str:
    # Tool payload shapes vary; keep this defensive.
    tool_input = data.get("tool_input") or {}
    return tool_input.get("file_path") or tool_input.get("path") or ""

def main() -> int:
    data = load_stdin()
    if not data:
        return 0

    hook_event = data.get("hook_event_name", "PostToolUse")
    tool_name = data.get("tool_name", "")

    # Only run for file-writing tools in PostToolUse.
    if hook_event != "PostToolUse" or tool_name not in {"Edit", "Write"}:
        return 0

    file_path = read_path_str(data)
    if not file_path:
        return 0

    # Only review “risky” areas (example: hooks, rules, auth, CI).
    risky_markers = ["/.claude/hooks/", "/.claude/rules/", "/supabase/", "/.github/"]
    if not any(m in file_path for m in risky_markers):
        return 0

    project_dir = Path(os.environ.get("CLAUDE_PROJECT_DIR", "."))
    cache_dir = project_dir / ".claude/hooks/cache"
    cache_dir.mkdir(parents=True, exist_ok=True)

    # Use tool_response as the primary signal when available.
    tool_response = data.get("tool_response") or ""
    cache_key = sha256(f"{file_path}\n{tool_response}")[:16]
    cache_file = cache_dir / f"opus-risk-review-{cache_key}.json"

    if cache_file.exists():
        return 0

    prompt = f\"\"\"Review the following hook/code change summary for risk.

File: {file_path}

Change summary (may be partial):
{tool_response}

Return JSON ONLY with keys:
- risk: low|medium|high|critical
- issues: array of short strings
- suggestions: array of short strings
\"\"\"

    # NOTE: Adjust flags to match your installed claude CLI.
    # The key properties are: model selection + thinking + JSON output + strict timeout.
    try:
        result = subprocess.run(
            ["claude", "--model", "opus", "--thinking", "--output-format", "json"],
            input=prompt,
            text=True,
            capture_output=True,
            timeout=12,
        )
    except Exception:
        emit(f\"{ICONS['WARN']} Risk review skipped (LLM unavailable)\", hook_event, "allow")
        return 0

    if result.returncode != 0 or not result.stdout.strip():
        emit(f\"{ICONS['WARN']} Risk review skipped (LLM error)\", hook_event, "allow")
        return 0

    try:
        review = json.loads(result.stdout)
    except Exception:
        emit(f\"{ICONS['WARN']} Risk review skipped (invalid JSON)\", hook_event, "allow")
        return 0

    risk = str(review.get("risk", "medium")).lower()
    issues = review.get("issues") or []
    suggestions = review.get("suggestions") or []

    # Persist cache to avoid repeated LLM calls for same input.
    cache_file.write_text(json.dumps(review, indent=2) + \"\\n\", encoding=\"utf-8\")

    headline = f\"{ICONS['INFO']} Opus risk review: {risk.upper()} ({Path(file_path).name})\"
    details = \"\\n\".join(
        [\"Issues:\"] + [f\"- {i}\" for i in issues[:5]] + [\"\", \"Suggestions:\"] + [f\"- {s}\" for s in suggestions[:5]]
    ).strip()

    emit(headline, hook_event, "allow", additional=details)
    return 0

if __name__ == \"__main__\":
    raise SystemExit(main())
```

## Do / Don’t

- Do: treat stdin payloads as untrusted and schema-varying; parse defensively.
- Do: default to allow on hook errors unless the hook is explicitly a blocker.
- Do: enforce strict timeouts for subprocesses and external calls.
- Don’t: add heavy third-party deps for hooks unless the repo already uses them.
- Don’t: put LLM calls on the critical path of `PreToolUse`.

