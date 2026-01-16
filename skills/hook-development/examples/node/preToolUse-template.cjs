#!/usr/bin/env node
/**
 * PreToolUse Hook Template (Node.js)
 *
 * Use Node.js for:
 * - Async I/O (HTTP calls, parallel file reads)
 * - JS/TS ecosystem integration
 * - Complex JSON transforms
 *
 * Performance budget: < 100ms for PreToolUse
 */

function outputMessage(
  icon,
  message,
  decision = "allow",
  reason = null,
  hookEvent = "PreToolUse"
) {
  const output = {
    systemMessage: `${icon} ${message}`,
    hookSpecificOutput: {
      hookEventName: hookEvent,
      permissionDecision: decision,
    },
  };

  if (reason) {
    output.hookSpecificOutput.permissionDecisionReason = reason;
  }

  console.log(JSON.stringify(output));
}

async function processHook() {
  let input = "";

  for await (const chunk of process.stdin) {
    input += chunk;
  }

  try {
    const data = JSON.parse(input);
    const hookEvent = data.hook_event_name || "PreToolUse";
    const toolName = data.tool_name || "";
    const toolInput = data.tool_input || {};

    // Fast-path exit for non-matching tools
    if (toolName !== "Bash") {
      process.exit(0);
    }

    const command = toolInput.command || "";

    // Example: Block dangerous patterns
    const dangerousPatterns = ["rm -rf /", "DROP TABLE", "xp_cmdshell"];
    for (const pattern of dangerousPatterns) {
      if (command.includes(pattern)) {
        outputMessage(
          "🚫",
          `Blocked: ${pattern}`,
          "deny",
          `Dangerous pattern: ${pattern}`,
          hookEvent
        );
        process.exit(2);
      }
    }

    // Success
    outputMessage("✅", "Validated", "allow", null, hookEvent);
    process.exit(0);
  } catch (error) {
    // Graceful degradation: allow on error
    outputMessage("⚠️", `Hook error: ${error.message}`, "allow");
    process.exit(0);
  }
}

processHook();
