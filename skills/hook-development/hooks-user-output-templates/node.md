### Hook Output Templates

Use these templates for consistent, visually appealing hook output. ANSI codes are stripped, so use Unicode only.

#### **Node.js Template**

```javascript
#!/usr/bin/env node

// Unicode symbols
const ICONS = {
  SUCCESS: "✅",
  FAILURE: "❌",
  WARNING: "⚠️",
  INFO: "ℹ️",
  PROGRESS: "⏳",
  BLOCKED: "🚫",
};

// Box drawing characters
const BOX = {
  TL: "╔",
  TR: "╗",
  BL: "╚",
  BR: "╝",
  H: "═",
  V: "║",
  VR: "╠",
  VL: "╣",
};

async function readStdin() {
  let input = "";
  for await (const chunk of process.stdin) input += chunk;
  return input;
}

function outputMessage(icon, message, hookEvent, decision = "allow", reason = null, additionalContext = null) {
  const output = {
    systemMessage: icon ? `${icon} ${message}` : message,
    hookSpecificOutput: {
      hookEventName: hookEvent,
      permissionDecision: decision,
    },
  };

  if (reason) output.hookSpecificOutput.permissionDecisionReason = reason;
  if (additionalContext) output.hookSpecificOutput.additionalContext = additionalContext;

  process.stdout.write(JSON.stringify(output));
}

async function main() {
  let data;
  try {
    const input = await readStdin();
    data = JSON.parse(input);
  } catch {
    process.exit(0);
  }

  const hookEvent = data.hook_event_name || "PreToolUse";
  const toolName = data.tool_name || "N/A";

  // Your validation logic here
  if (toolName === "Bash") {
    const command = data.tool_input?.command || "";

    if (command.includes("rm -rf")) {
      outputMessage(
        ICONS.BLOCKED,
        "Blocked dangerous command",
        hookEvent,
        "deny",
        "rm -rf not allowed",
      );
      process.exit(2);
    }
  }

  // Success case
  outputMessage(ICONS.SUCCESS, "Validation passed", hookEvent, "allow");
  process.exit(0);
}

main();
```

#### **Formatted Box Template (Node.js)**

```javascript
function createBox(title, lines) {
  const width = Math.max(title.length, ...lines.map((l) => l.length)) + 4;
  const pad = (text) => text + " ".repeat(width - text.length - 2);

  return [
    `${BOX.TL}${BOX.H.repeat(width)}${BOX.TR}`,
    `${BOX.V} ${pad(title)} ${BOX.V}`,
    `${BOX.VR}${BOX.H.repeat(width)}${BOX.VL}`,
    ...lines.map((line) => `${BOX.V} ${pad(line)} ${BOX.V}`),
    `${BOX.BL}${BOX.H.repeat(width)}${BOX.BR}`,
  ].join("\n");
}

// Usage:
const box = createBox("Hook Status", [
  "✅ Validation: Passed",
  "ℹ️  Tool: Bash",
  "⏳ Duration: 0.5s",
]);

outputMessage("", box, hookEvent, "allow");
```

#### **Table Template (Node.js)**

```javascript
function createTable(headers, rows) {
  const colWidths = headers.map((h, i) =>
    Math.max(h.length, ...rows.map((r) => String(r[i]).length)),
  );

  const headerRow = headers.map((h, i) => h.padEnd(colWidths[i])).join(" │ ");
  const separator = colWidths.map((w) => "─".repeat(w)).join("─┼─");
  const dataRows = rows.map((row) =>
    row.map((cell, i) => String(cell).padEnd(colWidths[i])).join(" │ "),
  );

  return [headerRow, separator, ...dataRows].join("\n");
}

// Usage:
const table = createTable(
  ["Check", "Status"],
  [
    ["Syntax", "✅ OK"],
    ["Security", "⚠️ Review"],
  ],
);

outputMessage("", table, hookEvent, "allow");
```
