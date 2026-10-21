# Work items as loops (Phase 4)

A multi-step work item in the approved plan (more than one session of work, or a human gate in
the middle) does not wait for Glody to launch it. It becomes a self-paced `/loop` run started by
a one-shot scheduled task at the block's time. Validated on five runs, 13-20 Oct 2026 (all
fired, resumed from their state files, reached `main` with green suites, kept the dependency
order); assessment in the vault at
`areas/ai-automation/routines/state-review-routine-loop-pattern.md`.

Scheduling rules (event vs run, shell plus versioned prompt, weekdays only for runs with a
gate, allowlist and app-open checks, peak hours) live in `gotcha-routine-scheduling`. Read it
before creating the task; do not restate its rules in the prompt.

## Per work item

1. **Prompt.** Reuse the item's versioned prompt if one exists, otherwise write one in the
   vault next to the work (`prompt-<slug>-<date>.md`). It contains:
   - goal in one sentence, and why it matters this week;
   - the state file path (`state-<slug>.md`, created on the first iteration, versioned) and
     the iteration protocol: pull, read state, do the next step, update state, commit, push;
   - the numbered steps, each with its own done condition;
   - the human gate(s): which step stops, what is presented, what answer unblocks it;
   - the hard constraints below.
2. **Slot.** Pick the time from Glody's real fasce for that day (calendar and
   `life-os.local.md`), not a fixed hour: a gate fired while he is away waits for him anyway.
   Off-peak: before 14:00 on weekdays. A loop that depends on another one starts on a later
   day, after the first one's planned end.
3. **One-shot task.** `create_scheduled_task` with `fireAt` at the slot. The task file is a
   shell: it invokes the `loop` skill with "Read <prompt path> and execute one iteration as it
   describes", then the vault's `routines/routine-closing.md`. All logic stays in the
   versioned prompt.
4. **Event.** The calendar block for the item gets the prompt path and the taskId in its
   description, so Glody can see what runs and relaunch it by hand.

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
  outward-facing ones wait for a yes (see `routine-closing.md`).
