"""show-neighbors engine for the session-retrospective rite.

Given a spark (a lesson or tool-idea that just emerged in a session), find the
already-existing similar fragments in the brain and rank them, so a lesson gets
fused/updated instead of duplicated and a tool-idea is checked against what's
already built. Lexical token-overlap ranking: deterministic, testable, no
embeddings (an embedding engine would be non-deterministic, heavy to install,
and impossible to reproduce at cold-read — against the audit's whole point).

Perimeter (decided with Glody, Fronte 2): principles/*.md (where a LESSON lives),
memory/MEMORY.md (the always-loaded index), areas/**/CLAUDE.md (area rules), and
installed skill descriptions (~/.claude/skills/*/SKILL.md — for "already covered
by a tool"). Ranking by shared-token count keeps irrelevant area rules out on a
global spark for free: few shared tokens -> below threshold -> excluded.
"""
from dataclasses import dataclass, field
from pathlib import Path
import re

# Stopwords: high-frequency Italian + English words that carry no topical signal,
# so counting them as "shared" would inflate every score equally. Kept small and
# explicit (no external nltk dependency).
_STOPWORDS = {
    # Italian
    "che", "con", "del", "della", "dei", "delle", "per", "una", "uno", "gli",
    "come", "non", "sul", "sui", "nel", "nei", "alla", "allo",
    "questo", "questa", "sono", "essere", "viene", "solo", "anche", "piu",
    # English
    "the", "and", "for", "with", "this", "that", "from", "are", "was", "not",
    "you", "your", "its", "into", "when", "where", "which", "have", "has",
}

_TOKEN_RE = re.compile(r"[a-zàèéìòù0-9]+")


def tokenize(text: str) -> set[str]:
    """Return the set of significant tokens in `text`.

    Lowercased, ≥3 chars, stopwords dropped, de-duplicated (a set). Short tokens
    and stopwords are noise for overlap scoring.
    """
    return {
        t for t in _TOKEN_RE.findall(text.lower())
        if len(t) >= 3 and t not in _STOPWORDS
    }


def score(spark_tokens: set[str], candidate_tokens: set[str]) -> int:
    """Number of significant tokens shared between spark and candidate."""
    return len(spark_tokens & candidate_tokens)


@dataclass
class Source:
    """A searchable brain fragment (one principle, memory line, area rule, skill)."""
    path: str
    kind: str          # principle | memory | area-rule | skill
    title: str
    text: str
    tokens: set[str] = field(default_factory=set)

    def __post_init__(self):
        if not self.tokens:
            self.tokens = tokenize(f"{self.title} {self.text}")


@dataclass
class Neighbor:
    """A source that matched the spark, with its overlap score."""
    source: Source
    score: int


def find_neighbors(spark: str, sources: list[Source], top_n: int = 5,
                   min_overlap: int = 2) -> list[Neighbor]:
    """Rank sources by token-overlap with the spark; return the top matches.

    Only sources sharing ≥ min_overlap significant tokens qualify (barra alta:
    few strong neighbors, not many weak ones). Ties break on path for a stable,
    reproducible order.
    """
    spark_tokens = tokenize(spark)
    scored = [
        Neighbor(source=s, score=score(spark_tokens, s.tokens))
        for s in sources
    ]
    qualified = [n for n in scored if n.score >= min_overlap]
    qualified.sort(key=lambda n: (-n.score, n.source.path))
    return qualified[:top_n]


# --- collecting the perimeter -----------------------------------------------

_FRONTMATTER_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)

# Subtrees to skip when walking areas/: ephemeral git worktrees (checkouts that
# duplicate every CLAUDE.md and vanish) and vendored/build dirs. Without this the
# collector surfaces the same rule many times as noisy neighbors — a real bug the
# vault canary exposed (the fake-vault stubs could not).
_SKIP_SUBTREES = {".claude", "node_modules", ".venv", ".next", "dist", "build",
                  ".git", ".pytest_cache"}


def _under_skipped_subtree(rel_parts) -> bool:
    return any(part in _SKIP_SUBTREES for part in rel_parts)


def _read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError):
        return ""


def _skill_description(skill_md: str) -> str:
    """Extract the `description:` field from a SKILL.md frontmatter (best-effort).

    A skill is findable as "already covered" by its description, not its body, so
    that is what we index. Handles both inline and YAML block (`>`/`|`) scalars.
    """
    m = _FRONTMATTER_RE.match(skill_md)
    front = m.group(1) if m else skill_md
    lines = front.splitlines()
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith("description:"):
            rest = stripped[len("description:"):].strip()
            if rest and rest not in (">", "|", ">-", "|-"):
                return rest
            # block scalar: gather the indented continuation lines
            block = []
            for cont in lines[i + 1:]:
                if cont.strip() and not cont.startswith((" ", "\t")):
                    break
                block.append(cont.strip())
            return " ".join(b for b in block if b)
    return ""


def collect_sources(vault_root=None, skills_root=None) -> list[Source]:
    """Gather the searchable perimeter into Source objects.

    vault_root -> principles/*.md, memory/MEMORY.md, areas/**/CLAUDE.md.
    skills_root -> */SKILL.md descriptions. Either may be None (skipped).
    """
    sources: list[Source] = []

    if vault_root is not None:
        vault_root = Path(vault_root)

        principles = vault_root / "principles"
        if principles.is_dir():
            for p in sorted(principles.glob("*.md")):
                sources.append(Source(path=str(p), kind="principle",
                                      title=p.stem, text=_read(p)))

        memory_index = vault_root / "memory" / "MEMORY.md"
        if memory_index.is_file():
            sources.append(Source(path=str(memory_index), kind="memory",
                                  title="MEMORY", text=_read(memory_index)))

        areas = vault_root / "areas"
        if areas.is_dir():
            for claude_md in sorted(areas.rglob("CLAUDE.md")):
                rel = claude_md.relative_to(vault_root)
                if _under_skipped_subtree(rel.parts):
                    continue
                sources.append(Source(path=str(claude_md), kind="area-rule",
                                      title=str(rel), text=_read(claude_md)))

    if skills_root is not None:
        skills_root = Path(skills_root)
        if skills_root.is_dir():
            for skill_md in sorted(skills_root.glob("*/SKILL.md")):
                desc = _skill_description(_read(skill_md))
                sources.append(Source(path=str(skill_md), kind="skill",
                                      title=skill_md.parent.name, text=desc))

    return sources
