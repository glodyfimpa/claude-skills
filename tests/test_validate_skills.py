"""Tests for scripts/validate-skills.py.

The validator is exercised as a CLI (the same way CI runs it) against throwaway
skill trees built under pytest's tmp_path, so the real repo never influences a test.
"""

import subprocess
import sys
from pathlib import Path

VALIDATOR = Path(__file__).resolve().parent.parent / "scripts" / "validate-skills.py"

VALID_FRONTMATTER = "---\nname: {name}\ndescription: Does one thing. Use it when asked for that thing.\n---\n\n# Body\n"


def make_skill(root, folder, content):
    skill_dir = root / folder
    skill_dir.mkdir(parents=True)
    (skill_dir / "SKILL.md").write_text(content, encoding="utf-8")
    return skill_dir


def run_validator(root):
    return subprocess.run(
        [sys.executable, str(VALIDATOR), str(root)],
        capture_output=True,
        text=True,
        check=False,
    )


def violation_lines(result, folder):
    marker = f"{folder}/SKILL.md"
    return [line for line in result.stdout.splitlines() if marker in line]


def test_valid_skill_passes(tmp_path):
    make_skill(tmp_path, "good-skill", VALID_FRONTMATTER.format(name="good-skill"))

    result = run_validator(tmp_path)

    assert result.returncode == 0, result.stdout + result.stderr
    assert violation_lines(result, "good-skill") == []


def test_valid_skill_with_block_scalar_description_passes(tmp_path):
    content = "---\nname: folded\ndescription: >\n  First line of the description,\n  continued on a second line.\n---\n"
    make_skill(tmp_path, "folded", content)

    result = run_validator(tmp_path)

    assert result.returncode == 0, result.stdout + result.stderr


def test_missing_frontmatter_is_reported(tmp_path):
    make_skill(tmp_path, "no-frontmatter", "# Just a title\n\nSome prose.\n")

    result = run_validator(tmp_path)

    assert result.returncode != 0
    lines = violation_lines(result, "no-frontmatter")
    assert len(lines) == 1
    assert "missing YAML frontmatter" in lines[0]


def test_unterminated_frontmatter_is_reported(tmp_path):
    make_skill(tmp_path, "unterminated", "---\nname: unterminated\ndescription: Never closed.\n")

    result = run_validator(tmp_path)

    assert result.returncode != 0
    lines = violation_lines(result, "unterminated")
    assert len(lines) == 1
    assert "not closed" in lines[0]


def test_invalid_yaml_is_reported(tmp_path):
    make_skill(tmp_path, "broken-yaml", "---\nname: broken-yaml\ndescription: [unclosed\n---\n")

    result = run_validator(tmp_path)

    assert result.returncode != 0
    lines = violation_lines(result, "broken-yaml")
    assert len(lines) == 1
    assert "invalid YAML" in lines[0]


def test_name_mismatch_is_reported(tmp_path):
    make_skill(tmp_path, "folder-name", VALID_FRONTMATTER.format(name="other-name"))

    result = run_validator(tmp_path)

    assert result.returncode != 0
    lines = violation_lines(result, "folder-name")
    assert len(lines) == 1
    assert "other-name" in lines[0]
    assert "folder-name" in lines[0]
    assert "does not match" in lines[0]


def test_missing_name_is_reported(tmp_path):
    make_skill(tmp_path, "nameless", "---\ndescription: Has a description only.\n---\n")

    result = run_validator(tmp_path)

    assert result.returncode != 0
    lines = violation_lines(result, "nameless")
    assert len(lines) == 1
    assert "name" in lines[0]
    assert "missing or empty" in lines[0]


def test_empty_description_is_reported(tmp_path):
    make_skill(tmp_path, "empty-desc", "---\nname: empty-desc\ndescription:\n---\n")

    result = run_validator(tmp_path)

    assert result.returncode != 0
    lines = violation_lines(result, "empty-desc")
    assert len(lines) == 1
    assert "description" in lines[0]
    assert "missing or empty" in lines[0]


def test_whitespace_only_description_is_reported(tmp_path):
    make_skill(tmp_path, "blank-desc", '---\nname: blank-desc\ndescription: "   "\n---\n')

    result = run_validator(tmp_path)

    assert result.returncode != 0
    assert len(violation_lines(result, "blank-desc")) == 1


def test_every_violation_is_reported_not_only_the_first(tmp_path):
    make_skill(tmp_path, "good-skill", VALID_FRONTMATTER.format(name="good-skill"))
    make_skill(tmp_path, "no-frontmatter", "# Title\n")
    make_skill(tmp_path, "both-wrong", "---\nname: wrong\ndescription: ''\n---\n")

    result = run_validator(tmp_path)

    assert result.returncode != 0
    assert violation_lines(result, "good-skill") == []
    assert len(violation_lines(result, "no-frontmatter")) == 1
    assert len(violation_lines(result, "both-wrong")) == 2


def test_folders_without_skill_md_are_ignored(tmp_path):
    make_skill(tmp_path, "good-skill", VALID_FRONTMATTER.format(name="good-skill"))
    (tmp_path / "docs").mkdir()
    (tmp_path / "docs" / "README.md").write_text("# not a skill\n", encoding="utf-8")

    result = run_validator(tmp_path)

    assert result.returncode == 0, result.stdout + result.stderr


def test_nested_skill_md_is_out_of_scope(tmp_path):
    make_skill(tmp_path, "good-skill", VALID_FRONTMATTER.format(name="good-skill"))
    make_skill(tmp_path / "good-skill" / "tests" / "fixtures", "nested", "# no frontmatter\n")

    result = run_validator(tmp_path)

    assert result.returncode == 0, result.stdout + result.stderr


def test_skill_md_that_is_a_directory_is_reported(tmp_path):
    make_skill(tmp_path, "good-skill", VALID_FRONTMATTER.format(name="good-skill"))
    (tmp_path / "dir-skill" / "SKILL.md").mkdir(parents=True)

    result = run_validator(tmp_path)

    assert result.returncode == 1, result.stdout + result.stderr
    lines = violation_lines(result, "dir-skill")
    assert len(lines) == 1
    assert "not a regular file" in lines[0]
    assert "directory" in lines[0]


def test_skill_md_that_is_a_dangling_symlink_is_reported(tmp_path):
    make_skill(tmp_path, "good-skill", VALID_FRONTMATTER.format(name="good-skill"))
    (tmp_path / "link-skill").mkdir()
    (tmp_path / "link-skill" / "SKILL.md").symlink_to(tmp_path / "does-not-exist.md")

    result = run_validator(tmp_path)

    assert result.returncode == 1, result.stdout + result.stderr
    lines = violation_lines(result, "link-skill")
    assert len(lines) == 1
    assert "not a regular file" in lines[0]
    assert "dangling symlink" in lines[0]


def test_bom_prefixed_valid_skill_passes(tmp_path):
    make_skill(tmp_path, "bom-skill", "﻿" + VALID_FRONTMATTER.format(name="bom-skill"))

    result = run_validator(tmp_path)

    assert result.returncode == 0, result.stdout + result.stderr
    assert violation_lines(result, "bom-skill") == []


def test_non_string_name_is_reported_as_not_a_string(tmp_path):
    make_skill(tmp_path, "int-name", "---\nname: 123\ndescription: Has a description.\n---\n")

    result = run_validator(tmp_path)

    assert result.returncode == 1, result.stdout + result.stderr
    lines = violation_lines(result, "int-name")
    assert len(lines) == 1
    assert "'name' is not a string" in lines[0]
    assert "int" in lines[0]
    assert "missing or empty" not in lines[0]


def test_date_description_is_reported_as_not_a_string(tmp_path):
    make_skill(tmp_path, "date-desc", "---\nname: date-desc\ndescription: 2026-11-16\n---\n")

    result = run_validator(tmp_path)

    assert result.returncode == 1, result.stdout + result.stderr
    lines = violation_lines(result, "date-desc")
    assert len(lines) == 1
    assert "'description' is not a string" in lines[0]
    assert "date" in lines[0]
    assert "missing or empty" not in lines[0]


def test_list_description_is_reported_as_not_a_string(tmp_path):
    make_skill(tmp_path, "list-desc", "---\nname: list-desc\ndescription:\n  - one\n  - two\n---\n")

    result = run_validator(tmp_path)

    assert result.returncode == 1, result.stdout + result.stderr
    lines = violation_lines(result, "list-desc")
    assert len(lines) == 1
    assert "'description' is not a string" in lines[0]
    assert "list" in lines[0]


def test_name_with_surrounding_whitespace_is_reported(tmp_path):
    make_skill(tmp_path, "s", '---\nname: " s "\ndescription: Has a description.\n---\n')

    result = run_validator(tmp_path)

    assert result.returncode == 1, result.stdout + result.stderr
    lines = violation_lines(result, "s")
    assert len(lines) == 1
    assert "whitespace" in lines[0]


def test_duplicate_name_key_is_reported(tmp_path):
    content = "---\nname: wrong\ndescription: Has a description.\nname: dup-name\n---\n"
    make_skill(tmp_path, "dup-name", content)

    result = run_validator(tmp_path)

    assert result.returncode == 1, result.stdout + result.stderr
    lines = violation_lines(result, "dup-name")
    assert len(lines) == 1
    assert "duplicate key" in lines[0]
    assert "'name'" in lines[0]


def test_duplicate_description_key_is_reported(tmp_path):
    content = "---\nname: dup-desc\ndescription: First.\ndescription: Second.\n---\n"
    make_skill(tmp_path, "dup-desc", content)

    result = run_validator(tmp_path)

    assert result.returncode == 1, result.stdout + result.stderr
    lines = violation_lines(result, "dup-desc")
    assert len(lines) == 1
    assert "duplicate key" in lines[0]
    assert "'description'" in lines[0]
