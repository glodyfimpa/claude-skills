# CLAUDE.md — claude-skills

## Repo Structure
- Each subdirectory with a `SKILL.md` is a skill
- `install.sh` — interactive installer (Claude Code or Desktop)
- `sync.sh` — syncs all skills to Claude Code (`~/.claude/skills/`) and Cowork (auto-discovered path). Post-commit hook runs `sync.sh --quiet` automatically
- `tests/test_sync.sh` — bash test suite (19 tests). Run: `bash tests/test_sync.sh`

## Bash Script Conventions
- `set -euo pipefail` in all scripts
- Use `BASH_SOURCE[0]` not `$0` for path resolution (scripts may be sourced by tests)
- Empty arrays under `set -u`: use `"${arr[@]+"${arr[@]}"}"` pattern
- rsync: use `--checksum` for small files to avoid same-second same-size skip
- Scripts support env var overrides (SYNC_SOURCE_DIR, SYNC_CC_DEST, etc.) for test isolation
- Funzioni interattive che restituiscono valori: SEMPRE redirect display (echo, read prompt, colori) su `>&2`. Lasciare stdout puro per il dato di ritorno se chiamate via `$()`. Alternativa bash 3.2-compatible (no nameref): variabile globale popolata dalla funzione (es. `SELECTED_SKILLS` in install.sh). Mai `echo "$result"` dopo aver stampato UI in stdout — il caller riceve UI mescolato al valore e `read -ra` rompe

## Testing
- Tests use `mktemp -d` fixtures, cleaned in teardown
- Source the script under test to access functions; guard main with `if [[ "${BASH_SOURCE[0]}" == "${0}" ]]`
- Every assert needs `|| return 1` to propagate failures inside `if`-wrapped test runners

## Edit workflow — source of truth
Consolidated 2026-07-15 from memory (Fronte 1 audit).
- **Always edit skills in THIS repo (`areas/tooling/skills/claude-skills/<skill>/`), never in `~/.claude/skills/`.** The latter is a sync *destination*: the post-commit hook runs `sync.sh` and rsyncs over it, so a direct edit there is overwritten on the next commit. Flow: edit here → feature branch → commit → push → PR (update README in the same PR). If the skill is untracked, add it to the repo before editing.
- **life-os plugin is also a destination, not a source.** `planning-review-system` + `time-energy-manager` live downstream in `~/.claude/skills/` AND `areas/tooling/plugins/life-os/skills/`. Editing `life-os/skills/<skill>/SKILL.md` directly is the same mistake — the next `life-os/scripts/sync-skills.sh ../claude-skills` overwrites it. Correct fix: propagate the edit up to claude-skills (the source), commit (post-commit hook auto-syncs to `~/.claude/skills` + Cowork), then `sync-skills.sh` pulls it into life-os.

## README sync (this repo is a public showcase)
- The README must reflect exactly what is on `origin/main` — no local-only, feature-branch, or untracked skills. Listing an unpublished skill sends visitors to a 404; listing a published one late makes it invisible.
- **Before adding a skill row, verify it is on main:** `git ls-tree -r origin/main --name-only | grep <skill>/SKILL.md`. Do not list from `ls` of the working tree.
- **When merging a skill PR, update four README sections in the same PR (or immediate follow-up on main):** intro count + capability list, skills table row, structure tree entry, final summary counts.

## Plugin README style (glodyfimpa/* family)
- READMEs for Glody's Claude Code plugins follow the life-os README shape exactly (structure, tone, install syntax are load-bearing). Reference: `github.com/glodyfimpa/life-os/blob/main/README.md`.
- Order: figlet banner (fenced) → one-line tagline → 1-2 pitch paragraphs (no marketing/badges) → `## Install` (canonical three-variant syntax, never invent commands like `/install-plugin`) → `## Update` → `## Prerequisites` (mode table if multi-level) → `## Commands` table → `## How it works` (prose) → `## Structure` (file tree, per-line comments, counts) → `## Development` → `## License`.
- Every plugin repo MUST have `.claude-plugin/marketplace.json` next to `plugin.json` (single-plugin marketplace pattern), created at the same time as `plugin.json` — without it `claude plugin marketplace add` fails with "Marketplace file not found".
- Writing-style guide applies inside the README (no emojis, em-dashes, "Not X but Y", hyperbole). Cross-check against an existing correct README (bnb-investment-toolkit was first to get it right).

## Skill design principles
Validated 2026-05-15 against Anthropic docs, "Building Effective Agents", Simon Willison, IFScale (arXiv 2507.11538) — the popular guides dress real principles in invented numbers.
1. **Description is semantic, not imperative.** A skill triggers on density and specificity of triggers ("what it does + when + real phrases"), not on imperative tone ("USE ALWAYS"). Anthropic: "what it does AND when to use it" + explicit triggers/contexts (max 1024 chars).
2. **The context constraint is conflict, not count.** Degradation from multiple instructions is real (IFScale: gradual, ~150-250, model-dependent) but driven by how many instructions activate *and contradict each other in the same turn*, not by total line count. Skill body <500 lines is a real Anthropic rule; "CLAUDE.md <200 lines" is invented. The personal 3-AND cancer-prevention filter is already more sophisticated than a line count — keep it.
3. **Orchestration is a cost to justify, not a goal.** Anthropic: "find the simplest solution possible… this might mean not building agentic systems at all". Default for "should I orchestrate/parallelize my setup?" is no; build fan-out only when a case proves it's the exception, not from FOMO.
- Apply principle 1 *lazily*: when you touch a skill for other reasons, check its description answers "what + when + real phrases". Never batch-audit all skills (that is meta-tooling, violates less-is-more).
