"""Dependency rule of the weekly-planner core.

The core is generic: it never names a user, a home folder, or the layout of one vault.
Everything vault-specific (paths, helper commands, section names of the note contract)
lives in the vault adapter under weekly-planner/references/adapters/, which the skill
loads only when the config says the notes live in a vault. Every other file of the
skill must be free of those markers.

The check is a predicate on file contents, not a list of names: a new vault path
written anywhere outside the adapter fails it.
"""

import re
from pathlib import Path

SKILL_DIR = Path(__file__).resolve().parent.parent / "weekly-planner"
ADAPTER_DIR = SKILL_DIR / "references" / "adapters"

# Vault layout, vault helper package, a home folder, and the section headings of the
# vault's note contract. Matching any of them outside the adapter is a violation.
FORBIDDEN = [
    (re.compile(r"\.brain/"), "vault layout path (.brain/)"),
    (re.compile(r"(?<![\w.-])areas/"), "vault layout path (areas/)"),
    (re.compile(r"vault_lint|agent_activity|learning_signal|day_cycle"), "vault helper package"),
    (re.compile(r"/Users/|/home/"), "home folder path"),
    (re.compile(r"\bGlody\b"), "user's name"),
    (
        re.compile(r"## (Focus settimana|Priorità del mese|Consuntivo|Calendario|Appunti della settimana|Progetti da guardare)"),
        "section heading of the vault note contract",
    ),
]


def core_files():
    for path in sorted(SKILL_DIR.rglob("*")):
        if path.is_file() and ADAPTER_DIR not in path.parents:
            yield path


def violations():
    found = []
    for path in core_files():
        for lineno, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
            for pattern, reason in FORBIDDEN:
                if pattern.search(line):
                    found.append(f"{path.relative_to(SKILL_DIR)}:{lineno}: {reason}: {line.strip()}")
    return found


def test_adapter_directory_exists():
    assert ADAPTER_DIR.is_dir(), "the vault adapter must live in references/adapters/"


def test_core_names_no_vault_path_user_or_home():
    found = violations()
    assert not found, "dependency rule broken outside the adapter:\n" + "\n".join(found)


def test_skill_loads_the_adapter_conditionally():
    skill = (SKILL_DIR / "SKILL.md").read_text(encoding="utf-8")
    assert "references/adapters/vault.md" in skill
    assert "notes_tool = vault_filesystem" in skill
