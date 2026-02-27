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
