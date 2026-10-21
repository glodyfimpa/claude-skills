---
name: weekly-planner
description: |
  Plans Glody's upcoming week end to end: reconciles last week's plan against what actually happened (done/partial/not touched, from agent sessions of every indexed agent and direct fact-check), collects state (tasks, projects, quarterly — including the yearly plan's current-quarter section, email, recent agent sessions, calendar), weighs and prioritizes every commitment, writes the collected state and the proposed focus into the week's note, and STOPS at a human gate before touching the calendar. Only after explicit approval does it apply the plan to the calendar and mark the focus as confirmed. Use this skill when the user says "pianifichiamo la settimana", "/weekly-planner", "pianificazione settimanale", "prepara la settimana", or when the Monday planning routine fires. Complements planning-review-system (backward-looking weekly review) and time-energy-manager (daily execution): weekly-planner looks forward across the whole week. Works with any task database, calendar, and email MCP, or in chat-only mode. Do NOT use for a single-day plan (use time-energy-manager) or a retrospective weekly review (use planning-review-system).
---

# Weekly Planner

Forward-looking weekly planning in 4 phases. Collects the week's state, weighs every
commitment, proposes a plan, gates on human approval, then applies it. A facade: it
reuses planning-review-system's collect and time-energy-manager's calendar-export
pattern, and writes the weekly plan as plain markdown. Its few helpers live in the vault
(`consuntivo-check`, `agent_activity`, `learning_signal`, `confirm_decision`).

**Principle:** a full calendar is not a planned week. Weigh every event, or you are just
filling holes.

## Config Guard

**Config lookup:** open and follow `_shared-refs/config-lookup.md` (or `../_shared-refs/config-lookup.md` when running from the synced plugin copy).

**If a config file exists:** read `task_tool`, `calendar_tool`, `notes_tool`, and
`email_tool` from the frontmatter, plus `vault_path` when
`notes_tool = vault_filesystem`. These decide MCP vs conversational fallback. Read also
`work_morning_block` and `work_afternoon_block` (the only work fascia, used in Phases 2-4).

**If NO config file exists:** run the same mini-setup as planning-review-system /
time-energy-manager (auto-detect tools, ask language + tools + schedule, save to
`~/.claude/life-os.local.md`). Never hardcode database IDs, field names, or schedule times.

## Language

See `_shared-refs/language.md` (or `../_shared-refs/language.md` in the synced copy).

## The week being planned

Default target = the week starting the **next Monday** (or the current week if invoked
Mon-morning). Confirm the Monday date with the user in one line before Phase 1 if
ambiguous. All dates below use that Monday as the anchor.

---

## Phase 0 — Open the week's note (FIRST step, before anything else)

The week's note must exist on disk whether or not Glody ever answers the gate: a plan only
in the chat is lost when the session goes idle (validated 2026-10-09: 8 Monday runs out of
12 waited for an OK that never came and left no file, because the note was written in Phase 4).

**If `notes_tool = vault_filesystem` and the directory `<vault_path>/.brain/system/vault_lint/review/`
exists** (the vault's rhythm chain, contract in `<vault_path>/.brain/system/schema/ritmi.md`):

```bash
PYTHONPATH=<vault_path>/.brain/system <vault_path>/.brain/system/.venv/bin/python \
  -m vault_lint.review apri <vault_path> --date <target Monday>
```

- **exit 0**: the command created the levels that were due (the week's note, and the
  monthly or quarter drafts if missing) and printed their paths. Work on those files.
- **exit 2**: the week's note already exists and nothing else is due. Work on that file.
- **any other exit, or the venv is missing**: stop and report the output. Do not create
  the note by hand.

Then run `… -m vault_lint.review stato <vault_path>` (read-only) and keep its signals
for Phase 3. If the command opened a monthly or quarter draft, say so in Phase 3: those
levels follow `<vault_path>/areas/glody/procedure/revisione-ritmi.md`, not this skill.

The note is `<vault_path>/.brain/weekly/<target Monday>-weekly.md`. Never overwrite it
or rewrite its frontmatter: edit sections in place (see "Writing into the note").
Then run `conta` and act on its verdict ("Learning signal" below).

**Otherwise** (no rhythm chain, or `notes_tool` is not the vault): skip Phase 0; the note
is written in Phase 3 as described under "Writing into the note".

---

## Phase 1 — Collect

Gather everything the week's plan depends on. Skip any source whose tool is `none`.
(This phase reuses the read logic of the sibling life-os skills; if they aren't loaded,
the steps below are self-contained enough to run directly.)

### Phase 1a — Consuntivo (runs first in Phase 1, before collecting anything new)

Before gathering new material, reconcile the previous plan against what happened.
Skipping this is how commitments quietly vanish (validated 2026-07-27: "prenota
appuntamento INPS" sat as a reminder in the 2026-07-20 plan and was never done).

1. **Read last week's plan**: `<vault_path>/.brain/weekly/<last-monday>-weekly.md`, its
   `## Focus settimana` first (older notes: Golden Rule and priorities): the commitment
   list to check against reality. If last week has no note, take the most recent one and
   say how many weeks are missing.
2. **Read last week's diary first** (`.brain/weekly/<last-monday>-diario.md`, see `references/diario.md`):
   the aggregator below is then needed only for the days it leaves open. **Then read the week's agent sessions through the aggregator** (all agents it indexes:
   Claude Code local, Cursor, and the git-based cloud adapters), never by guessing from
   file dates. When `notes_tool = vault_filesystem` and
   `<vault_path>/.brain/system/agent_activity/` exists:
   ```bash
   V=<vault_path>
   PYTHONPATH=$V/.brain/system $V/.brain/system/.venv/bin/python -m agent_activity.collect --vault $V
   PYTHONPATH=$V/.brain/system $V/.brain/system/.venv/bin/python -m agent_activity.query \
     --vault $V --since <start of last week, ISO UTC>
   ```
   Run `collect` first: the LaunchAgent runs it once a day, so today's sessions are
   missing otherwise. The query returns `sessions` (id, agent, project, title, turns,
   `closing_excerpt`, `source_path`), `collector_staleness_days` and `warnings`.
   - For every session judge delivery from `closing_excerpt` (where completion/handoff is
     usually declared). File mtimes are not evidence: files get touched without new work
     (validated 2026-10-13), and work can be delivered the same day a source file was last
     touched (validated 2026-07-27).
   - An empty `closing_excerpt` (cloud/git sessions, or not collected) is reported as
     "estratto assente", never silently skipped and never replaced by a guess.
   - **Drill down**: for each session whose title or excerpt touches an open commitment
     from step 1, or that has no usable excerpt, open the transcript at `source_path`
     and read the part that matters (search the commitment's keywords, then read around
     the hits). The excerpt is the map, the transcript is the evidence.
   - Report `collector_staleness_days` when it is `null` or above 3.
   - If the aggregator is missing or the command fails, say so in the note and fall back
     to scanning `~/.claude/projects/*/*.jsonl` (closing turns of each session in the
     window), stating that Cursor and cloud sessions were not covered.
   - **Cite what you used** in `## Consuntivo` as `sessione:<first 8 chars of the
     session_id>` next to each judgment (see Phase 3: the gate refuses a Consuntivo with
     no citation).
3. **Reconcile line by line**: for each commitment in last week's plan, mark DONE /
   PARTIAL / NOT TOUCHED, with the evidence (session excerpt, commit, or file) — not an
   assumption. If a commitment turns out already resolved by direct fact-check (e.g. the
   user states it plainly), trust the direct statement over inferred session evidence.
4. **Surface unresolved captures**: any reminder, idea, or task that appeared last week
   and was neither done nor explicitly dropped rejoins this week's raw material as an
   open item to place or discard — it does NOT get silently deferred to an undefined
   "retro" that has no calendar slot. If it implies real money or a hard consequence
   (a call to book, a cancellation with a window), it becomes a **calendar event**, not
   a reminder — a reminder with no slot is how it gets missed twice.
5. **Check predicted load vs actual load**: for each commitment marked DONE or PARTIAL,
   compare the load type it was weighed as (Phase 2, attribute 3) with what the session
   evidence shows it took. Flag a commitment predicted as light/handoff that turned out
   cognitive-heavy with no deliverable (validated 2026-07-27: a cashflow session weighed as
   a build produced design reasoning but no code, and Glody called it "tempo buttato").
   One line per mismatch, feeding Phase 3's report; a mismatch repeated across weeks on the
   same recurring commitment is surfaced explicitly. Register each one as a learning-signal
   row (`registra --origine consuntivo --classe carico-stimato-male --fase 2`, see
   "Learning signal"); `--testo` is Glody's words if he named it, else the mismatch line
   with the commitment and the week.

Output of this sub-phase: a short reconciliation summary (what was done, what wasn't,
what re-enters as open, and any load mismatch) — feeds directly into Phase 3's report.

### Phase 1b — New material

- **Tasks / projects / quarterly** (`task_tool`): reuse planning-review-system's collect:
  open tasks with due dates, active projects and their status, quarterly goals and progress,
  from `task_tool` per config. If `<vault_path>/.brain/system/piano-annuale-<year>.md` (or
  equivalent) exists, read the current quarter's section from there: it is the source of
  truth for quarterly goals, not the Notion `goals_page_url` fallback. Read also
  `## Priorità del mese` from `<vault_path>/.brain/monthly/<YYYY-MM>-monthly.md`: each
  focus of the week must serve one of those priorities.
- **Email** (`email_tool`): scan the last 7 days (config `email_scan_labels`, default
  INBOX; apply `email_exclude_patterns`). Extract only actionable items with a date or
  a decision — not newsletters.
- **Calendar** (`calendar_tool`): read every event already on the target week. These are
  existing commitments — they get weighed too (Phase 2), not just worked around.
- **Open deadlines** (deadlines other systems keep in their own files: project MOCs,
  pricing-agent proposals; vault only): run `PYTHONPATH=<vault_path>/.brain/system
  <vault_path>/.brain/system/.venv/bin/python -m vault_lint.review scadenze <vault_path>
  --date <target Monday> --giorni 21 --json`. Every row in `scadenze` (overdue included) is
  a hard deadline candidate: weigh it in Phase 2 and list it in Phase 3's "Hard deadlines
  of the week" with its Rome time; report every `problemi` entry. Exit 2 = bad arguments.
- **Recent agent sessions**: query the aggregator again with `--since <2 weeks ago>` (same
  command, staleness rule and fallback as Phase 1a) to surface threads still open (a build
  mid-flight, a deferred follow-up) that deserve a slot this week. Use metadata and
  `title_or_first_message` to spot open threads, not to judge delivery.
- **Future directions** (`<vault_path>/areas/glody/knowledge/direzioni-future.md`, if it
  exists): for each direction, is there a new real signal this week (an email, a session,
  a contact)? Is any direction dead, or is a new one emerging from what Glody said? Pick
  at most one item from its Radar section that could get a small slot this week. Report
  proposed edits to the file in Phase 3; never edit directions without Glody's OK.

Output of Phase 1 is raw material plus the reconciliation summary, not yet a plan. Do
not schedule anything here.

---

## Phase 2 — Weigh & Prioritize (the core)

This is the phase that makes the difference. Apply the weighing discipline to **every**
event — the ones you'd create, the ones already on the calendar from Phase 1, AND the
unresolved captures surfaced by Phase 1a's reconciliation. An open item from last week
is not automatically high priority just because it's old — weigh it like anything else.

**Weigh each event by five attributes, declared before placing it:**

1. **Nature** — **BLOCK** (occupies real time, `busy`, counts toward the 4h/day: "in that
   slot I'm doing this") vs **REMINDER** (no time, `free`/all-day, sits at the top of the
   day: "remember that"). There's a middle: a reminder that still implies a short task →
   occupies space but with a lighter specific weight (short block, not a 2h focus wall).
   Do not make everything a 2h busy block: it falsifies the 4h count.
2. **Glody-time, not machine-time** — the load is measured on Glody's **attention-hours**
   (supervision + checkpoint decisions), NOT the total execution time. A job that is big
   in execution-hours (e.g. building a skill: design+TDD+code = 6-8h) can be LIGHT for
   Glody if it's assisted: he approves the design (~30min), the code is HANDOFF to a
   subagent (he approves output ~15min) → his real time ~1-1.5h scattered. Always separate
   machine-time (mine + subagent, runs while Glody does other things) from Glody-time
   (checkpoints) and weigh the event ONLY on the second.
3. **Load type** — **delegated** (a person or an agent owns it end to end; Glody only
   spends the 10-15 minute checkpoint) vs **handoff** (an LLM carries it with little
   supervision: a message, an extraction, a routine to launch, the code part of an assisted
   build) vs **cognitive** (Glody must be present and focused: approving a design, a strategic
   decision) vs **physical/out-of-house** (an errand). A project decomposes into phases of
   different load: weigh each phase, not the whole project.
4. **Real weight / priority** — hard deadline? legal/economic consequence? or deferrable?
5. **Where** — at the desk / out / with people.

**The judgment is yours to make, but when genuinely in doubt about an event's nature or
weight, ask Glody** instead of guessing. A targeted question beats a wrong classification.

**The two work fascia — ONLY two, distinct, read from the config, never typed here:**
`work_morning_block` and `work_afternoon_block` in the life-os config; the day's cap is
`daily_work_cap_hours`, read from the config, never the sum of the fasce. Read them in the Config Guard and use them everywhere below ("the
morning fascia", "the afternoon fascia"); if a key is missing, ask Glody instead of assuming.
The time between and outside them is NOT work time — it is life, not "free holes to fill".
**Never place a work event outside these two fascia:** two separate islands, not one block.

**Planning rules file (read it before weighing anything).** If
`<vault_path>/areas/glody/procedure/regole-di-pianificazione.md` exists, it overrides the
defaults below for: the execution tiers, the DoD requirement, the capacity target
and the one-theme-per-day rule. The axes are the ordered `## Priorità del mese` of the
current monthly note (`<vault_path>/.brain/monthly/<YYYY-MM>-monthly.md`), not a separate
list. Apply the file as written: axes are the main ones, not the only
ones, and an urgent or deadline item outside any axis is still done, with no hour cap.
Delegated work still costs Glody 10-15 minutes of checkpoint. An activity with no DoD is
not placed: propose one and let Glody approve it. List, in the report, every activity that
is delegable together with the prep-run that would prepare it the day before. If the file
is missing, use the defaults below.

**Default capacity (when the rules file is missing): fill the 4 hours inside the two
fascia.** The cap is also a target, and there is no "park it outside the fascia" shortcut.
If a valuable event does not fit this week by priority or space, move it to next week (a
real date); if it has no value, delete it. Deferrable meta-tooling that clutters the view
moves to next week too.

**Ordering** (with the rules file: its tiers, then its axes as tie-break inside a tier;
without it, the defaults here):
- Sort by hard deadline first (legal/economic consequences lead).
- Then by the week's Golden Rule (the single "priority of priorities").
- Group by theme: one theme per day when possible, delegated runs included. Fixed events
  that cannot move (a loop with a dependency) stay; say so and put their checkpoint at the
  start of the fascia.
- Never two COGNITIVE blocks back-to-back — alternate cognitive ↔ handoff/physical/light.
  Handoff work an LLM can carry doesn't compete for focus; cognitive work is isolated and
  protected. With one theme per day the alternation happens inside the theme.

Produce, for the whole Mon-Fri grid: which event goes in which fascia on which day, each
with a one-line weighing (Glody-time + load type), respecting the rules above.

---

## Phase 3 — Report + GATE (handoff stop)

First write the week's note (see "Writing into the note" below): the collected state and
the proposed focus, marked as a proposal. This is local and reversible, and it is what
survives if the gate is never answered. Then run the evidence check on the note:

```bash
PYTHONPATH=<vault_path>/.brain/system <vault_path>/.brain/system/.venv/bin/python \
  -m vault_lint.review consuntivo-check <vault_path> --date <target Monday>
```

Exit 0 = `## Consuntivo` cites at least one real session (`sessione:<8 chars>` found in
the aggregator index). Any other exit = Phase 1a step 2 was not done: go back and do it,
then rewrite `## Consuntivo`. Do not present the gate until the check passes. Only when
the aggregator has no sessions at all in the window, the section may carry the explicit
token `sessioni:nessuna`.

Then commit + push only the note, plus the learning-signal files if they changed (vault:
the default branch, see the vault's git rules). Present a readable plan and **STOP**: do
not touch the calendar and do not mark the focus as confirmed yet.

Structure of the report:
- **Consuntivo settimana scorsa** — from Phase 1a: what was done, what was partial, what
  was not touched, each with its evidence. Unresolved captures list explicitly what
  they're becoming this week (a placed event, a dropped item) — never "we'll look at it
  in retro" when no retro ritual actually owns that slot. Include any load mismatch
  flagged in Phase 1a step 5 (predicted handoff/light, actual cognitive/heavy or vice
  versa) — one line each, not a full audit.
- **Hard deadlines of the week** (dated, with consequence).
- **Golden Rule** of the week (the one priority of priorities, highlighted first).
- **Priorities**, ordered by the Phase 2 sort (P1..Pn with a one-line why each).
- **Mon-Fri grid** — for each fascia (the two blocks from the config), the event placed
  there with its one-line weighing (Glody-time + load type). Show the reasoning, not just the grid.
- **Calendar proposal in ASCII (always, with every presentation of the plan)** — a
  Mon-Fri grid with the two fascia from the config as rows, built from the same list
  Phase 4 will write, so what Glody approves is what gets created. Mark each cell:
  `[=]` already on the calendar (not touched), `[+]` Phase 4 will create it, `[~]` an
  existing event Phase 4 would change (say what changes and why), and `.` free. Under the
  grid list every `[+]` and `[~]` with title, day, start-end, `busy`/`free`. Show it also
  when the gate is re-presented by "Resume the gate", after re-reading the calendar.
- **Cognitive vs handoff count** — blocks per load type (Phase 2 attribute 3), as a plain
  number, to show whether the week leans cognitive or handoff.
- **Prep-runs (always, proactive)** — for every cognitive block and every delegable
  activity, the one-shot delegated run that prepares it the day before: what it produces,
  its DoD, when it fires (weekday, before the block). Mark them `(p)` in the ASCII grid.
  Never stop at listing a problem: each one comes with a next action, and anything
  answerable from mail, chats, logs or files is looked up, not asked.
- **Actionable emails** (from Phase 1, with the action + date).
- **Conflicts / notes** — anything that didn't fit, moved to next week, or needs a Glody
  decision, plus the `review stato` signals from Phase 0.
- **Where the note is** — the path of the week's note just written.

Then end with an explicit gate line:

> "Questo è il piano, già scritto come proposta in `<path della weekly>`. Dimmi OK per
> applicarlo al calendario e confermare il focus, oppure dimmi cosa cambiare.
> Se vuoi: cosa ti è sfuggito o ho pesato male?"

**Wait for explicit approval.** Do NOT proceed to Phase 4 on anything less than a clear OK.
If Glody asks for changes, revise Phase 2/3 and re-present the gate.

Each change Glody asks for at the gate, and each answer to the optional question, is
feedback: classify it and `registra` it with `--origine gate` before revising (see
"Learning signal"). If the OK comes and no change was asked during the whole gate,
register one neutral row (`--esito identica`).

---

## Phase 4 — Apply (only after OK)

Only after explicit approval:

### Calendar export
**MANDATORY when `calendar_tool != none`.** Reuse time-energy-manager's Step 4.5 pattern:
- Use `calendar_id` from config (same calendar read in Phase 1). Optionally ask if a
  different calendar is wanted.
- Idempotent: list the target week's events first. Skip a planned block when an event
  with the same title and the same fascia already exists (a resumed gate must never
  duplicate events). For each planned block NOT already a calendar event (skip events
  that came from the calendar in Phase 1 — they already exist), create an event:
  - **Title:** block name (e.g. "Deep Focus: [task]", "Handoff: [routine]", "Reminder: [x]").
  - **Start/End:** the fascia times from the plan.
  - **Description:** brief context (priority, load type).
  - **Nature:** BLOCK → `busy`; REMINDER → `free`/all-day.
  - Do NOT notify attendees (`sendUpdates: none`).
- Confirm: "Fatto — [N] blocchi aggiunti al calendario."

If `calendar_tool = none`: skip calendar export.

### Prep-runs and work-item loops
The OK covers the prep-runs in the report and every multi-step work item: each becomes a
one-shot weekday task at its block time launching a versioned `/loop` prompt (state file, human
gate), linked from its event. How: `references/work-item-loops.md`. Tell Glody which exist.

### Confirm the focus in the note
Edit `## Focus settimana` in the week's note: replace the proposal marker with the
focus Glody approved (with his changes, if any). Touch only that section and the
`updated:` date in the frontmatter.

If Glody asks for changes before the OK, update the proposal in the note too, then
re-present the gate.

### Record the Decision
`review stato` and the briefing do not read the note: they read the confirmed Decision
YAML of the current ISO week (`read_confirmed_focus`). Editing only the note leaves them
saying "focus non confermato" after a real OK. So write the Decision too:

```bash
PYTHONPATH=<vault_path>/.brain/system <vault_path>/.brain/system/.venv/bin/python - <<'EOF'
from pathlib import Path
from vault_lint.focus import confirm_decision
week = "<ISO year>-W<ISO week>"            # e.g. 2026-W42
focus = [("<slug of focus 1>", "<label of focus 1>")]  # the approved items, max 3
confirm_decision(
    Path("<vault_path>"), f"week-{week}",
    decision_override={
        "horizon": "week", "arco_id": week,
        "focus": [{"ref": r, "label": l, "tempo": None} for r, l in focus],
        "delega": [], "lascia": [], "refs": [r for r, _ in focus],
    },
)
EOF
```

It writes `.brain/system/decisions/focus-week-<week>.yaml` with `status: confirmed`; it
refuses an empty focus. Then run `review stato <vault_path>`: it must now say the focus
is confirmed. If it does not, say so instead of reporting success.

### Commit
Commit + push the note and the Decision YAML after confirming the focus (only those two
files, plus the learning-signal files if they changed).

---

## Resume the gate (any later session)

The note and its commit exist before the gate on purpose, so the gate survives an idle
or closed session. A later session resumes it from the note, without redoing Phases 1-2:

- **Trigger**: "ok weekly", "applica la weekly", "riprendi la weekly", or the briefing
  signal `focus della settimana non confermato`.
- Read `<vault_path>/.brain/weekly/<target Monday>-weekly.md`. If `## Focus settimana`
  still carries the proposal marker ("da confermare"), re-present the Phase 3 report
  from the note (re-read the calendar for the week first: it may have changed, and say
  what changed), wait for the OK, then run Phase 4. Phase 4 is idempotent, so a repeated
  resume is safe.
- If the focus is already confirmed (the Decision YAML says so), do nothing and say so.

---

## Writing into the note

**If `notes_tool = vault_filesystem`:** the note is
`<vault_path>/.brain/weekly/<target Monday>-weekly.md` (filename = the Monday date,
never ISO `YYYY-Www`). Phase 0 created it, or it already existed: read it first and
edit sections in place with the Edit tool. Never overwrite the file, never rewrite its
frontmatter (only bump `updated:`), never delete what a person wrote there.

Write the plan only into the five fixed sections of the vault's rhythm contract
(`<vault_path>/.brain/system/schema/ritmi.md`):

- `## Consuntivo` — from Phase 1a: done / partial / not touched, with evidence, where
  each unresolved capture landed this week, and load mismatches (one line each).
- `## Calendario` — from Phase 1b: the week's events and hard deadlines (dated, with
  consequence), and what the next two weeks already hold.
- `## Appunti della settimana` — open captures and inbox items, each with a proposed
  title and folder. Keep what the command pre-filled; add, do not duplicate.
- `## Progetti da guardare` — projects past deadline, stalled, or without a goal, each
  with the suggested action.
- `## Focus settimana` — at most three items, each `N. <focus> — serve: <priorità del
  mese>`; the first one is the week's Golden Rule. Before the gate the section opens
  with a proposal line: keep the one `review apri` pre-fills ("Proposta dalle priorità
  del mese …, da confermare …"), or write `Proposta del <date>, da confermare:` if there
  is none. Replace the pre-filled items, do not append a second list. Phase 4 replaces
  the proposal line once Glody approves.

Extra sections are allowed after the fixed ones, for what the contract does not cover:
`## Griglia Lun-Ven` (name the two fascia with the times read from the config) with one
weighing line per event followed by the same ASCII calendar proposal shown in the report,
`## Bilancio cognitive/handoff`, `## Email azionabili`, `## Segnalazioni / conflitti`.
Priorities are written only in `## Focus settimana`, never in an extra section.

No external send happens here: email and messages stay drafts.

**If the rhythm chain does not exist** (Phase 0 skipped): create the note with the
Write tool, frontmatter `doc_type: log`, `created`/`updated` = today, `week: <ISO
week>`, then the same five fixed sections and the extras.

**If `notes_tool = notion`:** create/update the week's page under `output_page_url` with
the same sections. **If `notes_tool = none`:** present the plan in chat as formatted markdown.

---

## Learning signal

Every piece of feedback Glody gives on the planner becomes one row of an append-only log;
the counts decide what this skill adapts to. Vault only: needs
`<vault_path>/.brain/system/learning_signal/weekly.py` (README next to it), else skip. Run
`PYTHONPATH=<vault_path>/.brain/system <vault_path>/.brain/system/.venv/bin/python -m learning_signal.weekly <command>`.

**Register: whenever Glody gives feedback on the planner, at any point** (the gate, the
retro, a later chat, another session), register it before moving on. One row per request,
not per message and not per section touched: split a message that carries two requests.

```bash
… registra --origine gate|retro|consuntivo --classe <class> --fase 0|1a|1b|2|3|4 \
  [--fonte <source>] --testo - <<'EOF'
<his words, verbatim>
EOF
```

`--testo -` reads the heredoc verbatim: apostrophes ("l'hai") break `--testo='…'`.

- Classes (closed list): `fonte-mancata` (a source was not read; add `--fonte
  sessione|mail|calendario|nota|scadenza|altro`), `peso-sbagliato`, `scadenza-mancata`,
  `carico-stimato-male`, `fascia-sbagliata`, `troppo-lungo`, `formato`; `altro` never counts.
  Do not force a class to make it count.
- `--fase` is the phase whose output was wrong. A gate approved with no change:
  `registra --origine gate --esito identica`.
- Exit 2 = refused, the reason is on stderr. "already registered" means the same gesture
  is already in the log: nothing to do.

**Read (Phase 0): `… conta`** returns `adatta`, `promuovi`, `richieste`, `problemi`.

- `adatta` (same place and class at least 3 times): read those rows' `testo_orig` and
  apply the correction in that phase during this run; say it in ONE line in the report.
- `adatta` empty: change nothing and say nothing about the signal.
- `promuovi` (at least 5 times over at least 14 days): propose to Glody, in the Phase 3
  report, the edit to this skill that would make the correction permanent. Never edit
  the skill yourself. Once proposed, add `"<dove>:<classe>"` to the JSON list in
  `suggeriti.json` next to the log (create it if missing), so it is not proposed again.
- `problemi` not empty (exit 1): name them in one line and go on. Never rewrite past
  rows. If the command fails, plan without adaptation and say so in one line.

The log and `suggeriti.json` are versioned: commit them with the run's next commit.

---

## Trigger Mapping

- "pianifichiamo la settimana" / "prepara la settimana" → full run, Phases 0-4.
- "/weekly-planner" → full run.
- "ok weekly" / "applica la weekly" / "riprendi la weekly" → "Resume the gate" section.
- Monday planning routine → full run (the routine is a 3-line trigger, all logic is here).
