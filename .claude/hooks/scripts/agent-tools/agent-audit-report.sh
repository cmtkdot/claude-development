#!/bin/bash
# Generates audit report for agent creation sessions
# Stop hook - provides summary before agent completes

set -uo pipefail

echo "=== Agent Creator Audit Report ==="
echo ""

# Find recently modified agent files (last 60 minutes)
RECENT_AGENTS=$(find .claude/agents -name "*.md" -mmin -60 2>/dev/null || true)

if [[ -z "$RECENT_AGENTS" ]]; then
    echo "No agent files modified in this session."
    exit 0
fi

TOTAL=0
VALID=0
WARNINGS=0

while read -r agent_file; do
    [[ -z "$agent_file" ]] && continue
    ((TOTAL++)) || true

    # Extract frontmatter only
    FRONTMATTER=$(awk '/^---$/{n++; next} n==1{print} n==2{exit}' "$agent_file")

    NAME=$(echo "$FRONTMATTER" | grep -m1 -E "^name:" | sed 's/^name:[[:space:]]*//; s/["'"'"']//g' | tr -d ' ' || true)
    DESC=$(echo "$FRONTMATTER" | grep -m1 -E "^description:" || true)
    SKILLS=$(echo "$FRONTMATTER" | grep -m1 -E "^skills:" || true)
    HOOKS=$(echo "$FRONTMATTER" | grep -m1 -E "^hooks:" || true)

    echo "Agent: ${NAME:-$(basename "$agent_file" .md)}"
    echo "  File: $agent_file"

    # Validation checks
    AGENT_VALID=true

    if [[ -z "$NAME" ]]; then
        echo "  [ERROR] Missing name field"
        AGENT_VALID=false
    fi

    if [[ -z "$DESC" ]]; then
        echo "  [ERROR] Missing description field"
        AGENT_VALID=false
    fi

    if [[ -n "$SKILLS" ]]; then
        echo "  [OK] Skills configured"
    else
        echo "  [INFO] No skills configured"
    fi

    if [[ -n "$HOOKS" ]]; then
        echo "  [OK] Hooks configured"
    else
        echo "  [INFO] No hooks configured"
    fi

    if $AGENT_VALID; then
        ((VALID++)) || true
        echo "  [PASS] Agent structure valid"
    else
        ((WARNINGS++)) || true
        echo "  [WARN] Agent has issues"
    fi

    echo ""
done <<< "$RECENT_AGENTS"

echo "=== Summary ==="
echo "Total agents modified: $TOTAL"
echo "Valid: $VALID"
echo "With warnings: $WARNINGS"

if [[ $WARNINGS -gt 0 ]]; then
    echo ""
    echo "Review warnings before deploying agents."
fi

exit 0
