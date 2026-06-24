---
name: forfettario-tax-calculator
description: |
  Calculate the real net income for an Italian freelancer on the regime forfettario, starting from annual revenue. Use when a freelancer asks "quanto mi rimane davvero?", "calcola il mio netto reale", "quanto pago di tasse in forfettario", or provides a fatturato with a request for a tax breakdown. Returns the full calculation chain (imponibile lordo, contributi INPS, imponibile netto, imposta sostitutiva, netto finale) so the result can be shown as a detailed preventivo, not just the final number.
---

# Forfettario Tax Calculator

Compute the real net take-home for a freelancer on the Italian *regime forfettario*, starting from annual revenue. Shows the full breakdown so the client can see exactly where each euro goes.

## Sequenza di calcolo (ordine vincolante)

```
1. imponibile_lordo  = fatturato × coefficiente_redditivita
2. contributi_inps   = imponibile_lordo × aliquota_inps        (Gestione Separata)
3. imponibile_netto  = imponibile_lordo − contributi_inps      ← INPS deducibile PRIMA dell'imposta
4. imposta           = imponibile_netto × aliquota_sostitutiva
5. netto             = fatturato − contributi_inps − imposta
```

I contributi INPS si deducono sempre **prima** di applicare l'imposta sostitutiva — è l'unica deduzione ammessa nel regime forfettario e modifica significativamente l'imposta finale.

## Utilizzo

```python
from scripts.forfettario_calc import calculate, format_breakdown

result = calculate(
    fatturato=50000,
    coefficiente_redditivita=0.78,   # default — attività professionali ATECO 64-88
    aliquota_sostitutiva=0.05,       # 0.05 nuove attività (primi 5 anni) / 0.15 ordinario
    aliquota_inps=0.2607,            # default — Gestione Separata 2024
)

print(format_breakdown(result, fatturato=50000))
```

Output:

```
Fatturato annuo:        €      50000.00
Imponibile lordo:       €      39000.00
Contributi INPS:      - €      10167.30
Imponibile netto:       €      28832.70
Imposta sostitutiva:  - €       1441.64
──────────────────────────────────────────
Netto reale:            €      38391.07
```

La funzione `calculate()` restituisce un dict con tutte le voci intermedie in piena precisione float — arrotondare solo in presentazione (usa `format_breakdown()` o `f"{value:.2f}"`).

## Parametri

| Parametro | Default | Note |
|-----------|---------|------|
| `fatturato` | — obbligatorio — | Fatturato annuo lordo in EUR (≥ 0) |
| `coefficiente_redditivita` | `0.78` | Professionisti/servizi (ATECO 64-88). Verificare Allegato 4, L. 190/2014 |
| `aliquota_sostitutiva` | `0.15` | Regime ordinario; `0.05` per nuove attività (primi 5 anni) |
| `aliquota_inps` | `0.2607` | Gestione Separata 2024 — aggiornare ogni anno dalla circolare INPS |

### Tabella coefficienti ATECO comuni

| Attività | Coefficiente |
|----------|-------------|
| Professionisti e servizi (ATECO 64-88, 93, 99) | 0.78 |
| Commercio, hotel, ristorazione (45, 46, 47, 55, 56) | 0.40 |
| Costruzioni, idraulica (41-43, 68) | 0.86 |
| Intermediari di commercio (46.1) | 0.62 |
| Altri servizi | 0.67 |

Fonte: Allegato 4, Legge n. 190/2014 — verificare con il commercialista per il codice ATECO esatto.

## Casi d'uso principali

**Professionista con nuova attività (agevolazione 5 anni):**
```python
result = calculate(fatturato=40000, aliquota_sostitutiva=0.05)
```

**Senza contributi INPS (es. già coperto da altra cassa previdenziale):**
```python
result = calculate(fatturato=30000, aliquota_inps=0.0)
```

**Commerciante (ATECO 45-47, coeff=0.40):**
```python
result = calculate(fatturato=80000, coefficiente_redditivita=0.40)
```

## Arrotondamento

I valori nel dict restituito sono `float` senza arrotondamento intermedio. Arrotondare **solo nella presentazione** con `format_breakdown()` o `f"{value:.2f}"`. Applicare `round()` nella logica di calcolo introdurrebbe errori di propagazione sui passaggi intermedi.

## Scripts Reference

`scripts/forfettario_calc.py` — logica pura, nessuna dipendenza esterna.
- `calculate(fatturato, ...)` → `dict` con chiavi: `imponibile_lordo`, `contributi_inps`, `imponibile_netto`, `imposta`, `netto`. Valori float in piena precisione.
- `format_breakdown(result, fatturato)` → stringa formattata con arrotondamento a 2 decimali, pronta per display in messaggio o report.
- Solleva `ValueError` se `fatturato < 0`.

## Tests

```bash
python3 -m pytest tests/test_forfettario_calc.py -v
```

13 test pytest coprono:
- Caso canonico fatturato 50.000 (5 asserzioni sui valori intermedi)
- Isolamento deduzione INPS con aliquota zero
- Fatturato zero → tutti gli output a zero
- Fatturato negativo → `ValueError`
- Presenza di tutte le chiavi nel dict restituito
- `format_breakdown()` produce output con voce netto e fatturato

## Limiti e avvertenze

- Applicabile solo al regime forfettario (L. 190/2014). Non adatto a soci SRL, ditte individuali in regime ordinario, lavoratori dipendenti.
- I parametri di default riflettono i valori 2024. Le aliquote INPS variano ogni anno — verificare la circolare INPS prima di comunicare cifre a un cliente.
- L'agevolazione 5% si applica solo se non si è esercitata la stessa attività nei 3 anni precedenti (art. 1 c. 65 L. 190/2014). Verificare con un commercialista.
- Il calcolo non considera acconti/saldi IRPEF di periodi precedenti, né detrazioni fuori regime.
- Soglia di accesso al forfettario: 85.000 € di ricavi annui (2024). Non verificata dal calcolatore.
