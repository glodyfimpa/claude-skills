---
name: design-review-harness
description: Fa passare una spec o un design attraverso un giro di review multi-agente a mandati distinti, e ne scrive il verdetto. Usa questa skill quando nasce una spec di design (un `*-design.md` sotto `specs/`), quando l'hook design-review-harness te lo ricorda, o quando Glody dice "fai il giro di review", "revisiona questo design", "manda i reviewer". Ogni reviewer guarda una zona diversa (architettura, assunzioni sul reale, implementabilità, cold-reader) e scrive lui stesso il proprio referto su disco. NON usare per code review di un diff (usa /code-review), né per revisionare un piano di esecuzione (fase rinviata al backlog).
---

# Design Review Harness

Il self-review inline non basta. Sulla spec di questo stesso sistema aveva dato **verde**,
mentre un giro esterno a quattro mandati trovava **sei difetti strutturali** — fra cui una
combinazione di decisioni che avrebbe autorizzato un automatismo a cancellare un branch con
`-D`. Il giro non è teatro.

## Cosa fa

Lancia N subagenti in parallelo, ognuno con un **mandato diverso**. Non sono N voti sulla
stessa domanda: ognuno ispeziona una zona che gli altri lasciano in ombra. Poi riconcili i
loro referti e scrivi il verdetto.

## I quattro mandati (fascia piena)

| # | Mandato | La domanda che deve farsi |
|---|---|---|
| 1 | **Architettura + interazione** | C'è una contraddizione di fondo? **Le decisioni si disarmano a vicenda?** |
| 2 | **Assunzioni sul reale** | Per ogni affermazione fattuale: **apri la fonte e guarda.** |
| 3 | **Implementabilità** | Un cold-reader costruisce senza dover re-inventare i pezzi mancanti? |
| 4 | **Cold-reader integrale + pacchetto** | Si capisce a freddo? Ci sono più superfici con rischi e DONE disgiunti in un pacchetto solo? |

**Mandato 1 è quello che nessuno fa.** Il difetto che invalidò la spec del 14/07 non era una
decisione sbagliata: nessuna, presa da sola, lo era. Era sbagliata la loro **combinazione** —
il fix ammorbidiva l'unica guardia che teneva innocui due bug latenti. Un reviewer che valuta
le decisioni una per una non lo vede mai.

**Mandato 2 è il più concreto.** Le sei affermazioni false del 14/07 erano *citazioni a memoria
spacciate per prove*. Il reviewer non valuta se un'affermazione è **plausibile** — apre la fonte
e guarda. Non «questa soglia mi sembra ragionevole», ma «ho aperto `prune_worktrees.py:25`, la
soglia è 2, la spec dice 7». Il referto scrive **cosa ha aperto** e **cosa ci ha visto**.

**Esito legittimo: NON VERIFICABILE.** Un reviewer che non riesce a verificare qualcosa lo
*dichiara*, invece di inventare una conferma. Sulla spec di questo sistema, un «non verificabile»
è ciò che ha fatto partire l'esperimento che ha risolto la questione.

## Profondità: quanti mandati

La profondità scala con la posta in gioco, e **va dichiarata** (campo `fascia` nel verdetto).

- **`piena`** — quattro mandati. Design grosso o irreversibile.
- **`mirata`** — una o due passate. Design piccolo e reversibile.

**Interruttore alta-posta, meccanico (non a tuo giudizio — se decidi tu, torna a essere contesto
passivo).** La spec nomina un'operazione che rimuove o sovrascrive? (`rm`, `git branch -d`,
`--force`, `worktree remove`, `DROP`, un hook che scrive fuori dalla sessione.) Allora è **alta
posta**: fascia piena, e i mandati 1 e 2 ereditano due domande obbligatorie:

- **Quante difese indipendenti restano in piedi dopo il fix, e quante ce n'erano prima?**
- **Il primo run è un dry-run?** (Il `CLAUDE.md` del vault impone «snapshot git pre-batch» sulle
  operazioni distruttive; un dry-run è il modo di ottenerlo senza fidarsi del predicato.)

**Niente mandato "sicurezza" separato.** La sicurezza non è una *zona* dell'artefatto, è una
*posta in gioco*: attraversa tutte le zone. Come quinto reviewer produrrebbe un agente che, su
un design innocuo, deve trovare qualcosa per giustificarsi.

## Come si esegue

1. **Leggi l'artefatto.** Tutto, non a campione.
2. **Applica l'interruttore alta-posta** → decidi la `fascia`.
3. **Lancia i subagenti in parallelo**, uno per mandato, in un solo messaggio.
   Ogni prompt contiene: il path dell'artefatto, il mandato (la riga della tabella, per esteso),
   e l'ordine di **scrivere lui stesso il referto** in `<stem>-referto-<n>-<mandato>.md` accanto
   all'artefatto. Il referto è **grezzo**: cosa ha aperto, cosa ci ha visto, cosa ne conclude.
   Non passa da te.
4. **Riconcilia** (vedi sotto).
5. **Scrivi il verdetto** in `<stem>-verdetto.md`.

## I tre ruoli — non sono tre voti

Se i reviewer votassero, due reviewer che sbagliano nello stesso modo batterebbero Glody.

- **Reviewer = input.** Porta un dato osservato, non un verdetto. Non decide.
- **Tu = voto.** Hai il diritto e il **dovere** di respingere un'obiezione sbagliata, motivando.
  Un agente che accetta tutto non revisiona: obbedisce, e la spec finisce spinta dove punta
  l'ultimo reviewer.
- **Glody = sovrana.** Decide, anche contro tutti.

**Glody entra nel loop in un punto solo:** quando un reviewer solleva un'obiezione **strutturale**
e tu decidi di **respingerla**. Non quando accetti (routine), non quando respingi un dettaglio
(rumore). Respingere in silenzio un'obiezione strutturale è il gesto con cui un agente compiacente
si auto-assolve: è l'unico punto dove il sistema può marcire senza che si veda.

## Quando smettere

**Il criterio è la natura dei residui, non il conteggio.** «Zero difetti» non è mai un criterio:
esisterà sempre una zona non ancora guardata — sulla spec di questo sistema il conteggio non è
mai sceso a zero in tre giri, e non doveva.

Test operativo prima del giro N: **quale zona non ho ancora fatto guardare?** Se non sai
rispondere, l'N-1 era l'ultimo utile.

Si smette quando i residui sono di **dettaglio implementativo**: lì il ciclo RED→GREEN li espone
a costo minore di una review, e insistere tocca il blind-spot del perfezionismo.

## Il verdetto

**Path:** accanto all'artefatto, stesso stem: `<stem>-verdetto.md`.

```yaml
---
created: YYYY-MM-DD
updated: YYYY-MM-DD
tipo: verdetto
fase: spec
slug: <stem>-verdetto
esito: APPROVATA | BOCCIATA | SALTO_MOTIVATO
fascia: piena | mirata
motivazione_salto: "<testo non vuoto se esito=SALTO_MOTIVATO, altrimenti assente>"
referti:
  - <stem>-referto-1-architettura.md
  - <stem>-referto-2-assunzioni.md
---
```

**Corpo: la riconciliazione.** Cosa hai accettato. **Cosa hai respinto e perché.** La natura dei
residui. È lo strato che i reviewer non scrivono: loro portano i dati grezzi, tu porti il giudizio.

### I tre esiti

- **APPROVATA** — i residui sono implementativi. Si passa al piano.
- **BOCCIATA** — difetti strutturali. Il verdetto dice **sempre cosa sopravvive**: una bocciatura
  non butta il lavoro, lo separa. (L'handoff del 14/07 salvava esplicitamente la diagnosi: «la
  diagnosi regge; il pacchetto di lavoro no».)
- **SALTO_MOTIVATO** — il giro non serve, e la ragione è **scritta**. Nessun salto silenzioso:
  per saltare devi firmare che stai saltando, e Glody lo legge. La via d'uscita non è un flag,
  è una firma.

### Perché i referti stanno su disco

La separazione fra referti (grezzi, scritti dai reviewer) e riconciliazione (scritta da te)
chiude i tre modi di barare:

- **non lanciare i reviewer e inventare tutto** → i referti dichiarati in frontmatter non
  esistono su disco.
- **ammorbidire quello che hanno detto** → il referto grezzo è lì accanto, con le parole loro.
- **respingere in silenzio** → un'obiezione strutturale respinta interpella Glody.

**Onestà sul limite:** questo rende il bypass **esplicito invece che silenzioso**; non lo rende
impossibile. La dimenticanza è il fallimento osservato; la falsificazione non è mai accaduta.
