# Time & Energy Manager — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a Claude skill that manages daily energy and time through 4 phases (Morning Plan, Mid-day Check, Pivot, Evening Close), integrated with Notion and the existing planning-review-system.

**Architecture:** Pure documentation skill (SKILL.md + 2 reference files), no scripts. All logic lives in SKILL.md as Claude instructions. Reads from 3 existing Notion databases (Tasks, PROJECTS, Planning), writes daily plan pages to SECOND BRAIN. Follows the exact same pattern as `planning-review-system/`.

**Tech Stack:** Markdown (SKILL.md), Notion MCP for database queries and page creation.

---

### Task 1: Create skill directory structure

**Files:**
- Create: `time-energy-manager/`
- Create: `time-energy-manager/references/`

**Step 1: Create directories**

```bash
mkdir -p time-energy-manager/references
```

**Step 2: Verify structure**

Run: `ls -la time-energy-manager/`
Expected: empty directory with `references/` subdirectory

**Step 3: Commit**

```bash
git add time-energy-manager/
git commit -m "chore: scaffold time-energy-manager skill directory"
```

---

### Task 2: Write `references/ideal-week.md`

This file contains the complete Ideal Week template with all schedule variants (Sprint A vs B), fixed blocks, meeting map, and pause rules. The SKILL.md will reference this file.

**Files:**
- Create: `time-energy-manager/references/ideal-week.md`

**Step 1: Write the Ideal Week reference file**

```markdown
# Ideal Week Template

Reference template for the Time & Energy Manager skill. Claude reads this to generate daily plans adapted to the day of the week and sprint cycle.

## Vincoli Fissi

- **Lavoro:** Lun-Ven 9:00-17:00 (remoto, ADESSO - GNV)
- **Pranzo:** 13:00-13:30 con famiglia
- **Palestra:** Lun + Gio, esce 17:00, rientra ~19:30 (dopo = solo famiglia/relax)
- **Compagna palestra:** Mer, esce 17:30, rientra ~20:00 (lui col bimbo)
- **Aperitivo famiglia:** Ven dalle 18:00
- **Domenica:** OFF totale
- **Sonno:** mezzanotte/1:00 → sveglia 8:20
- **Routine mattutina:** 08:20-09:00 (stretching + meditazione + doccia)

## Meeting Ricorrenti

| Meeting | Quando | Orario |
|---------|--------|--------|
| Daily standup | Lun-Ven | 10:15-10:30 |
| Daily cliente (ciclo 3 settimane) | Lun-Ven | 10:45-11:00 |
| Refinement | Lun + Gio | 11:00-13:00 |
| Sprint review prep | Ogni 2 Lun | 15:30-16:00 |
| Sprint Review | Settimana A, Mar | 09:30-11:00 |
| Planning 1 | Settimana A, Mar | 11:30-13:00 |
| Planning 2 | Settimana A, Mar | 15:00-16:00 |
| Tech Review | Settimana B, Mar | 11:30-13:00 |
| Retrospective | Ogni 2 Mer | Orario variabile |

## Ciclo Sprint

Le settimane si alternano: **Settimana A** (sprint ceremonies) e **Settimana B** (tech review). Per determinare quale settimana e, calcola il numero della settimana ISO dalla data corrente. Se pari = A, se dispari = B (calibrare con l'utente al primo utilizzo).

## Finestra d'Oro: 9:00-10:15

Ogni mattina lavorativa, ~1h prima dei meeting. Proteggi questo blocco per side business e studio personale. Non schedulare mai lavoro del cliente qui a meno che non ci sia un'emergenza (e in quel caso, Fase 3 Pivot lo gestisce).

## Giornate Tipo

### Lunedi

| Orario | Attivita | Tipo |
|--------|----------|------|
| 08:20-09:00 | Routine mattutina | Fisso |
| 09:00-09:10 | Morning Plan con Claude | TEM |
| 09:10-10:10 | Side business / studio personale | Personale |
| 10:15-10:30 | Daily standup | Lavoro |
| 10:30-11:00 | Lavoro | Lavoro |
| 11:00-13:00 | Refinement | Lavoro |
| 13:00-13:30 | Pranzo con famiglia | Famiglia |
| 13:30-14:00 | Rientro morbido | Lavoro leggero |
| 14:00-14:15 | Pausa early afternoon | Pausa |
| 14:15-15:45 | Deep work | Lavoro |
| 15:45-16:00 | Pausa | Pausa |
| 16:00-17:00 | Admin / chiusura (+ prep sprint review ogni 2 Lun 15:30-16:00) | Lavoro |
| 17:00-19:30 | Palestra (uscita 17:00, rientro ~19:30) | Benessere |
| 19:30+ | Famiglia e relax | OFF |

### Martedi — Settimana A (Sprint)

| Orario | Attivita | Tipo |
|--------|----------|------|
| 08:20-09:00 | Routine mattutina | Fisso |
| 09:00-09:10 | Morning Plan con Claude | TEM |
| 09:10-09:25 | Side business (finestra ridotta) | Personale |
| 09:30-11:00 | Sprint Review | Lavoro |
| 11:00-11:15 | Micro-reset post-meeting | Pausa |
| 11:30-13:00 | Planning 1 | Lavoro |
| 13:00-13:30 | Pranzo | Famiglia |
| 13:30-14:15 | Rientro morbido | Lavoro leggero |
| 14:15-15:00 | Lavoro | Lavoro |
| 15:00-16:00 | Planning 2 | Lavoro |
| 16:00-17:00 | Lavoro / recupero | Lavoro |
| 17:00-17:20 | Reset break | Pausa |
| 17:20-17:50 | Sviluppo personale (se energia >= 3) | Personale |
| 17:50-18:00 | Evening Close | TEM |
| 18:00+ | Famiglia e relax | OFF |

### Martedi — Settimana B (Tech)

| Orario | Attivita | Tipo |
|--------|----------|------|
| 08:20-09:00 | Routine mattutina | Fisso |
| 09:00-09:10 | Morning Plan con Claude | TEM |
| 09:10-10:10 | Side business / studio | Personale |
| 10:15-10:30 | Daily | Lavoro |
| 10:30-11:30 | Deep work | Lavoro |
| 11:30-13:00 | Tech Review | Lavoro |
| 13:00-13:30 | Pranzo | Famiglia |
| 13:30-14:15 | Rientro morbido | Lavoro leggero |
| 14:15-15:45 | Deep work | Lavoro |
| 15:45-16:00 | Pausa | Pausa |
| 16:00-17:00 | Admin / chiusura | Lavoro |
| 17:00-17:20 | Reset break | Pausa |
| 17:20-17:50 | Sviluppo personale (se energia >= 3) | Personale |
| 17:50-18:00 | Evening Close | TEM |
| 18:00+ | Famiglia e relax | OFF |

### Mercoledi

| Orario | Attivita | Tipo |
|--------|----------|------|
| 08:20-09:00 | Routine mattutina | Fisso |
| 09:00-09:10 | Morning Plan con Claude | TEM |
| 09:10-10:10 | Side business / studio | Personale |
| 10:15-10:30 | Daily | Lavoro |
| 10:30-12:00 | Deep work (o Retrospective ogni 2 Mer) | Lavoro |
| 12:00-12:15 | Pausa | Pausa |
| 12:15-13:00 | Lavoro | Lavoro |
| 13:00-13:30 | Pranzo | Famiglia |
| 13:30-14:15 | Rientro morbido | Lavoro leggero |
| 14:15-15:45 | Deep work | Lavoro |
| 15:45-16:00 | Pausa | Pausa |
| 16:00-17:00 | Admin / chiusura | Lavoro |
| 17:00-17:30 | Transizione | — |
| 17:30-20:00 | Solo con il bimbo (compagna in palestra) | Famiglia |
| 20:00+ | Relax | OFF |

### Giovedi

| Orario | Attivita | Tipo |
|--------|----------|------|
| 08:20-09:00 | Routine mattutina | Fisso |
| 09:00-09:10 | Morning Plan con Claude | TEM |
| 09:10-10:10 | Side business / studio | Personale |
| 10:15-10:30 | Daily | Lavoro |
| 10:30-11:00 | Lavoro | Lavoro |
| 11:00-13:00 | Refinement | Lavoro |
| 13:00-13:30 | Pranzo | Famiglia |
| 13:30-14:15 | Rientro morbido | Lavoro leggero |
| 14:15-15:45 | Deep work | Lavoro |
| 15:45-16:00 | Pausa | Pausa |
| 16:00-17:00 | Admin / chiusura | Lavoro |
| 17:00-19:30 | Palestra | Benessere |
| 19:30+ | Famiglia e relax | OFF |

### Venerdi

| Orario | Attivita | Tipo |
|--------|----------|------|
| 08:20-09:00 | Routine mattutina | Fisso |
| 09:00-09:10 | Morning Plan con Claude | TEM |
| 09:10-10:10 | Side business / studio | Personale |
| 10:15-10:30 | Daily | Lavoro |
| 10:30-12:00 | Deep work (giorno piu libero da meeting) | Lavoro |
| 12:00-12:15 | Pausa | Pausa |
| 12:15-13:00 | Lavoro | Lavoro |
| 13:00-13:30 | Pranzo | Famiglia |
| 13:30-14:15 | Rientro morbido | Lavoro leggero |
| 14:15-15:45 | Deep work | Lavoro |
| 15:45-16:00 | Pausa | Pausa |
| 16:00-17:00 | Admin / chiusura | Lavoro |
| 17:00-17:20 | Reset break (opzionale) | Pausa |
| 17:20-17:50 | Sviluppo personale (opzionale, se energia >= 3) | Personale |
| 18:00+ | Aperitivo + famiglia | OFF |

### Sabato

| Attivita | Note |
|----------|------|
| Famiglia, ritmo lento | Mattina |
| 2h studio/side business | Quando possibile, non obbligatorio |
| Famiglia e relax | Resto della giornata |

### Domenica

| Attivita | Note |
|----------|------|
| Famiglia, relax, zero programmi | Tutto il giorno |
| Weekly Review con PRS (opzionale) | Sera, per preparare la settimana |

## Regole Pause

1. **Mai piu di 90 min consecutivi di deep work** → 10-15 min pausa
2. **Dopo meeting lungo (>1h)** → 5-10 min micro-reset
3. **13:30-14:15** → rientro morbido, niente deep work
4. **14:00-14:15** → early afternoon reset
5. **Transizione post-lavoro (17:00-17:20)** → reset break prima dello sviluppo personale

## Logica Energia Post-Lavoro

- Energia >= 3/5 → propone blocco 17:20-17:50 con reset break
- Energia = 2/5 → solo 20 min di qualcosa leggero (lettura, review)
- Energia = 1/5 → "Oggi hai dato abbastanza. Vai diretto a relax."

## Budget Settimanale Side Business/Studio

- Lun-Ven 9:00-10:15: ~5h/settimana
- Mar/Ven 17:20-17:50: ~1h/settimana (se energia lo permette)
- Sabato: ~2h (quando possibile)
- **Totale: 7-8h/settimana**
```

**Step 2: Verify file is well-formed**

Run: `wc -l time-energy-manager/references/ideal-week.md`
Expected: ~200 lines

**Step 3: Commit**

```bash
git add time-energy-manager/references/ideal-week.md
git commit -m "feat: add ideal-week reference template for time-energy-manager"
```

---

### Task 3: Write `references/energy-patterns.md`

This file documents how Claude interprets energy data and generates insights after 2+ weeks of check-ins.

**Files:**
- Create: `time-energy-manager/references/energy-patterns.md`

**Step 1: Write the energy patterns reference file**

```markdown
# Energy Patterns — Guida Interpretazione

Reference per il Time & Energy Manager. Claude usa questa guida per analizzare i dati energetici raccolti dai check-in giornalieri e produrre insight actionable.

## Dati Raccolti

Ogni pagina giornaliera contiene:
- **Energia mattina:** 1-5 (da Morning Plan)
- **Energia pomeriggio:** 1-5 (da Mid-day Check, opzionale)
- **Energia sera:** 1-5 (da Evening Close)
- **Nota contesto:** testo libero (opzionale)
- **Giorno della settimana:** automatico dalla data
- **Tipo settimana:** Sprint A / Sprint B
- **Task completati vs. pianificati:** dal recap Evening Close

## Scala Energia

| Livello | Significato | Azione Morning Plan |
|---------|-------------|---------------------|
| 5 | Pieno di energia, lucido | Deep work creativo, task complessi, side business ambizioso |
| 4 | Buona energia, focus ok | Deep work standard, task importanti |
| 3 | Nella media, funzionale | Task importanti ma non creativi, alterna con pause |
| 2 | Stanco, fatica a concentrarsi | Solo task essenziali, niente deep work, pausa extra |
| 1 | Svuotato, difficolta a funzionare | Minimo indispensabile, proteggi energia, suggerisci staccare prima |

## Pattern da Rilevare (dopo 2+ settimane)

### Pattern Giornalieri

Analizza le medie per giorno della settimana:

| Pattern | Cosa cercare | Suggerimento |
|---------|-------------|-------------|
| **Giorno debole** | Media < 2.5 per un giorno specifico | "Il [giorno] e il tuo punto debole. Solo task leggeri." |
| **Giorno forte** | Media > 4 per un giorno specifico | "Il [giorno] e il tuo picco. Proteggi deep work." |
| **Calo post-pranzo** | Media pomeriggio < media mattina - 2 | "Il calo post-pranzo e sistematico. Il rientro morbido e fondamentale." |
| **Effetto palestra** | Energia media giorno dopo Lun/Gio > media altri giorni | "I giorni dopo la palestra rendi di piu." |
| **Effetto sprint A** | Media settimana A < media settimana B | "Le settimane sprint ti scaricano. Calibra aspettative." |

### Pattern Settimanali

| Pattern | Cosa cercare | Suggerimento |
|---------|-------------|-------------|
| **Trend discendente** | 3+ giorni di calo consecutivo | "Trend in calo. Hai bisogno di un giorno di recupero serio." |
| **Costantemente basso** | Media settimanale < 2.5 | "Settimana difficile. Rivedi carico di lavoro nella prossima weekly review." |
| **Completamento vs energia** | Alta correlazione tra energia 4-5 e task completati | Conferma: "Quando l'energia e alta, completi il 60% in piu. Proteggi quei momenti." |

### Pattern Contestuali

| Pattern | Cosa cercare | Suggerimento |
|---------|-------------|-------------|
| **Meeting drain** | Energia bassa nei giorni con 3+ ore di meeting | "I giorni pesanti di meeting ti scaricano. Metti solo admin dopo." |
| **Side business boost** | Energia piu alta dopo mattine di side business | "Lavorare sui tuoi progetti al mattino ti carica per il resto." |
| **Weekend recovery** | Energia lunedi > energia venerdi | "Il weekend ti ricarica bene. Rispetta la domenica OFF." |

## Come Presentare i Pattern

Nella weekly review (via PRS) o quando l'utente chiede "pattern energia" / "trend":

### Formato Output

```
## Energy Report — Settimana [data]

**Media settimanale:** X.X/5
**Trend:** ↑ in salita / → stabile / ↓ in calo
**Giorno migliore:** [giorno] (media X.X)
**Giorno peggiore:** [giorno] (media X.X)

### Insight
- [Pattern rilevato 1 con suggerimento]
- [Pattern rilevato 2 con suggerimento]

### Suggerimento per la prossima settimana
[1 azione concreta basata sui dati]
```

## Quando NON Analizzare

- Meno di 5 giorni di dati: "Non ho abbastanza dati. Continuiamo a raccogliere."
- Meno di 2 settimane: solo medie giornaliere, nessun pattern
- Dati incompleti (molti check-in saltati): "I dati sono frammentari. Cerca di fare almeno il Morning Plan e l'Evening Close."

## Principi

1. **Mai giudicare** — "Energia 1 non e un fallimento, e informazione"
2. **Suggerimenti concreti** — non "riposa di piu" ma "il giovedi metti solo task leggeri"
3. **Onesta sui limiti** — se i dati non bastano, dirlo
4. **Collegamento azione** — ogni insight ha un suggerimento specifico per il Morning Plan
```

**Step 2: Verify**

Run: `wc -l time-energy-manager/references/energy-patterns.md`
Expected: ~100 lines

**Step 3: Commit**

```bash
git add time-energy-manager/references/energy-patterns.md
git commit -m "feat: add energy-patterns reference guide for time-energy-manager"
```

---

### Task 4: Write `SKILL.md` — Frontmatter + Header + Database References

The main skill file. We build it in parts to keep tasks bite-sized. This task writes the frontmatter, overview, and database references section.

**Files:**
- Create: `time-energy-manager/SKILL.md`

**Step 1: Write frontmatter + header + database section**

```markdown
---
name: time-energy-manager
description: |
  Daily time and energy management system with 4 phases: Morning Plan, Mid-day Check, Pivot, Evening Close. Complements the planning-review-system by translating weekly priorities into daily execution with energy-adaptive scheduling. Use this skill when: starting the day, checking energy levels, handling schedule changes, or closing the day. Triggers: "buongiorno", "morning plan", "pianifica la giornata", "come sto?", "energy check", "urgenza", "cambio piano", "ho finito", "posso rilassarmi?", "evening close", "ideal week", "settimana A o B?", "pattern energia". Requires Notion MCP connected.
---

# Time & Energy Manager

Sistema di gestione quotidiana tempo ed energia in 4 fasi. Complemento operativo del planning-review-system: il PRS guarda indietro e in alto (weekly review, quarter), il TEM guarda avanti e in basso (cosa fai oggi, con quanta energia).

**Principio:** Non fare di piu. Fare il giusto e poi vivere.

## Database References

- **Tasks:** `collection://8e608c2b-6cbb-46a2-b233-fffc0b4f5e21`
- **PROJECTS:** `collection://38d9dc09-59f1-4f94-b36b-f62ab9772ac6`
- **Planning (board settimanale):** `collection://2dde510c-5e59-81a5-b80e-000bf6f27cce`
- **SECOND BRAIN (parent per pagine giornaliere):** `https://www.notion.so/142e510c5e598039933ef8a447570ece`

## Filtri Critici

| Database | Filtro | Motivo |
|----------|--------|--------|
| PROJECTS | `Legacy = false` | Ignora progetti archiviati |
| Tasks | `Status != Done` AND `Due Date = oggi` | Solo task attivi del giorno |
| Planning | `Status = [giorno corrente]` | Task assegnati a oggi nel board settimanale |
```

**Step 2: Verify file starts correctly**

Run: `head -5 time-energy-manager/SKILL.md`
Expected: YAML frontmatter starting with `---`

**Step 3: Commit**

```bash
git add time-energy-manager/SKILL.md
git commit -m "feat: add SKILL.md skeleton with frontmatter and database references"
```

---

### Task 5: Write `SKILL.md` — Fase 1: Morning Plan

Append the Morning Plan workflow to SKILL.md.

**Files:**
- Modify: `time-energy-manager/SKILL.md` (append after filtri critici section)

**Step 1: Append Phase 1**

Append the following to the end of `SKILL.md`:

```markdown

## Fase 1 — Morning Plan (5 min)

**Trigger:** "buongiorno", "morning plan", "pianifica la giornata", "inizia la giornata"

### Step 1: Leggi contesto (automatico)

Query Notion in parallelo:

1. **Ultima Weekly Review:** Cerca in SECOND BRAIN la pagina piu recente con titolo "Weekly Review —". Estrai: priorita della settimana, numero/metrica, perche.
2. **Task del giorno:** Da Tasks, filtra `Status != Done` AND (`Due Date = oggi` OR `Due Date` e scaduta). Da Planning board, filtra `Status = [giorno della settimana corrente in italiano, es. "Lunedi"]`.
3. **Progetti trimestre:** Da PROJECTS, filtra `Quarter = Q[trimestre corrente]` AND `Status = In progress` AND `Legacy = false`.
4. **Ideal Week:** Consulta `references/ideal-week.md` per il template del giorno corrente. Determina se e settimana Sprint A o B.

### Step 2: Energy check-in (30 sec)

Chiedi all'utente:
> "Come ti senti stamattina? (1-5)"

Se l'utente vuole aggiungere contesto (opzionale):
> "Qualcosa di specifico che ti pesa o ti carica oggi?"

### Step 3: Genera piano adattivo

Basato su: priorita settimanali + task del giorno + energia + template ideal week del giorno.

**Logica energia:**

| Energia | Strategia |
|---------|-----------|
| 4-5 | Deep work creativo prima, admin dopo. Proponi task ambiziosi per il blocco 9:10-10:10. |
| 3 | Task importanti ma non creativi. Alterna focus e pause. Blocco 9:10-10:10 per studio/review. |
| 1-2 | Solo task essenziali e scadenze. Proteggi energia. Blocco 9:10-10:10 opzionale. Suggerisci pausa extra. |

**Struttura blocchi** (usa il template del giorno da ideal-week.md, adattando in base a energia):

```
### Blocchi del giorno

🔵 09:10-10:10 → [Side business/studio: task specifico]
⚪ 10:15-10:30 → Daily standup
🔵 10:30-12:00 → Deep work: [task specifico dal backlog]
⚡ 12:00-12:15 → PAUSA — stacca, cammina
🟡 12:15-13:00 → Admin / task leggeri
🟠 13:00-13:30 → Pranzo con famiglia
🟡 13:30-14:00 → Rientro morbido
⚡ 14:00-14:15 → PAUSA
🔵 14:15-15:45 → Deep work: [task specifico]
⚡ 15:45-16:00 → PAUSA
🟡 16:00-17:00 → Admin / chiusura
⚡ 17:00-17:20 → Reset break
🟢 17:20-17:50 → Sviluppo personale: [task specifico]
📋 17:50-18:00 → Evening Close
```

Icone: 🔵 focus | 🟡 leggero | ⚡ pausa | 🟢 personale | 🟠 famiglia | ⚪ meeting

**Concludi SEMPRE con:**
> "Oggi se fai [X], [Y] e [Z] → stasera puoi staccare tranquillo."

Dove X, Y, Z sono le 3 priorita reali della giornata (non tutti i task, solo quelli che contano).

### Step 4: Conferma utente

Presenta il piano e chiedi:
> "Va bene cosi o vuoi cambiare qualcosa?"

Se l'utente modifica, adatta. Se conferma, procedi.

### Step 5: Salva su Notion

Crea una pagina in SECOND BRAIN con:
- **Titolo:** `Piano [data in italiano, es. "24 Febbraio 2026"]`
- **Contenuto:** il piano completo con blocchi, energia, priorita settimana

Struttura pagina:

```markdown
## Piano [data]

**Energia mattina:** [N]/5
**Contesto:** [nota opzionale o "—"]
**Priorita settimana:** [da weekly review]
**Tipo settimana:** Sprint A / Sprint B

### Blocchi del giorno
[lista blocchi con icone come sopra]

**Obiettivo giornata:** Se fai [X], [Y], [Z] → stasera puoi staccare.

---
### Check-in pomeridiano
[completato dalla Fase 2]

---
### Evening Close
[completato dalla Fase 4]
```
```

**Step 2: Verify the section was appended**

Run: `grep -c "Fase 1" time-energy-manager/SKILL.md`
Expected: at least 1

**Step 3: Commit**

```bash
git add time-energy-manager/SKILL.md
git commit -m "feat: add Phase 1 Morning Plan workflow to SKILL.md"
```

---

### Task 6: Write `SKILL.md` — Fase 2: Mid-day Check

**Files:**
- Modify: `time-energy-manager/SKILL.md` (append after Phase 1)

**Step 1: Append Phase 2**

```markdown

## Fase 2 — Mid-day Check (1 min)

**Trigger:** "come sto?", "energy check", "check pomeriggio", "energia"

### Step 1: Energy rating

> "Energia adesso? (1-5)"

### Step 2: Confronta con mattina

Leggi la pagina del Piano di oggi da Notion (cerca in SECOND BRAIN la pagina "Piano [data odierna]").

- Se calo > 2 punti rispetto alla mattina: "Calo significativo. Suggerisco di alleggerire il pomeriggio."
- Se stabile o in salita: "Energia stabile, continua cosi."

### Step 3: Quick status

> "Delle priorita di stamattina ([X], [Y], [Z]), cosa hai fatto?"

- Se in linea: "Stai andando bene. Il pomeriggio concentrati su [priorita rimanente]."
- Se indietro: ricalibra senza giudizio. "Ok, [X] e ancora aperto. Vuoi metterlo nel blocco 14:15 o spostarlo a domani?"

### Step 4: Logica post-lavoro

Se e un giorno con blocco post-lavoro disponibile (Mar, Ven — non Lun/Gio palestra, non Mer bimbo):

| Energia attuale | Suggerimento |
|-----------------|-------------|
| >= 3 | "Dopo le 17 hai il blocco 17:20-17:50. Reset break prima, poi [task personale]." |
| 2 | "Energia bassa. Se vuoi, 20 min di qualcosa leggero dopo le 17. Niente coding." |
| 1 | "Oggi hai dato abbastanza. Dopo le 17 vai diretto a relax. Zero senso di colpa." |

### Step 5: Aggiorna Notion

Aggiorna la pagina del Piano di oggi, sezione "Check-in pomeridiano":

```markdown
### Check-in pomeridiano
**Energia:** [N]/5 | Completati: [lista] | Manca: [lista] → [azione]
```
```

**Step 2: Commit**

```bash
git add time-energy-manager/SKILL.md
git commit -m "feat: add Phase 2 Mid-day Check workflow to SKILL.md"
```

---

### Task 7: Write `SKILL.md` — Fase 3: Pivot

**Files:**
- Modify: `time-energy-manager/SKILL.md` (append after Phase 2)

**Step 1: Append Phase 3**

```markdown

## Fase 3 — Pivot (2 min)

**Trigger:** "e cambiato tutto", "urgenza", "devo spostare", "mi e arrivato...", "cambio piano"

### Step 1: Raccogli info

> "Cos'e successo? Descrivimi la nuova cosa."

### Step 2: Valutazione onesta

Leggi la pagina del Piano di oggi e le priorita settimanali dalla weekly review. Confronta:

> "La priorita della settimana e [X]. Questa nuova cosa e piu importante? Vediamo."

**Matrice decisionale:**

| La nuova cosa... | Azione |
|-------------------|--------|
| Ha scadenza oggi e impatta il cliente | "Si, e prioritaria. Togliamo [task meno urgente] dal piano." |
| E importante ma non urgente | "Non e urgente. Suggerisco di schedularla per [giorno con spazio] e mantenere il piano." |
| E una richiesta di altri ma non critica | "Qualcun altro puo aspettare. La tua priorita oggi e [X]. Rispondi dopo." |
| E ansia/reattivita, non vera urgenza | "Fermati. Questa sembra urgente ma non lo e. Il piano di stamattina e ancora valido." |

**Principio: MAI aggiungere senza togliere.** Se entra qualcosa nel piano, Claude chiede esplicitamente:
> "Ok, aggiungiamo [nuova cosa]. Cosa togliamo? Le opzioni sono: [A], [B], [C]."

### Step 3: Conferma

> "Vuoi procedere con lo switch o mantenere il piano originale?"

### Step 4: Aggiorna Notion

Se l'utente cambia piano, aggiorna la pagina giornaliera con i nuovi blocchi. Aggiungi nota:
> "⚠️ Pivot alle [ora]: [motivo]. Tolto [X], aggiunto [Y]."
```

**Step 2: Commit**

```bash
git add time-energy-manager/SKILL.md
git commit -m "feat: add Phase 3 Pivot workflow to SKILL.md"
```

---

### Task 8: Write `SKILL.md` — Fase 4: Evening Close

**Files:**
- Modify: `time-energy-manager/SKILL.md` (append after Phase 3)

**Step 1: Append Phase 4**

```markdown

## Fase 4 — Evening Close (2 min)

**Trigger:** "ho finito", "chiudo la giornata", "posso rilassarmi?", "evening close", "basta per oggi"

### Step 1: Leggi il piano

Recupera la pagina del Piano di oggi da Notion. Leggi le 3 priorita e i blocchi pianificati.

### Step 2: Cosa hai completato?

> "Cosa hai completato oggi?"

Oppure, se i task Notion sono aggiornati, deducilo dai cambi di status.

### Step 3: Energy rating finale

> "Energia di fine giornata? (1-5)"

### Step 4: Il verdetto

Confronta priorita pianificate vs completate:

| Situazione | Messaggio |
|-----------|-----------|
| Tutte le 3 priorita fatte | "Hai fatto quello che serviva. Rilassati, te lo sei guadagnato." |
| 2 su 3 fatte, la terza non critica | "Giornata solida. [Task mancante] puo aspettare domani. Stacca." |
| 1 su 3 o meno, ma con buon motivo (pivot, energia bassa) | "Giornata imperfetta ma hai protetto le priorita possibili. Va bene cosi." |
| Giornata andata male | "Capita a tutti. Domani ricalibramo con il Morning Plan. Stasera stacca comunque — rimuginare non aiuta." |

**IMPORTANTE:** Il verdetto e SEMPRE orientato al permesso di staccare. Mai chiudere con "avresti dovuto fare di piu". Il senso di colpa non produce risultati, il riposo si.

### Step 5: Nota per domani

> "Qualcosa da ricordare per domani mattina?"

Se si, annotalo. Se no, salta.

### Step 6: Aggiorna Notion

Aggiorna la pagina del Piano di oggi, sezione "Evening Close":

```markdown
### Evening Close
**Energia sera:** [N]/5
**Completati:** [lista]
**Non completati:** [lista + motivo breve]
**Verdict:** [messaggio dal verdetto]
**Nota per domani:** [testo o "—"]
```
```

**Step 2: Commit**

```bash
git add time-energy-manager/SKILL.md
git commit -m "feat: add Phase 4 Evening Close workflow to SKILL.md"
```

---

### Task 9: Write `SKILL.md` — Trigger Mapping + Comandi Extra + Contesto Orario

**Files:**
- Modify: `time-energy-manager/SKILL.md` (append after Phase 4)

**Step 1: Append trigger mapping and extras**

```markdown

## Trigger Mapping

| L'utente dice | Esegui |
|---------------|--------|
| "buongiorno" / "morning plan" / "pianifica la giornata" / "inizia la giornata" | Fase 1 completa |
| "come sto?" / "energy check" / "check pomeriggio" / "energia" | Fase 2 |
| "e cambiato tutto" / "urgenza" / "devo spostare" / "mi e arrivato..." / "cambio piano" | Fase 3 |
| "ho finito" / "chiudo la giornata" / "posso rilassarmi?" / "evening close" / "basta per oggi" | Fase 4 |

## Comandi Extra

| L'utente dice | Azione |
|---------------|--------|
| "settimana tipo" / "ideal week" / "mostrami la settimana" | Mostra il template da `references/ideal-week.md` per il giorno corrente |
| "che settimana e?" / "settimana A o B?" | Calcola settimana ISO dalla data, pari = A, dispari = B (calibrare al primo uso) |
| "pattern energia" / "come va la mia energia?" / "trend" | Analisi pattern da `references/energy-patterns.md` usando le pagine Piano delle ultime 2+ settimane |
| "setup ideal week" / "personalizza settimana" | Sessione guidata per modificare `references/ideal-week.md` |

## Logica di Contesto Orario

Se l'utente attiva lo skill senza un trigger specifico, usa l'ora per suggerire la fase:

| Ora | Default |
|-----|---------|
| Prima delle 10:00 (e nessun Piano di oggi esiste su Notion) | Proponi Fase 1 |
| 12:00-15:00 | Proponi Fase 2 |
| Dopo le 17:00 | Proponi Fase 4 |
| Parole di urgenza in qualsiasi momento | Fase 3 sempre |

## Dependencies

| Servizio | Richiesto | Scopo |
|----------|-----------|-------|
| Notion MCP | Si | Tutte le operazioni database + creazione pagine |
| planning-review-system | No (ma consigliato) | Il Morning Plan legge la weekly review. Senza PRS, salta quel contesto. |

## Principi (applica SEMPRE)

1. **Zero sovraccarico** — ogni touchpoint < 5 min, solo il Morning Plan e consigliato, il resto e opzionale
2. **Quarter > Week > Day** — la gerarchia delle priorita e sempre rispettata
3. **Mai aggiungere senza togliere** — se entra qualcosa nel piano, esce qualcos'altro
4. **Il permesso di staccare** — l'Evening Close esiste per dirti "hai fatto abbastanza"
5. **Onesta radicale** — se qualcosa non e prioritario, lo skill lo dice chiaramente
6. **Rispetta il ritmo** — mai proporre sveglia alle 6 o sacrificare famiglia/relax
7. **Pause non negoziabili** — integrate nel piano, non opzionali
```

**Step 2: Verify complete SKILL.md**

Run: `wc -l time-energy-manager/SKILL.md`
Expected: ~250-300 lines

Run: `grep -c "## Fase" time-energy-manager/SKILL.md`
Expected: 4

**Step 3: Commit**

```bash
git add time-energy-manager/SKILL.md
git commit -m "feat: add trigger mapping, extras, and principles to SKILL.md"
```

---

### Task 10: Final review + publish commit

**Files:**
- Review: `time-energy-manager/SKILL.md`
- Review: `time-energy-manager/references/ideal-week.md`
- Review: `time-energy-manager/references/energy-patterns.md`

**Step 1: Verify all files exist**

Run: `find time-energy-manager/ -type f | sort`
Expected:
```
time-energy-manager/SKILL.md
time-energy-manager/references/energy-patterns.md
time-energy-manager/references/ideal-week.md
```

**Step 2: Verify SKILL.md frontmatter is valid**

Run: `head -3 time-energy-manager/SKILL.md`
Expected: starts with `---`

**Step 3: Verify all 4 phases are present**

Run: `grep "## Fase" time-energy-manager/SKILL.md`
Expected:
```
## Fase 1 — Morning Plan (5 min)
## Fase 2 — Mid-day Check (1 min)
## Fase 3 — Pivot (2 min)
## Fase 4 — Evening Close (2 min)
```

**Step 4: Verify database references are present**

Run: `grep "collection://" time-energy-manager/SKILL.md`
Expected: 3 collection URLs (Tasks, PROJECTS, Planning)

**Step 5: Read through SKILL.md for coherence**

Read the full file. Check:
- No placeholder text remaining
- All Notion IDs are real (match planning-review-system)
- Trigger mapping is complete
- Energy logic is consistent across phases
- Italian text is natural

**Step 6: Final commit with all files**

```bash
git add -A time-energy-manager/
git status
git commit -m "feat: complete time-energy-manager skill (#next-pr-number)

Add Time & Energy Manager skill with 4-phase daily workflow:
- Morning Plan: energy-adaptive daily planning from weekly review
- Mid-day Check: quick energy rating and recalibration
- Pivot: honest priority evaluation when plans change
- Evening Close: permission to disconnect with daily recap

Includes Ideal Week template and Energy Patterns reference guide.
Complements planning-review-system (PRS handles weekly/quarterly,
TEM handles daily execution and energy management)."
```
