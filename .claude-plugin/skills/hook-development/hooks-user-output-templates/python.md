### Hook Output Templates

Use these templates for consistent, visually appealing hook output. ANSI codes are stripped, so use Unicode only.

#### **Python Template**

```python
#!/usr/bin/env python3
import json
import os
import sys
from datetime import datetime
from pathlib import Path

# Unicode symbols
class Icons:
    SUCCESS = "✅"
    FAILURE = "❌"
    WARNING = "⚠️"
    INFO = "ℹ️"
    PROGRESS = "⏳"
    BLOCKED = "🚫"

# Box drawing characters
class Box:
    TL = "╔"
    TR = "╗"
    BL = "╚"
    BR = "╝"
    H = "═"
    V = "║"
    VR = "╠"
    VL = "╣"

def output_message(icon, message, hook_event, decision="allow", reason=None, additional_context=None):
    output = {
        "systemMessage": f"{icon} {message}" if icon else message,
        "hookSpecificOutput": {
            "hookEventName": hook_event,
            "permissionDecision": decision,
        },
    }
    if reason:
        output["hookSpecificOutput"]["permissionDecisionReason"] = reason
    if additional_context:
        output["hookSpecificOutput"]["additionalContext"] = additional_context
    print(json.dumps(output))

def create_box(title, lines):
    width = max(len(title), *(len(line) for line in lines)) + 4

    def pad(text):
        return text + " " * (width - len(text) - 2)

    box_lines = [
        f"{Box.TL}{Box.H * width}{Box.TR}",
        f"{Box.V} {pad(title)} {Box.V}",
        f"{Box.VR}{Box.H * width}{Box.VL}",
        *[f"{Box.V} {pad(line)} {Box.V}" for line in lines],
        f"{Box.BL}{Box.H * width}{Box.BR}",
    ]
    return "\n".join(box_lines)

def progress_bar(percent, width=20):
    filled = int(percent * width / 100)
    empty = width - filled
    return f"[{'█' * filled}{'░' * empty}] {percent}%"

def multi_line_status(title, items):
    lines = [title, "─" * len(title)]
    for item in items:
        lines.append(f"{item['icon']} {item['label']}: {item['value']}")
    return "\n".join(lines)

def main() -> int:
    try:
        input_data = json.load(sys.stdin)
    except Exception:
        return 0

    hook_event = input_data.get("hook_event_name", "PreToolUse")
    tool_name = input_data.get("tool_name", "N/A")
    tool_input = input_data.get("tool_input", {})

    project_dir = Path(os.environ.get("CLAUDE_PROJECT_DIR", "."))
    log_file = project_dir / ".claude/hooks/logs" / f"{Path(__file__).stem}.log"
    log_file.parent.mkdir(parents=True, exist_ok=True)
    with log_file.open("a", encoding="utf-8") as f:
        f.write(f"[{datetime.now().isoformat()}] Hook started: {hook_event} for {tool_name}\n")

    # Your validation logic here
    if tool_name == "Bash":
        command = tool_input.get("command", "")
        if "rm -rf" in command:
            output_message(
                Icons.BLOCKED,
                "Blocked dangerous command",
                hook_event,
                decision="deny",
                reason="rm -rf not allowed",
            )
            return 2

    output_message(Icons.SUCCESS, "Validation passed", hook_event, decision="allow")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
```

#### **Python Box Example**

```python
box = create_box("Hook Status", [
    f"{Icons.SUCCESS} Validation: Passed",
    f"{Icons.INFO} Tool: {tool_name}",
    f"{Icons.PROGRESS} Duration: 0.5s",
])
output_message("", box, hook_event, decision="allow")
```

#### **Python Progress Bar Example**

```python
bar = progress_bar(75)
output_message(Icons.PROGRESS, f"Processing: {bar}", hook_event, decision="allow")
```

#### **Python Multi-line Example**

```python
status = multi_line_status("Validation Report", [
    {"icon": Icons.SUCCESS, "label": "Syntax", "value": "Valid"},
    {"icon": Icons.SUCCESS, "label": "Security", "value": "Passed"},
    {"icon": Icons.WARNING, "label": "Performance", "value": "Needs review"},
])
output_message("", status, hook_event, decision="allow")
```
