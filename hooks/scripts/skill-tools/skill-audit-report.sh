#!/bin/bash
# Stop hook for skill-creator - generates audit report
set -euo pipefail

echo "=== Skill Creator Audit Report ==="
echo ""

# Find recently modified skill files (last 60 minutes)
RECENT_SKILLS=$(find .claude/skills -name "SKILL.md" -mmin -60 2>/dev/null || true)

if [[ -z "$RECENT_SKILLS" ]]; then
    echo "No skill files modified in this session."
    echo ""
    echo "Existing skills:"
    find .claude/skills -name "SKILL.md" 2>/dev/null | while read -r skill; do
        NAME=$(grep -m1 "^name:" "$skill" 2>/dev/null | sed 's/^name:[[:space:]]*//' | tr -d '"' || echo "unknown")
        echo "  - $NAME"
    done
    exit 0
fi

TOTAL=0
VALID=0
WARNINGS=0

while read -r skill_file; do
    [[ -z "$skill_file" ]] && continue
    ((TOTAL++)) || true

    NAME=$(grep -m1 "^name:" "$skill_file" 2>/dev/null | sed 's/^name:[[:space:]]*//' | tr -d '"' || echo "unknown")
    DESC=$(grep -m1 "^description:" "$skill_file" 2>/dev/null || true)

    echo "Skill: $NAME"
    echo "  File: $skill_file"

    SKILL_VALID=true

    # Check name
    if [[ "$NAME" == "unknown" || -z "$NAME" ]]; then
        echo "  [ERROR] Missing name field"
        SKILL_VALID=false
    fi

    # Check description
    if [[ -z "$DESC" ]]; then
        echo "  [ERROR] Missing description field"
        SKILL_VALID=false
    elif [[ ! "$DESC" =~ Use\ when ]]; then
        echo "  [WARN] Description should start with 'Use when...'"
    fi

    # Check size
    LINE_COUNT=$(wc -l < "$skill_file" | tr -d ' ')
    if [[ $LINE_COUNT -gt 500 ]]; then
        echo "  [WARN] Large skill ($LINE_COUNT lines > 500)"
    else
        echo "  [OK] Size: $LINE_COUNT lines"
    fi

    # Check for hooks
    if grep -q "^hooks:" "$skill_file" 2>/dev/null; then
        echo "  [OK] Hooks configured"
    fi

    if $SKILL_VALID; then
        ((VALID++)) || true
        echo "  [PASS] Skill structure valid"
    else
        ((WARNINGS++)) || true
    fi

    echo ""
done <<< "$RECENT_SKILLS"

echo "=== Summary ==="
echo "Skills modified: $TOTAL"
echo "Valid: $VALID"
echo "With issues: $WARNINGS"

exit 0
