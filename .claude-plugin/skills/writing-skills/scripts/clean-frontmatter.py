#!/usr/bin/env python3
"""
Clean SKILL.md frontmatter to only include valid fields.
Valid fields: name, description, allowed-tools, model, context, agent, hooks, user-invocable, disable-model-invocation
"""

import os
import re
import sys
from pathlib import Path

VALID_FIELDS = {
    "name",
    "description",
    "allowed-tools",
    "model",
    "context",
    "agent",
    "hooks",
    "user-invocable",
    "disable-model-invocation",
}

FIELD_ORDER = ["name", "description", "allowed-tools", "model", "context", "agent", "hooks", "user-invocable", "disable-model-invocation"]


def extract_frontmatter_and_body(content):
    """Extract frontmatter and body from file content."""
    lines = content.split('\n')

    if not lines or lines[0] != '---':
        return None, content

    fm_end = None
    for i in range(1, len(lines)):
        if lines[i] == '---':
            fm_end = i
            break

    if fm_end is None:
        return None, content

    frontmatter_lines = lines[1:fm_end]
    body_lines = lines[fm_end+1:]

    return frontmatter_lines, '\n'.join(body_lines)


def parse_frontmatter(fm_lines):
    """Parse YAML frontmatter into a dict."""
    fields = {}
    current_field = None
    current_value = []

    for line in fm_lines:
        # Check if this is a field definition
        if ':' in line and not line.startswith(' '):
            # Save previous field
            if current_field:
                value = '\n'.join(current_value).strip()
                fields[current_field] = value

            # Parse new field
            parts = line.split(':', 1)
            current_field = parts[0].strip()
            current_value = [parts[1].strip()] if len(parts) > 1 else []
        elif current_field and line.startswith(' '):
            # Continuation of current field
            current_value.append(line)

    # Save last field
    if current_field:
        value = '\n'.join(current_value).strip()
        fields[current_field] = value

    return fields


def build_frontmatter(fields):
    """Build YAML frontmatter from dict."""
    lines = ['---']

    # Add fields in preferred order
    for field in FIELD_ORDER:
        if field in fields:
            value = fields[field]
            if '\n' in value:
                # Multiline value
                lines.append(f"{field}:")
                for vline in value.split('\n'):
                    lines.append(f"  {vline}")
            else:
                lines.append(f"{field}: {value}")

    lines.append('---')
    return '\n'.join(lines)


def clean_skill_file(filepath):
    """Clean a single SKILL.md file."""
    with open(filepath, 'r') as f:
        content = f.read()

    fm_lines, body = extract_frontmatter_and_body(content)

    if fm_lines is None:
        return False  # No frontmatter found

    # Parse frontmatter
    fields = parse_frontmatter(fm_lines)

    # Check if any invalid fields exist
    has_invalid = False
    for field in fields:
        if field not in VALID_FIELDS:
            has_invalid = True
            break

    if not has_invalid:
        return False  # No changes needed

    # Filter to only valid fields
    cleaned_fields = {k: v for k, v in fields.items() if k in VALID_FIELDS}

    # Rebuild file
    new_frontmatter = build_frontmatter(cleaned_fields)
    new_content = new_frontmatter + '\n' + body

    with open(filepath, 'w') as f:
        f.write(new_content)

    return True


def main():
    skills_dir = os.environ.get('CLAUDE_PROJECT_DIR', '.')
    skills_path = Path(skills_dir) / '.claude' / 'skills'

    if not skills_path.exists():
        print(f"Skills directory not found: {skills_path}")
        sys.exit(1)

    # Find all SKILL.md files
    skill_files = sorted(skills_path.rglob('SKILL.md'))

    print(f"Cleaning {len(skill_files)} SKILL.md files...")
    print()

    cleaned = 0
    for filepath in skill_files:
        if clean_skill_file(filepath):
            print(f"  ✓ {filepath.relative_to(skills_path.parent)}")
            cleaned += 1

    print()
    print(f"Summary:")
    print(f"  Total files: {len(skill_files)}")
    print(f"  Files cleaned: {cleaned}")
    print()

    if cleaned > 0:
        print("Done!")
    else:
        print("All files already have valid frontmatter.")


if __name__ == '__main__':
    main()
