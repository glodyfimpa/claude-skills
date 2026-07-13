# Weekly-planner — chiusura del debito (B minima)

**Data:** 2026-07-13
**Tipo:** debt-close / riconciliazione sorgente↔runtime
**Repo:** `claude-skills` (fonte di verità), propaga a `life-os` + runtime app

## Problema

La routine schedulata `pianificazione-settimanale` (lun 09:33, `~/.claude/scheduled-tasks/pianificazione-settimanale/SKILL.md`) doveva essere un trigger sottile che invoca la skill `weekly-planner`. Invece contiene le 4 fasi del workflow **duplicate inline**, con un riferimento a `weekly-planner` che a runtime non si risolve.

### Causa radice (verificata 2026-07-13)

La skill `weekly-planner` **esiste ed è completa** (215 righe) nel sorgente:
- `areas/tooling/skills/claude-skills/weekly-planner/` (repo `claude-skills.git`)
- `areas/tooling/plugins/life-os/skills/weekly-planner/` (repo `life-os.git`, 2 commit di sync il 06/07)

Ma **non è in `managed_skills`** del file `claude-skills/.sync-manifest.json`. Lo script `sync.sh` propaga al runtime solo le skill elencate lì → `weekly-planner` non è mai stata copiata nelle destinazioni:
- `~/.claude/skills` (Claude Code)
- `~/Library/Application Support/Claude/local-agent-mode-sessions/skills-plugin/.../skills` (app / sessione cowork)

Conseguenza a catena: skill invisibile alla sessione → la routine non poteva invocarla → workflow duplicato inline nella routine come ripiego. È un caso "sorgente ≠ runtime" (memory `feedback_source_repo_vs_runtime`): il lavoro c'era, non è arrivato dove viene eseguito.

Nota storica: il 06/07 era stato progettato un facade completo a 6 componenti (ContextCollector, EventWeigher, Prioritizer, PlanReporter, CalendarAdapter, VaultWriter). È stata realizzata la skill monolitica (le 4 fasi in un file), non la scomposizione. La scomposizione è l'**Opzione A**, pianificata a parte (calendario mer 22/07), fuori dallo scope di questo spec.

## Obiettivo (scope)

Chiudere il debito con il minimo intervento: **una sola copia della logica** (nella skill), **skill attiva nel runtime**, **routine sottile**. NON scomporre in componenti/adapter (quello è A).

## Gap di contenuto della skill

La skill copre già:
- "weigh **every** event — including ones already on the calendar" (Fase 2)
- "never park outside fascia; move to next week with a real date; delete if no value" (Fase 2)
- le due fasce 10-12 / 16-18, "never two cognitive back-to-back", il gate umano (Fase 3)

Le **mancano** i due punti emersi il 2026-07-13 (dopo 3 richiami di Glody su eventi meta-tooling accavallati lasciati "ignorati a parole" invece di pesati):

1. **Anti-collisione di slot** — se dopo aver piazzato un fronte una fascia contiene 2+ eventi sovrapposti, va SCIOLTA scegliendo per ognuno: (a) spostare a slot libero nella settimana, (b) declassare a promemoria all-day free se davvero derogabile, (c) far slittare alla settimana prossima a data precisa. Mai due eventi busy sullo stesso slot. "Nominare un evento senza pesarlo = non averlo pesato."
2. **Gerarchia nei conflitti di slot** — il derogabile (meta-tooling / "rimanda senza sensi di colpa") NON scavalca il fronte vero (cashflow, primo cliente, BnB, scadenza dura). Se serve spazio: si sposta il meta-tooling, oppure si sposta il fronte vero a un altro GIORNO — mai lo si sfratta.

## Interventi

### 1. Aggiornare la skill sorgente (contenuto)
File: `claude-skills/weekly-planner/SKILL.md`, Fase 2 ("Weigh & Prioritize").
Aggiungere i due punti sopra come estensione della disciplina di pesatura esistente (non riscrivere la fase, integrarla). Registrare inline la provenienza: "regola derivata 2026-07-13".

### 2. Registrare + propagare al runtime
- Aggiungere `"weekly-planner"` all'array `managed_skills` di `claude-skills/.sync-manifest.json` (in ordine alfabetico, dopo `time-energy-manager` o dove tiene l'ordine).
- Lanciare `claude-skills/sync.sh`.
- **Verifica canarino (obbligatoria):** confermare che `weekly-planner/SKILL.md` compaia nella stessa directory runtime da cui `planning-review-system` è stata caricata in questa sessione. Il manifest ha una destinazione `cowork` con un path di sessione potenzialmente stantio (session-id invertito rispetto a quello vivo); `sync.sh` ha `discover_cowork_path` che trova la dir viva dinamicamente — verificare che la copia sia atterrata nella dir viva, non solo in quella del manifest.

### 3. Svuotare la routine
File: `~/.claude/scheduled-tasks/pianificazione-settimanale/SKILL.md`.
Sostituire le 4 fasi inline con un trigger sottile: invoca `weekly-planner` + i soli parametri specifici della routine (fonte primaria = vault brain, Notion solo fallback esplicito; calendario `primary`; gate in-sessione; scrivi il weekly in `brain/weekly/YYYY-MM-DD-weekly.md`). Il fix di oggi che era stato messo qui **si rimuove** (confluito nella skill al punto 1): una sola fonte di verità.
NB: `~/.claude` non è un repo git → questa modifica vive solo su disco, non è versionabile.

### 4. Allineare i due sorgenti
Dopo l'update in `claude-skills`, sincronizzare la copia in `plugins/life-os/skills/weekly-planner/` (via `sync.sh` o rsync mirato) così `claude-skills.git` e `life-os.git` non divergono.

## Fuori scope
- Scomposizione in 6 componenti isolati + adapter intercambiabili Notion/GCal/chat = **Opzione A** (calendario mer 22/07). La skill resta un file monolitico (~215 righe oggi, un po' di più dopo il fix): è l'implementazione concreta da cui A estrarrà i componenti (principio "3 implementazioni concrete prima di estrarre la base").
- Open question dal 06/07 (dove vivono EventWeigher + fasce come fonte di verità: oggi memory + config) → si scioglie in A, non qui.

## Testing / verifica
Nessun unit test: è una skill-markdown, non codice. La verifica è il **run reale di lunedì 20/07** (routine schedulata): deve trovare `weekly-planner` nel runtime e girare le 4 fasi end-to-end. È il canarino (memory `feedback_adversarial_e2e_reconcile` / "stub-green ≠ system-works"). Se gira, il debito è chiuso.

## Commit
- `claude-skills`: update skill + manifest + spec → commit + push.
- `life-os`: copia skill allineata → commit + push.
- routine (`~/.claude`): non versionabile, solo su disco.

## Rischi
- **Propagazione runtime (punto 2)** — rischio principale. Se la copia atterra in una dir di sessione stantia invece di quella viva, lunedì 20 la routine di nuovo non trova la skill. Mitigazione: verifica canarino esplicita nel punto 2 prima di considerare chiuso.
- **Doppia fonte claude-skills/life-os** — se si aggiorna una e non l'altra, divergono. Mitigazione: punto 4 esplicito + `sync.sh` come gesto unico.
