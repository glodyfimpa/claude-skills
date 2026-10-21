# Work items as loops (Phase 3 report, Phase 4 apply)

A multi-step work item in the plan (more than one session of work, or a human gate in the
middle) does not wait for Glody to launch it. It becomes a self-paced `/loop` run started by a
one-shot scheduled task. Validated on five runs, 13-20 Oct 2026 (all fired, resumed from their
state files, reached `main` with green suites, kept the dependency order); assessment in the
vault at `areas/ai-automation/routines/state-review-routine-loop-pattern.md`.

Scheduling rules (event vs run, shell plus versioned prompt, weekdays only for runs with a
gate, allowlist and app-open checks, peak hours, closing protocol) live in
`gotcha-routine-scheduling`. Read it before creating the task; do not restate its rules in the
prompt.

## In the Phase 3 report

List each loop before the gate, so the OK covers only what Glody saw: item, prompt path, fire
time, gates. Mark it `(L)` in the ASCII grid.

## Per work item (Phase 4, after the OK)

1. **Prompt.** Reuse the item's versioned prompt if one exists, otherwise write
   `areas/<domain>/routines/<slug>.prompt.md` (the gotcha's standard), with the state file
   `state-<slug>.md` next to it (created on the first iteration, versioned). The prompt holds:
   - goal in one sentence, and why it matters this week;
   - the iteration protocol: pull, read state, do the next step, update state, commit, push;
   - the numbered steps, each with its done condition and its planned end date;
   - the human gate(s): which step stops, what is presented, what answer unblocks it;
   - the hard constraints below.
2. **One loop per work item.** It ends when the state file marks the last step done. When the
   item spans several blocks or days, each later block is a new one-shot task that resumes the
   same state file. A loop that depends on another one fires after the planned end date of the
   last step it waits for, and checks that step is done in the other state file before starting.
3. **Slot.** Pick the time from Glody's real fasce for that day (calendar and
   `life-os.local.md`), not a fixed hour: a gate fired while he is away waits for him anyway.
   Never fire between 14:00 and 20:00 (peak). If the block sits in that window, fire before
   14:00 the same day and let the loop stop at its gate; Glody answers at the block.
4. **One-shot task.** `create_scheduled_task` with `fireAt` at the slot. The task file is a
   shell: it invokes the `loop` skill with "Read <prompt path> and execute one iteration as it
   describes", then reads and executes
   `/Users/figlody_mac/Documents/brain/areas/ai-automation/routines/routine-closing.md`. All
   logic stays in the versioned prompt.
5. **Event.** Create the task first, then `update_event` on the item's calendar block (created
   by the calendar export) to add the prompt path and the taskId to its description, so Glody
   sees what runs and can relaunch it by hand.

## Hard constraints every loop prompt carries

- **Commit scoped:** `git commit -m ... -- <paths>` with only the files this run wrote; other
  sessions share the checkout.
- **Ask once, at the end.** Reversible steps (vault text, code with tests, git) are done and
  reported, not asked. A follow-up of a class Glody already approved is covered by that
  approval. Questions that really need him (irreversible, outward-facing, money, data to third
  parties) are collected and asked once, with a recommendation, not one per turn.
- **Read the state file before asking.** The gate may have been answered in another session
  (for example the day's orchestrator) and written there.
- **Closing retrospective:** reversible diffs are applied and reported; only irreversible or
  outward-facing ones wait for a yes (`routine-closing.md`, section 1).
