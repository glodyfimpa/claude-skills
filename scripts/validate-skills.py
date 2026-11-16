#!/usr/bin/env python3
"""Validate the structure of every skill in the repo.

A skill is a top-level folder that contains a SKILL.md. Each SKILL.md must open
with YAML frontmatter holding:

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
    lines = text.lstrip("﻿").splitlines()
    if not lines or lines[0].rstrip() != DELIMITER:
        return None, "missing YAML frontmatter (file must start with a '---' line)"
    for index, line in enumerate(lines[1:], start=1):
        if line.rstrip() == DELIMITER:
            return "\n".join(lines[1:index]), None
    return None, "YAML frontmatter is not closed (no terminating '---' line)"


def is_non_empty_string(value):
    return isinstance(value, str) and value.strip() != ""


def validate_skill(skill_dir):
    """Return the list of violation reasons for one skill folder."""
    try:
        text = (skill_dir / SKILL_FILE).read_text(encoding="utf-8")
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
    name = data.get("name")
    if not is_non_empty_string(name):
        reasons.append("frontmatter 'name' is missing or empty")
    elif name.strip() != skill_dir.name:
        reasons.append(f"frontmatter 'name' ({name.strip()!r}) does not match folder name ({skill_dir.name!r})")

    if not is_non_empty_string(data.get("description")):
        reasons.append("frontmatter 'description' is missing or empty")

    return reasons


def find_skill_dirs(root):
    return sorted(
        entry for entry in root.iterdir() if entry.is_dir() and (entry / SKILL_FILE).is_file()
    )


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
