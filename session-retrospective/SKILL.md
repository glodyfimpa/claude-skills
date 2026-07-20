---
name: session-retrospective
description: >
  Rito di fine sessione, una domanda sola: è successo qualcosa di raro che cambia il domani
  in meglio? L'esito normale è "niente, chiudi". Se c'è una scintilla, il mostra-vicini cerca
  i simili già nel brain e li mette davanti, così una lezione si fonde/aggiorna invece di
  duplicare, e un'idea-strumento si controlla contro ciò che esiste già. Tre esiti: LEZIONE →
  principles/hook; SEME-STRUMENTO forma-A → commessa nella build-queue degli autonomous-agents;
  serve-la-tua-testa → appuntamento in calendario. Assorbe revise-claude-md nel ramo LEZIONE.
  Triggers (Italian): "retrospettiva sessione", "session retrospective", "cosa salvo di oggi?",
  "è emerso qualcosa da tenere?", "chiudiamo la sessione", "/session-retrospective",
  "pattern da automatizzare", "cosa posso automatizzare?". Non è un magazzino: la barra è alta,
  l'esito più frequente e più onorevole è "niente da salvare".
---

# Session Retrospective — il rito a una domanda

A fine sessione, **una domanda sola**:

> **È successo qualcosa di raro che cambia il domani in meglio?**

"In meglio" = più qualità in meno tempo, produttività per efficienza non per fatica, migliora
la mia vita o quella d'altri, se possibile fa guadagnare. L'**esito normale è NIENTE** — la
maggior parte delle sessioni non insegna niente di raro, e va bene così: chiudi senza output.

Questo rito ha il default giusto. Il vecchio rito partiva da "cerchiamo cosa automatizzare" e
ti spingeva a produrre output da ogni sessione → rumore, cimiteri, cose che esistono già. Qui
non chiedi "cosa automatizzo?" (che pretende un output): chiedi "è successo qualcosa di raro?"
(che si aspetta un no).

## Passo 1 — la scintilla (o niente)

Ripercorri la sessione e cerca UNA scintilla: una lezione pagata con un errore, una frizione
che si è ripetuta, un'idea di strumento maturata sul campo. **Barra alta**: si salva solo ciò
che "cambia il domani in meglio", non la frequenza di un gesto.

**Self-check obbligatorio, scritto esplicitamente PRIMA di eseguire il mostra-vicini** (non
dopo, non in testa): rispondi per iscritto a — *"tolta la mia soddisfazione di averla notata,
questa scintilla cambia il domani in meglio, o è solo un episodio vivido perché è appena
successo?"* Se non hai un caso concreto di beneficio futuro (non "è interessante", non "si è
ripetuto nella sessione"), è rumore: fermati qui, non procedere al mostra-vicini. Il bias da
intercettare: un episodio ripetuto PIÙ VOLTE NELLA STESSA sessione sembra "leva" solo perché è
fresco e vivido — ma la frequenza dentro una sessione non è la stessa cosa della frequenza tra
sessioni diverse (quella la misura la famiglia di lezioni già esistente, non questo rito).
Verificato 2026-07-20: due "scintille" proposte (un dominio nuovo per verify-before-react, un
pattern sintomo-vs-causa) erano entrambe già coperte nello spirito da principi esistenti — il
mostra-vicini le avrebbe comunque agganciate a vicini forti, ma il self-check le avrebbe fermate
un passo prima, senza nemmeno investigare.

Se non c'è scintilla (o il self-check la boccia) → **dillo e chiudi**: "Niente di raro da
salvare oggi." Fine. Non forzare.

Se c'è, e il self-check la conferma → una frase asciutta che la descrive, e vai al Passo 2.

## Passo 2 — il mostra-vicini (il fulcro)

Prima di salvare QUALSIASI cosa, cerca i simili già nel brain. Esegui (path assoluto —
funziona da qualsiasi cwd; a fine sessione sei nella working-dir del lavoro, non nella skill-dir):

```bash
~/.claude/skills/session-retrospective/bin/show-neighbors "<la scintilla in una frase>"
```

I default sono già giusti (`--vault ~/Documents/brain`, `--skills ~/.claude/skills`); passa
`--vault`/`--skills` solo per puntare altrove nei test.

Stampa i frammenti del brain che condividono più parole-chiave con la scintilla, dal più
simile, dentro il perimetro: `principles/*.md` (dove vive una LEZIONE), `memory/MEMORY.md`
(l'indice sempre caricato), `areas/**/CLAUDE.md` (regole d'area), e le skill installate
(`~/.claude/skills/*/SKILL.md` — per "già coperto da uno strumento").

Il mostra-vicini fa **tre lavori in un gesto**:

1. **Già-coperto** — ti dice se una cosa esiste già ("ce l'hai in X, non ricostruirla").
2. **Appiglio** — coi vicini davanti capisci in un secondo se è nuova o l'ennesima variante.
3. **Oblio** — salvare guardando i vicini = fondere/aggiornare invece di duplicare. Cattura ed
   eliminazione nello stesso gesto; nessun consolidamento schedulato a parte.

Se il mostra-vicini dice **"nessun vicino"** → la scintilla è nuova, nasce ex-novo nel ramo
giusto. Se mostra vicini forti → **fondi/aggiorna quel file**, non crearne uno nuovo. Se un
vicino la copre già del tutto → **è già coperta, non salvare** (dillo a Glody e chiudi).

## Passo 3 — i tre esiti (nessuno è un magazzino)

```
scintilla (dopo il mostra-vicini)
   │
   ├─ LEZIONE — cambia il giudizio dove ripaghi un errore
   │     → principles/ (globale) o CLAUDE.md d'area (trasversale d'area) o un hook.
   │       Si salva GUARDANDO i vicini: fondi/aggiorni un simile invece di duplicare.
   │       (Questo ramo assorbe il vecchio revise-claude-md — vedi sotto.)
   │
   ├─ SEME-DI-STRUMENTO forma-A — un agente headless lo costruisce DA SOLO
   │     → COMMESSA nella coda pulita (build-queue.md degli autonomous-agents).
   │       Forma-A = codice puro testabile con editor + test runner (calcolatori,
   │       linter, parser, generatori, librerie, skill di sola logica). NON forma-A
   │       se serve browser su sito loggato, MCP dell'app, o il vault a runtime.
   │
   ├─ SERVE-LA-TUA-TESTA — design/browser/giudizio, non automatizzabile headless
   │     → APPUNTAMENTO in calendario (evento Google Calendar con prompt cold-start:
   │       frase-trigger, path dei file, fatto-vs-resta). Pattern manuale, NON un tool.
   │
   └─ NON DECISO ("forse un giorno") — NON si parcheggia. È una lezione
         ("quando rifaccio X, valuta se automatizzarlo") che riemerge alla prossima
         frizione reale. Niente limbo, niente contatori di occorrenze.
```

### Ramo LEZIONE — assorbe revise-claude-md

Quando l'esito è LEZIONE, il gesto è quello dell'ex `revise-claude-md`, ma con il mostra-vicini
davanti (che revise-claude-md non aveva):

1. **Formula la lezione** in una riga: `<gesto/regola> — <perché conta / cosa fare>`.
2. **Guarda i vicini** (Passo 2): se un principle/CLAUDE.md/memory già simile esiste, **fondi lì**
   (aggiorna la riga, aggiungi l'occorrenza) invece di scriverne una nuova.
3. **Scegli la casa** (dall'albero d'instradamento del brain):
   - regola che regge FUORI dal suo dominio d'origine → `principles/` (globale);
   - regola trasversale a un'area → `CLAUDE.md` di quella cartella d'area;
   - gesto-predicato deterministico (un check su un path, un campo, un diff) → un **hook**,
     non una regola-testo (una regola-testo su un gesto-predicato è un ponte provvisorio).
4. **Mostra il diff** a Glody prima di scrivere (sezione + righe esatte, `+`/`~`), poi applica
   solo su conferma. Una riga per concetto, stesso stile del file, mai duplicare, mai rimuovere
   contenuto salvo che sia stato corretto in questa sessione.

### Ramo SEME-STRUMENTO — la commessa

Se e solo se la scintilla è **forma-A** e i vicini confermano che non esiste già: accoda UNA
commessa in `~/Documents/brain/areas/ai-automation/build-queue.md` con il contratto stretto
(`queue_parser.append_voice`). Campi che scrivi tu: `slug` (kebab), `title` (testo semplice, no
backtick), `repo_target` (`claude-skills` | `bnb-investment-toolkit` | `claude-autopilot` |
`life-os`), `effort` (`simple`|`standard`|`complex`), `notes` (opzionale). Il campo `added`
(data di enqueue) lo auto-compila `append_voice` — non scriverlo. Ordine = priorità (il Builder
pesca la prima).
Il motore è oggi spento: a motore spento lanci tu il Builder; a motore acceso lo fa lui — **mai
entrambi i canali per la stessa voce** (coda XOR calendario: una voce non sta in coda e in
calendario insieme).

## Cosa NON fare

- Niente magazzino da potare, niente `# Idee da sessione [data]`, niente contatori di occorrenze
  (misuravano la frequenza, non la leva). Il vecchio `backlog-skill.md` è archiviato (Fronte 3).
- Niente output forzato da una sessione che non ha insegnato niente: "niente da salvare" è l'esito
  più frequente e più onorevole.
- Niente doppioni: se il mostra-vicini segnala che esiste già, marca "già coperta" e chiudi.
- Niente motore di consolidamento schedulato a parte: il consolidamento È il mostra-vicini.
