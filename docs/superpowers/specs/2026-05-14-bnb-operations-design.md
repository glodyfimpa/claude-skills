# BnB Operations — Design Spec

**Date**: 2026-05-14
**Status**: Approved
**Repo**: `claude-skills` (skill source-of-truth) + `bnb-investment-toolkit` (plugin consumer via sync)
**Implementation constraints**: `/autopilot` orchestrator + TDD strict (red→green→refactor)

## Problema

Glody sta lanciando il suo PRIMO BnB (l'appartamento, Milano) entro fine maggio 2026 in regime Locazione Turistica non imprenditoriale (LT C204 LNI). Ha programmato un **2° BnB a settembre 2026** (4 mesi). Nella sessione del 14/05/2026 è stata costruita su misura una dashboard kanban acquisti go-live (`<project-folder>/ACQUISTI_DASHBOARD.html`, 765 righe) con decisioni operative LT vs CAV (kit cortesia, servizi consumabili) e mapping responsabilità host vs servizio pulizia.

Quel lavoro vive solo nel filesystem del progetto dell'appartamento. Senza estrazione in skill: (a) a settembre andrà rifatto da zero al 2° BnB, perdendo ~8-15h, (b) le decisioni legali maturate (riferimenti DL 145/2023, L.R. Lombardia 27/2015) e operative non sono richiamabili in altre sessioni, (c) la conoscenza scappa.

Stessa logica del Bureaucratic Research Assistant (PR #19, 2026-05-13): pattern operativo italiano ripetibile va distillato in skill richiamabile invece di rieseguito manualmente. Backlog Notion conferma 3ª occorrenza in 8 giorni (06/05, 13/05, 14/05) → soglia rule of three superata.

## Scope

Una skill `bnb-operations` nel repo `claude-skills` come source-of-truth, propagata al plugin `bnb-investment-toolkit` via `sync.sh` esistente. Più 1 comando plugin-specific `/setup-bnb-operations [nome-bnb]`.

Out-of-scope (non costruire qui):
- Analisi pre-acquisto zona/ROI → già `short-term-rental-analyzer`
- Scraping portali immobiliari → già `property-acquisition-tracker`
- Compliance SCIA/SUAP pre-go-live → futuro skill `bnb-compliance` se necessario
- Dynamic pricing, channel manager → fuori scope iniziale, eventuale modulo separato futuro

## Architettura

```
claude-skills/                                  [source of truth]
├── bnb-operations/
│   ├── SKILL.md                                # ~190 righe
│   ├── assets/
│   │   └── shopping-dashboard-template.html    # ~750 righe, skeleton kanban
│   └── references/
│       ├── lt-vs-cav-decision-tree.md          # ~140 righe, normativa Italia
│       ├── host-vs-cleaning-service-responsibilities.md  # ~90 righe
│       └── post-golive-checklist.md            # ~110 righe
├── tests/
│   └── test_bnb_operations.sh                  # bats, pattern come test_bureaucratic_research_assistant.sh
├── sync.sh                                     # esistente, untracked — committare in PR housekeeping separata
└── .sync-manifest.json                         # esistente, untracked — entry per bnb-operations da aggiungere

bnb-investment-toolkit/                         [plugin consumer]
├── commands/
│   └── setup-bnb-operations.md                 # NUOVO, ~22 righe, plugin-specific
├── skills/
│   └── bnb-operations/                         # popolato da sync.sh, non committato a mano
└── .claude-plugin/plugin.json                  # bump version 0.1.0 → 0.2.0
```

## Skill: `bnb-operations`

### Scopo

Gestione operativa post-acquisto di un BnB italiano in regime LT non imprenditoriale. Copre 3 macro-aree: setup acquisti go-live, classificazione fiscale operativa (LT vs CAV), gestione ricorrente post-go-live.

### YAML header

```yaml
name: bnb-operations
description: |
  Operative management for Italian short-term rental properties in LT non-imprenditoriale regime.
  Use for: shopping dashboard setup, LT vs CAV/B&B reclassification risk decisions, host vs cleaning service responsibility mapping, recurring post-go-live checklists.
  Triggers: "imposta dashboard acquisti BnB", "gestisci shopping list go-live BnB", "checklist post go-live BnB", "decision tree LT vs CAV", "responsabilità host vs servizio pulizia".
  Italy-specific: cedolare 21%, DL 145/2023 art. 13-ter, L.R. Lombardia 27/2015 art. 38 c.10, Alloggiati Web, ISTAT Turismo5.
version: 0.1.0
```

### Sezioni SKILL.md

1. **Introduzione** — fase POST-acquisto, 3 macro-aree
2. **When NOT to use** — 3 bullets di scope delimitation (no pre-acquisto, no scraping, no SCIA/SUAP)
3. **Workflow 4-step**: setup dashboard → verifica perimetro LT/CAV → mappa responsabilità pulizia → checklist operativa ricorrente. Ogni step rimanda al reference appropriato
4. **Schema item dashboard** — tabella 11 campi: `id, status, priority 1-4, category, channel, title, model, qty, cost, link, link2, note`
5. **Categorie pre-popolate** — 10 categorie: sicurezza, biancheria, arredo, elettrodomestici, illuminazione, cucina, bagno, kit cortesia, consumabili, attrezzature
6. **Decision criteria status item** — ready/decide/research
7. **Configuration & customization** — adattamento a 2° BnB via comando o copia manuale
8. **Usage examples** — 4 esempi di trigger phrase con output atteso

### Asset: `shopping-dashboard-template.html`

Clone "scheletro" della dashboard dell'appartamento con:
- Stessa struttura visuale (3 colonne kanban ready/decide/research, dark theme, localStorage state, filtri categoria+canale, calcolo totale "Spesa pronta al click")
- Titolo placeholder "BnB — Dashboard Acquisti"
- localStorage key generico `bnb-shopping-dashboard-state` (sostituibile per multi-BnB)
- 13 voci skeleton con `status: "research"`, `cost: null`, `link: ""`, `model: ""`, ma `title`/`category`/`priority` pre-impostati:
  1. Smoke detector (sicurezza, P1)
  2. Estintore portatile 1kg (sicurezza, P1) — obbligatorio LT
  3. Kit pronto soccorso (sicurezza, P1)
  4. Cuscini camera (biancheria, P2)
  5. Copricuscini impermeabili (biancheria, P2)
  6. Coprimaterasso impermeabile (biancheria, P2)
  7. Tende oscuranti (arredo, P2)
  8. Sedie tavolo (arredo, P3)
  9. Stiratore verticale (elettrodomestici, P3)
  10. Macchina caffè (elettrodomestici, P3)
  11. Asciugacapelli (elettrodomestici, P3)
  12. Kit cortesia welcome (kit cortesia, P4) — nota "una tantum, vedi LT vs CAV decision tree"
  13. Ciabatta multipresa (consumabili, P4)
- Scrub dei riferimenti all'appartamento: rimuovere ASIN reali (B0DZHQV7RT, B0D4ZHPWC4, B0CX5GZV1T), prezzi reali, nomi specifici di persone, path filesystem (`TROVARE_CUSCINI/`), brand specifici (PALUPLUS, SEBSON, KORGMOTT)

### Reference: `lt-vs-cav-decision-tree.md`

1. **TL;DR** — LT non-imprenditoriale: zero SCIA, cedolare 21%, RC opzionale. CAV/B&B imprenditoriale: SCIA SUAP, P.IVA, RC obbligatoria
2. **Criteri riclassificazione** — 3 trigger: servizi quotidiani aggiuntivi, >4 appartamenti gestiti (art. 13-ter DL 145/2023), presentazione organizzata
3. **Decision tree per servizi** — flowchart ASCII:
   - Kit cortesia una tantum welcome → SAFE LT
   - Pulizia quotidiana inclusa → CAV
   - Pulizia tra ospiti solo turnover → SAFE LT
   - Colazione preparata in loco → CAV
   - Cestino confezionato lasciato in frigo → zona grigia SAFE LT
4. **Dispositivi sicurezza Lombardia** — tabella: estintore SI sempre, gas/CO esonerabili per <4 appartamenti via dichiarazione comma 7 art. 13-ter DL 145/2023, smoke detector NON obbligatorio per legge
5. **RC privata** — non obbligatoria LT Lombardia (L.R. 27/2015 art. 38 c.10)
6. **Riferimenti normativi** — DL 145/2023, L.R. Lombardia 27/2015, Circolare AdE 9/E 2017

### Reference: `host-vs-cleaning-service-responsibilities.md`

1. **TL;DR** — prima di acquistare biancheria/protezioni, ottieni preventivo dettagliato dal servizio pulizia
2. **Matrice responsabilità** — tabella 3 colonne (Voce | Servizio Pulizia | Host):
   - Cambio federe/lenzuola/asciugamani → Servizio
   - Lavanderia → Servizio
   - Pulizia turnover → Servizio
   - Copricuscino impermeabile → Host (durevole)
   - Coprimaterasso impermeabile → Host
   - Kit cortesia → Host
   - Kit pronto soccorso → Host
   - Asciugacapelli → Host
   - Estintore + manutenzione → Host
   - Smoke detector + batterie → Host
3. **Pattern operativo "verifica prima di acquistare"** — checklist 4 step
4. **Esempio preventivo tipo Milano** — €25-45/turnover con pool biancheria vs €18-30/turnover solo manodopera
5. **Anti-pattern** — host che compra 4 set biancheria e scopre dopo che il servizio li include: spreco €300-500

### Reference: `post-golive-checklist.md`

Task ricorrenti raggruppati per frequenza:
- **Daily** (check-in/out): Alloggiati Web schedina entro 24h, foto check-out, coordinamento pulizia
- **Weekly**: gestione recensioni Airbnb (entro 14gg), monitoring calendario, ottimizzazione prezzi
- **Monthly**: ISTAT Turismo5 entro il 5, restock kit cortesia, controllo batteria smoke detector
- **Quarterly**: revisione semestrale estintore, controllo caldaia, refresh welcome book
- **Annual**: dichiarazione redditi cedolare secca (modello Redditi PF quadro RB sez II), revisione RC, refresh foto listing
- **Welcome book** — checklist contenuti minimi (wifi, check-out, contatti emergenza, raccolta differenziata, regole condominio, attrazioni vicine)
- **Link utili** — Alloggiati Web portal, ISTAT Turismo5, AdE cedolare

## Comando plugin: `/setup-bnb-operations [nome-bnb]`

File: `~/Documents/3.RESOURCES/PLUGINS/bnb-investment-toolkit/commands/setup-bnb-operations.md`

```
---
description: Set up the operational dashboard and reference workflow for a live Italian BnB
argument-hint: [nome-bnb]
---

Initialize the post-go-live operational kit for an Italian short-term rental (regime LT non-imprenditoriale).

Load the `bnb-operations` skill from this plugin and execute the 4-step workflow.

If user provides argument:
- First argument: nome-bnb (default: ask interactively)

Workflow:
1. Copy `${CLAUDE_PLUGIN_ROOT}/skills/bnb-operations/assets/shopping-dashboard-template.html` to the current project working directory as `ACQUISTI_DASHBOARD_${nome-bnb}.html`.
2. Personalize the dashboard title and localStorage key with nome-bnb.
3. Walk the user through the 13 skeleton items to fill model, cost, link, channel.
4. Surface reference files (LT-vs-CAV, host-vs-cleaning, post-golive checklist) when relevant.

Closing summary: dashboard path, count items by status, next-actions list from post-golive checklist.
```

## TDD Plan

Test suite in `claude-skills/tests/test_bnb_operations.sh` (bats), pattern come `test_bureaucratic_research_assistant.sh`. Test scritti PRIMA del codice (red→green→refactor).

### Test cases obbligatori (acceptance criteria)

**Group 1 — Asset HTML template validity**
- [ ] `T1.1` HTML template file exists at `bnb-operations/assets/shopping-dashboard-template.html`
- [ ] `T1.2` HTML is parseable (basic structure: `<!DOCTYPE html>`, `<html>`, `<body>`, balanced tags)
- [ ] `T1.3` Contains 13 skeleton items in JS array `ITEMS`
- [ ] `T1.4` All 13 items have `status: "research"` (verifica grep)
- [ ] `T1.5` Nessun ASIN Amazon reale presente (no match per regex `B0[A-Z0-9]{8}`)
- [ ] `T1.6` Nessun nome di persona reale / "PALUPLUS" / "SEBSON" / "KORGMOTT" presente
- [ ] `T1.7` Nessun path `TROVARE_CUSCINI/` presente
- [ ] `T1.8` localStorage key = `bnb-shopping-dashboard-state` (non la chiave originale della dashboard)

**Group 2 — SKILL.md structure**
- [ ] `T2.1` `bnb-operations/SKILL.md` esiste con header YAML valido
- [ ] `T2.2` Header YAML contiene tutti i campi richiesti: `name`, `description`, `version`
- [ ] `T2.3` `name: bnb-operations` matcha cartella
- [ ] `T2.4` Description contiene almeno 1 trigger phrase italiana (regex su trigger noti)
- [ ] `T2.5` Description dichiara Italy-specific (regex "Italian|Italia|LT non-imprenditoriale")
- [ ] `T2.6` Sezione "When NOT to use" presente (anti-trigger spurio)

**Group 3 — Reference files presenza**
- [ ] `T3.1` `references/lt-vs-cav-decision-tree.md` esiste
- [ ] `T3.2` `references/host-vs-cleaning-service-responsibilities.md` esiste
- [ ] `T3.3` `references/post-golive-checklist.md` esiste
- [ ] `T3.4` lt-vs-cav reference cita art. 13-ter DL 145/2023 (verifica grep)
- [ ] `T3.5` host-vs-cleaning ha tabella matrice 3 colonne (regex markdown table)
- [ ] `T3.6` post-golive include sezioni Daily/Weekly/Monthly/Quarterly/Annual

**Group 4 — Sync integration**
- [ ] `T4.1` Dopo aver eseguito `sync.sh` (assumendo entry in `.sync-manifest.json` per `bnb-investment-toolkit`), la cartella `~/Documents/3.RESOURCES/PLUGINS/bnb-investment-toolkit/skills/bnb-operations/` esiste
- [ ] `T4.2` md5sum di `SKILL.md` matcha tra `claude-skills/bnb-operations/SKILL.md` e `bnb-investment-toolkit/skills/bnb-operations/SKILL.md`
- [ ] `T4.3` Tutti i reference file sincronizzati (count file in `references/` matcha)

**Group 5 — Plugin command**
- [ ] `T5.1` `bnb-investment-toolkit/commands/setup-bnb-operations.md` esiste
- [ ] `T5.2` Frontmatter YAML contiene `description` e `argument-hint`
- [ ] `T5.3` Comando referenzia path `${CLAUDE_PLUGIN_ROOT}/skills/bnb-operations/assets/shopping-dashboard-template.html`
- [ ] `T5.4` `plugin.json` version bumped a 0.2.0

## Workflow di implementazione via `/autopilot`

### Step 0 (prerequisito raccomandato) — Housekeeping sync

Prima della PR `bnb-operations`, PR separata su `claude-skills`:
- Committare `sync.sh` + `.sync-manifest.json` + `tests/test_sync.sh` + `docs/superpowers/specs/2026-03-20-skill-sync-design.md` (esistente untracked da 10/04/2026)
- Verifica `bash tests/test_sync.sh` verde prima di commit
- Capire perché era rimasto untracked (test rosso? Spec draft? Naming dubbio?), documentare la risoluzione nel commit message

Alternativa: la sessione può procedere con `bnb-operations` usando sync locale "as-is" se vuole rinviare housekeeping a sessione dedicata.

### Implementation flow (autopilot)

1. Sessione nuova lancia `/autopilot-prd` puntando a `docs/superpowers/specs/2026-05-14-bnb-operations-design.md`
2. Autopilot decompone questo PRD in task in `tasks/` (provider `local-file` da `.autopilot-pipeline.json`)
3. Per ogni task: TDD strict — bats test FIRST, poi implementazione, poi quality gates
4. Autopilot gestisce branch isolato, commit messages convenzionali, PR creation

### PR finali attese

**PR 1 (opzionale, raccomandato) — `claude-skills` housekeeping sync**:
- Branch: `chore/commit-sync-system`
- Files: `sync.sh`, `.sync-manifest.json`, `tests/test_sync.sh`, design spec sync già esistente
- Test: `bash tests/test_sync.sh` verde

**PR 2 — `claude-skills` bnb-operations skill**:
- Branch: `feat/bnb-operations-skill`
- Files: tutti i 5 file della skill + `tests/test_bnb_operations.sh`
- Test: bats suite verde (~20 test cases)

**PR 3 — `bnb-investment-toolkit` plugin update**:
- Branch: `feat/bnb-operations`
- Files: `commands/setup-bnb-operations.md`, `skills/bnb-operations/*` (popolato da sync.sh), `.claude-plugin/plugin.json` (version bump), `README.md` (tabella commands)
- Test: verifica E2E che `/setup-bnb-operations "Test"` copi il template correttamente

## Effort stimato

| Componente | Effort |
|---|---|
| Test bats suite (~20 test cases, scrivere PRIMA) | 40 min |
| SKILL.md | 25 min |
| shopping-dashboard-template.html | 20 min (clone dashboard dell'appartamento + scrub) |
| lt-vs-cav-decision-tree.md | 20 min (verifica normativa) |
| host-vs-cleaning-service-responsibilities.md | 12 min |
| post-golive-checklist.md | 15 min |
| setup-bnb-operations.md (comando) | 5 min |
| plugin.json bump + README update | 8 min |
| Esecuzione sync + verifica E2E | 10 min |
| **Totale TDD** | **~155 min (~2h35)** |

Compatibile con sessione mirata di ~3h, includendo overhead autopilot.

## Verifica end-to-end post-merge

1. **Reinstall pulito plugin**: `/plugin uninstall bnb-investment-toolkit` → `/plugin marketplace update` → `/plugin install`. Restart Claude Code.
2. **Verifica registrazione**: `/plugin list` mostra `bnb-investment-toolkit` v0.2.0 enabled; `/help` elenca 4 comandi (incluso `/setup-bnb-operations`).
3. **Test trigger skill**: in nuova sessione scrivere `imposta dashboard acquisti BnB` → Claude carica `bnb-operations/SKILL.md` e inizia workflow 4-step. Anti-test: `analizza zona Navigli` deve triggerare `short-term-rental-analyzer`, NON `bnb-operations`.
4. **Test asset accessibile**: `/setup-bnb-operations "Test"` in directory temporanea → Claude copia template, personalizza. Verifica manuale: aprire in browser, confermare kanban funzioni, localStorage persista, filtri rispondano.
5. **Test reference loading**: chiedere `decision tree LT vs CAV per kit cortesia quotidiano` → Claude apre `lt-vs-cav-decision-tree.md` e risponde "CAV (riclassifica)".
6. **Test localizzazione**: session in inglese, `setup short-term rental dashboard for my London flat` → Claude avvisa che la skill è Italy-specific.
7. **Smoke test ecosistema**: `/analyze-zone "Porta Romana" "Milan"` e `/scan-apartments Milan 1300` devono funzionare invariati (no regressione su skill esistenti).

## Source di riferimento (read-only durante implementazione)

- `<project-folder>/ACQUISTI_DASHBOARD.html` — source per template HTML (765 righe, scrubbing necessario)
- `claude-skills/short-term-rental-analyzer/SKILL.md` e `claude-skills/property-acquisition-tracker/SKILL.md` — pattern di stile/lunghezza
- `claude-skills/tests/test_bureaucratic_research_assistant.sh` — pattern test bats
- `claude-skills/sync.sh` (untracked, locale) — tool battle-tested per propagazione skill→plugin

## Aggiornamento backlog Notion post-merge

- Aggiornare riga "Airbnb Operations Kit" in tabella Status Implementazione: status `💡 IDEA` → `✅ Pubblicato`, link al repo, data
- Aggiornare tabella "Plugins Pubblicati" riga `bnb-investment-toolkit`: bump version 0.1.0 → 0.2.0, count "(3 skill, 4 comandi)"
