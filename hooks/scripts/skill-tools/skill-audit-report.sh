#!/bin/bash
# Generates audit report when skill-master stops

echo "=== Skill Audit Summary ==="
echo "Skills found in project:"
find .claude/skills -name "SKILL.md" 2>/dev/null | while read -r skill; do
    NAME=$(grep -m1 "^name:" "$skill" | cut -d: -f2 | tr -d ' ')
    DESC_LEN=$(grep -m1 "^description:" "$skill" | wc -c)
    echo "  * $NAME (desc: ${DESC_LEN} chars)"
done

echo ""
echo "Hooks configured:"
grep -r "^hooks:" .claude/skills 2>/dev/null | wc -l | xargs echo "  Total skills with hooks:"

exit 0
