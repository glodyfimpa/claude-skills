# weekly-planner Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `weekly-planner` skill (4-phase facade: Collect / Weigh & Prioritize / Report+gate / Apply) that plans Glody's week, stopping at a human gate before touching the calendar.

**Architecture:** Skill lives in `claude-skills` (source of truth), synced into `life-os` plugin via `sync-skills.sh`. Strangler order: extract the tiny identical core to `_shared-refs/` first, migrate the 2 existing skills to cite it, then write weekly-planner reusing them, then command + routine. No new Python — reuses `life_os.weekly_review.append_weekly_review_sections`.

**Tech Stack:** Markdown SKILL.md prompts, bash (`sync-skills.sh`), existing Python helpers (`scripts/life_os/`, py3.11, pyyaml only).

## Global Constraints

- Skills are the source of truth in `claude-skills`; `life-os/skills/*` are generated copies. Never edit the life-os copies directly.
- Work fascia (referenced by the skill's Phase 2 text): ONLY 10-12 and 16-18, two separate islands. Never schedule work events outside these.
- Weekly file convention in vault: `weekly/YYYY-MM-DD-weekly.md` (Monday date), NOT ISO `YYYY-Www`.
- Extract ONLY byte-identical text to `_shared-refs/`. Analogous-but-divergent text stays per-skill (astrai l'identico, non l'analogo).
- Config/notes/language field parsing stays per-skill (it diverges); only the config-file *lookup* and the Language paragraph are byte-identical and extracted. Source-resolution diverges by one word and stays per-skill.
- Two repos, two PRs: claude-skills `feat/weekly-planner` and life-os `feat/weekly-planner`.
- Commit messages end with `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.

---

## Task 1: Extract the identical core to `_shared-refs/`

**Files:**
- Create: `claude-skills/_shared-refs/config-lookup.md`
- Create: `claude-skills/_shared-refs/language.md`

**Interfaces:**
- Produces: two reference files that skills cite. Content is the byte-identical core lifted from the two existing skills.

**Re-scope note (2026-07-10):** source-resolution was dropped from extraction — it differs by one word between the skills ("the save-actions" vs "the four save-actions"), so it is NOT byte-identical and stays per-skill. Only config-lookup and language are extracted.

- [ ] **Step 1: Create `config-lookup.md`** with exactly this content (the 5 identical lines, verified in both skills):

```markdown
**BEFORE ANYTHING ELSE:** Look for the config file in this order:
1. `.claude/life-os.local.md` (project-level)
2. `~/.claude/life-os.local.md` (global, portable across projects)

Use the first one found.
```

- [ ] **Step 2: Create `language.md`** with exactly this content (identical `## Language` paragraph):

```markdown
Respond in the language specified by the `language` field in the config. If no config exists yet (during mini-setup), detect language from the user's message. Format dates according to the configured language's conventions.
```

- [ ] **Step 3: Confirm source-resolution is NOT extracted** — it diverges by one word between skills; it stays per-skill. (No file created for it.)

- [ ] **Step 4: Commit**

```bash
cd claude-skills
git add _shared-refs/
git commit -m "feat: extract identical config-lookup + language core to _shared-refs

Only the byte-identical fragments (config-file lookup, Language paragraph)
are extracted. Source-resolution stays per-skill (differs by one word:
'the four save-actions' in time-energy vs 'the save-actions' in
planning-review). Field parsing and the rest of Config Guard stay per-skill
too. astrai l'identico, non l'analogo.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: Migrate the 2 existing skills to cite `_shared-refs/`

**Files:**
- Modify: `claude-skills/planning-review-system/SKILL.md` (config lookup block, Language paragraph)
- Modify: `claude-skills/time-energy-manager/SKILL.md` (config lookup block, Language paragraph)

Note: source-resolution is NOT touched (stays inline per-skill).

**Interfaces:**
- Consumes: the two files from Task 1 (config-lookup, language).
- Produces: two migrated skills whose divergent field-parsing text is preserved, whose identical core is now a citation.

- [ ] **Step 1: In `planning-review-system/SKILL.md`, replace the 5 identical config-lookup lines** (the `**BEFORE ANYTHING ELSE:** ... Use the first one found.` block) with:

```markdown
**Config lookup:** open and follow `_shared-refs/config-lookup.md` (or `../_shared-refs/config-lookup.md` when running from the synced plugin copy).
```
Leave the `**If a config file exists**` parsing block below it UNCHANGED (it diverges per skill).

- [ ] **Step 2: In `planning-review-system/SKILL.md`, replace the `## Language` paragraph body** with:

```markdown
See `_shared-refs/language.md` (or `../_shared-refs/language.md` in the synced copy).
```

- [ ] **Step 3: Repeat Steps 1-2 for `time-energy-manager/SKILL.md`** at its own line locations. Same two citations (config-lookup + language). Leave time-energy's divergent parsing block (with `calendar_tool`, `schedule settings`) AND its source-resolution paragraph UNCHANGED.

- [ ] **Step 4: Guard — confirm no identical core text remains inline** (should now only appear in `_shared-refs/`):

```bash
cd claude-skills
echo "config-lookup literal still inline? (expect only _shared-refs hit)"
grep -rln "life-os.local.md.*global, portable" planning-review-system/SKILL.md time-energy-manager/SKILL.md _shared-refs/
```
Expected: the literal is gone from the two SKILL.md, present in `_shared-refs/config-lookup.md`. (The citation lines themselves are fine.)

- [ ] **Step 5: Run SBM Python tests — they must stay green** (they cover the helpers, not the prose; green here just confirms the markdown edits broke nothing importable):

```bash
# NOTE: system python3 is 3.9 — the helpers use `X | None` (needs 3.11+). Use a 3.11 venv:
cd /Users/figlody_mac/Documents/brain/projects/second-brain-migration
python3.11 -m venv /tmp/sbm-venv && /tmp/sbm-venv/bin/pip install -q pyyaml pytest
/tmp/sbm-venv/bin/python -m pytest tests/skills/ -q
```
Expected: all pass (66 tests as of 2026-07-10). If you see `TypeError: unsupported operand type(s) for |`, you're on py3.9 — use the 3.11 venv.

- [ ] **Step 6: Commit**

```bash
cd claude-skills
git add planning-review-system/SKILL.md time-energy-manager/SKILL.md
git commit -m "refactor: cite _shared-refs core in the two existing life-os skills

Config-lookup and Language now cite the shared refs; source-resolution and
the divergent field-parsing blocks stay per-skill.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: Write `weekly-planner/SKILL.md`

**Files:**
- Create: `claude-skills/weekly-planner/SKILL.md`

**Interfaces:**
- Consumes: `_shared-refs/*` (Task 1); `life_os.weekly_review.append_weekly_review_sections` (existing, unchanged); the calendar-export pattern from `time-energy-manager` Step 4.5.
- Produces: the skill invoked by the command (Task 5) and routine (Task 6).

- [ ] **Step 1: Write the SKILL.md** with frontmatter (name `weekly-planner`, description with triggers "pianifichiamo la settimana", "/weekly-planner", "pianificazione settimanale") and the 4-phase body. Body requirements, each written explicitly:
  - **Config lookup / Language:** cite `_shared-refs/config-lookup.md` and `_shared-refs/language.md`. Read `task_tool`, `notes_tool`, `email_tool`, `calendar_tool` from config.
  - **Phase 1 Collect:** read tasks/projects/quarterly via `task_tool`; scan Gmail last 7d via `email_tool`; read this week's calendar via `calendar_tool`; scan Claude sessions last 2 weeks.
  - **Phase 2 Weigh & Prioritize:** inline the 5-attribute weighing rules from `memory/feedback_weigh_every_calendar_event.md` (natura / tempo-Glody / tipo-carico / peso / dove), the two-fascia rule (10-12, 16-18 only), no two cognitive back-to-back, order by hard deadline then Golden Rule, ask when in doubt.
  - **Phase 3 Report + GATE:** present readable summary (hard deadlines, Golden Rule, ordered priorities, Lun-Ven grid with one weighing line per event, actionable emails, conflicts). Then STOP. Wait for explicit OK. Do NOT touch calendar before.
  - **Phase 4 Apply (post-OK):** calendar export (reuse time-energy Step 4.5 pattern, `sendUpdates: none`); write `<vault_path>/weekly/YYYY-MM-DD-weekly.md` (Monday date) via `append_weekly_review_sections`; commit/push weekly.

- [ ] **Step 2: Verify the skill cites shared refs and uses the correct weekly-file convention:**

```bash
cd claude-skills
grep -c "_shared-refs" weekly-planner/SKILL.md   # expect >= 2
grep -c "YYYY-MM-DD-weekly.md" weekly-planner/SKILL.md   # expect >= 1
grep -c "YYYY-Www" weekly-planner/SKILL.md   # expect 0 (no ISO)
```
Expected: `>=2`, `>=1`, `0`.

- [ ] **Step 3: Commit**

```bash
cd claude-skills
git add weekly-planner/SKILL.md
git commit -m "feat: add weekly-planner skill (4-phase facade with human gate)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: Teach `sync-skills.sh` to carry `_shared-refs/` and weekly-planner

**Files:**
- Modify: `life-os/scripts/sync-skills.sh` (SKILLS array + a new `_shared-refs` copy step)

**Interfaces:**
- Consumes: `claude-skills/_shared-refs/` and `claude-skills/weekly-planner/`.
- Produces: a sync that installs weekly-planner AND `_shared-refs/` into `life-os/skills/`.

- [ ] **Step 1: Add `weekly-planner` to the SKILLS array** in `sync-skills.sh` (after `time-energy-manager`).

- [ ] **Step 2: Add a `_shared-refs` copy step** after the per-skill loop, so the shared core lands at `life-os/skills/_shared-refs/`:

```bash
# Sync _shared-refs (cited by multiple skills)
if [ -d "$SOURCE/_shared-refs" ]; then
  mkdir -p "$PLUGIN_DIR/skills/_shared-refs"
  cp "$SOURCE/_shared-refs/"* "$PLUGIN_DIR/skills/_shared-refs/"
  echo "  _shared-refs/*"
fi
```

- [ ] **Step 3: Run the sync** from the claude-skills source path:

```bash
cd /Users/figlody_mac/Documents/brain/areas/tooling/plugins/life-os
./scripts/sync-skills.sh /Users/figlody_mac/Documents/brain/areas/tooling/skills/claude-skills
```
Expected output lists `weekly-planner/SKILL.md` and `_shared-refs/*`.

- [ ] **Step 4: Verify the citation path resolves in the synced copy** (the #1 risk):

```bash
cd /Users/figlody_mac/Documents/brain/areas/tooling/plugins/life-os
ls skills/_shared-refs/config-lookup.md skills/_shared-refs/language.md skills/_shared-refs/source-resolution.md
ls skills/weekly-planner/SKILL.md
# a skill at skills/weekly-planner/ citing ../_shared-refs/ resolves to skills/_shared-refs/ — confirm it exists:
test -f skills/_shared-refs/config-lookup.md && echo "PATH OK: ../_shared-refs/ resolves"
```
Expected: all files exist, `PATH OK`.

- [ ] **Step 5: Commit (life-os repo, feat/weekly-planner branch)**

```bash
cd /Users/figlody_mac/Documents/brain/areas/tooling/plugins/life-os
git add scripts/sync-skills.sh skills/
git commit -m "feat: sync weekly-planner skill + _shared-refs into plugin

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 5: Command trigger in life-os

**Files:**
- Create: `life-os/commands/weekly-planner.md`

**Interfaces:**
- Consumes: the synced weekly-planner skill.
- Produces: `/weekly-planner` slash command.

- [ ] **Step 1: Read the pattern** from an existing thin command:

```bash
cd /Users/figlody_mac/Documents/brain/areas/tooling/plugins/life-os && cat commands/weekly-review.md
```

- [ ] **Step 2: Create `commands/weekly-planner.md`** matching that pattern: frontmatter + "Before starting, read connected tools from config. Invoke the `weekly-planner` skill." Minimal arg parse (no-arg → full 4-phase run). Zero logic.

- [ ] **Step 3: Verify it's thin** (a trigger, not logic):

```bash
cd /Users/figlody_mac/Documents/brain/areas/tooling/plugins/life-os
wc -l commands/weekly-planner.md   # expect small, ~10-20 lines
grep -c "weekly-planner skill" commands/weekly-planner.md   # expect >= 1
```
Expected: small line count, skill referenced.

- [ ] **Step 4: Commit**

```bash
cd /Users/figlody_mac/Documents/brain/areas/tooling/plugins/life-os
git add commands/weekly-planner.md
git commit -m "feat: /weekly-planner command trigger

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 6: Routine (documented, created after canary)

**Files:**
- Create: `life-os/docs/weekly-planner-routine.md` (the routine prompt + creation params, self-contained)

**Interfaces:**
- Consumes: the `/weekly-planner` command / skill.
- Produces: a documented routine spec ready to instantiate via scheduled-tasks (form B, in-app) AFTER the canary passes.

- [ ] **Step 1: Write `docs/weekly-planner-routine.md`** documenting: schedule Monday 09:33 (off-minute), form B (in-app, needs Calendar+Gmail MCP), a 3-line trigger prompt that invokes the weekly-planner skill, zero logic. State explicitly: instantiate only after the canary (Task 7) is green.

- [ ] **Step 2: Commit**

```bash
cd /Users/figlody_mac/Documents/brain/areas/tooling/plugins/life-os
git add docs/weekly-planner-routine.md
git commit -m "docs: weekly-planner routine spec (instantiate post-canary)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 7: Canary e2e (manual, human-gated) + PRs

**Files:** none (verification + PR creation).

- [ ] **Step 1: Dry-run the skill by reading it as an operator would** — walk Phases 1-3 mentally against this real week, confirm the gate stops before any calendar write. (Full live run is a real user action Glody drives; the skill must not auto-apply.)

- [ ] **Step 2: Push both branches**

```bash
cd /Users/figlody_mac/Documents/brain/areas/tooling/skills/claude-skills && git push -u origin feat/weekly-planner
cd /Users/figlody_mac/Documents/brain/areas/tooling/plugins/life-os && git push -u origin feat/weekly-planner
```

- [ ] **Step 3: Open both PRs** (claude-skills: core + skill; life-os: sync + command + routine doc + the earlier Vault-FS commit). Use `gh pr create --body-file` to avoid quoting issues.

---

## Self-Review

**Spec coverage:** every design section maps to a task — extraction→T1, migration→T2, skill→T3, sync→T4, command→T5, routine→T6, canary+PRs→T7. Weekly-file convention → Global Constraints + T3 Step 2. No new Python → stated in T3.

**Placeholder scan:** no TBD/TODO; every code/content step shows the actual text or command.

**Type/name consistency:** `_shared-refs/` (not `_shared/`), `YYYY-MM-DD-weekly.md` (not ISO), `append_weekly_review_sections`, `feat/weekly-planner` — used consistently across tasks.

**Known risk surfaced:** the `../_shared-refs/` citation path is verified physically in T4 Step 4, the #1 risk from the design.
