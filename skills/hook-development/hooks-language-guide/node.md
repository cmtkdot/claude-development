# Node.js Hook Guide

## Use Node.js When

- You need async operations (HTTP calls, parallel file reads).
- The hook is tightly coupled to JS/TS workflows (linting, package metadata, codegen).
- You want native JSON handling without `jq`.

## Avoid Node.js When

- The hook is a simple `PreToolUse` gate with deterministic string checks (use Bash).
- The hook would require adding npm dependencies just for the hook.

## Skeleton (recommended)

Use the output helper style from `.claude/hooks/hooks-user-output-templates/node.md`, but keep it minimal and correct.

```js
#!/usr/bin/env node

let input = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  try {
    const data = JSON.parse(input);
    const hookEvent = data.hook_event_name || "PreToolUse";
    emit("✅ Hook ran", hookEvent, "allow");
  } catch {
    process.exit(0);
  }
});

function emit(message, hookEvent, decision = "allow", reason = null, additional = null) {
  const out = {
    systemMessage: message,
    hookSpecificOutput: {
      hookEventName: hookEvent,
      permissionDecision: decision,
    },
  };
  if (reason) out.hookSpecificOutput.permissionDecisionReason = reason;
  if (additional) out.hookSpecificOutput.additionalContext = additional;
  process.stdout.write(JSON.stringify(out));
}
```

## Example: PreToolUse “Outbound curl allowlist” (async-free)

Use when you want stronger string parsing than Bash, without network calls.

```js
#!/usr/bin/env node

let input = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", main);

const ALLOWED_HOSTS = new Set(["localhost", "127.0.0.1", "api.internal.example"]);

function emit(icon, msg, hookEvent, decision = "allow", reason = null) {
  const out = {
    systemMessage: `${icon} ${msg}`,
    hookSpecificOutput: { hookEventName: hookEvent, permissionDecision: decision },
  };
  if (reason) out.hookSpecificOutput.permissionDecisionReason = reason;
  process.stdout.write(JSON.stringify(out));
}

function main() {
  let data;
  try {
    data = JSON.parse(input);
  } catch {
    process.exit(0);
  }

  const hookEvent = data.hook_event_name || "PreToolUse";
  const toolName = data.tool_name || "";

  if (hookEvent !== "PreToolUse" || toolName !== "Bash") process.exit(0);

  const command = data.tool_input?.command || "";
  if (!command.includes("curl ")) {
    emit("ℹ️", "Not a curl command", hookEvent, "allow");
    process.exit(0);
  }

  const urls = command.split(/\s+/).filter((t) => /^https?:\/\//i.test(t));
  for (const u of urls) {
    let host = "";
    try {
      host = new URL(u).hostname;
    } catch {
      continue;
    }
    if (!ALLOWED_HOSTS.has(host)) {
      emit("🚫", `Blocked curl to non-allowlisted host: ${host}`, hookEvent, "deny", "Host is not allowlisted");
      process.exit(2);
    }
  }

  emit("✅", "curl allowlist validated", hookEvent, "allow");
  process.exit(0);
}
```

## Do / Don’t

- Do: keep hooks dependency-free; use Node’s standard library.
- Do: enforce timeouts for any async I/O.
- Do: read `hook_event_name` from stdin JSON (not env).
- Don’t: rely on long-running network calls in `PreToolUse`.
- Don’t: install npm packages just for hook code unless unavoidable.

