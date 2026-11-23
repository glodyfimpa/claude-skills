# Planning parameters and gestures

Read in the Config Guard (the keys) and in Phase 2 (the gestures). The skill holds the
generic gesture; the config holds the user's number; the planning rules file
(`planning_rules_path`) holds the user's policy: exceptions to these gestures and why.
A number lives only in the config: if the rules file states one the config also holds,
the config wins and the mismatch is reported in Phase 3.

## Keys (frontmatter of the life-os config)

| Key | Meaning | Default when missing |
|---|---|---|
| `planning_rules_path` | the user's planning policy file | none: plan with the gestures below only |
| `rhythm_review_path` | the procedure that owns the monthly and quarter levels | none: only name the drafts Phase 0 opened |
| `future_directions_path` | the user's list of future directions (Phase 1b) | none: skip that source |
| `capacity_pct` | share of `daily_work_cap_hours` that gets planned | 80 |
| `buffer_hours` | hours per day left unplanned for the unexpected, inside the cap | 1 |
| `hard_deadline_max_hours` | the most a day may reach, only for a hard deadline, never planned ahead | `daily_work_cap_hours` (no overrun allowed) |
| `study_hours_week` | unstructured study or experiment time per week, no deliverable | 0 (off) |
| `prep_run_threshold` | prep-runs in the window from which one fixed evening routine is proposed | 3 |
| `prep_run_window_days` | the window for that count, in days | 21 |
| `planning_max_hours` | the most this planning session may last | 2 |
| `calendar_delete_mode` | `propose`: approved `[-]` events are only listed for manual deletion; `apply`: Phase 4 backs them up in the note and deletes them | `propose` |
| `scheduled_task_stale_days` | age from which a disabled scheduled task, an orphan task folder or an un-archived session is listed for housekeeping | 7 |
| `routine_closing_path` | the closing protocol a work-item loop runs at the end of each iteration | none: the loop ends without it |

The `*_path` keys above are each absolute (a leading `~` expands to the home folder), else relative to
`vault_path`; a relative path with no `vault_path` counts as missing.

A default is a generic starting point, not a recommendation for a specific user: say in
Phase 3 which keys fell back to a default.

## Gestures (Phase 2)

Each gesture names the law it applies; change a gesture only after checking what the law loses.
A gesture marked **(invariant)** cannot be overridden by the policy file nor by the learning
signal's `adatta`; the policy wins over every other gesture where they differ.

- **DoD and deliverable on every activity** (invariant; study time excepted). An activity with no DoD is not placed: propose
  one and let the user approve it. The deliverable is written in the note as the artifact
  path, so a later drift check can see it. A calendar event whose DoD is already reached
  (check the source: git log on the path, the deliverable, the session that carried it) is
  not moved: it becomes a `[-]` cell with that proof, deleted only after the OK (the skill's
  Guard 2).
- **Tiers** (Theory of Constraints, Eisenhower): 1 in progress and closable soon, or
  unblocking other work, takes the nearest slot; 2 urgent or with a deadline, done even
  outside every axis and with no per-axis hour budget (the daily cap still applies, see
  Capacity); 3 priorities, the axes choose; 4 delegable. Inside
  a tier the lower-numbered axis wins.
- **Themes** (deep work): one theme per day when possible; activities of the same axis form
  one continuous block; the priority of priorities gets a block every day, even when the
  theme is another axis (Pareto).
- **Capacity** (invariant; time-boxing, Hofstadter): on every day, deadline days included, plan at most
  the smaller of `capacity_pct` of the daily cap and the cap minus `buffer_hours`, inside the
  fasce; delegated agent work does not count, only the user's time. A known hard deadline
  that needs more is started on earlier days, or listed as a conflict for the user. Only on
  the day itself, for that hard deadline, may the user's time reach `hard_deadline_max_hours`,
  outside the fasce if needed: a decision of that day, never written into the weekly plan.
- **Stop cap on every cognitive and judgment block** (Parkinson): each declares its maximum
  duration and what is delivered at the stop. At the stop the rest is closed or re-dated,
  never extended. Time saved is not refilled with more cognitive or judgment work.
- **Durations** (Hofstadter): estimate from similar blocks already measured and state the
  basis; no fixed default duration, not even for a short judgment.
- **Delegates cost checkpoints**: 10-15 minutes of the user's time each, never zero.
- **Study**: reserve `study_hours_week` per week with no deliverable, when the key is above 0;
  it sits inside the fasce and counts toward the planned capacity.
- **Prep-run count** (YAGNI, only when the notes adapter has `count-prep-runs`): count the
  prep-run prompts born in the last `prep_run_window_days` days with that operation.
  From `prep_run_threshold` up, propose one fixed evening routine that runs the prep-runs
  named in tomorrow's events; below it, propose nothing.
- **Planning time** (Parkinson): this session lasts at most `planning_max_hours` and builds
  no tools; every tool or system idea that comes up goes to the end of the note, under a
  "dedicated sessions" list, with a deliverable and a DoD.
- **The note follows the focus**: a later session that closes or decides a focus item
  updates its line in the week's note before closing.
- **Refusals**: besides the DoD rule above, an activity outside every axis is
  dropped only when it has neither urgency nor a deadline.
