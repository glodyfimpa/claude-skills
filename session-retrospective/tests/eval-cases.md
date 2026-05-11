# Eval Cases — session-retrospective (Fase 1.7)

These cases are the spec for Fase 1.7 of the session-retrospective skill: the `/find-skills` cross-check
that verifies a candidate skill does not already exist locally before proposing it to the user.

Each case has:
- **Setup**: what emerged from the session scan, and what `/find-skills` returns
- **Expected**: what Claude must do in response
- **Pass criterion**: how to verify the skill contains this behavior

Run a manual eval by reading `SKILL.md` and checking each case against the Fase 1.7 guidance.
A case fails when the skill is missing the expected behavior or contains contradicting guidance.

---

## TC-01 — Skill identico trovato → scarta silenziosamente

**Setup**

La Fase 1 identifica una sequenza multi-step: l'utente ha esportato documenti da Notion, li ha caricati
su Drive, e ha estratto metadati in CSV. Claude propone come candidato: `document-exporter`.

`/find-skills` restituisce un match ad alta confidenza: lo skill `document-collector` copre esattamente
la sequenza (Notion export → Drive upload → metadata extraction). Copertura stimata: 95%+.

**Expected**

Claude scarta silenziosamente il candidato. Non lo menziona nel report finale. Non chiede all'utente
cosa fare. Il report di Fase 3 elenca solo candidati che hanno superato il cross-check.

**Pass criterion**

SKILL.md Fase 1.7 contiene una regola esplicita: se il match supera una soglia di copertura (es. ≥90%),
il candidato viene scartato senza apparire nel report. La soglia deve essere dichiarata numericamente.

---

## TC-02 — Copertura parziale (~70%) → segnalazione "estendi lo skill esistente"

**Setup**

La Fase 1 identifica: l'utente ha iterato 4 volte su un processo di review di PR con checklist custom
(sicurezza, performance, leggibilità, test coverage). Candidato proposto: `pr-review-toolkit`.

`/find-skills` restituisce un match parziale: lo skill `code-review:code-review` copre review generica
ma non la parte checklist custom né il loop multi-iterazione. Copertura stimata: ~70%.

**Expected**

Claude segnala il match parziale nel report. Invece di proporre `pr-review-toolkit` come skill nuovo,
suggerisce di estendere `code-review:code-review` con i gap identificati (checklist custom, loop).
Indica esplicitamente i gap: cosa manca nello skill esistente rispetto al pattern osservato.

**Pass criterion**

SKILL.md Fase 1.7 distingue tra match completo (≥90%) e match parziale (50-89%). Per il caso parziale
deve contenere istruzioni a presentare il candidato come "miglioramento skill esistente" con lista dei gap,
non come skill nuovo.

---

## TC-03 — Alta frequenza (≥3 occorrenze) + duplicato esatto → segnalazione della frequenza

**Setup**

La Fase 1 trova che l'utente ha eseguito la stessa sequenza di deploy 5 volte durante la sessione:
`git push` → attesa CI → check Notion status → aggiornamento manuale del campo. Candidato: `ci-deploy-tracker`.

`/find-skills` restituisce un match esatto (95%+): lo skill `planning-review-system` include già un
passo di aggiornamento Notion post-CI. Copertura: ~92%.

In aggiunta, la Fase 1 rileva che questa sequenza è apparsa ≥3 volte nella sessione corrente.

**Expected**

Il candidato viene scartato (match esatto). Tuttavia, anche se scartato, Claude segnala all'utente la
frequenza elevata (5 occorrenze) come dato rilevante: "Il pattern è già coperto da `planning-review-system`,
ma la sua frequenza (5×) suggerisce di lanciare quello skill o automatizzare il trigger."

Il messaggio è costruttivo, non ridondante: non ripete "già coperto" due volte, ma aggiunge il valore
della frequenza come segnale d'azione.

**Pass criterion**

SKILL.md Fase 1.7 specifica che, anche in caso di scarto per duplicato, se la frequenza osservata
è ≥3 occorrenze, Claude aggiunge una nota separata sulla frequenza con suggerimento d'azione concreto
(es. "lancia X" o "automatizza il trigger"). La frequenza soglia deve essere dichiarata numericamente.

---

## TC-04 — Skill esistente con descrizione obsoleta/non pertinente → segnalazione + delega utente

**Setup**

La Fase 1 identifica: l'utente ha configurato più volte impostazioni di deploy su tre ambienti diversi
(staging, prod, preview) usando file `.env` distinti con logica di merge. Candidato: `env-config-manager`.

`/find-skills` restituisce un match nominale: esiste uno skill `update-config`, ma la sua descrizione
parla esclusivamente di configurazione del harness Claude Code (settings.json, hooks, permissions),
non di deploy environments o `.env` files. Il nome coincide vagamente ma il dominio è completamente diverso.

**Expected**

Claude non scarta il candidato e non lo tratta come match parziale. Invece, segnala all'utente:
lo skill `update-config` esiste ma copre un dominio diverso. Chiede all'utente di decidere se:
(a) `env-config-manager` è davvero un nuovo skill separato, o (b) `update-config` va aggiornato per
includere anche env management.

Claude non prende la decisione autonomamente perché il confine di dominio è ambiguo.

**Pass criterion**

SKILL.md Fase 1.7 prevede un caso "falso positivo per nome": quando il match è solo nominale (descrizione
non pertinente al dominio del candidato), Claude segnala l'ambiguità e delega la decisione all'utente
con le due opzioni esplicite (nuovo skill vs estensione). Non scarta silenziosamente, non assume automaticamente
che siano la stessa cosa.

---

## TC-05 — Nessun match trovato → candidato passa a Fase 2 normalmente

**Setup**

La Fase 1 identifica: l'utente ha analizzato 3 appartamenti BnB, calcolato ROI stimato per ognuno,
e generato un report comparativo in markdown. Candidato: `bnb-roi-comparator`.

`/find-skills` non trova alcun match. Nessuno skill installato copre analisi comparativa di immobili
BnB con calcolo ROI.

**Expected**

Claude procede normalmente a Fase 2 con il candidato `bnb-roi-comparator` intatto. Nessun messaggio
aggiuntivo sul cross-check (il silenzio sul check è il comportamento atteso per il caso "tutto ok").
Il candidato viene presentato in Fase 3 come skill nuovo con la struttura standard: nome, tipo, cosa
automatizza, trigger di esempio, effort, priorità.

**Pass criterion**

SKILL.md Fase 1.7 specifica che, in assenza di match, il candidato passa al flusso normale senza
modifiche e senza messaggi aggiuntivi sul cross-check. Il comportamento "nessun match" deve essere
il caso neutro, non un caso che genera output extra.

---

## Come eseguire questo eval

1. Leggi `SKILL.md` sezione Fase 1.7 (quando esiste)
2. Per ogni caso, verifica il pass criterion
3. Segna pass/fail per ogni TC
4. Un caso fail significa che SKILL.md deve essere aggiornato prima di mergiare

Lo skill è "green" quando tutti e 5 i casi passano.

| ID | Descrizione | Pass |
|----|-------------|------|
| TC-01 | Skill identico → scarto silenzioso | [ ] |
| TC-02 | Copertura parziale → segnala gap | [ ] |
| TC-03 | Alta frequenza + duplicato → nota frequenza | [ ] |
| TC-04 | Match nominale obsoleto → delega utente | [ ] |
| TC-05 | Nessun match → passa avanti senza rumore | [ ] |
