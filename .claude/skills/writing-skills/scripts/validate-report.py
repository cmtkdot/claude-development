#!/usr/bin/env python3
"""
Generate a validation report of SKILL.md frontmatter compliance.
Shows all 43 skills with their frontmatter fields.
"""

import os
import re
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


def extract_frontmatter(content):
    """Extract frontmatter from file content."""
    lines = content.split('\n')

    if not lines or lines[0] != '---':
        return None

    fm_end = None
    for i in range(1, len(lines)):
        if lines[i] == '---':
            fm_end = i
            break

    if fm_end is None:
        return None

    return lines[1:fm_end]


def parse_frontmatter(fm_lines):
    """Parse YAML frontmatter into a dict."""
    fields = {}
    current_field = None

    for line in fm_lines:
        if ':' in line and not line.startswith(' '):
            parts = line.split(':', 1)
            current_field = parts[0].strip()
            fields[current_field] = True

    return fields


def main():
    skills_dir = Path(os.environ.get('CLAUDE_PROJECT_DIR', '.')) / '.claude' / 'skills'

    if not skills_dir.exists():
        print(f"Skills directory not found: {skills_dir}")
        return

    # Find all SKILL.md files
    skill_files = sorted(skills_dir.rglob('SKILL.md'))

    print("=" * 80)
    print("SKILL.md FRONTMATTER VALIDATION REPORT")
    print("=" * 80)
    print()

    all_valid = True
    invalid_skills = []

    for filepath in skill_files:
        with open(filepath, 'r') as f:
            content = f.read()

        fm_lines = extract_frontmatter(content)
        if not fm_lines:
            print(f"❌ {filepath.relative_to(skills_dir.parent)}: NO FRONTMATTER")
            all_valid = False
            invalid_skills.append(str(filepath.relative_to(skills_dir.parent)))
            continue

        fields = parse_frontmatter(fm_lines)

        # Check for invalid fields
        invalid_fields = [f for f in fields if f not in VALID_FIELDS]

        if invalid_fields:
            print(f"❌ {filepath.relative_to(skills_dir.parent)}")
            print(f"   Invalid fields: {', '.join(invalid_fields)}")
            all_valid = False
            invalid_skills.append(str(filepath.relative_to(skills_dir.parent)))
        else:
            # Show valid fields
            field_list = ', '.join(sorted(fields.keys()))
            print(f"✓ {filepath.relative_to(skills_dir.parent)}")
            print(f"  Fields: {field_list}")

    print()
    print("=" * 80)
    print(f"Total skills: {len(skill_files)}")
    print(f"Valid: {len(skill_files) - len(invalid_skills)}")
    print(f"Invalid: {len(invalid_skills)}")
    print()

    if all_valid:
        print("✓ ALL SKILLS HAVE VALID FRONTMATTER")
    else:
        print("❌ SOME SKILLS HAVE INVALID FRONTMATTER:")
        for skill in invalid_skills:
            print(f"  - {skill}")

    print("=" * 80)


if __name__ == '__main__':
    main()
