---
name: session-retrospective
description: >
  Analizza la sessione corrente per identificare pattern ripetitivi che potrebbero diventare skill, command o plugin.
  Lancia questo command verso la fine di una sessione di lavoro, dopo aver completato i task principali. Trigger:
  "cosa posso automatizzare?", "session retrospective", "retrospettiva sessione", "c'è qualcosa da trasformare in skill?",
  "analizza la sessione", "pattern da automatizzare", o qualsiasi richiesta di identificare opportunità di automazione
  dal lavoro appena svolto. Funziona bene in combinazione con /claude-md-management:revise-claude-md (prima questo
  per catturare automazioni, poi revise-claude-md per salvare in memoria).
---

# Session Retrospective

Analizza la sessione corrente per estrarre opportunità di automazione.

## Scopo

Alla fine di una sessione di lavoro, ripercorri quello che è stato fatto e identifica:
- Sequenze di azioni ripetitive che potrebbero diventare **skill**
- Singoli comandi riutilizzabili che potrebbero diventare **command**
- Gruppi di skill/command correlati che potrebbero diventare **plugin**
- Pattern che si ripetono tra sessioni diverse

L'obiettivo è trasformare il lavoro manuale in automazione incrementale: ogni sessione lascia dietro di sé strumenti che rendono la prossima sessione più veloce.

## Workflow

### Fase 1: Scan della sessione

Ripercorri l'intera conversazione e cataloga:

1. **Azioni eseguite**: ogni tool call, bash command, file creato/modificato, ricerca fatta
2. **Sequenze multi-step**: gruppi di azioni che insieme completano un obiettivo (es. "cerca file → filtra → copia → rinomina")
3. **Decisioni prese dall'utente**: scelte che indicano preferenze ricorrenti
4. **Correzioni e aggiustamenti**: dove l'utente ha corretto il corso indica un pattern da codificare

### Fase 1.5: Cross-check con il backlog esistente

Prima di identificare nuovi candidati, controlla la pagina Notion "Skills & Sub-agents per Claude" (cercala su Notion). Leggi la tabella "Status Implementazione" per vedere:
- Quali skill sono già pubblicati (status ✅)
- Quali sono già registrati come idee (status 💡 IDEA)
- Eventuali sezioni "Idee da sessione" da retrospettive precedenti

Se un candidato di questa sessione corrisponde a un IDEA esistente, marcalo come **"confirmed by repetition"** invece di proporlo come nuovo. Più occorrenze indipendenti dello stesso pattern attraverso sessioni diverse sono un segnale forte per dare priorità alla costruzione.

### Fase 1.7: Cross-check con skill installati (/find-skills)

Per ogni candidato che ha superato il check Notion (Fase 1.5), invoca lo skill `/find-skills` cercando skill che coprono lo stesso caso d'uso.

**Default: scarta silenziosamente** se `/find-skills` trova uno skill con copertura ≥90% del caso d'uso. Il candidato non appare nel report finale e non viene menzionato all'utente.

**Segnala invece di scartare** nei quattro casi seguenti:

- **Copertura parziale (50-89%)**: presenta il candidato come "miglioramento skill esistente" anziché skill nuovo. Indica esplicitamente i gap: cosa copre lo skill trovato e cosa manca rispetto al pattern osservato. Suggerisci di estendere lo skill esistente piuttosto che crearne uno nuovo.
- **Pattern ad alta frequenza (≥3 occorrenze nella sessione)**: anche se il match supera ≥90% e il candidato viene scartato, aggiungi una nota separata con il dato di frequenza e un suggerimento d'azione concreto (es. "lancia quello skill" o "automatizza il trigger"). Non ripetere "già coperto" — aggiungi solo il valore della frequenza come segnale d'azione.
- **Match nominale con dominio non pertinente**: se lo skill trovato ha un nome vagamente simile ma la sua descrizione copre un dominio diverso da quello del candidato, non scartare e non trattare come match parziale. Segnala l'ambiguità all'utente con le due opzioni esplicite: (a) il candidato è un nuovo skill separato, o (b) lo skill esistente va aggiornato per includere il nuovo dominio. Non prendere la decisione autonomamente.
- **Skill esistente sembra obsoleto**: la descrizione dello skill trovato non menziona il caso d'uso specifico emerso nella sessione, pur avendo potenziale sovrapposizione. Segnala e lascia decidere all'utente.

Se `/find-skills` non trova nulla di rilevante, il candidato passa a Fase 2 senza messaggi aggiuntivi sul cross-check. Il silenzio è il comportamento atteso per "tutto ok".

### Fase 2: Identificare i candidati

Per ogni sequenza o pattern identificato che ha superato le fasi precedenti, valuta:

**È ripetibile?** Se è un'azione one-off specifica a questa situazione, non serve automatizzarla. Se potrebbe succedere di nuovo (anche in forma leggermente diversa), è un candidato.

**È sufficientemente complesso?** Se sono 1-2 comandi banali, non vale la pena di uno skill. Se sono 3+ step con logica decisionale, sì.

**Esiste già come skill?** Questo viene verificato automaticamente in Fase 1.7 tramite `/find-skills` — non ripetere il controllo manualmente qui.

**Esiste già come idea nel backlog?** Verifica nel backlog Notion (Fase 1.5). Se presente, non presentarlo come scoperta nuova: nota "Già in backlog come [nome] (IDEA, [data]). Questa sessione conferma il pattern — valuta di alzare la priorità."

Categorizza ogni candidato:

| Tipo | Quando | Esempio |
|------|--------|---------|
| **Skill** | Workflow multi-step con logica, riutilizzabile in contesti diversi | Raccolta documenti per pratiche burocratiche |
| **Command** | Azione singola o prompt strutturato da lanciare con un trigger | Retrospettiva di fine sessione |
| **Plugin** | Gruppo di skill + command correlati che servono uno stesso dominio | Toolkit gestione pratiche PA |
| **Miglioramento skill esistente** | Uno skill c'è ma manca qualcosa | Aggiungere ricerca cloud a document-collector |

### Fase 3: Presentare i risultati

Per ogni candidato, presenta:

**Nome proposto**: es. `document-collector`

**Tipo**: skill / command / plugin / miglioramento

**Cosa automatizza**: descrizione concreta di cosa farebbe, basata su quello che è successo nella sessione. Niente astrazioni vaghe, fai riferimento alle azioni reali osservate.

**Trigger di esempio**: 2-3 frasi che l'utente direbbe per attivarlo.

**Effort stimato**: basso (< 30 min), medio (30 min - 2 ore), alto (> 2 ore)

**Priorità suggerita**: basata su frequenza d'uso stimata × tempo risparmiato per utilizzo

### Fase 4: Decidere e agire

Chiedi all'utente cosa vuole fare:

1. **Creare subito** uno o più degli skill/command identificati → usa lo skill-creator se disponibile, altrimenti scrivi il SKILL.md direttamente
2. **Salvare come idea** → aggiungi a un backlog (Notion task, file locale, o semplicemente in CLAUDE.md)
3. **Scartare** → niente da fare, la sessione non ha prodotto pattern automatizzabili

Se l'utente sceglie di creare, procedi immediatamente. Non rimandare a "la prossima sessione".

## Cosa NON è un buon candidato per l'automazione

- Conversazioni e decisioni che richiedono giudizio umano ogni volta
- Azioni eseguite una sola volta per un contesto irripetibile
- Pattern troppo semplici (un singolo comando bash, una query di ricerca)
- Cose che l'utente preferisce fare manualmente per mantenere il controllo

## Suggerimento d'uso

Lancia questo command prima di `/claude-md-management:revise-claude-md`. L'ordine ideale a fine sessione:

1. `/session-retrospective` → identifica cosa automatizzare
2. Crea gli skill/command se deciso
3. `/claude-md-management:revise-claude-md` → salva le nuove conoscenze (inclusi i nuovi skill creati)
