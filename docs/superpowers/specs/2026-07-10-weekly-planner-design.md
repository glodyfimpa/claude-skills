---
title: weekly-planner — design
date: 2026-07-10
status: approved-pending-review
supersedes_partial: areas/tooling/plugins/life-os/docs/weekly-planner-NEXT.md
---

# weekly-planner — design

Skill che pianifica la settimana di Glody: raccoglie lo stato (task, progetti,
quarterly, email, sessioni, calendario), **pesa e prioritizza** gli impegni, presenta
un report leggibile, si ferma al gate umano, e solo dopo l'OK applica il piano sul
calendario e scrive il weekly nel vault.

Nasce dal punto di ripartenza `life-os/docs/weekly-planner-NEXT.md` (scope calibrato
2026-07-06). Questo design **corregge** due affermazioni di quel doc, verificate contro
il codice reale il 2026-07-10 (vedi §"Correzioni al doc NEXT").

## Scope

**IN** (questo design):
- Skill `weekly-planner` in `claude-skills`, facade a 4 fasi, invocabile a mano e da routine.
- Estrazione del **solo nocciolo identico** condiviso tra le 3 skill life-os.
- Command trigger in `life-os/commands/weekly-planner.md`.
- Routine `pianificazione-settimanale` (scheduled-task dentro l'app), lunedì 09:33.
- `sync-skills.sh` aggiornato per trasportare weekly-planner.

**OUT** (rimandato, con trigger esplicito — invariato dal doc NEXT):
- Refactoring life-os a 3 livelli → nessun trigger attivo.
- Adapter Pattern per tool diversi → trigger: secondo tool reale (es. Outlook).
- Strategy Pattern per regole iniettabili → trigger: secondo utente reale.
- Taglio core/config open-core → trigger: decisione di prodotto esplicita di Glody.

## Correzioni al doc NEXT (verificato sul codice 2026-07-10)

Il doc NEXT (2026-07-06) affermava che Config Guard e Vault Filesystem Mode fossero
"già IDENTICI in planning-review-system e time-energy-manager". **Falso oggi:**

| Blocco | doc NEXT | realtà 2026-07-10 |
|---|---|---|
| Config Guard | "identici" | analoghi: 6 divergenze (time-energy ha `calendar_tool`, schedule, work-hours) |
| Vault Filesystem Mode | "identici" | divergenti: 130/210 righe diverse (weekly-file vs daily-files, funzioni Python diverse) |

Conseguenza: **non** si estraggono i blocchi interi (sarebbe astrarre l'analogo =
over-engineering). Si estrae **solo il nocciolo davvero identico** (§Estrazione).

## Topologia dei repo

Due repo git distinti, entrambi nested nel vault brain:

- **`areas/tooling/skills/claude-skills`** = fonte di verità di TUTTE le skill.
  Qui vivono: la skill `weekly-planner/SKILL.md`, il nocciolo condiviso in
  `_shared-refs/`, e le fonti di planning-review-system + time-energy-manager.
- **`areas/tooling/plugins/life-os`** = plugin che impacchetta 2 (poi 3) skill +
  command + config. Le sue `skills/*/` sono **copie generate** da `sync-skills.sh`.

Branch di lavoro:
- claude-skills: `feat/weekly-planner` (da creare) → PR verso `origin/main`.
- life-os: `feat/weekly-planner` (già creato, 1 commit residuo Vault-FS) → PR verso `origin/main`.

## Estrazione condivisa (solo il nocciolo identico)

Tre frammenti sono **identici parola-per-parola** nelle skill esistenti e diventerebbero
la 3ª copia con weekly-planner:

1. **Config lookup** (~8 righe): "cerca config in `.claude/life-os.local.md` poi
   `~/.claude/life-os.local.md`, usa il primo".
2. **Source resolution** (~6 righe): `read_life_os_mode()` + `resolve_source()`.
3. **Language** (~3 righe): rispondi nella lingua del campo `language`.

Vivono in `claude-skills/_shared-refs/`:
- `config-lookup.md`
- `source-resolution.md`
- `language.md`

**Come le skill li usano (traduzione onesta di DRY al registro delle skill):** un
SKILL.md è un prompt markdown, non ha `import`. L'LLM non "risolve" un rimando da solo.
Quindi ogni skill che usa il nocciolo mette una riga esplicita:

> **Config lookup:** apri e segui `_shared-refs/config-lookup.md`.

Questo è il massimo DRY realizzabile *rispettando il packaging*: una fonte, N citazioni
esplicite. NON si mette `_shared-refs/` a livello plugin (il sync non lo trasporta →
link rotto). NON si duplica il testo inline (viola DRY). Il resto di Config Guard e
Vault-FS resta per-skill (diverge per dominio).

**Vincolo sync:** `sync-skills.sh` deve copiare `_shared-refs/` in
`life-os/skills/_shared-refs/` (oggi copia solo per-skill SKILL.md + references/).
Le tre skill in life-os citeranno `../_shared-refs/config-lookup.md` (path relativo a
`skills/`). Verificare che il path regga sia in claude-skills sia in life-os.

**Migrazione delle 2 skill esistenti:** planning-review-system e time-energy-manager
sostituiscono il nocciolo inline con la citazione a `_shared-refs/`. Le loro parti
divergenti restano invariate. Test a guardia: i test esistenti in SBM
(`tests/skills/`) devono restare verdi dopo la sostituzione.

## La skill weekly-planner — 4 fasi

Facade che orchestra. **Nessun nuovo codice Python**: riusa
`life_os.weekly_review.append_weekly_review_sections` (esiste, test verdi) e lo Step 4.5
calendar export di time-energy.

### Fase 1 — Collect
Riusa il collect di planning-review-system (task/progetti/quarterly via `task_tool`) +
scan Gmail (`email_tool`) + calendario (`calendar_tool`, eventi della settimana) + scan
sessioni Claude ultime 2 settimane. Config via nocciolo condiviso.

### Fase 2 — Weigh & Prioritize (NUOVO — il cuore della skill)
Applica `memory/feedback_weigh_every_calendar_event.md` alla lettera. Per OGNI evento
(creato o trovato) dichiara 5 attributi: **natura** (blocco/promemoria/via-di-mezzo),
**tempo-Glody** (ore-attenzione ai checkpoint, NON tempo-macchina), **tipo di carico**
(handoff/cognitivo/fisico), **peso/priorità** (scadenza dura?), **dove**.
Regole dure:
- Fasce di lavoro SOLO 10-12 e 16-18 (due isole, non 10-18 continuo). Mai eventi di
  lavoro fuori fascia.
- Le 4h si riempiono pesando, non si svuotano parcheggiando fuori fascia.
- Mai due cognitivi back-to-back; alterna cognitivo ↔ handoff/leggero.
- Ordina per scadenza dura, poi Golden Rule della settimana.
- Nel dubbio sul peso di un evento → chiedi a Glody, non indovinare.

### Fase 3 — Report + GATE handoff
Presenta riepilogo leggibile: scadenze dure, Golden Rule, priorità ordinate, griglia
Lun-Ven con una riga di pesatura per evento (tempo + tipo), email azionabili, conflitti.
Poi **STOP**. Aspetta l'OK esplicito di Glody. NON tocca il calendario prima.

### Fase 4 — Apply (post-OK)
Solo dopo l'OK:
- Calendario: riusa lo Step 4.5 export di time-energy (crea/sposta eventi, `sendUpdates: none`).
- Vault: scrive `<vault_path>/weekly/YYYY-MM-DD-weekly.md` (data del lunedì — **non**
  ISO `YYYY-Www`, vedi §Convenzione file) via `append_weekly_review_sections`.
- Commit/push del weekly nel vault (vault-autosave o commit esplicito).

## Convenzione file weekly (conflitto risolto)

La skill planning-review dice `weekly/YYYY-Www.md` (ISO). Il **vault reale usa
`weekly/YYYY-MM-DD-weekly.md`** (data del lunedì, es. `2026-07-06-weekly.md`). Il vault
vince. weekly-planner scrive `YYYY-MM-DD-weekly.md`. (Nota di debito: la skill
planning-review ha la convenzione ISO stale — fuori scope qui, ma da annotare.)

## Command trigger (life-os)

`life-os/commands/weekly-planner.md`: 3-5 righe, stesso pattern di `morning-plan.md` /
`weekly-review.md`. Parse args minimale, "read config, invoke the weekly-planner skill".
Zero logica.

## Routine

Scheduled-task **forma B (dentro l'app)** perché dipende da Calendar + Gmail MCP
interattivi (non gira in CCR sandbox). Lunedì **09:33** (off-minute). Trigger di 3 righe
che invoca la skill. Zero logica nella routine. Off-minute per evitare lo spike fleet
API sui minuti :00/:30.

## Come si costruisce (strangler + TDD)

Un componente alla volta, le 4 skill (2 esistenti + weekly-planner + i command)
restano funzionanti a ogni passo. Zero big-bang.
1. Estrai `_shared-refs/` (3 file) + aggiorna sync per trasportarli.
2. Migra le 2 skill esistenti al nocciolo condiviso; test SBM verdi (guardia).
3. Scrivi weekly-planner/SKILL.md (4 fasi).
4. Command trigger + voce nella lista SKILLS del sync.
5. Sync in life-os; verifica path `_shared-refs/` reggono da entrambe le parti.
6. Canarino e2e reale: invoca la skill a mano su questa settimana, gate incluso.
7. Routine (creata solo dopo canarino verde).

## Testing

- **Helper Python**: già coperti (`tests/skills/test_weekly_review.py`). Se la Fase 4
  tocca il payload, aggiungere test RED→GREEN lì.
- **Migrazione nocciolo**: i test SBM esistenti sono la guardia — verdi prima e dopo.
- **Skill (prompt)**: non unit-testabile; il canarino e2e reale (step 6) è il gate.
  "stub-green ≠ system-works": il primo run vero rivela i gap.

## Rischi noti

- **Path `_shared-refs/` cross-repo**: il rischio n.1. Il rimando relativo deve reggere
  sia in claude-skills sia dopo il sync in life-os. Da verificare fisicamente (step 5).
- **sync-skills.sh non trasporta `_shared-refs/`**: va modificato, altrimenti link rotto
  in life-os (stessa classe del bug packaging già identificato).
- **Convenzione ISO stale in planning-review**: non toccata qui, ma è debito.
