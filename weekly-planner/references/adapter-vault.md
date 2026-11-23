# Vault adapter

The only file of this skill that knows a vault's layout. `SKILL.md` names an operation
(`open-week`, `consuntivo-check`, ...); this file says how the vault runs it. Swap this
file to plug the skill into a different notes system; the core does not change.

**Applies when** `notes_tool = vault_filesystem` and `vault_path` is set. The note paths and
section names below then always hold. The helper operations need more: each is available only
when its module exists under `<vault_path>/.brain/system/` (the rhythm chain: `vault_lint/review/`;
contract in `<vault_path>/.brain/system/schema/ritmi.md`), else it is "not available" and
`SKILL.md` takes its fallback branch.

All Python helpers run with the vault's venv:

```bash
V=<vault_path>
PY="env PYTHONPATH=$V/.brain/system $V/.brain/system/.venv/bin/python"
```

If the venv is missing, every helper operation fails: report it, never emulate the helper.

## Notes and their sections (the rhythm contract)

| Name in SKILL.md | In the vault |
|---|---|
| week note | `$V/.brain/weekly/<Monday>-weekly.md` (filename = the Monday date, never ISO `YYYY-Www`) |
| last week's note | `$V/.brain/weekly/<previous Monday>-weekly.md` |
| month note | `$V/.brain/monthly/<YYYY-MM>-monthly.md` |
| yearly plan | `$V/.brain/system/piano-annuale-<year>.md`, the current quarter's section (source of truth for quarterly goals) |
| month priorities section | `## Priorità del mese` of the month note (ordered: these are the axes) |
| focus section | `## Focus settimana` (older notes: Golden Rule and priorities) |
| reconciliation section | `## Consuntivo` |
| calendar section | `## Calendario` |
| captures section | `## Appunti della settimana` |
| projects section | `## Progetti da guardare` |
| proposal marker | the line `review apri` pre-fills ("Proposta dalle priorità del mese …, da confermare …"), or `Proposta del <date>, da confermare:`; the marker is the words `da confermare` |
| extra sections | `## Griglia Lun-Ven`, `## Bilancio cognitive/handoff`, `## Email azionabili`, `## Segnalazioni / conflitti`, `## Eventi da cancellare` |
| deliverable citation | the artifact path in backticks or a `[[wikilink]]`: the vault's `weekly_drift` check watches only cited artifacts |
| diary | `references/adapter-vault-diary.md` |

The five fixed sections are, in order: reconciliation, calendar, captures, projects, focus.
Write the focus items as `N. <focus> — serve: <priorità del mese>`.

## Operations

| Operation | Command | Exit codes and output |
|---|---|---|
| `open-week` | `$PY -m vault_lint.review apri $V --date <Monday>` | 0: created the levels that were due (week note, and monthly or quarter drafts if missing), prints their paths. 2: the week note exists and nothing else is due. Other: stop and report; never create the note by hand. |
| `state` | `$PY -m vault_lint.review stato $V --date <Monday>` | read-only signals for the report; says whether that week's focus is confirmed (without `--date` it looks at the current week) |
| `deadlines` | `$PY -m vault_lint.review scadenze $V --date <Monday> --giorni 21 --json` | rows in `scadenze` (overdue included) are hard-deadline candidates; report every `problemi` entry. 2: bad arguments |
| `consuntivo-check` | `$PY -m vault_lint.review consuntivo-check $V --date <Monday>` | 0: the reconciliation section cites at least one real session as `sessione:<first 8 chars of session_id>`. Other: read the output; a missing or unknown citation means Phase 1a step 2 was skipped, any other reason is reported as is. When the aggregator has no session in the window the section may carry the token `sessioni:nessuna` |
| `sessions` | `$PY -m agent_activity.collect --vault $V`, then `$PY -m agent_activity.query --vault $V --since <ISO UTC>` | run `collect` first (its scheduled run is daily). Returns `sessions` (id, agent, project, title, turns, `closing_excerpt`, `source_path`), `collector_staleness_days`, `warnings`. Not available when `$V/.brain/system/agent_activity/` is missing |
| `confirm-focus` | see "Record the Decision" below | writes `$V/.brain/system/decisions/focus-week-<ISO week>.yaml` with `status: confirmed` |
| `count-prep-runs` | the command under the table | the number of prep-run prompts born in the window (prep-run prompts are named `prompt-prep-*.md`; their events carry `Prep:` in the title); 0 is a valid answer |
| `peak-hours` | `$PY -m vault_lint.peak_hours check <ISO datetime>` | says whether a slot is in the peak window (defined once, in Pacific time, in that module) |
| `loop-prompt-dir` | `$V/areas/<domain>/routines/` | where a work-item loop's prompt `<slug>.prompt.md` and its `state-<slug>.md` live |
| `commit` | scoped commit on the vault's default branch: `git -C $V commit -m ... -- <paths>`, then push | other sessions share the checkout |

`count-prep-runs` (copy it as is; the count is 0 when no prompt was born):

```bash
git -C $V log --since="<prep_run_window_days> days ago" --diff-filter=A --name-only \
  --pretty=format: -- '*prompt-prep-*.md' | sort -u | sed '/^$/d' | wc -l
```

### Record the Decision (`confirm-focus`)

`state` and the vault's briefing read the confirmed Decision YAML of the current ISO week, not
the note: editing only the note leaves them saying the focus is not confirmed.

```bash
$PY - <<'EOF'
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

It refuses an empty focus. Then run `state`: it must say the focus is confirmed.

## Learning signal

Available when `$V/.brain/system/learning_signal/weekly.py` exists (README next to it).
Command: `$PY -m learning_signal.weekly <command>`; the log and `suggeriti.json` sit next to it
and are versioned.

```bash
$PY -m learning_signal.weekly registra --origine gate|retro|consuntivo --classe <class> \
  --fase 0|1a|1b|2|3|4 [--fonte <source>] [--esito identica] --testo - <<'EOF'
<the user's words, verbatim>
EOF
```

`--testo -` reads the heredoc verbatim: apostrophes break `--testo='…'`.

| Name in SKILL.md | Value for `--classe` |
|---|---|
| source missed (add `--fonte sessione\|mail\|calendario\|nota\|scadenza\|altro`) | `fonte-mancata` |
| wrong weight | `peso-sbagliato` |
| deadline missed | `scadenza-mancata` |
| load misjudged | `carico-stimato-male` |
| wrong work window | `fascia-sbagliata` |
| too long | `troppo-lungo` |
| format | `formato` |
| other (never counts) | `altro` |

Origins: `gate` (at the gate), `retro`, `consuntivo` (load mismatches of Phase 1a).
`$PY -m learning_signal.weekly conta` returns `adatta`, `promuovi`, `richieste`, `problemi`
(exit 1 when `problemi` is not empty). Exit 2 on `registra` = refused, reason on stderr;
"already registered" = nothing to do.
Marking a `promuovi` proposal as suggested: add `"<dove>:<classe>"` to the JSON list in
`suggeriti.json` next to the log (create it if missing).
