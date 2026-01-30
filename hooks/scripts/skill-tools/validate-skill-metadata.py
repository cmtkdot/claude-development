#!/usr/bin/env python3
"""Validates skill metadata before writing."""
import json
import sys
import re

try:
    input_data = json.load(sys.stdin)
except json.JSONDecodeError as e:
    print(f"Error: Invalid JSON input: {e}", file=sys.stderr)
    sys.exit(1)

file_path = input_data.get("tool_input", {}).get("file_path", "")

# Only validate SKILL.md files
if not file_path.endswith("SKILL.md"):
    sys.exit(0)

content = input_data.get("tool_input", {}).get("content", "")

errors = []

# Check for frontmatter
if not content.startswith("---"):
    errors.append("Missing YAML frontmatter (must start with ---)")

# Extract frontmatter
frontmatter_match = re.search(r'^---\n(.*?)\n---', content, re.DOTALL)
if frontmatter_match:
    frontmatter = frontmatter_match.group(1)

    # Validate name field
    name_match = re.search(r'^name:\s*(.+)$', frontmatter, re.MULTILINE)
    if name_match:
        name = name_match.group(1).strip()
        if not re.match(r'^[a-z0-9-]+$', name):
            errors.append(f"Invalid name '{name}': use lowercase letters, numbers, hyphens only")
        if len(name) > 64:
            errors.append(f"Name too long ({len(name)} chars): max 64 characters")
    else:
        errors.append("Missing required 'name' field in frontmatter")

    # Validate description field
    desc_match = re.search(r'^description:\s*(.+)$', frontmatter, re.MULTILINE)
    if desc_match:
        desc = desc_match.group(1).strip()
        if not desc.lower().startswith("use when"):
            errors.append("Description should start with 'Use when...'")
        if len(desc) > 1024:
            errors.append(f"Description too long ({len(desc)} chars): max 1024 characters")
    else:
        errors.append("Missing required 'description' field in frontmatter")

if errors:
    for error in errors:
        print(f"* {error}", file=sys.stderr)
    sys.exit(2)

print("Skill metadata valid")
sys.exit(0)
