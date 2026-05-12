# Bureaucratic Research Assistant — Design Spec

**Date**: 2026-05-12  
**Status**: Approved  
**Repo**: `claude-skills`

## Problema

Le pratiche burocratiche italiane (INPS, portali PA regionali, registrazioni strutture ricettive) richiedono ogni volta lo stesso set di operazioni manuali: raccogliere dati identificativi sparsi in documenti diversi, compilare form multi-step con ID campi dinamici, gestire session token Keycloak che scadono dopo 30 minuti, e interpretare clausole di esonero nascose in PDF FAQ di 40 pagine. Queste operazioni si sono ripetute 4 volte in 8 giorni (INPS 19/03, CIR sblocco 05/05, BDSR CIN 06/05 mattina, SoggiorniAmo + ROSS 1000 06/05 pomeriggio).

## Scope

Tre skill standalone nel repo `claude-skills`, invocabili indipendentemente:

1. **`pa-data-vault`** — raccoglie e struttura dati identificativi (persona fisica + struttura BnB) prima di compilare qualsiasi form
2. **`pa-form-filler`** — compila form PA online con browser automation; include i sub-moduli `pa-form-checkpoint` (recovery da token scaduto) e `pa-form-dynamic-id-mapper` (discovery campi con ID dinamici)
3. **`pa-legal-clause-analyzer`** — analizza autocertificazioni PA per identificare clausole di esonero sulla base delle norme citate nel documento stesso

Nessun orchestratore: l'utente invoca la skill giusta per il contesto.

## Architettura

```
claude-skills/
├── pa-data-vault/
│   ├── SKILL.md
│   └── references/
│       ├── personal/
│       │   └── glody.md          # CF, doc identità, PEC, tel, indirizzo
│       └── bnb-via-braida/
│           └── structure.md      # CIN, ATECO, P.IVA, codici portali PA
│
├── pa-form-filler/
│   ├── SKILL.md                  # include logica checkpoint + id-mapper
│   └── references/
│       └── portals-catalog.yaml  # regole portale-specifiche (auto-aggiornato)
│
└── pa-legal-clause-analyzer/
    └── SKILL.md
```

Checkpoint files: `~/.claude/pa-checkpoints/{portale}-{YYYY-MM-DD}.json` (non nel repo, locale)

## Skill 1: `pa-data-vault`

### Scopo

Fonte di verità per i dati identificativi usati in qualsiasi form PA. Evita di cercare CF, CIN, P.IVA, codici portale a ogni nuova pratica.

### Reference files

**`references/personal/glody.md`**
```
# Profilo personale — Glody Fimpa
CF: [da completare]
Nome: Glody
Cognome: Fimpa
Data nascita: [da completare]
Comune nascita: [da completare]
Documento: [tipo] n. [numero] rilasciato [data] da [ente]
Indirizzo residenza: [da completare]
PEC: [da completare]
Telefono: [da completare]
Email: glodyfimpa@gmail.com
```

**`references/bnb-via-braida/structure.md`**
```
# Struttura BnB — Via Braida
CIN: [da completare]
P.IVA: [da completare]
Codice ATECO: [da completare]
Indirizzo struttura: [da completare]
Codice SoggiorniAmo: [da completare]
Codice BDSR: [da completare]
Codice ROSS 1000: [da completare]
```

### Workflow skill

1. Chiede: per quale pratica / quale struttura?
2. Carica il profilo corretto dai reference file
3. Rileva campi mancanti ([da completare]) e li chiede all'utente
4. Salva i valori nuovi nel reference file
5. Restituisce il data bundle pronto per `pa-form-filler`

Per trovare documenti di identità sul filesystem (carta d'identità scannerizzata, visura camerale PDF): riusa `document-collector` invece di reimplementare la ricerca.

Per aggiungere una seconda struttura: creare `references/bnb-struttura2/structure.md` con lo stesso schema.

## Skill 2: `pa-form-filler`

### Scopo

Compila form PA online con browser automation. Gestisce ID campi dinamici e recovery da session timeout.

### Browser adapter (gerarchia automatica)

Tenta in ordine, passa al successivo se il precedente fallisce o non è disponibile:

1. **Playwright MCP** — primo tentativo. Più preciso, supporta shadow DOM, React Select, form multi-step. Workaround noti documentati in CLAUDE.md globale.
2. **Chrome MCP** — secondo tentativo. Più rapido su pagine semplici. Dropdown custom spesso invisibili: usa `javascript_tool` per trovare `<select>` e triggerare `change` event.
3. **Computer Use MCP** — fallback visivo. Funziona su qualsiasi portale indipendentemente dall'HTML. Più lento.

### Sub-modulo: `pa-form-dynamic-id-mapper`

Risolve i campi con ID generati dinamicamente (es. Keycloak: `name="field_a3f7b"` cambia ad ogni sessione).

**Strategia hybrid (label-first + catalog fallback):**

1. **Label-first**: scansiona il DOM, trova `<label>` con il testo atteso (es. "Codice CIN"), risale al campo associato tramite attributo `for` o posizione DOM (campo immediatamente successivo alla label). Funziona su ~90% dei portali PA standard.
2. **Catalog lookup**: se label-first fallisce, consulta `references/portals-catalog.yaml` per regole portale-specifiche già note.
3. **Discovery manuale + auto-save**: se il catalog non ha una regola per il portale corrente, chiede conferma all'utente ("Il campo 'Codice CIN' è questo? [mostra elemento]"), poi salva la regola nel catalog per usi futuri.

**`references/portals-catalog.yaml` schema:**
```yaml
portals:
  soggiorniamoMilano:
    base_url: "https://www.soggiornisicuri.regione.lombardia.it"
    fields:
      cin:
        strategy: label-first
        label_text: "Codice CIN"
      piva:
        strategy: catalog
        selector: "input[data-field='partita_iva']"
  bdsr:
    base_url: "https://bdsr.alloggiatiweb.poliziadistato.it"
    fields:
      cin:
        strategy: label-first
        label_text: "CIN"
```

### Sub-modulo: `pa-form-checkpoint`

Salva e ripristina lo stato della compilazione per gestire session timeout (Keycloak scade dopo ~30min su portali PA).

**Checkpoint automatico:**
- Salva dopo ogni cambio pagina e ogni 5 campi compilati
- File: `~/.claude/pa-checkpoints/{portale}-{YYYY-MM-DD}.json`
- Schema: `{ "portal": "...", "url": "...", "current_field": "...", "filled_fields": { "campo": "valore", ... }, "timestamp": "..." }`

**Detection session timeout:**
- Rileva HTTP 401 / redirect a login / elemento "sessione scaduta" nel DOM
- Pausa immediata + messaggio: "Token scaduto dopo [N] campi. Vuoi rinnovare la sessione e riprendere da [campo X]?"
- Resume: naviga all'URL checkpoint, ri-autentica, re-inietta i valori già compilati (skip automatico)

**Resume esplicito:**
- L'utente può invocare la skill con "riprendi il form [portale]"
- La skill lista i checkpoint disponibili e propone di riprendere dal più recente

### FAQ PDF scan (integrato)

Prima di compilare qualsiasi form, cerca il PDF FAQ del portale:
- Pattern: `{base_url}/res/FAQ.pdf`, link nel footer della pagina
- Estrae tramite `pdftotext` la lista dei campi obbligatori per legge
- Ignora i campi opzionali durante la compilazione
- Motivazione: su BDSR e ROSS 1000, la lista "obbligatori per legge" era 5-10x più corta di quella visiva (validato 2× su 06/05/2026)

### Workflow skill

1. Riceve: URL portale + profilo dati (da `pa-data-vault` o inseriti inline)
2. Cerca e legge il PDF FAQ → lista campi obbligatori
3. Naviga al form con il browser adapter
4. Per ogni campo obbligatorio: id-mapper → compila → checkpoint ogni 5 campi
5. Submit → conferma visiva del successo
6. Elimina il checkpoint file se submit avvenuto con successo

## Skill 3: `pa-legal-clause-analyzer`

### Scopo

Data un'autocertificazione PA, identifica le clausole di esonero e indica quali dichiarazioni l'utente può omettere o compilare con "N/A" sulla base delle norme citate nel documento stesso.

**Caso d'uso reale:** BDSR Punto 2 gas/CO — il comma 7 art. 13-ter DL 145/2023 esonerava strutture con meno di 4 appartamenti. Trovato manualmente; questa skill lo avrebbe estratto automaticamente.

### Workflow skill

1. Riceve il documento: URL, PDF (path locale), o testo incollato
2. Estrae tutte le clausole con riferimento normativo (pattern: "ai sensi dell'art. X", "comma Y del D.L. Z/YYYY", "di cui al D.Lgs. N/YYYY")
3. Carica il profilo da `pa-data-vault` (tipo struttura, numero appartamenti, categoria ATECO, ecc.)
4. Per ogni clausola con norma citata: verifica se il profilo soddisfa i criteri di esonero descritti nella norma
5. Produce tabella output:

| Clausola | Obbligatoria? | Norma citata | Valore suggerito |
|---|---|---|---|
| Punto 2 — rilevatori gas/CO | N/A se <4 app. | Art. 13-ter c.7 DL 145/2023 | N/A |
| Punto 5 — dichiarazione antincendio | Sì | Art. 3 DM 16/03/2012 | [compilare] |

**Limite esplicito:** la skill cita solo le norme già presenti nel documento. Se il documento non contiene riferimenti normativi, risponde "verifica manualmente con il portale o un consulente". Non fornisce interpretazioni legali proprie.

## Testing

### Approccio: TDD strict (RED → GREEN → REFACTOR)

Ogni sub-modulo e ogni funzione di supporto vengono sviluppati seguendo il ciclo TDD:

1. **RED**: scrivere il test bats che fallisce prima di scrivere il codice
2. **GREEN**: implementare il minimo indispensabile per far passare il test
3. **REFACTOR**: pulire senza rompere i test

Suite di test in `tests/test_bureaucratic_research_assistant.sh` (bats), nella struttura già esistente nel repo `claude-skills`. Ogni skill ha la propria sezione nella suite. I test devono essere tutti verdi prima di considerare una skill pronta per il commit.

**Integrazione con `/autopilot`:** implementare usando `/autopilot-sprint` o `/autopilot-task`. Le 3 skill rientrano nella complessità `complex` (stimata dall'autopilot via `lib/complexity-estimator.sh`), quindi TDD strict è applicato automaticamente dall'autopilot senza configurazione aggiuntiva. Il ciclo RED → GREEN → REFACTOR → COMMIT viene eseguito per ogni unità logica, con commit separati test+implementazione verificabili via `git log --stat`.

Casi da testare con fixture isolate (pattern `mktemp -d`, cleanup in teardown):
- `pa-data-vault`: caricamento reference file, detection campi `[da completare]`, salvataggio valori nuovi, gestione profilo mancante
- `pa-form-filler` (id-mapper): strategy label-first su DOM fixture, fallback catalog lookup, auto-save regola nuova nel YAML
- `pa-form-filler` (checkpoint): creazione file JSON, schema corretto, resume da checkpoint, detection HTTP 401, eliminazione checkpoint post-submit
- `pa-legal-clause-analyzer`: estrazione riferimenti normativi, match profilo → esonero, output tabella, fallback "verifica manualmente"

### Verifica end-to-end

1. `pa-data-vault`: invocare la skill, verificare che carichi i reference file, rilevi i campi `[da completare]`, li chieda e li salvi correttamente
2. `pa-form-filler` su portale test: compilare SoggiorniAmo Milano (prossima pratica BnB nei 7-14gg) con Playwright MCP; verificare checkpoint file creato in `~/.claude/pa-checkpoints/`; simulare token timeout e verificare resume
3. `pa-legal-clause-analyzer`: fornire il PDF BDSR autocertificazione; verificare che estragga il comma 7 art. 13-ter DL 145/2023 e proponga "N/A" per il Punto 2

### Validazione portals-catalog.yaml

Dopo ogni compilazione su un nuovo portale, verificare che il catalog sia stato aggiornato con le regole corrette per i campi rilevati.

## Priorità di costruzione

1. `pa-data-vault` — foundation: serve a tutte le altre skill (1-2h)
2. `pa-form-filler` — core value: il modulo più usato, include i 2 sub-moduli (4-6h)
3. `pa-legal-clause-analyzer` — high value, più semplice da implementare (2-3h)

Costruire nell'ordine sopra: `pa-data-vault` prima perché `pa-form-filler` lo riusa.

## Come implementare con `/autopilot`

Aprire una sessione Claude Code nella root del repo `claude-skills`:

```bash
cd ~/Documents/3.RESOURCES/SKILLS/claude-skills
```

Poi lanciare lo sprint passando questa spec come PRD:

```
/autopilot-sprint docs/superpowers/specs/2026-05-12-bureaucratic-research-assistant-design.md
```

L'autopilot legge la spec, scompone il lavoro in task (uno per skill), stima la complessità (`complex` per tutte e 3), e avvia il ciclo TDD strict — RED → GREEN → REFACTOR → COMMIT — per ogni unità logica. Al termine di ogni skill apre una PR separata.

In alternativa, per implementare una skill alla volta:

```
/autopilot-task "Implementa pa-data-vault come descritto nella spec docs/superpowers/specs/2026-05-12-bureaucratic-research-assistant-design.md"
/autopilot-task "Implementa pa-form-filler (con pa-form-checkpoint e pa-form-dynamic-id-mapper) come descritto nella spec"
/autopilot-task "Implementa pa-legal-clause-analyzer come descritto nella spec"
```

Rispettare l'ordine: `pa-data-vault` prima, poi `pa-form-filler`, poi `pa-legal-clause-analyzer`.
