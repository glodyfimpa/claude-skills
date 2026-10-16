---
name: forfettario-tax-calculator
description: |
  Deterministic calculator for an Italian freelancer on the regime forfettario: imposta sostitutiva, INPS Gestione Separata contributions and real net income from the year's incassi, the certified ATECO profitability coefficient, the sanction of a late Gestione Separata payment (ravvedimento) and how much income the acconti already paid cover. Use when someone asks "quanto mi rimane davvero?", "calcola il mio netto reale", "quanto pago di tasse e INPS?", "che coefficiente ha il mio ATECO?", "quanto costa pagare l'INPS in ritardo?", "il primo acconto copre già le tasse?", or before deciding on acconti (metodo storico vs previsionale). Not for P.IVA ordinaria, IRPEF progressive rates, cedolare secca or Gestione Artigiani/Commercianti.
---

# Forfettario Tax Calculator

Every number comes from the functions in `scripts/forfettario_calc.py`, never from mental
arithmetic or from an LLM: the rules are fixed by law, so the calculation is deterministic.
Each rule cites its primary source; parameters that change yearly (INPS rate, TUR) are inputs.

## Calculation chain (Istruzioni Redditi PF 2026, fascicolo 3, quadro LM)

```
1. imponibile_lordo = incassi × coefficiente_redditivita        LM22-LM34, cash basis (compensi percepiti)
2. contributi_inps  = imponibile_lordo × aliquota_inps          GS base = LM34 col. 2, before contributions
3. imponibile_netto = max(imponibile_lordo − contributi_versati, 0)   LM35: contributions PAID in the year
4. imposta          = imponibile_netto × aliquota_sostitutiva
5. netto            = incassi − contributi_inps − imposta
```

`contributi_versati` are the GS contributions actually paid in the year (previous-year saldo
plus current-year acconti), not the ones computed in step 2. When income changes between
years the two differ a lot: always pass the real paid amount. Without it, the function uses
step 2 as a steady-state approximation.

## Usage

```python
from scripts.forfettario_calc import (
    calculate, coefficiente_per_ateco, sanzione_ravvedimento_gs, incassi_coperti_da_acconti,
    format_breakdown,
)

coeff = coefficiente_per_ateco("62.10.00")                 # 0.67
r = calculate(20000, coeff, aliquota_sostitutiva=0.05, aliquota_inps=0.2607,
              contributi_versati=6000)
print(format_breakdown(r, fatturato=20000))

sanzione_ravvedimento_gs(3000, giorni=120, tur=0.0265)     # 26.14 (within 120 days: TUR only)
incassi_coperti_da_acconti(acconti_gs_versati=3000, acconti_imposta_versati=600,
                           contributi_versati=6000, coefficiente_redditivita=0.67,
                           aliquota_sostitutiva=0.05)      # {'gs': ..., 'imposta': ..., 'limite': ...}
```

## Functions

| Function | What it returns | Source |
|---|---|---|
| `calculate(fatturato, coefficiente, aliquota_sostitutiva, aliquota_inps, contributi_versati=None)` | imponibile lordo/netto, INPS, imposta, netto. `fatturato` = incassi of the year (name kept for compatibility) | Istruzioni PF 2026 fasc. 3, LM22-LM36 |
| `coefficiente_per_ateco(code)` | certified coefficient; raises on unknown codes | fasc. 3 coefficient table (allegato 2 L. 145/2018), ATECO 2007 |
| `sanzione_ravvedimento_gs(importo, giorni, tur)` | civil sanction for a late GS payment: TUR/year within 120 days in a single payment, TUR + 5,5 points after, cap 40% | art. 116 c. 8 L. 388/2000; TUR from INPS circolari (2,65% from 16/09/2026, circ. 98/2026) |
| `incassi_coperti_da_acconti(...)` | max incassi of the year already covered by the acconti paid (tax: 100% of the year's tax; GS: 80%, informative only) | previsionale on the tax: art. 4 c. 2 DL 69/1989; GS acconti: 80% rule, fasc. 2 appendix |
| `format_breakdown(result, fatturato)` | text breakdown rounded to 2 decimals | — |

## Parameters

| Parameter | Value | Source |
|---|---|---|
| `aliquota_inps` | 0.2607 (2026, not insured elsewhere); 0.24 if pensioner or insured elsewhere | circ. INPS 8/2026 |
| `aliquota_sostitutiva` | 0.15 standard; 0.05 for new activities, first 5 years (check eligibility) | L. 190/2014 |
| `tur` | 0.0265 from 16/09/2026 | circ. INPS 98/2026 |

## Coefficient table (certified)

| Group | ATECO 2007 | Coeff. |
|---|---|---|
| Food and beverage industry | 10-11 | 0.40 |
| Wholesale and retail trade | 45, 46.2-46.9, 47.1-47.7, 47.9 | 0.40 |
| Street trade, food and beverages | 47.81 | 0.40 |
| Street trade, other products | 47.82-47.89 | 0.54 |
| Construction and real estate | 41-43, 68 | 0.86 |
| Trade intermediaries | 46.1 | 0.62 |
| Accommodation and food services | 55-56 | 0.40 |
| Professional, scientific, technical, health, education, finance, insurance | 64-66, 69-75, 85, 86-88 | 0.78 |
| Other economic activities (includes 62 software, 63, 93, 99) | 01-03, 05-09, 12-33, 35, 36-39, 49-53, 58-63, 77-82, 84, 90-99 | 0.67 |

## What is NOT certified (do not apply)

- Metodo previsionale on INPS Gestione Separata acconti: no primary source found (only the
  80%-of-previous-income rule is written). `incassi_coperti_da_acconti()["gs"]` is informative.

## Tests

```bash
python3 -m unittest tests.test_forfettario_calc -v
```

Chain with contributions paid, floor at zero, steady-state approximation, coefficient groups,
ravvedimento within/after 120 days and cap, acconti coverage.

## Caveats

- Forfettario only. The 85.000 € cap on revenue is not enforced: check eligibility first.
- Planning tool: official filings stay with the commercialista.
