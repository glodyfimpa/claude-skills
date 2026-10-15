# Phase 1a — reading the week's diary

The evening close writes one line per working day in
`<vault_path>/.brain/weekly/<monday>-diario.md` (format and rules: the daily cycle design spec,
DiaryLine). For last week:

1. Read last week's diary. Each line gives intervals, active minutes vs the cap, blocks done vs
   the day's theme, inbound requests and uncovered agents.
2. Do not trust the line: recompute each day with
   `PYTHONPATH=<vault>/.brain/system <vault>/.brain/system/.venv/bin/python -m day_cycle.activity --vault <vault> --date <day>`
   and flag in `## Consuntivo` every day whose `active_minutes` differs from the line by more
   than 15 minutes, and every line that ends with `· corretta` (Glody's edit wins, say so).
3. Read the sessions (step 2 of Phase 1a) only for: days without a line, days flagged in 2,
   and commitments of `## Focus settimana` that no line covers.
4. Report days over the cap (`daily_work_cap_hours`) and inbound requests marked `aggiunta`
   as load mismatches.
5. When creating the new week's note, write in `## Appunti della settimana` the line
   `Diario: [[<monday>-diario]]` (never in Focus or Consuntivo: `weekly_drift` watches those).
