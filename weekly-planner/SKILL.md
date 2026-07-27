---
name: weekly-planner
description: |
  Plans Glody's upcoming week end to end: reconciles last week's plan against what actually happened (done/partial/not touched, from Claude sessions and direct fact-check), collects state (tasks, projects, quarterly — including the yearly plan's current-quarter section, email, recent Claude sessions, calendar), weighs and prioritizes every commitment, presents a readable plan, and STOPS at a human gate before touching the calendar. Only after explicit approval does it apply the plan to the calendar and write the weekly note to the vault. Use this skill when the user says "pianifichiamo la settimana", "/weekly-planner", "pianificazione settimanale", "prepara la settimana", or when the Monday planning routine fires. Complements planning-review-system (backward-looking weekly review) and time-energy-manager (daily execution): weekly-planner looks forward across the whole week. Works with any task database, calendar, and email MCP, or in chat-only mode. Do NOT use for a single-day plan (use time-energy-manager) or a retrospective weekly review (use planning-review-system).
---

# Weekly Planner

Forward-looking weekly planning in 4 phases. Collects the week's state, weighs every
commitment, proposes a plan, gates on human approval, then applies it. A facade: it
reuses planning-review-system's collect and time-energy-manager's calendar-export
pattern, and writes the weekly plan as plain markdown. No new code.

**Principle:** a full calendar is not a planned week. Weigh every event, or you are just
filling holes.

## Config Guard

**Config lookup:** open and follow `_shared-refs/config-lookup.md` (or `../_shared-refs/config-lookup.md` when running from the synced plugin copy).

**If a config file exists:** read `task_tool`, `calendar_tool`, `notes_tool`, and
`email_tool` from the frontmatter, plus `vault_path` when
`notes_tool = vault_filesystem`. These decide MCP vs conversational fallback.

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

## Phase 1 — Collect

Gather everything the week's plan depends on. Skip any source whose tool is `none`.
(This phase reuses the read logic of the sibling life-os skills; if they aren't loaded,
the steps below are self-contained enough to run directly.)

### Phase 1a — Consuntivo (runs FIRST, before collecting anything new)

Before gathering new material, reconcile the previous plan against what actually
happened. Skipping this step is how commitments quietly vanish (validated 2026-07-27:
"prenota appuntamento INPS" sat as an all-day reminder in the 2026-07-20 plan and was
never done — nobody reopened it because no ritual re-surfaced it).

1. **Read last week's plan**: `<vault_path>/weekly/<last-monday>-weekly.md`. This is the
   commitment list to check against reality, not to trust at face value.
2. **Read the week's Claude sessions**: scan `~/.claude/projects/*/*.jsonl` for user
   turns dated within the past week. Read the closing turns of each session (where
   completion/handoff is usually declared) — a grep on file mtimes alone is not enough:
   work can be finished and delivered on the same day a source file was last touched,
   with no file-level trace of the delivery itself (validated 2026-07-27: a capstone's
   source files were dated the same day it was delivered; only the session's closing
   turn confirmed delivery — file dates alone would have wrongly read it as unfinished).
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
   compare the load type it was weighed as (Phase 2's attribute 3: handoff vs cognitive)
   against what the session evidence shows it actually took. Flag a mismatch when a
   commitment predicted as light/handoff turned out cognitive-heavy with no deliverable
   (validated 2026-07-27: a cashflow session weighed as a build produced serious design
   reasoning but zero code shipped, zero bank connected — the user called it "tempo
   buttato"). This is not a full retrospective audit — just a one-line note per mismatch,
   feeding Phase 3's report. A repeated mismatch on the same recurring commitment across
   multiple weeks is worth surfacing explicitly, not just noting once and dropping.

Output of this sub-phase: a short reconciliation summary (what was done, what wasn't,
what re-enters as open, and any load mismatch) — feeds directly into Phase 3's report.

### Phase 1b — New material

- **Tasks / projects / quarterly** (`task_tool`): reuse planning-review-system's collect.
  Read open tasks with due dates, active projects and their status, quarterly goals and
  progress. If `task_tool = vault_filesystem` / `notion`, read from there per config.
  If `<vault_path>/system/piano-annuale-2026.md` (or equivalent yearly-plan file) exists,
  read the current quarter's section from there — it is the source of truth for
  quarterly goals, not the Notion `goals_page_url` fallback.
- **Email** (`email_tool`): scan the last 7 days (config `email_scan_labels`, default
  INBOX; apply `email_exclude_patterns`). Extract only actionable items with a date or
  a decision — not newsletters.
- **Calendar** (`calendar_tool`): read every event already on the target week. These are
  existing commitments — they get weighed too (Phase 2), not just worked around.
- **Recent Claude sessions**: scan the last 2 weeks of work to surface threads still open
  (a build mid-flight, a deferred follow-up) that deserve a slot this week. (Phase 1a
  already read the past week in detail for reconciliation; this widens the window to 2
  weeks for threads not tied to last week's specific plan.)

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
3. **Load type** — **handoff** (an LLM carries it with little supervision: a message, an
   extraction, a wait, a routine to launch, OR the code part of an assisted build) vs
   **cognitive** (Glody must be present and focused, even if LLM-assisted: approving a
   design, a strategic decision) vs **physical/out-of-house** (going somewhere, an errand).
   A single "project" decomposes into phases of different load — don't weigh the whole
   project with one load type.
4. **Real weight / priority** — hard deadline? legal/economic consequence? or deferrable?
5. **Where** — at the desk / out / with people.

**The judgment is yours to make, but when genuinely in doubt about an event's nature or
weight, ask Glody** instead of guessing. A targeted question beats a wrong classification.

**The two work fascia — ONLY two, distinct: morning 10:00-12:00 + afternoon 16:00-18:00**
(= 4h/day). 12:00-16:00 and after 18:00 are NOT work time — they are life, not "free holes
to fill". **Never place a work event outside these two fascia** (e.g. 14-16 is forbidden).
They are two separate islands, not a continuous 10-18 block with gaps.

**The 4 hours get FILLED inside the two fascia, not emptied.** Glody works 4h/day (a cap,
but also a target). There is no "park it outside the fascia" shortcut for a valuable event.
If a valuable event conflicts inside the fascia, fit it by weighing; if it doesn't fit this
week by priority/space, move it to next week (a real date, not outside the fascia). If it
has no value, delete it. Deferrable meta-tooling that doesn't fit and clutters the view →
move to next week, don't leave it in the fascia or the gaps.

**Ordering:**
- Sort by hard deadline first (legal/economic consequences lead).
- Then by the week's Golden Rule (the single "priority of priorities").
- Never two COGNITIVE blocks back-to-back — alternate cognitive ↔ handoff/physical/light.
  Handoff work an LLM can carry doesn't compete for focus; cognitive work is isolated and
  protected.

Produce, for the whole Mon-Fri grid: which event goes in which fascia on which day, each
with a one-line weighing (Glody-time + load type), respecting the rules above.

---

## Phase 3 — Report + GATE (handoff stop)

Present a readable plan, then **STOP**. Do not touch the calendar or write any file yet.

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
- **Mon-Fri grid** — for each fascia (10-12, 16-18), the event placed there with its
  one-line weighing (Glody-time + load type). Show the reasoning, not just the grid.
- **Cognitive vs handoff count** — how many blocks this week's grid places in each load
  type (Phase 2 attribute 3). A number, not a judgment — it makes visible whether the
  week leans toward deep/cognitive or shallow/handoff work without another audit.
- **Actionable emails** (from Phase 1, with the action + date).
- **Conflicts / notes** — anything that didn't fit, moved to next week, or needs a Glody
  decision.

Then end with an explicit gate line:

> "Questo è il piano. Dimmi OK per applicarlo al calendario e scrivere il weekly, oppure
> dimmi cosa cambiare."

**Wait for explicit approval.** Do NOT proceed to Phase 4 on anything less than a clear OK.
If Glody asks for changes, revise Phase 2/3 and re-present the gate.

---

## Phase 4 — Apply (only after OK)

Only after explicit approval:

### Calendar export
**MANDATORY when `calendar_tool != none`.** Reuse time-energy-manager's Step 4.5 pattern:
- Use `calendar_id` from config (same calendar read in Phase 1). Optionally ask if a
  different calendar is wanted.
- For each planned block NOT already a calendar event (skip events that came from the
  calendar in Phase 1 — they already exist), create an event:
  - **Title:** block name (e.g. "Deep Focus: [task]", "Handoff: [routine]", "Reminder: [x]").
  - **Start/End:** the fascia times from the plan.
  - **Description:** brief context (priority, load type).
  - **Nature:** BLOCK → `busy`; REMINDER → `free`/all-day.
  - Do NOT notify attendees (`sendUpdates: none`).
- Confirm: "Fatto — [N] blocchi aggiunti al calendario."

If `calendar_tool = none`: skip calendar export.

### Write the weekly note
**If `notes_tool = vault_filesystem`:** write the approved plan directly to
`<vault_path>/weekly/YYYY-MM-DD-weekly.md` with the **Write tool** (plain markdown — no
Python helper: the `weekly_review.py` helper renders *review* sections, Quick
Capture / Inbox / Projects Status, which are the wrong shape for a *plan*).

`YYYY-MM-DD` is the target **Monday** date (e.g. `2026-07-13-weekly.md`). This is the
vault convention for the **filename** — NOT ISO `YYYY-Www`. (The ISO week still appears
*inside* the frontmatter as the `week:` field — the ban is on the filename only.)

Mirror the existing weekly-plan format (see `<vault_path>/weekly/2026-07-06-weekly.md`
as the reference). Required frontmatter (mandatory `created` + `updated`, per vault rules):

```yaml
---
title: "Piano settimana — <Monday date in configured language>"
created: '<today ISO>'
updated: '<today ISO>'
tipo: weekly
week: <ISO week, e.g. 2026-W29>
quarter: <e.g. Q3>
notion_url: null
tags:
  - weekly-plan
---
```

Then these sections, filled from Phases 2-3 (omit a section only if genuinely empty):
- `## Contesto` — one paragraph on the week's situation.
- `## Consuntivo settimana scorsa` — from Phase 1a: done / partial / not touched, with
  evidence, and where each unresolved capture landed this week. Include load mismatches
  (predicted vs actual) as one line each.
- `## Scadenze legali dure della settimana` — dated hard deadlines with consequence.
- `## Golden Rule della settimana` — the one priority of priorities.
- `## Priorità della settimana (ordine dettato dalle scadenze)` — P1..Pn, one why each.
- `## Griglia Lun-Ven (blocchi: mattina 10-12, pomeriggio 16-18)` — the weighed grid,
  one line per event (Glody-time + load type).
- `## Bilancio cognitive/handoff della settimana` — the count from Phase 3.
- `## Email azionabili (scan Gmail ultimi 7gg)` — actionable emails with action + date.
- `## Segnalazioni / conflitti` — anything moved to next week or needing a decision.

If the file already exists (e.g. hand-written earlier this week), read it first and
merge rather than overwrite — never destroy hand-written content; if unsure, ask.

**If `notes_tool = notion`:** create/update the week's page under `output_page_url` with
the same sections.

**If `notes_tool = none`:** present the final plan in chat as formatted markdown.

### Commit
If the vault note was written, commit + push it (vault-autosave handles this on session
end, or commit explicitly if the user asked to save now).

---

## Trigger Mapping

- "pianifichiamo la settimana" / "prepara la settimana" → full run, Phases 1-4.
- "/weekly-planner" → full run.
- Monday planning routine → full run (the routine is a 3-line trigger, all logic is here).
