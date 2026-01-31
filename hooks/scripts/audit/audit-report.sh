#!/usr/bin/env bash
# Stop hook for workflow-auditor - Audit completion report
set -euo pipefail

# Check dependencies
command -v jq >/dev/null 2>&1 || { echo "Warning: jq not installed, skipping audit report" >&2; exit 0; }

# Read stdin safely
INPUT=""
if ! INPUT=$(cat 2>/dev/null); then
  echo "Warning: Failed to read stdin" >&2
  exit 0
fi

# Validate JSON
if ! echo "$INPUT" | jq -e . >/dev/null 2>&1; then
  echo "Warning: Invalid JSON input" >&2
  exit 0
fi

STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // "false"')

# Prevent infinite loop
if [[ "$STOP_HOOK_ACTIVE" == "true" ]] || [[ "$STOP_HOOK_ACTIVE" == "1" ]]; then
  exit 0
fi

echo "=== Workflow Audit Report ==="
echo ""

# Check for common issues
ISSUES=0

# Empty skills arrays - handle multiple YAML formats:
# skills: []
# skills:[]
# skills: [ ]
# skills:\n  - (empty list represented differently)
check_empty_skills() {
  local file="$1"
  if [[ -f "$file" ]]; then
    # Check for various empty array patterns
    if grep -qE '^skills:\s*\[\s*\]' "$file" 2>/dev/null; then
      return 0  # Found empty
    fi
  fi
  return 1  # Not empty or not found
}

EMPTY_SKILLS=0
if [[ -d ".claude/agents" ]]; then
  for agent_file in .claude/agents/*.md; do
    if [[ -f "$agent_file" ]] && check_empty_skills "$agent_file"; then
      EMPTY_SKILLS=$((EMPTY_SKILLS + 1))
    fi
  done
fi

if [[ "$EMPTY_SKILLS" -gt 0 ]]; then
  echo "! Agents with empty skills: $EMPTY_SKILLS"
  ISSUES=$((ISSUES + 1))
fi

# Model inherit usage - check for the pattern
INHERIT_MODELS=0
if [[ -d ".claude/agents" ]]; then
  for agent_file in .claude/agents/*.md; do
    if [[ -f "$agent_file" ]] && grep -qE '^model:\s*inherit' "$agent_file" 2>/dev/null; then
      INHERIT_MODELS=$((INHERIT_MODELS + 1))
    fi
  done
fi

if [[ "$INHERIT_MODELS" -gt 0 ]]; then
  echo "! Agents using model:inherit: $INHERIT_MODELS (may be intentional)"
  # Don't count as issue - inherit can be intentional
fi

# Large skills
if [[ -d ".claude/skills" ]]; then
  for skill in .claude/skills/*/SKILL.md; do
    if [[ -f "$skill" ]]; then
      LINES=$(wc -l < "$skill" 2>/dev/null || echo "0")
      # Trim whitespace
      LINES="${LINES##* }"
      LINES="${LINES:-0}"
      if [[ "$LINES" -gt 500 ]]; then
        echo "! Large skill (${LINES} lines): $skill"
        ISSUES=$((ISSUES + 1))
      fi
    fi
  done
fi

# Check for hooks without scripts
if [[ -f ".claude/settings.json" ]]; then
  # Extract commands from hooks and check if scripts exist
  while IFS= read -r cmd; do
    # Extract path from command (handle quotes and variables)
    script_path=$(echo "$cmd" | grep -oE '\$CLAUDE_PROJECT_DIR[^"]*|\.claude/hooks/[^"]*' | head -1 || true)
    if [[ -n "$script_path" ]]; then
      # Expand variable if present
      expanded_path="${script_path/\$CLAUDE_PROJECT_DIR/.}"
      if [[ ! -f "$expanded_path" ]] && [[ "$expanded_path" != *'$'* ]]; then
        echo "! Missing hook script: $expanded_path"
        ISSUES=$((ISSUES + 1))
      fi
    fi
  done < <(jq -r '.. | .command? // empty' .claude/settings.json 2>/dev/null || true)
fi

if [[ "$ISSUES" -eq 0 ]]; then
  echo "No issues found"
fi

echo ""
echo "Audit complete"
exit 0
