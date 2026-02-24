# Time & Energy Manager — Design Document

**Data:** 2026-02-24
**Tipo skill:** Ibrido (Claude + Notion via MCP)
**Skill ID:** `time-energy-manager`
**Dominio:** Produttivita
**Complemento di:** planning-review-system

---

## Problema

Lavoro full-time 9-17, figlio piccolo, 2 side business (BnB Airbnb, EditorialMente), patente da prendere, inglese da migliorare. Il problema non e solo il tempo scarso ma:

1. Arrivo svuotato alle ore side business e relax
2. Nessuna struttura giornaliera — le urgenze vincono sempre
3. Gap tra weekly review (PRS) e esecuzione quotidiana
4. Nessun "permesso di staccare" — senso di colpa anche quando hai fatto abbastanza

L'obiettivo non e fare di piu. E fare il giusto e poi vivere.

---

## Architettura

### Struttura file

```
time-energy-manager/
├── SKILL.md              # Skill principale con workflow completo
├── references/
│   ├── ideal-week.md     # Template settimana tipo personalizzata
│   └── energy-patterns.md # Guida interpretazione pattern energetici
```

### Database Notion (riuso esistenti)

| Database | Collection ID | Uso |
|----------|--------------|-----|
| Tasks | `collection://8e608c2b-6cbb-46a2-b233-fffc0b4f5e21` | Leggere task del giorno (due date, status) |
| PROJECTS | `collection://38d9dc09-59f1-4f94-b36b-f62ab9772ac6` | Bussola trimestrale |
| Planning | `collection://2dde510c-5e59-81a5-b80e-000bf6f27cce` | Leggere task assegnati per giorno (status = giorno settimana) |

Nessun database nuovo. Le pagine giornaliere vengono create come child page nel SECOND BRAIN.

### Collegamento con PRS

```
Quarter Goals --> Weekly Review (PRS) --> Morning Plan (TEM) --> Daily Execution
                         ^                        |
                  Weekly Pattern <-- Energy Data <-- Check-ins
```

Il Morning Plan legge l'ultima weekly review. L'Evening Close scrive dati che il PRS usa nella prossima weekly review.

---

## Workflow — 4 Fasi

### Fase 1 — Morning Plan (5 min)

**Trigger:** "buongiorno", "morning plan", "pianifica la giornata", "inizia la giornata"

1. **Leggi contesto** (automatico)
   - Ultima weekly review dal Planning
   - Task con status = giorno corrente dal Planning board
   - Task con due date = oggi dal Tasks database
   - Progetti attivi del trimestre dal PROJECTS

2. **Energy check-in** (30 sec)
   - "Come ti senti stamattina? (1-5)"
   - Opzionale: "Qualcosa di specifico che ti pesa o ti carica oggi?"

3. **Proposta piano adattivo** (Claude genera)
   - Basato su: priorita settimanali + task del giorno + livello energia
   - Energia alta (4-5): deep work prima, admin dopo
   - Energia media (3): task importanti ma non creativi, alterna con pause
   - Energia bassa (1-2): solo task essenziali, proteggi l'energia
   - Blocchi orari con pause ogni 90 min integrate
   - Indica: "Oggi se fai X, Y, Z puoi rilassarti stasera tranquillo"
   - Conosce se e settimana sprint A o B per adattare i blocchi

4. **Conferma utente** — accetta, modifica, o chiede alternative

5. **Salva su Notion** — crea pagina giornaliera

### Fase 2 — Mid-day Check (1 min)

**Trigger:** "come sto?", "energy check", "check pomeriggio", "energia"

1. "Energia adesso? (1-5)"
2. Confronta con mattina: se calo > 2 punti, suggerisce adattamento
3. Quick status: "Delle priorita di stamattina, cosa hai fatto?"
4. Se in linea: "Stai andando bene, continua cosi"
5. Se indietro: ricalibra senza giudizio
6. Aggiorna pagina Notion

### Fase 3 — Pivot (2 min)

**Trigger:** "e cambiato tutto", "urgenza", "devo spostare", "mi e arrivato...", "cambio piano"

1. "Cos'e successo?"
2. Valutazione onesta vs. priorita settimanali:
   - "Questa cosa e piu importante di [obiettivo settimana]? Si/No e perche"
   - Se non prioritaria: lo dice, suggerisce di rinviare
   - Se prioritaria: propone cosa togliere per fare spazio
3. Principio: mai aggiungere senza togliere
4. "Vuoi procedere o mantenere il piano originale?"
5. Aggiorna Notion se cambia qualcosa

### Fase 4 — Evening Close (2 min)

**Trigger:** "ho finito", "chiudo la giornata", "posso rilassarmi?", "evening close", "basta per oggi"

1. Legge piano della mattina da Notion
2. "Cosa hai completato oggi?"
3. Energy rating fine giornata (1-5)
4. Verdetto:
   - Priorita fatte: "Hai fatto quello che serviva. Rilassati."
   - Non tutto ma il possibile: "Giornata imperfetta ma hai protetto le priorita. Va bene cosi."
   - Giornata andata male: "Capita. Domani ricalibramo. Stasera stacca comunque."
5. Nota opzionale per domani
6. Aggiorna Notion con recap + energy finale

---

## Struttura Pagina Giornaliera Notion

Titolo: "Piano [data]" (es. "Piano 24 feb 2026")

```markdown
## Piano 24 feb 2026

**Energia mattina:** 4/5
**Priorita settimana:** [da weekly review]
**Tipo settimana:** Sprint A / Sprint B

### Blocchi del giorno
- 09:10-10:10 -> Side business: [task]
- 10:15-10:30 -> Daily standup
- 10:30-12:00 -> Deep work: [task lavoro]
- 12:00-12:15 -> PAUSA
- 12:15-13:00 -> Admin / task leggeri
- 13:00-13:30 -> Pranzo con famiglia
- 13:30-14:00 -> Rientro morbido
- 14:00-14:15 -> PAUSA
- 14:15-15:45 -> Deep work: [task lavoro]
- 15:45-16:00 -> PAUSA
- 16:00-17:00 -> Admin / chiusura
- 17:00-17:20 -> Reset break
- 17:20-17:50 -> Sviluppo personale: [task]
- 17:50-18:00 -> Evening Close

**Obiettivo giornata:** Se fai X, Y, Z -> stasera puoi staccare.

---
### Check-in pomeridiano
**Energia:** _/5 | Completati: _ | Manca: _ -> [ricalibrazione]

---
### Evening Close
**Energia sera:** _/5
**Completati:** _
**Verdict:** [messaggio]
**Nota per domani:** [opzionale]
```

---

## Ideal Week Template

### Vincoli fissi

- Lavoro: Lun-Ven 9:00-17:00 (remoto, ADESSO - GNV)
- Pranzo: 13:00-13:30 con famiglia
- Palestra: Lun+Gio, esce 17:00, rientra ~19:30
- Compagna palestra: Mer, esce 17:30, rientra ~20:00 (lui col bimbo)
- Aperitivo famiglia: Ven dalle 18:00
- Domenica: OFF totale
- Sonno: mezzanotte-1:00 -> sveglia 8:20

### Meeting ricorrenti

- Daily standup: Lun-Ven 10:15-10:30
- Daily cliente (ogni 3 settimane): 10:45-11:00
- Refinement: Lun+Gio 11:00-13:00
- Sprint review prep: ogni 2 Lun 15:30-16:00
- Settimana A (sprint): Mar 09:30-11:00 Sprint Review + 11:30-13:00 Planning 1 + 15:00-16:00 Planning 2
- Settimana B: Mar 11:30-13:00 Tech Review
- Retrospective: ogni 2 Mer

### Finestra d'oro: 9:00-10:15

Ogni mattina lavorativa, ~1h prima dei meeting. Lo skill protegge questo blocco per side business e studio personale.

### Regole pause

- Mai piu di 90 min consecutivi di deep work -> 10-15 min pausa
- Dopo meeting lungo (>1h) -> 5-10 min micro-reset
- 13:30-14:15 -> rientro morbido, niente deep work
- 14:00-14:15 -> early afternoon reset
- Transizione post-lavoro (17:00-17:20) -> reset break prima dello sviluppo personale

### Logica energia post-lavoro

- Energia >= 3/5 -> propone blocco 17:20-17:50 con reset break
- Energia = 2/5 -> solo 20 min di qualcosa leggero (lettura, review)
- Energia = 1/5 -> "Oggi hai dato abbastanza. Vai diretto a relax."

### Budget tempo settimanale side business/studio

- Lun-Ven 9:00-10:15: ~5h/settimana
- Mar/Ven 17:20-17:50: ~1h/settimana (se energia lo permette)
- Sabato: ~2h (quando possibile)
- Totale: 7-8h/settimana

---

## Trigger Mapping

### Fasi principali

| Trigger | Fase |
|---------|------|
| "buongiorno", "morning plan", "pianifica la giornata", "inizia la giornata" | Fase 1 — Morning Plan |
| "come sto?", "energy check", "check pomeriggio", "energia" | Fase 2 — Mid-day Check |
| "e cambiato tutto", "urgenza", "devo spostare", "mi e arrivato...", "cambio piano" | Fase 3 — Pivot |
| "ho finito", "chiudo la giornata", "posso rilassarmi?", "evening close", "basta per oggi" | Fase 4 — Evening Close |

### Comandi extra

| Trigger | Azione |
|---------|--------|
| "settimana tipo", "ideal week", "mostrami la settimana" | Mostra template Ideal Week |
| "che settimana e?", "settimana A o B?" | Calcola settimana sprint in base alla data |
| "pattern energia", "come va la mia energia?", "trend" | Analisi pattern energetici (2+ settimane) |
| "setup ideal week", "personalizza settimana" | Sessione guidata per modificare il template |

### Logica di contesto orario

| Orario attivazione | Comportamento default |
|--------------------|-----------------------|
| Prima delle 10:00 senza Morning Plan | Propone Fase 1 |
| 12:00-15:00 | Default Fase 2 |
| Dopo le 17:00 | Default Fase 4 |
| Parole di urgenza | Fase 3 sempre |

---

## Energy Patterns (dopo 2+ settimane)

| Pattern rilevato | Suggerimento |
|------------------|-------------|
| Giorno X pomeriggio sempre 1-2 | Metti solo task leggeri quel pomeriggio |
| Energia alta dopo esercizio | I giorni palestra rendi di piu, proteggi il giorno dopo |
| Calo costante post-pranzo | Blocca 13-14 per rientro morbido |
| Giorno Y mattina sempre 4-5 | Proteggi quel blocco per deep work |
| Martedi settimana A sempre basso | Normale — 3 meeting di fila. Calibra aspettative |

---

## Principi di design

1. **Zero sovraccarico** — ogni touchpoint < 5 min, solo il Morning Plan e consigliato, il resto e opzionale
2. **Quarter > Week > Day** — la gerarchia delle priorita e sempre rispettata
3. **Mai aggiungere senza togliere** — se entra qualcosa nel piano, esce qualcos'altro
4. **Il permesso di staccare** — l'Evening Close esiste per dirti "hai fatto abbastanza"
5. **Onesta radicale** — se qualcosa non e prioritario, lo skill lo dice
6. **Rispetta il ritmo** — mai proporre sveglia alle 6 o sacrificare famiglia/relax
7. **Pause non negoziabili** — integrate nel piano, non opzionali
