---
name: weekly-planner
description: |
  Plans the user's upcoming week end to end: reconciles last week's plan against what actually happened (done/partial/not touched, from agent sessions of every indexed agent and direct fact-check), collects state (tasks, projects, quarterly — including the yearly plan's current-quarter section, email, recent agent sessions, calendar), weighs and prioritizes every commitment, writes the collected state and the proposed focus into the week's note, and STOPS at a human gate before touching the calendar. Only after explicit approval does it apply the plan to the calendar and mark the focus as confirmed. Use this skill when the user says "pianifichiamo la settimana", "/weekly-planner", "pianificazione settimanale", "prepara la settimana", or when the Monday planning routine fires. Complements planning-review-system (backward-looking weekly review) and time-energy-manager (daily execution): weekly-planner looks forward across the whole week. Works with any task database, calendar, and email MCP, or in chat-only mode. Do NOT use for a single-day plan (use time-energy-manager) or a retrospective weekly review (use planning-review-system).
---

# Weekly Planner

Forward-looking weekly planning in 4 phases. Collects the week's state, weighs every
commitment, proposes a plan, gates on human approval, then applies it. A facade: it
reuses planning-review-system's collect and time-energy-manager's calendar-export
pattern (DRY: a rule lives in one place and is called, never restated), and writes the
weekly plan as plain markdown.

**Principle:** a full calendar is not a planned week. Weigh every event, or you fill holes.

## Guards (whoever starts the skill)

The same defences hold whether the skill is started by a scheduled routine, a chat, or a
day-orchestrator session: the caller only starts the skill and adds none of its own. These
guards are the skill's flow, not planning gestures: the user's policy file does not change them.

1. **Calendar read-only until the OK.** Phases 0-3 only read the calendar: no create, update
   or delete before the user's explicit OK at the gate.
2. **Every deletion is shown first.** An existing calendar event leaves the calendar only as a
   `[-]` cell in the Phase 3 proposal, with its reason and its proof next to it, and only in
   Phase 4 after the OK (see "Calendar deletions"). The same holds for scheduled tasks
   ("Scheduled-task housekeeping").
3. **No external sends.** Email and messages stay drafts.

## Config Guard

**Config lookup:** open and follow `_shared-refs/config-lookup.md` (or `../_shared-refs/config-lookup.md` when running from the synced plugin copy).

**If a config file exists:** read from the frontmatter `task_tool`, `calendar_tool`,
`notes_tool`, `email_tool` (MCP vs conversational fallback), `calendar_id`, `vault_path` when
`notes_tool = vault_filesystem`, `work_morning_block` and `work_afternoon_block` (the only
work fascia), `daily_work_cap_hours` (no default: ask if missing; in a run with nobody
present, write the note anyway and list the missing key first under conflicts), and every key in
`references/planning-parameters.md`, with its default when missing.

**Policy file:** if `planning_rules_path` is set and the file exists, read it (Phase 2). If the
key is set but the file is not found, plan with the gestures only and report it **at the top of
the Phase 3 report as a broken path** («file delle regole non trovato: <path>»), never as a
silent default: a moved file must not drop the policy without anyone noticing.

**If NO config file exists:** run the same mini-setup as planning-review-system /
time-energy-manager (auto-detect tools, ask language + tools + schedule, save to
`~/.claude/life-os.local.md`). Never hardcode database IDs, field names, schedule times, or a user's paths, names and numbers
(dependency inversion: the flow depends on the tools named in the config, not on a concrete tool).

**Notes adapter:** when `notes_tool = vault_filesystem`, open `references/adapter-vault.md`.
It holds every vault path, helper command and section name this skill uses; below they are
named by operation (`open-week`, `sessions`, `consuntivo-check`, ...) and by section (the
focus section, the reconciliation section, ...). If the adapter's condition is not met, every
adapter operation is "not available" and the fallback branch applies.

## Language

See `_shared-refs/language.md` (or `../_shared-refs/language.md` in the synced copy).

## The week being planned

Default target = the week starting the **next Monday** (or the current week if invoked
Mon-morning). Confirm the Monday date with the user in one line before Phase 1 if
ambiguous. All dates below use that Monday as the anchor.

---

## Phase 0 — Open the week's note (FIRST step, before anything else)

The week's note must exist on disk whether or not the user ever answers the gate: a plan only
in the chat is lost when the session goes idle (validated 2026-10-09: 8 Monday runs out of
12 waited for an OK that never came and left no file, because the note was written in Phase 4).

**If the adapter's `open-week` is available:** run it for the target Monday and follow its exit
codes (adapter table): work on the week note it created or found; on any other exit, stop and
report the output. Do not create the note by hand.

Then run the adapter's `state` (read-only) and keep its signals for Phase 3. If `open-week`
opened a monthly or quarter draft, say so in Phase 3: those levels follow the procedure at
`rhythm_review_path` (config), not this skill.

Never overwrite the week note or rewrite its frontmatter: edit sections in place (see
"Writing into the note"). Then read the learning signal and act on its verdict ("Learning signal" below).

**Otherwise** (no `open-week`): skip Phase 0; the note is written in Phase 3 as described
under "Writing into the note".

---

## Phase 1 — Collect

Gather everything the week's plan depends on. Skip any source whose tool is `none`.
(This phase reuses the read logic of the sibling life-os skills; if they aren't loaded,
the steps below are self-contained enough to run directly.)

### Phase 1a — Reconciliation (runs first in Phase 1, before collecting anything new)

Before gathering new material, reconcile the previous plan against what happened.
Skipping this is how commitments quietly vanish (validated 2026-07-27: a booking
reminder sat in the previous week's plan and was never done).

1. **Read last week's plan**: the focus section of last week's note first: the commitment
   list to check against reality. If last week has no note, take the most recent one and
   say how many weeks are missing.
2. **Read last week's diary first** when the adapter has one (`references/adapter-vault-diary.md`):
   the session read below is then needed only for the days it leaves open. **Then read the
   week's agent sessions** through the adapter's `sessions` operation (all agents it indexes:
   local, editor, and cloud adapters), never by guessing from file dates. It returns per
   session an id, a title, a `closing_excerpt` and a `source_path`.
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
   - If `sessions` is not available or fails, say so in the note and fall back to scanning
     `~/.claude/projects/*/*.jsonl` (closing turns of each session in the window), stating
     that other agents and cloud sessions were not covered.
   - **Cite what you used** in the reconciliation section as `sessione:<first 8 chars of the
     session id>` next to each judgment (Phase 3's `consuntivo-check` refuses a
     reconciliation with no citation).
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
   cognitive-heavy with no deliverable (validated 2026-07-27: a session weighed as
   a build produced design reasoning but no code, and the user called it wasted time).
   One line per mismatch, feeding Phase 3's report; a mismatch repeated across weeks on the
   same recurring commitment is surfaced explicitly. Register each one as a learning-signal
   row (origin: reconciliation, class: load misjudged, phase 2; see "Learning signal"); the
   text is the user's words if they named it, else the mismatch line with the commitment and
   the week.

Output of this sub-phase: a short reconciliation summary (what was done, what wasn't,
what re-enters as open, and any load mismatch) — feeds directly into Phase 3's report.

### Phase 1b — New material

- **Tasks / projects / quarterly** (`task_tool`): reuse planning-review-system's collect:
  open tasks with due dates, active projects and their status, quarterly goals and progress,
  from `task_tool` per config. If the adapter has a yearly plan, read the current quarter's
  section from there: it is the source of truth for quarterly goals, not the Notion
  `goals_page_url` fallback. Read also the month priorities section of the month note:
  each focus of the week must serve one of those priorities.
- **Email** (`email_tool`): scan the last 7 days (config `email_scan_labels`, default
  INBOX; apply `email_exclude_patterns`). Extract only actionable items with a date or
  a decision — not newsletters.
- **Calendar** (`calendar_tool`): read every event already on the target week. These are
  existing commitments — they get weighed too (Phase 2), not just worked around.
- **Open deadlines** (deadlines other systems keep in their own files: project notes,
  pricing-agent proposals): run the adapter's `deadlines` for the target Monday. Every row
  (overdue included) is a hard deadline candidate: weigh it in Phase 2 and list it in Phase
  3's "Hard deadlines of the week" with its local time; report every problem it lists.
- **Recent agent sessions**: run `sessions` again with `--since <2 weeks ago>` (same staleness
  rule and fallback as Phase 1a) to surface threads still open (a build mid-flight, a
  deferred follow-up) that deserve a slot this week. Use metadata and titles to spot open
  threads, not to judge delivery.
- **Future directions** (the file at `future_directions_path` in the config, if set and it
  exists): for each direction, is there a new real signal this week (an email, a session,
  a contact)? Is any direction dead, or is a new one emerging from what the user said? Pick
  at most one item from its Radar section that could get a small slot this week. Report
  proposed edits to the file in Phase 3; never edit directions without the user's OK.
- **Scheduled-task housekeeping** (when the scheduled-tasks tool is available; read only):
  list the scheduled tasks and keep for Phase 3 every task with `enabled: false` whose
  `fireAt` or `lastRunAt` is older than `scheduled_task_stale_days`, plus every folder in
  `~/.claude/scheduled-tasks/` the list does not return (orphan). One line each: task id, last
  run, the versioned prompt it points to. When the sessions tool is available, also count the
  un-archived sessions older than `scheduled_task_stale_days`. Nothing is deleted here.

Output of Phase 1 is raw material plus the reconciliation summary, not yet a plan. Do
not schedule anything here.

---

## Phase 2 — Weigh & Prioritize (the core)

Weigh **every** event: the ones you'd create, the ones already on the calendar, AND the
unresolved captures from Phase 1a. An old open item is not high priority for being old.

**Weigh each event by five attributes, declared before placing it:**

1. **Nature** — **BLOCK** (occupies real time, `busy`, counts toward the daily cap: "in that
   slot I'm doing this") vs **REMINDER** (no time, `free`/all-day, sits at the top of the
   day: "remember that"). There's a middle: a reminder that still implies a short task →
   occupies space but lighter (a short block: a 2h busy wall falsifies the daily count).
2. **User-time, not machine-time** — the load is measured on the user's **attention-hours**
   (supervision + checkpoint decisions), NOT the total execution time. A job that is big
   in execution-hours (e.g. building a skill: design+TDD+code = 6-8h) can be LIGHT for
   the user if it's assisted: the user approves the design (~30min), the code is HANDOFF to a
   subagent (output approved in ~15min) → real user-time ~1-1.5h scattered. Always separate
   machine-time (mine + subagent, runs while the user does other things) from user-time
   (checkpoints) and weigh the event ONLY on the second (Theory of Constraints: the plan's
   capacity is the capacity of its constraint, the user's attention).
3. **Load type** — **delegated** (a person or an agent owns it end to end; the user only
   spends the 10-15 minute checkpoint) vs **handoff** (an LLM carries it with little
   supervision: a message, an extraction, a routine to launch, the code part of an assisted
   build) vs **cognitive** (the user must be present and focused: approving a design, a strategic
   decision) vs **physical/out-of-house** (an errand). A project decomposes into phases of
   different load: weigh each phase, not the whole project.
4. **Real weight / priority** — hard deadline? legal/economic consequence? or deferrable?
5. **Where** — at the desk / out / with people.

**When genuinely in doubt about an event's nature or weight, ask the user** instead of guessing.

**Events that leave the calendar.** An existing event that should not stay (its DoD is already
reached, or it has no value this week and no real later date) is never deleted here: mark it
`[-]` for the Phase 3 proposal, with the reason and the proof (the commit, the deliverable, the
session that carried it, or the user's decision with its source). Phase 4 deletes it only
after the OK (Guard 2).

**The two work fascia — ONLY two, distinct, read from the config, never typed here:**
`work_morning_block` and `work_afternoon_block` in the life-os config; the day's cap is
`daily_work_cap_hours`, never the sum of the fasce; if a key is missing, ask the user.
The time between and outside them is life, not "free holes to fill": **never place a block of
the user's time outside these two fascia; a delegated agent run may run outside, its checkpoint
sits inside** (fixed boundary for the user's time; the only exception is the same-day hard-deadline
decision in gesture «Capacity», never planned).

**Planning gestures and the user's policy (read both before weighing anything).** The
generic gestures, each with its law and its config key, are in
`references/planning-parameters.md`: DoD, tiers, themes, capacity, stop cap, durations,
delegate cost, study, prep-run count, planning time, refusals. If `planning_rules_path` is set
and the file exists, read it too: it holds the user's policy, the exceptions to those
gestures and their why, and it wins over a gesture not marked invariant where they differ (numbers excepted: those come from the config). An invariant gesture holds even when the policy file says otherwise: report the difference in Phase 3. The axes are the
ordered month priorities (Phase 1b), not a separate list: the main axes, not the only ones.

**Capacity, with or without the rules file:** the daily cap is a ceiling, never a target
to fill (gestures «Capacity» and «Stop cap»), and there is no "park it outside the fascia" shortcut.
An event that does not fit moves to next week (a real date) if it has value, else it is
dropped; if it is already on the calendar, it becomes a `[-]` cell (above). Deferrable
meta-tooling moves to next week too.

**Ordering** (the tiers of the gestures file, then the axes as tie-break inside a tier, as
the user's policy adjusts them):
- A hard deadline of the week is placed on a day before its date, whatever its tier
  (legal/economic consequences lead). Inside tier 2, legal/economic deadlines first, then the axis.
- Then by the week's Golden Rule (the single "priority of priorities"; Keller, *The ONE Thing*:
  the one item that makes the others easier or unnecessary goes first).
- Group by theme (gesture «Themes»). Fixed events that cannot move stay; say so and put
  their checkpoint at the start of the fascia.
- Never two COGNITIVE blocks back-to-back — alternate cognitive ↔ handoff/physical/light.
  Handoff work an LLM can carry doesn't compete for focus; cognitive work is isolated and
  protected (deep work, Newport). With one theme per day the alternation happens inside the theme.

Produce, for the whole Mon-Fri grid: which event goes in which fascia on which day, each
with a one-line weighing (user-time + load type), respecting the rules above.

**End-of-Phase-2 check (before Phase 3).** Against the finished grid, check each day: planned
user-time within the «Capacity» limit, a stop cap on every cognitive and judgment block, one
theme, the tier order, every `[-]` with its proof; then re-read the user's policy file. Write
ONE line of outcome in the note (passed, or the correction made): weighing errors recur on
rules already written.

---

## Phase 3 — Report + GATE (handoff stop)

First write the week's note (see "Writing into the note" below): the collected state and
the proposed focus, marked as a proposal. This is local and reversible, and it is what
survives if the gate is never answered. Then, when the adapter has it, run
`consuntivo-check` for the target Monday: on a failing exit, read its output. A missing or
unknown session citation means Phase 1a step 2 was not done: go back and do it, then rewrite
the reconciliation section; any other reason is fixed or reported as is. Do not present the gate until
the check passes.

Then commit + push only the note, plus the learning-signal files if they changed (the adapter's
`commit`). Present a readable plan and **STOP**: do not touch the calendar and do not mark
the focus as confirmed yet (Guard 1).

Structure of the report:
- **Broken policy path** — first, only if the Config Guard found `planning_rules_path` set
  and its file missing.
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
  there with its one-line weighing (user-time + load type). Show the reasoning, not just the grid.
- **Calendar proposal in ASCII (always, with every presentation of the plan)** — a
  Mon-Fri grid with the two fascia from the config as rows, built from the same list
  Phase 4 will write, so what the user approves is what gets created or removed. Mark each cell:
  `[=]` already on the calendar (not touched), `[+]` Phase 4 will create it, `[~]` an
  existing event Phase 4 would change (say what changes and why), `[-]` an existing event
  Phase 4 would delete, and `.` free. Under the grid list every `[+]`, `[~]` and `[-]` with
  title, day, start-end, `busy`/`free`; each `[-]` also carries the event id, its reason and
  proof, and whether Phase 4 will delete it or only list it (`calendar_delete_mode`). The same
  `[-]` rows, with their ids, go into the note's events-to-delete section before the gate, each
  with a number (D1, D2, …) and state `proposto`, so a later session resumes them by id (row states: "Row states" in
  Phase 4). Show it also
  when the gate is re-presented by "Resume the gate", after re-reading the calendar.
- **Cognitive vs handoff count** — blocks per load type (Phase 2 attribute 3), as a plain
  number, to show whether the week leans cognitive or handoff.
- **Prep-runs (always, proactive)** — for every cognitive block and every delegable
  activity, the one-shot delegated run that prepares it the day before (mise en place,
  Charnas, *Work Clean*): what it produces,
  its DoD, when it fires (weekday, before the block). Mark them `(p)` in the ASCII grid, and
  each work-item loop (prompt path, fire time, gates; `references/work-item-loops.md`) `(L)`.
  Never stop at listing a problem: each one comes with a next action, and anything
  answerable from mail, chats, logs or files is looked up, not asked.
- **Scheduled tasks to delete (your OK)** — the Phase 1b housekeeping list, one line each,
  written in the note's conflicts section before the gate with a number (T1, T2, …) and state
  `proposto`,
  and the count of un-archived old sessions with the reminder «archivia, non cancellare».
- **Actionable emails** (from Phase 1, with the action + date).
- **Conflicts / notes** — anything that didn't fit, moved to next week, or needs a user
  decision, the `state` signals, planning keys on default, rules-vs-config number mismatches.
- **Where the note is** — the path of the week's note just written.

Then end with an explicit gate line:

> "Questo è il piano, già scritto come proposta in `<path della weekly>`. Dimmi OK per
> applicarlo al calendario e confermare il focus, oppure dimmi cosa cambiare.
> Se vuoi: cosa ti è sfuggito o ho pesato male?"

**Wait for explicit approval.** Do NOT proceed to Phase 4 on anything less than a clear OK.
If the user asks for changes, revise Phase 2/3 and re-present the gate. An OK covers the
`[-]` cells and the housekeeping lines only as shown; the user may approve them apart
("ok tranne il [-] di giovedì", "ok tutte / ok tranne N"). The first step of Phase 4 writes
that answer into the note (see "Row states").

Each change the user asks for at the gate, and each answer to the optional question, is
feedback: classify it and register it with origin gate before revising (see
"Learning signal"). If the OK comes and no change was asked during the whole gate,
register one neutral row (outcome: identical).

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

### Row states (first step of Phase 4)
Every `[-]` row and every housekeeping line in the note carries one state, and only the step
named here writes it:

| State | Written by | Meaning |
|---|---|---|
| `proposto` | Phase 3, before the gate | shown at the gate, no answer yet |
| `approvato` / `escluso` | this step, right after the OK | the user's answer for that row: a plain "ok" or "ok tutte" approves every `proposto` row, "ok tranne D2, T1" excludes those; until a row's action has run, a later answer may still turn `approvato` into `escluso` |
| `elencato` | "Calendar deletions", propose mode | listed for the user to delete by hand |
| `fatto` | "Calendar deletions", apply mode; "Scheduled-task housekeeping" | deleted (or already gone) |

`escluso`, `elencato` and `fatto` are final: no later step or resume changes them or acts on
them. This step runs first in Phase 4, before the calendar export. Commit the note after writing the answers, before any deletion. Phase 4 acts only on
rows in state `approvato`; a row still `proposto` is never acted on.

### Calendar deletions
Only rows in state `approvato`, and only by event id (never by title search). The
note's events-to-delete section holds one row per event id: update that row, never
append a second one, so a resumed gate is safe.

- **`calendar_delete_mode: propose`** (the default): delete nothing. Set each `approvato` row to
  `elencato` (da cancellare a mano) and say «[N] eventi da cancellare
  a mano: elenco nella weekly». This is the dry-run: keep it until the user has seen the
  proposals be right and sets `apply`.
- **`calendar_delete_mode: apply`**: for each `approvato` id, first get the event. If it is
  already gone, mark the row `fatto` and move on. If its title, start or end differ from the
  row, set the row back to `proposto` and ask again: the proof was about another event. Else write its backup in the row (id, title,
  start-end, description, calendar, attendees, organizer, recurrence; for a recurring event
  delete only that instance) and commit the note, so the event can be recreated from
  it. Then delete it with `sendUpdates: none`, re-list the week, confirm the id is gone, and
  mark the row `fatto`. Report «[N] eventi cancellati, backup nella weekly».

### Scheduled-task housekeeping
Only in a session the user opened (an unattended scheduled run cannot delete a scheduled
task and must not try), and only the lines in state `approvato`, after re-listing the tasks
(a task already gone is `fatto`; one no longer disabled or no longer older than
`scheduled_task_stale_days` goes back to `proposto`): make a `tar` backup of
`~/.claude/scheduled-tasks` first, then delete the approved tasks and remove the approved
orphan folders, and set each line to `fatto` in the note. Sessions are archived, never
deleted. In an unattended run, leave those lines `approvato`: the session that resumes the
gate does them (see "Resume the gate").

### Prep-runs and work-item loops
The OK covers the prep-runs and the `(L)` loops in the report: each loop is a one-shot weekday
task launching a versioned `/loop` prompt, linked from its event (`references/work-item-loops.md`).

### Confirm the focus in the note
Edit the focus section in the week's note: replace the proposal marker with the
focus the user approved (with their changes, if any). Touch only that section and the
`updated:` date in the frontmatter.

If the user asks for changes before the OK, update the proposal in the note too, then
re-present the gate.

### Record the Decision
When the adapter has `confirm-focus`, run it with the approved items (max 3): the adapter's
state check and briefing read that record, not the note. Then run `state`: it must say the
focus is confirmed. If it does not, say so instead of reporting success.

### Commit
Commit + push the note and the Decision record after confirming the focus (only those
files, plus the learning-signal files if they changed).

---

## Resume the gate (any later session)

The note and its commit exist before the gate on purpose, so the gate survives an idle
or closed session. A later session resumes it from the note, without redoing Phases 1-2:

- **Trigger**: "ok weekly", "applica la weekly", "riprendi la weekly", or the briefing
  signal `focus della settimana non confermato`.
- Read the most recent week note whose focus section still carries the proposal marker, or
  that still has rows in state `approvato` or `proposto` (normally the current week, not the
  next Monday's). If its focus still carries the marker,
  re-present the Phase 3 report from the note (re-read the calendar for the week first: it
  may have changed, and say what changed; the rows still `proposto` are asked again, the rows
  in a final state are shown with their state and not asked), wait for the OK, then run Phase 4.
  Phase 4 is idempotent, so a repeated resume is safe.
- If the focus is already confirmed (the Decision record says so) but the note still has rows
  in state `approvato`, run only the Phase 4 steps for those rows; rows still `proposto` are
  shown and asked once more. Otherwise do nothing and say so.

---

## Writing into the note

**If the adapter applies:** the week note is the adapter's, created by `open-week` or already
there: read it first and edit sections in place with the Edit tool. Never overwrite the file,
never rewrite its frontmatter (only bump `updated:`), never delete what a person wrote there.

Write the plan only into the five fixed sections the adapter names (the vault's rhythm contract):

- reconciliation section — from Phase 1a: done / partial / not touched, with evidence, where
  each unresolved capture landed this week, and load mismatches (one line each).
- calendar section — from Phase 1b: the week's events and hard deadlines (dated, with
  consequence), and what the next two weeks already hold.
- captures section — open captures and inbox items, each with a proposed title and folder.
  Keep what `open-week` pre-filled; add, do not duplicate.
- projects section — projects past deadline, stalled, or without a goal, each with the
  suggested action.
- focus section — at most three items, in the adapter's item format; the first one is the
  week's Golden Rule. Before the gate the section opens with the proposal marker: keep the
  one `open-week` pre-fills, or write the adapter's dated proposal line. Replace the
  pre-filled items, do not append a second list. Phase 4 replaces the proposal line once
  the user approves.

Each deliverable is cited in the adapter's deliverable format, so a later drift check can see it.
Extra sections are allowed after the fixed ones, for what the contract does not cover: the
adapter lists their names (grid with the two fascia and their times from the config, one
weighing line per event followed by the same ASCII calendar proposal shown in the report;
cognitive/handoff count; actionable emails; conflicts; events to delete). Priorities are
written only in the focus section, never in an extra section.

No external send happens here: email and messages stay drafts.

**If `notes_tool = vault_filesystem` but `open-week` is not available** (Phase 0 skipped):
the note path and section names still come from the adapter; create the note with the Write tool, frontmatter `doc_type: log`, `created`/`updated` = today,
`week: <ISO week>`, then the same five fixed sections and the extras.

**Without the vault adapter** the five fixed sections are, in order: `## Reconciliation`,
`## Calendar`, `## Captures`, `## Projects`, `## Focus` (the proposal marker is the words
"to be confirmed"), in the user's language.

**If `notes_tool = notion`:** create/update the week's page under `output_page_url` with
the same sections. **If `notes_tool = none`:** present the plan in chat as formatted markdown.

---

## Learning signal

Every piece of feedback the user gives on the planner becomes one row of an append-only log;
the counts decide what this skill adapts to. Available only when the adapter has a learning
signal, else skip; commands, class values and exit codes are in the adapter.

**Register: whenever the user gives feedback on the planner, at any point** (the gate, the
retro, a later chat, another session), register it before moving on, with the user's words
verbatim. One row per request, not per message and not per section touched: split a message
that carries two requests.

- Classes (closed list, values in the adapter): source missed (with which source), wrong
  weight, deadline missed, load misjudged, wrong work window, too long, format; "other"
  never counts. Do not force a class to make it count.
- The phase is the one whose output was wrong. A gate approved with no change: one row with
  outcome identical.

**Read (Phase 0):** the count returns `adatta`, `promuovi`, `richieste`, `problemi`.

- `adatta` (same place and class at least 3 times): read those rows' original text and
  apply the correction in that phase during this run; say it in ONE line in the report.
- `adatta` empty: change nothing and say nothing about the signal. `adatta` never changes the Guards, nor an invariant gesture.
- `promuovi` (at least 5 times over at least 14 days): propose to the user, in the Phase 3
  report, the edit that would make the correction permanent, where it belongs: a generic
  gesture in this skill, a number in the config, an exception of this user in the policy
  file (`planning_rules_path`). Never make the edit yourself. Once proposed, mark it as
  suggested (the adapter says where), so it is not proposed again.
- `problemi` not empty: name them in one line and go on. Never rewrite past rows. If the
  command fails, plan without adaptation and say so in one line.

The log is versioned: commit it with the run's next commit.

---

## Trigger Mapping

- "pianifichiamo la settimana" / "prepara la settimana" → full run, Phases 0-4.
- "/weekly-planner" → full run.
- "ok weekly" / "applica la weekly" / "riprendi la weekly" → "Resume the gate" section.
- Monday planning routine → full run (the routine only starts the skill, all logic and all guards are here).
