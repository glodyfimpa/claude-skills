# Golden set — riferimento qualità per la Fase 3 (CONFRONTA)

Questo file NON è una suite di test: l'output del confronto-knowledge è giudizio LLM,
non deterministico, e un `assert` sarebbe finto (vedi PRD `prd-skill-distill.md`). È un
**riferimento di calibrazione**: due sintesi del pilot che mostrano com'è fatta una sintesi
buona, e in cosa consiste il valore. Il sub-agente di Fase 3 le legge prima di abbozzare,
e ci confronta il proprio output.

Le sintesi vere vivono nel vault, non sono copiate qui (una sola fonte di verità):

- **001** — `~/Documents/brain/areas/affitti-brevi/bnb-academy/analisi-lezioni/sintesi/001.md`
- **002** — `~/Documents/brain/areas/affitti-brevi/bnb-academy/analisi-lezioni/sintesi/002.md`

## Cosa rende una sintesi "golden"

1. **Il valore sta nei punti di disallineamento, non nelle conferme.** Una sintesi tutta
   "ATTUALE" non ha prodotto valore: significa che la nostra knowledge già copriva la
   lezione. Il deliverable sono i 2-3 punti dove corso o nostra knowledge erano sbagliati.
2. **Ogni marcatura non-ATTUALE poggia su una fonte citata (link), mai sul naso.** È il
   gate, non un consiglio.
3. **Confronto alla pari, discriminante = applicabilità 2026.** Non "chi ha ragione" ma "è
   valido oggi". A volte corregge il corso la nostra knowledge, a volte una fonte esterna
   corregge entrambi.
4. **Onestà sul non risolto.** Se la fonte non si trova, `DA VERIFICARE` esplicito +
   segnalazione, non una marcatura forzata.

## 001 — il pattern "CORSO IMPRECISO con fonte"

La sintesi è quasi tutta ATTUALE (la procedura `gestione-recensioni.md` era già derivata da
questa lezione), **tranne una riga** che è il valore:

| Affermazione del corso | Stato 2026 | Fonte di verità |
|---|---|---|
| Superhost = media >**4,9** | **CORSO IMPRECISO** | soglia reale **4,8**. Fonte: [Airbnb Help art. 829](https://www.airbnb.com/help/article/829) |

Perché è golden:
- La marcatura `CORSO IMPRECISO` cita l'articolo ufficiale Airbnb, non un'impressione.
- Ha prodotto un'**azione concreta**: propagare 4,8 in `gestione-recensioni.md` (che diceva >4,9).
- Distingue ATTUALE puro da `ATTUALE con precisazioni` (il flag "ospiteresti di nuovo?",
  confermato ma riformulato in "consiglieresti l'ospite ad altri host") — granularità onesta.

## 002 — il pattern "marcatura calibrata, NON allarmista" (il caso-scuola del gate)

Questa è la lezione più istruttiva, perché documenta un **errore corretto**. La prima
stesura marcava il mito viste/preferiti come "datato, fa crollare il ranking" — a naso,
allarmista. La versione golden è la calibrazione:

| Affermazione | Stato 2026 | Fonte |
|---|---|---|
| Gonfiare viste/preferiti = boost ranking | **INEFFICACE, non provato dannoso** | conversione è il fattore #1; saves sono fattore minore. 4 fonti citate |

Perché è golden:
- **Non si ferma al primo cluster di blog allarmisti.** Cerca la doc ufficiale (Airbnb Help
  art. 39 e 2714) + un esperto tecnico riconosciuto (OptimizeMyBnb) prima di marcare.
- **Marca il grado giusto**: non "DATATO/dannoso" (allarmista) ma "INEFFICACE, non provato
  dannoso" — la differenza tra "non sposta la conversione" e "ti penalizza".
- **Cita 4 fonti** con cosa dice ciascuna, e una nota esplicita ("Correzione rispetto a una
  prima stesura troppo allarmista") che rende tracciabile il ragionamento.
- L'azione per Via Braida è dimensionata sul valore reale ("rischio ~nullo ma guadagno
  minimo"), non sull'allarme.

Questo è esattamente il bug che il gate fonti previene: marcare a naso (in entrambe le
direzioni, sottovalutare o sovra-allarmare). La memory `feedback-compare-dont-assume-winner`
è la lezione metodologica dietro.

## Anti-esempi (cosa NON fare)

- Marcare `DATATO` perché "suona vecchio" senza link → viola il gate.
- Fermarsi al primo blog che conferma l'ipotesi (inerzia narrativa) → cerca la doc ufficiale.
- Sovra-allarmare ("fa crollare il ranking") senza prova del danno → 002 insegna a calibrare.
- Sintesi tutta ATTUALE presentata come "lavoro fatto" → se non c'è disallineamento, dillo
  in una riga, non gonfiare.
- Forzare una marcatura quando la fonte non si trova → `DA VERIFICARE` onesto + segnala.
