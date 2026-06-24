---
name: forfettario-tax-calculator
description: |
  Calculate the real net income for an Italian freelancer on the regime forfettario, starting from annual revenue. Use when a freelancer asks "quanto mi rimane davvero?", "calcola il mio netto reale", "quanto pago di tasse in forfettario", or provides a fatturato with a request for a tax breakdown. Returns the full calculation chain (imponibile lordo, contributi INPS, imponibile netto, imposta sostitutiva, netto finale) so the result can be shown as a detailed preventivo, not just the final number.
---

# Forfettario Tax Calculator

Compute the real net take-home for a freelancer on the Italian *regime forfettario*,
starting from annual revenue. Shows the full breakdown so the client can see exactly
where each euro goes.

## Calculation chain (order is fixed by law)

```
1. imponibile_lordo  = fatturato × coefficiente_redditivita
2. contributi_inps   = imponibile_lordo × aliquota_inps        (Gestione Separata)
3. imponibile_netto  = imponibile_lordo − contributi_inps      (INPS deductible before tax)
4. imposta           = imponibile_netto × aliquota_sostitutiva
5. netto             = fatturato − contributi_inps − imposta
```

INPS contributions are **always deducted before applying the flat tax** — this is the key
rule of the forfettario regime and must not be skipped or reordered.

## Usage

```python
from scripts.forfettario_calc import calculate, format_breakdown

result = calculate(
    fatturato=50000,
    coefficiente_redditivita=0.78,   # optional, default 0.78
    aliquota_sostitutiva=0.05,       # optional, default 0.15
    aliquota_inps=0.2607,            # optional, default 0.2607
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

The `calculate()` function returns a dict with all intermediate values at full float
precision — format only at the presentation layer (see `format_breakdown()`).

## Parameters and defaults

| Parameter | Default | Notes |
|-----------|---------|-------|
| `coefficiente_redditivita` | `0.78` | Professional services, ATECO 64-88 |
| `aliquota_sostitutiva` | `0.15` | Standard regime; use `0.05` for new activities (first 5 years) |
| `aliquota_inps` | `0.2607` | Gestione Separata 2024 — update annually |

### When to use `aliquota_sostitutiva=0.05`

New activity in the forfettario for the first 5 tax years, if the freelancer has not
carried out the same business activity in the previous 3 years as an employee or
self-employed. Verify eligibility with the commercialista before applying.

### ATECO coefficient table (common codes)

| Activity | Coefficiente |
|----------|-------------|
| Professional services (64-88, 93, 99) | 0.78 |
| Trade, hotels, catering (45, 46, 47, 55, 56) | 0.40 |
| Construction, plumbing (41-43, 68) | 0.86 |
| Intermediaries in trade (46.1) | 0.62 |
| Other services (other ATECO) | 0.67 |

Source: Allegato 4, Legge n. 190/2014 — verify with commercialista for exact ATECO match.

## Scripts reference

`scripts/forfettario_calc.py`
- `calculate(fatturato, ...)` → `dict` with five keys: `imponibile_lordo`,
  `contributi_inps`, `imponibile_netto`, `imposta`, `netto`.
- `format_breakdown(result, fatturato)` → formatted string with 2-decimal rounding,
  suitable for display in a message or report.
- Raises `ValueError` if `fatturato < 0`.

## Tests

```bash
python3 -m unittest tests.test_forfettario_calc -v
```

Four numeric cases covered (50k standard, 30k zero-INPS, zero revenue, negative revenue).

## Important caveats

- This tool applies the forfettario regime only. It does not cover P.IVA ordinaria,
  cedolare secca (rental income), or IRPEF progressive rates.
- Contributi INPS in Gestione Separata are calculated on `imponibile_lordo`, not on
  `fatturato`. This differs from Gestione Artigiani/Commercianti where minimale fisso
  applies.
- The 85.000 € annual revenue cap for the forfettario regime is not enforced here —
  check eligibility before applying to revenues above that threshold.
- Always consult a commercialista for official tax filings. This tool is for planning
  and estimation only.
