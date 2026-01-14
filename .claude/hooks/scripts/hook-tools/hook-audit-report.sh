#!/bin/bash
# Generates audit report when hook-creator stops

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
HOOKS_DIR="$PROJECT_DIR/.claude/hooks/utils"
SETTINGS="$PROJECT_DIR/.claude/settings.json"

echo "=== Hook Development Audit Summary ==="
echo ""

# Count hooks by event type
echo "Hooks by Event Type:"
for event in preToolUse postToolUse sessionStart sessionEnd stop subagentStart subagentStop userPromptSubmit; do
    if [ -d "$HOOKS_DIR/$event" ]; then
        count=$(find "$HOOKS_DIR/$event" -name "*.sh" -o -name "*.py" -o -name "*.cjs" 2>/dev/null | wc -l | tr -d ' ')
        echo "  $event: $count scripts"
    fi
done

echo ""
echo "Hooks in settings.json:"
if [ -f "$SETTINGS" ]; then
    for event in PreToolUse PostToolUse SessionStart SessionEnd Stop SubagentStart SubagentStop UserPromptSubmit; do
        count=$(jq -r ".hooks.$event // [] | length" "$SETTINGS" 2>/dev/null || echo "0")
        if [ "$count" -gt 0 ]; then
            echo "  $event: $count configured"
        fi
    done
else
    echo "  (settings.json not found)"
fi

echo ""
echo "Recent Hook Activity:"
# Show recently modified hook scripts
find "$HOOKS_DIR" -type f \( -name "*.sh" -o -name "*.py" -o -name "*.cjs" \) -mtime -1 2>/dev/null | while read -r hook; do
    relpath="${hook#$PROJECT_DIR/}"
    echo "  * $relpath (modified today)"
done

echo ""
echo "Syntax Validation:"
# Quick syntax check on all hooks
ERROR_COUNT=0
for hook in $(find "$HOOKS_DIR" -name "*.sh" 2>/dev/null); do
    if ! bash -n "$hook" 2>/dev/null; then
        echo "  ❌ $hook"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi
done
for hook in $(find "$HOOKS_DIR" -name "*.py" 2>/dev/null); do
    if ! python -m py_compile "$hook" 2>/dev/null; then
        echo "  ❌ $hook"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi
done
for hook in $(find "$HOOKS_DIR" -name "*.cjs" 2>/dev/null); do
    if ! node --check "$hook" 2>/dev/null; then
        echo "  ❌ $hook"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi
done

if [ "$ERROR_COUNT" -eq 0 ]; then
    echo "  ✓ All hooks pass syntax check"
else
    echo "  $ERROR_COUNT hook(s) have syntax errors"
fi

exit 0
