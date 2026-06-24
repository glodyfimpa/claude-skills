---
name: forfettario-tax-calculator
description: |
  Calculate the real net income of an Italian freelancer in the regime forfettario (flat-tax regime) from annual revenue. Use this skill when the user asks to estimate their actual take-home pay, compare gross-vs-net in the forfettario regime, or verify the impact of INPS contributions on taxable income. Triggers include: "quanto mi rimane netto", "calcola tasse regime forfettario", "netto da fatturato", "imposta sostitutiva", "contributi INPS Gestione Separata", or any combination of forfettario + income figures.
---

# Forfettario Tax Calculator

Calcola il netto reale di un freelance italiano in regime forfettario a partire dal fatturato annuo. Logica pura in Python — niente browser, niente API.

## Sequenza di calcolo (ordine vincolante)

```
1. imponibile_lordo  = fatturato × coefficiente
2. contributi_inps   = imponibile_lordo × aliquota_inps
3. imponibile_netto  = imponibile_lordo − contributi_inps   ← INPS deducibile PRIMA dell'imposta
4. imposta           = imponibile_netto × aliquota_sostitutiva
5. netto             = fatturato − contributi_inps − imposta
```

I contributi INPS si deducono dall'imponibile **prima** di applicare l'imposta sostitutiva: è l'unica deduzione ammessa nel regime forfettario e cambia sensibilmente l'imposta finale.

## Utilizzo

```python
from scripts.forfettario_calc import calculate

# Caso tipico: professionista servizi, regime ordinario
result = calculate(
    fatturato=50000,
    coefficiente=0.78,           # default — attività professionali ATECO 64-88
    aliquota_inps=0.2607,        # default — Gestione Separata 2024
    aliquota_sostitutiva=0.15,   # 0.15 ordinario / 0.05 nuove attività (primi 5 anni)
)

print(f"Imponibile lordo:  {result['imponibile_lordo']:.2f}")
print(f"Contributi INPS:   {result['contributi_inps']:.2f}")
print(f"Imponibile netto:  {result['imponibile_netto']:.2f}")
print(f"Imposta:           {result['imposta']:.2f}")
print(f"Netto reale:       {result['netto']:.2f}")
```

La funzione restituisce un dict con tutte le voci intermedie — il breakdowncompleto permette al preventivo di mostrare ogni passaggio, non solo il risultato finale.

## Parametri

| Parametro | Default | Note |
|-----------|---------|------|
| `fatturato` | — obbligatorio — | Fatturato annuo lordo in EUR (≥ 0) |
| `coefficiente` | 0.78 | Redditività forfettaria. 0.78 per professionisti/servizi (ATECO 64-88). Verificare il proprio codice ATECO sull'allegato alla Legge 145/2018 |
| `aliquota_inps` | 0.2607 | Gestione Separata 2024. Aggiornare ogni anno dalla circolare INPS. Artigiani/commercianti hanno aliquota diversa (~24%) |
| `aliquota_sostitutiva` | 0.15 | 0.05 per nuove attività nei primi 5 anni (agevolazione start-up forfettario) |

## Casi d'uso principali

**Professionista con nuova attività (agevolazione 5 anni):**
```python
result = calculate(fatturato=40000, aliquota_sostitutiva=0.05)
```

**Senza contributi INPS (es. già coperto da altra cassa previdenziale):**
```python
result = calculate(fatturato=30000, aliquota_inps=0.0)
```

**Coefficiente diverso (es. commercio, ATECO 45-47, coeff=0.40):**
```python
result = calculate(fatturato=80000, coefficiente=0.40)
```

## Arrotondamento

I valori nel dict restituito sono `float` senza arrotondamento intermedio. Arrotondare **solo nella presentazione** con `f"{value:.2f}"`. Applicare `round()` nella logica di calcolo introdurrebbe errori di propagazione sui passaggi intermedi.

## Limiti e avvertenze

- Il modello si applica esclusivamente al regime forfettario (L. 190/2014 e successive modifiche). Non è adatto a soci di SRL, ditte individuali in regime ordinario, o lavoratori dipendenti.
- I parametri di default riflettono i valori 2024. Le aliquote INPS variano ogni anno — verificare la circolare INPS prima di comunicare cifre a un cliente.
- L'agevolazione 5% si applica solo se non si è esercitata nei 3 anni precedenti un'attività artistica, professionale o d'impresa, anche in forma associata o familiare (art. 1 c. 65 L. 190/2014). Verificare con un commercialista in caso di dubbio.
- Il calcolo non considera acconti e saldo IRPEF di periodi precedenti, né eventuali detrazioni/deduzioni fuori regime.

## Scripts Reference

`scripts/forfettario_calc.py` — logica pura, nessuna dipendenza esterna. Funzione `calculate()` con parametri documentati, sollevamento `ValueError` per fatturato negativo.

## Tests

12 test pytest in `tests/test_forfettario_calc.py` coprono:
- Caso canonico fatturato 50.000 con tutti i parametri (5 asserzioni sui valori intermedi)
- Isolamento deduzione INPS con aliquota zero
- Fatturato zero → tutti gli output a zero
- Fatturato negativo → `ValueError`
- Presenza di tutte le chiavi nel dict restituito
