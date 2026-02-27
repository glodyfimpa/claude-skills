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
