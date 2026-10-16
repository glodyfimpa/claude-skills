"""
Forfettario tax calculator for Italian freelancers (regime forfettario).

Calculation chain, certified on Istruzioni Redditi PF 2026, fascicolo 3 (quadro LM):
  1. imponibile_lordo  = incassi * coefficiente_redditivita        (LM22-LM34; cash basis: compensi percepiti)
  2. contributi_inps   = imponibile_lordo * aliquota_inps          (GS base = LM34 col. 2, before contributions)
  3. imponibile_netto  = max(imponibile_lordo - contributi_versati, 0)
                         contributi_versati = GS contributions PAID in the same year (LM35),
                         i.e. previous-year saldo + current-year acconti, not the ones computed in step 2
  4. imposta           = imponibile_netto * aliquota_sostitutiva
  5. netto             = incassi - contributi_inps - imposta

If contributi_versati is not given, step 3 uses contributi_inps (steady-state approximation:
same income every year). Use the real paid amount whenever income changes between years.

Intermediates are kept in full float precision; rounding is the caller's responsibility.
"""

_DEFAULT_COEFFICIENTE = 0.78          # professional, scientific, technical... (see coefficiente_per_ateco)
_DEFAULT_ALIQUOTA_SOSTITUTIVA = 0.15  # standard regime; 0.05 for new activities (first 5 years)
_DEFAULT_ALIQUOTA_INPS = 0.2607       # Gestione Separata 2026, not insured elsewhere (circ. INPS 8/2026)

# Certified table: Istruzioni Redditi PF 2026 fasc. 3, coefficienti (allegato 2 L. 145/2018), ATECO 2007.
# Ranges are on the ATECO prefix; more specific prefixes are checked first.
_SPECIFIC = [
    ("47.81", 0.40),                       # commercio ambulante alimentari e bevande
    ("47.82", 0.54), ("47.83", 0.54), ("47.84", 0.54), ("47.85", 0.54),
    ("47.86", 0.54), ("47.87", 0.54), ("47.88", 0.54), ("47.89", 0.54),  # ambulante altri prodotti
    ("46.1", 0.62),                        # intermediari del commercio
]
_DIVISIONS = {}
for _d in ("10", "11", "45", "55", "56"):
    _DIVISIONS[_d] = 0.40
for _d in ("41", "42", "43", "68"):
    _DIVISIONS[_d] = 0.86
for _d in ("64", "65", "66", "69", "70", "71", "72", "73", "74", "75", "85", "86", "87", "88"):
    _DIVISIONS[_d] = 0.78
_COMMERCE_40 = ("46.2", "46.3", "46.4", "46.5", "46.6", "46.7", "46.8", "46.9",
                "47.1", "47.2", "47.3", "47.4", "47.5", "47.6", "47.7", "47.9")
_OTHER_67 = {f"{d:02d}" for d in list(range(1, 4)) + list(range(5, 10)) + list(range(12, 34))
             + [35] + list(range(36, 40)) + list(range(49, 54)) + list(range(58, 64))
             + list(range(77, 83)) + [84] + list(range(90, 94)) + list(range(94, 97)) + [97, 98, 99]}


def coefficiente_per_ateco(codice: str) -> float:
    """Return the certified profitability coefficient for an ATECO code like '62.10.00'."""
    code = codice.strip()
    if len(code) < 2 or not code[:2].isdigit():
        raise ValueError(f"invalid ATECO code: {codice!r}")
    for prefix, coeff in _SPECIFIC:
        if code.startswith(prefix):
            return coeff
    if code.startswith(_COMMERCE_40):
        return 0.40
    division = code[:2]
    if division in _DIVISIONS:
        return _DIVISIONS[division]
    if division in _OTHER_67:
        return 0.67
    raise ValueError(f"ATECO code not in the forfettario table: {codice!r}")


def calculate(
    fatturato: float,
    coefficiente_redditivita: float = _DEFAULT_COEFFICIENTE,
    aliquota_sostitutiva: float = _DEFAULT_ALIQUOTA_SOSTITUTIVA,
    aliquota_inps: float = _DEFAULT_ALIQUOTA_INPS,
    contributi_versati: float | None = None,
) -> dict:
    """Return a breakdown dict for a freelancer on the Italian forfettario regime.

    Args:
        fatturato: Annual amount COLLECTED in the year (incassi, cash basis), must be >= 0.
            The name is kept for backward compatibility.
        coefficiente_redditivita: Profitability coefficient (see coefficiente_per_ateco).
        aliquota_sostitutiva: Flat-tax rate (0.05 new activity, 0.15 standard).
        aliquota_inps: INPS Gestione Separata contribution rate.
        contributi_versati: GS contributions actually paid in the year (deducted for the tax,
            LM35). None = steady-state approximation (deduct contributi_inps).

    Returns:
        Dict with keys: imponibile_lordo, contributi_inps, imponibile_netto, imposta, netto.

    Raises:
        ValueError: If fatturato is negative.
    """
    if fatturato < 0:
        raise ValueError(f"fatturato must be >= 0, got {fatturato}")

    imponibile_lordo = fatturato * coefficiente_redditivita
    contributi_inps = imponibile_lordo * aliquota_inps
    deducibili = contributi_inps if contributi_versati is None else contributi_versati
    imponibile_netto = max(imponibile_lordo - deducibili, 0.0)
    imposta = imponibile_netto * aliquota_sostitutiva
    netto = fatturato - contributi_inps - imposta

    return {
        "imponibile_lordo": imponibile_lordo,
        "contributi_inps": contributi_inps,
        "imponibile_netto": imponibile_netto,
        "imposta": imposta,
        "netto": netto,
    }


def sanzione_ravvedimento_gs(importo: float, giorni: int, tur: float) -> float:
    """Civil sanction for late Gestione Separata payment (art. 116 c. 8 lett. a L. 388/2000).

    Paid within 120 days of the deadline, in a single payment and before any INPS request:
    TUR per year only. Otherwise TUR + 5.5 points per year. Cap: 40% of the amount.
    TUR is set by INPS circolari (2,65% from 16/09/2026, circ. INPS 98/2026).
    """
    rate = tur if giorni <= 120 else tur + 0.055
    return min(importo * rate * giorni / 365, importo * 0.40)


def incassi_coperti_da_acconti(
    acconti_gs_versati: float,
    acconti_imposta_versati: float,
    contributi_versati: float,
    coefficiente_redditivita: float,
    aliquota_sostitutiva: float,
    aliquota_inps: float = _DEFAULT_ALIQUOTA_INPS,
) -> dict:
    """Max incassi of the year already covered by the acconti paid (safety margin of a reduced acconto).

    imposta: the acconto due is 100% of the year's tax (metodo previsionale certified, art. 4 c. 2
             DL 69/1989); covered while (lordo - contributi_versati) * aliquota <= acconti paid.
    gs:      the storico rule is 80% of the contributions; a previsionale on GS acconti has NO primary
             source, so this value is informative only.
    """
    lordo_imposta = acconti_imposta_versati / aliquota_sostitutiva + contributi_versati
    lordo_gs = acconti_gs_versati / 0.80 / aliquota_inps
    gs = lordo_gs / coefficiente_redditivita
    imposta = lordo_imposta / coefficiente_redditivita
    return {"gs": gs, "imposta": imposta, "limite": min(gs, imposta)}


def format_breakdown(result: dict, fatturato: float) -> str:
    """Return a human-readable breakdown string (rounded to 2 decimals)."""
    lines = [
        f"Incassi annui:          € {fatturato:>12.2f}",
        f"Imponibile lordo:       € {result['imponibile_lordo']:>12.2f}",
        f"Contributi INPS:      - € {result['contributi_inps']:>12.2f}",
        f"Imponibile netto:       € {result['imponibile_netto']:>12.2f}",
        f"Imposta sostitutiva:  - € {result['imposta']:>12.2f}",
        "─" * 42,
        f"Netto reale:            € {result['netto']:>12.2f}",
    ]
    return "\n".join(lines)
