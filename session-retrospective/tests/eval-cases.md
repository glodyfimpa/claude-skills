# Eval Cases — session-retrospective (rito a una domanda)

Casi-spec per il rito riscritto (Fronte 2, 2026-07-15). Ogni caso descrive una sessione, la
scintilla (o la sua assenza), e cosa il rito deve fare. Un caso fallisce se la SKILL.md manca del
comportamento atteso o ne contiene uno contraddittorio.

La meccanica del **mostra-vicini** ha i suoi test automatici (`tests/test_neighbors.py`,
`tests/test_show_neighbors.bats`); questi eval-case coprono il GIUDIZIO del rito attorno ad essa.

---

## TC-01 — Sessione senza scintilla → niente da salvare

**Setup.** Sessione di lavoro ordinaria: qualche fix, un paio di ricerche, nessun errore pagato,
nessuna frizione ripetuta, nessuna idea di strumento maturata.

**Atteso.** Il rito risponde "Niente di raro da salvare oggi" e chiude. NON forza un output, NON
apre il mostra-vicini, NON propone skill/idee. L'esito "niente" è quello normale e onorevole.

**Criterio.** La SKILL.md dichiara esplicitamente che l'esito più frequente è "niente" e che non
si forza output da una sessione che non ha insegnato niente.

## TC-02 — Scintilla nuova → mostra-vicini dice "nessuno" → nasce ex-novo

**Setup.** È emersa una lezione genuinamente nuova (nessun frammento simile nel brain). Il
mostra-vicini stampa "nessun vicino".

**Atteso.** La lezione si salva ex-novo nel ramo giusto (LEZIONE → principles/CLAUDE.md-area/hook).
Il mostra-vicini gira PRIMA di salvare.

**Criterio.** La SKILL.md prescrive di eseguire `bin/show-neighbors` prima di salvare qualsiasi cosa,
e di far nascere ex-novo solo quando non ci sono vicini.

## TC-03 — Scintilla che duplica un vicino forte → fondi, non duplicare

**Setup.** È emersa una lezione. Il mostra-vicini mostra un principle esistente che la copre già
al 90%+ (score alto, stesse parole-chiave).

**Atteso.** Il rito NON crea una riga nuova: aggiorna/fonde il file vicino (aggiunge l'occorrenza o
affina la riga esistente). Se il vicino la copre del tutto, marca "già coperta" e chiude senza scrivere.

**Criterio.** La SKILL.md prescrive di fondere nel vicino invece di duplicare, e di non salvare se
un vicino copre già del tutto.

## TC-04 — Seme-strumento forma-A → commessa in coda

**Setup.** È maturata un'idea di strumento costruibile headless (codice puro testabile: es. un
linter, un parser). Il mostra-vicini conferma che non esiste già una skill che lo copre.

**Atteso.** Il rito accoda UNA commessa in `build-queue.md` col contratto stretto (slug/title/
repo_target/effort/notes via `queue_parser.append_voice`; `added` è auto-compilato, non si
scrive). NON la mette anche in calendario (coda XOR calendario).

**Criterio.** La SKILL.md descrive l'accodamento col contratto e l'invariante "un canale solo per voce".

## TC-05 — Seme che serve la tua testa → appuntamento calendario

**Setup.** È emerso un lavoro rinviato che richiede giudizio umano / browser su sito loggato /
design (NON forma-A).

**Atteso.** Il rito crea un evento Google Calendar con prompt cold-start (frase-trigger, path file,
fatto-vs-resta). NON lo accoda in build-queue (il Builder headless non saprebbe finirlo).

**Criterio.** La SKILL.md distingue forma-A (coda) da serve-la-tua-testa (calendario) e non confonde i canali.

## TC-06 — Ramo LEZIONE assorbe revise-claude-md

**Setup.** La scintilla è una lezione di metodo (es. "prima di X, verifica Y sul reale").

**Atteso.** Il rito applica il gesto dell'ex revise-claude-md — formula la riga, guarda i vicini,
sceglie la casa (globale/area/hook), mostra il diff a Glody, applica su conferma — SENZA che serva
invocare una skill separata revise-claude-md.

**Criterio.** La SKILL.md contiene il ramo LEZIONE con i 4 passi (formula → vicini → casa → diff+conferma)
e dichiara di assorbire revise-claude-md.
