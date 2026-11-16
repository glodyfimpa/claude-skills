#!/usr/bin/env python3
"""Validate the structure of every skill in the repo.

A skill is a top-level folder that contains a SKILL.md entry. The entry must be a
readable regular file (a directory or a dangling symlink is a violation), and it
must open with YAML frontmatter holding:

  - a non-empty `name` equal to the folder name
  - a non-empty `description`

Every violation is printed as `<path>: <reason>`; the exit code is 1 if there is
at least one violation, 0 otherwise.

Usage: python scripts/validate-skills.py [ROOT]   (ROOT defaults to the repo root)
Requires PyYAML.
"""

import sys
from pathlib import Path

import yaml

SKILL_FILE = "SKILL.md"
DELIMITER = "---"


def extract_frontmatter(text):
    """Return (frontmatter_text, None) or (None, reason)."""
    lines = text.lstrip("\ufeff").splitlines()
    if not lines or lines[0].rstrip() != DELIMITER:
        return None, "missing YAML frontmatter (file must start with a '---' line)"
    for index, line in enumerate(lines[1:], start=1):
        if line.rstrip() == DELIMITER:
            return "\n".join(lines[1:index]), None
    return None, "YAML frontmatter is not closed (no terminating '---' line)"


def string_field_problem(data, key):
    """Return a reason when data[key] is not a non-empty string, else None."""
    value = data.get(key)
    if value is None or (isinstance(value, str) and value.strip() == ""):
        return f"frontmatter '{key}' is missing or empty"
    if not isinstance(value, str):
        return f"frontmatter '{key}' is not a string (got {type(value).__name__})"
    return None


def skill_file_kind_problem(skill_file):
    """Return a reason when SKILL.md exists but is not a regular file, else None."""
    if skill_file.is_symlink() and not skill_file.exists():
        return "SKILL.md is not a regular file (dangling symlink)"
    if skill_file.is_dir():
        return "SKILL.md is not a regular file (directory)"
    if not skill_file.is_file():
        return "SKILL.md is not a regular file"
    return None


def validate_skill(skill_dir):
    """Return the list of violation reasons for one skill folder."""
    skill_file = skill_dir / SKILL_FILE
    problem = skill_file_kind_problem(skill_file)
    if problem:
        return [problem]
    try:
        text = skill_file.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as error:
        return [f"cannot read file: {error}"]

    frontmatter, reason = extract_frontmatter(text)
    if reason:
        return [reason]

    try:
        data = yaml.safe_load(frontmatter)
    except yaml.YAMLError as error:
        return [f"invalid YAML frontmatter: {' '.join(str(error).split())}"]

    if not isinstance(data, dict):
        return ["YAML frontmatter is not a key/value mapping"]

    reasons = []
    name_problem = string_field_problem(data, "name")
    if name_problem:
        reasons.append(name_problem)
    elif data["name"] != data["name"].strip():
        reasons.append(f"frontmatter 'name' ({data['name']!r}) has leading or trailing whitespace")
    elif data["name"] != skill_dir.name:
        reasons.append(f"frontmatter 'name' ({data['name']!r}) does not match folder name ({skill_dir.name!r})")

    description_problem = string_field_problem(data, "description")
    if description_problem:
        reasons.append(description_problem)

    return reasons


def has_skill_entry(folder):
    """True when the folder holds a SKILL.md entry of any kind (file, dir, symlink, even dangling)."""
    skill_file = folder / SKILL_FILE
    return skill_file.exists() or skill_file.is_symlink()


def find_skill_dirs(root):
    return sorted(entry for entry in root.iterdir() if entry.is_dir() and has_skill_entry(entry))


def main(argv):
    if len(argv) > 2:
        print(f"usage: {argv[0]} [ROOT]", file=sys.stderr)
        return 2
    root = Path(argv[1]) if len(argv) == 2 else Path(__file__).resolve().parent.parent
    if not root.is_dir():
        print(f"error: {root} is not a directory", file=sys.stderr)
        return 2

    skill_dirs = find_skill_dirs(root)
    violations = 0
    for skill_dir in skill_dirs:
        for reason in validate_skill(skill_dir):
            violations += 1
            print(f"{skill_dir.name}/{SKILL_FILE}: {reason}")

    print(f"{len(skill_dirs)} skill(s) checked, {violations} violation(s)")
    return 1 if violations else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
