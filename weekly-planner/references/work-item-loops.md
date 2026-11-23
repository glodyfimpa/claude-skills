# Work items as loops (Phase 3 report, Phase 4 apply)

A multi-step work item in the plan (more than one session of work, or a human gate in the
middle) does not wait for the user to launch it. It becomes a self-paced `/loop` run started by a
one-shot scheduled task. Validated on five runs, 13-20 Oct 2026 (all fired, resumed from their
state files, reached `main` with green suites, kept the dependency order).

Scheduling rules (event vs run, shell plus versioned prompt, weekdays only for runs with a
gate, allowlist and app-open checks, peak hours, closing protocol) live in the user's scheduling
gotchas skill, when one is installed (for example `gotcha-routine-scheduling`). Read it before
creating the task; do not restate its rules in the prompt. Vault paths and helper commands below
are operations of the vault adapter (`adapter-vault.md`).

## In the Phase 3 report

List each loop before the gate, so the OK covers only what the user saw: item, prompt path, fire
time, gates. Mark it `(L)` in the ASCII grid.

## Per work item (Phase 4, after the OK)

1. **Prompt.** Reuse the item's versioned prompt if one exists, otherwise write
   `<slug>.prompt.md` in the adapter's `loop-prompt-dir` (the gotcha's standard), with the state
   file `state-<slug>.md` next to it (created on the first iteration, versioned). The prompt holds:
   - goal in one sentence, and why it matters this week;
   - the iteration protocol: pull, read state, do the next step, update state, commit, push;
   - the numbered steps, each with its done condition and its planned end date;
   - the human gate(s): which step stops, what is presented, what answer unblocks it;
   - the hard constraints below.
2. **One loop per work item.** It ends when the state file marks the last step done. When the
   item spans several blocks or days, each later block is a new one-shot task that resumes the
   same state file. A loop that depends on another one fires after the planned end date of the
   last step it waits for, and checks that step is done in the other state file before starting.
3. **Slot.** Pick the time from the user's real fasce for that day (calendar and
   `life-os.local.md`), not a fixed hour: a gate fired while the user is away waits for them anyway.
   Never fire in peak hours: check the slot with the adapter's `peak-hours` operation. If it is
   peak, fire before 13:00 the same day and let the loop stop at its gate; the user answers at
   the block.
4. **One-shot task.** `create_scheduled_task` with `fireAt` at the slot. The task file is a
   shell: it invokes the `loop` skill with "Read <prompt path> and execute one iteration as it
   describes", then, when `routine_closing_path` is set in the config, reads and executes that
   closing protocol; when it is not set, the loop's last line says «nessun protocollo di
   chiusura: routine_closing_path non impostata». All logic stays in the versioned prompt.
5. **Event.** Create the task first, then `update_event` on the item's calendar block (created
   by the calendar export) to add the prompt path and the taskId to its description, so the user
   sees what runs and can relaunch it by hand.

## Hard constraints every loop prompt carries

- **Commit scoped:** `git commit -m ... -- <paths>` with only the files this run wrote; other
  sessions share the checkout.
- **Ask once, at the end.** Reversible steps (vault text, code with tests, git) are done and
  reported, not asked (Nielsen: undo over up-front confirmation; Bezos: two-way doors are
  delegated, one-way doors are deliberated). A follow-up of a class the user already approved is covered by that
  approval. Questions that really need the user (irreversible, outward-facing, money, data to third
  parties) are collected and asked once, with a recommendation, not one per turn.
- **Read the state file before asking.** The gate may have been answered in another session
  (for example the day's orchestrator) and written there.
- **Closing retrospective:** reversible diffs are applied and reported; only irreversible or
  outward-facing ones wait for a yes (the closing protocol at `routine_closing_path`, if set).
