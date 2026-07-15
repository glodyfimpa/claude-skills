"""TDD for the show-neighbors engine (session-retrospective rite).

The mostra-vicini is the fulcrum of the rewritten retro: given a spark (a lesson
or tool-idea that just emerged), it searches the brain for the already-existing
similar fragments and puts them in front of Glody, so a lesson is fused/updated
instead of duplicated. Lexical (token-overlap) ranking: deterministic, testable,
zero-dependency — no embeddings.
"""
import textwrap

import neighbors


# --- tokenize ---------------------------------------------------------------

def test_tokenize_lowercases_and_drops_short_tokens():
    toks = neighbors.tokenize("Verify Before React on FS")
    # lowercased, ≥3 chars kept, short filler ("on") dropped
    assert "verify" in toks
    assert "before" in toks
    assert "react" in toks
    assert "on" not in toks


def test_tokenize_drops_stopwords():
    # Italian + English stopwords are noise for overlap ranking.
    toks = neighbors.tokenize("il gate del design con the rule")
    assert "gate" in toks
    assert "design" in toks
    assert "rule" in toks
    assert "del" not in toks
    assert "the" not in toks


def test_tokenize_returns_a_set_no_duplicates():
    toks = neighbors.tokenize("gate gate gate design")
    assert toks == {"gate", "design"}


# --- score ------------------------------------------------------------------

def test_score_counts_shared_significant_tokens():
    spark = neighbors.tokenize("design review gate on specs")
    cand = neighbors.tokenize("the design review harness for specs")
    # shared significant tokens: design, review, specs -> 3
    assert neighbors.score(spark, cand) == 3


def test_score_zero_when_no_overlap():
    spark = neighbors.tokenize("pricing airbnb calendar")
    cand = neighbors.tokenize("java spring clean code")
    assert neighbors.score(spark, cand) == 0


# --- find_neighbors ---------------------------------------------------------

def _src(path, title, text):
    return neighbors.Source(path=path, kind="principle", title=title, text=text)


def test_find_neighbors_ranks_by_overlap_desc():
    sources = [
        _src("a.md", "design review gate specs", "design review gate on specs"),
        _src("b.md", "pricing", "airbnb pricing calendar break-even"),
        _src("c.md", "review harness", "design review harness distinct mandates"),
    ]
    hits = neighbors.find_neighbors("design review gate for a new spec", sources,
                                    top_n=5, min_overlap=2)
    # a.md (design/review/gate/spec) ranks above c.md (design/review) above b.md (0)
    assert hits[0].source.path == "a.md"
    assert hits[1].source.path == "c.md"
    # b.md is below the min_overlap threshold and excluded entirely
    assert all(h.source.path != "b.md" for h in hits)


def test_find_neighbors_respects_min_overlap_threshold():
    sources = [_src("a.md", "gate", "design gate")]
    # only one shared token ("design") -> below min_overlap=2 -> no neighbors
    hits = neighbors.find_neighbors("design something", sources, top_n=5, min_overlap=2)
    assert hits == []


def test_find_neighbors_caps_at_top_n():
    sources = [
        _src(f"{i}.md", "design review", "design review gate spec")
        for i in range(10)
    ]
    hits = neighbors.find_neighbors("design review gate spec", sources,
                                    top_n=3, min_overlap=2)
    assert len(hits) == 3


def test_find_neighbors_empty_sources_returns_empty():
    assert neighbors.find_neighbors("anything at all here", [], top_n=5, min_overlap=2) == []


# --- collect_sources (perimeter: principles + memory index + area CLAUDE.md + skills) ---

def test_collect_sources_reads_principles_and_memory_and_areas(tmp_path):
    (tmp_path / "principles").mkdir()
    (tmp_path / "principles" / "collaboration.md").write_text(
        "# Collaboration\n- decidi veloce spedisci itera\n", encoding="utf-8")
    (tmp_path / "memory").mkdir()
    (tmp_path / "memory" / "MEMORY.md").write_text(
        "- [Verify-before-react](feedback_verify.md) — guarda il dato\n", encoding="utf-8")
    (tmp_path / "areas" / "affitti-brevi").mkdir(parents=True)
    (tmp_path / "areas" / "affitti-brevi" / "CLAUDE.md").write_text(
        "# Affitti\n- messaggi ospiti da fonte ufficiale\n", encoding="utf-8")

    sources = neighbors.collect_sources(vault_root=tmp_path, skills_root=None)
    paths = {s.path for s in sources}
    kinds = {s.kind for s in sources}

    # every perimeter root contributes at least one source
    assert any("collaboration.md" in p for p in paths)
    assert any("MEMORY.md" in p for p in paths)
    assert any("affitti-brevi/CLAUDE.md" in p for p in paths)
    assert {"principle", "memory", "area-rule"} <= kinds


def test_collect_sources_skips_ephemeral_worktrees_and_vendored_dirs(tmp_path):
    # Real vault has .claude/worktrees/ (ephemeral checkouts) and node_modules
    # nested under areas/. rglob("CLAUDE.md") would surface duplicate/noise copies
    # from inside them. The collector must skip those subtrees.
    (tmp_path / "areas" / "real").mkdir(parents=True)
    (tmp_path / "areas" / "real" / "CLAUDE.md").write_text(
        "# Real area\n- una regola vera\n", encoding="utf-8")
    wt = tmp_path / "areas" / "real" / ".claude" / "worktrees" / "wt1"
    wt.mkdir(parents=True)
    (wt / "CLAUDE.md").write_text("# copy in worktree\n- rumore\n", encoding="utf-8")
    nm = tmp_path / "areas" / "real" / "node_modules" / "pkg"
    nm.mkdir(parents=True)
    (nm / "CLAUDE.md").write_text("# vendored\n- rumore\n", encoding="utf-8")

    sources = neighbors.collect_sources(vault_root=tmp_path, skills_root=None)
    area_paths = [s.path for s in sources if s.kind == "area-rule"]
    assert any("areas/real/CLAUDE.md" in p for p in area_paths)
    assert all(".claude/worktrees" not in p for p in area_paths)
    assert all("node_modules" not in p for p in area_paths)


def test_collect_sources_reads_installed_skill_descriptions(tmp_path):
    skills = tmp_path / "skills"
    (skills / "quick-capture").mkdir(parents=True)
    (skills / "quick-capture" / "SKILL.md").write_text(
        textwrap.dedent("""\
            ---
            name: quick-capture
            description: cattura veloce di una nota in inbox
            ---
            # Quick Capture
        """), encoding="utf-8")

    sources = neighbors.collect_sources(vault_root=None, skills_root=skills)
    skill_sources = [s for s in sources if s.kind == "skill"]
    assert len(skill_sources) == 1
    assert skill_sources[0].title == "quick-capture"
    # the description is what makes a skill findable as "already covered"
    assert "cattura" in skill_sources[0].text
