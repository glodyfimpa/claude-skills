"""Dependency rule of the weekly-planner core.

The core is generic: it never names a user, a home folder, or the layout of one vault.
Everything vault-specific (paths, helper commands, section names of the note contract)
lives in the vault adapter files weekly-planner/references/adapter-*.md (flat, because the
plugin sync copies references/ without subfolders), which the skill
loads only when the config says the notes live in a vault. Every other file of the
skill must be free of those markers.

The check is a predicate on file contents, not a list of names: a new vault path
written anywhere outside the adapter fails it.
"""

import re
from pathlib import Path

SKILL_DIR = Path(__file__).resolve().parent.parent / "weekly-planner"
REFERENCES_DIR = SKILL_DIR / "references"
ADAPTER_GLOB = "adapter-*.md"

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


# Only the skill's own text and code: caches, .DS_Store and other local files are not the core.
SCANNED_SUFFIXES = {".md", ".py", ".sh", ".yaml", ".yml", ".json"}


def is_adapter(path):
    return path.parent == REFERENCES_DIR and path.match(ADAPTER_GLOB)


def core_files():
    for path in sorted(SKILL_DIR.rglob("*")):
        relative = path.relative_to(SKILL_DIR)
        if any(part.startswith(".") for part in relative.parts):
            continue
        if path.is_file() and path.suffix in SCANNED_SUFFIXES and not is_adapter(path):
            yield path


def violations():
    found = []
    for path in core_files():
        for lineno, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
            for pattern, reason in FORBIDDEN:
                if pattern.search(line):
                    found.append(f"{path.relative_to(SKILL_DIR)}:{lineno}: {reason}: {line.strip()}")
    return found


def test_adapter_files_exist_flat_in_references():
    assert sorted(p.name for p in REFERENCES_DIR.glob(ADAPTER_GLOB)), "no references/adapter-*.md"
    subfolders = [p.name for p in REFERENCES_DIR.iterdir() if p.is_dir()]
    assert not subfolders, f"the plugin sync skips subfolders of references/: {subfolders}"


def test_core_names_no_vault_path_user_or_home():
    found = violations()
    assert not found, "dependency rule broken outside the adapter:\n" + "\n".join(found)


def test_skill_loads_the_adapter_conditionally():
    skill = (SKILL_DIR / "SKILL.md").read_text(encoding="utf-8")
    assert "references/adapter-vault.md" in skill
    assert "notes_tool = vault_filesystem" in skill
