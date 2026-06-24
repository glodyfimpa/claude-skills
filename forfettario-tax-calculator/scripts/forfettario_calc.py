"""
Forfettario tax calculator for Italian freelancers (regime forfettario).

Calculation order is fixed by law:
  1. imponibile_lordo  = fatturato * coefficiente_redditivita
  2. contributi_inps   = imponibile_lordo * aliquota_inps
  3. imponibile_netto  = imponibile_lordo - contributi_inps   (INPS deductible before tax)
  4. imposta           = imponibile_netto * aliquota_sostitutiva
  5. netto             = fatturato - contributi_inps - imposta

Intermediates are kept in full float precision; rounding is the caller's responsibility.
"""

# Default parameters (2024 values — update aliquota_inps yearly)
_DEFAULT_COEFFICIENTE = 0.78      # professional services, ATECO 64-88
_DEFAULT_ALIQUOTA_SOSTITUTIVA = 0.15   # standard regime; use 0.05 for new activities (first 5 years)
_DEFAULT_ALIQUOTA_INPS = 0.2607   # Gestione Separata rate


def calculate(
    fatturato: float,
    coefficiente_redditivita: float = _DEFAULT_COEFFICIENTE,
    aliquota_sostitutiva: float = _DEFAULT_ALIQUOTA_SOSTITUTIVA,
    aliquota_inps: float = _DEFAULT_ALIQUOTA_INPS,
) -> dict:
    """Return a breakdown dict for a freelancer on the Italian forfettario regime.

    Args:
        fatturato: Annual gross revenue (invoiced total), must be >= 0.
        coefficiente_redditivita: Profitability coefficient per ATECO code.
        aliquota_sostitutiva: Flat-tax rate (0.05 new activity, 0.15 standard).
        aliquota_inps: INPS Gestione Separata contribution rate.

    Returns:
        Dict with keys: imponibile_lordo, contributi_inps, imponibile_netto,
        imposta, netto. All values are floats in full precision.

    Raises:
        ValueError: If fatturato is negative.
    """
    if fatturato < 0:
        raise ValueError(f"fatturato must be >= 0, got {fatturato}")

    if fatturato == 0:
        return {
            "imponibile_lordo": 0.0,
            "contributi_inps": 0.0,
            "imponibile_netto": 0.0,
            "imposta": 0.0,
            "netto": 0.0,
        }

    imponibile_lordo = fatturato * coefficiente_redditivita
    contributi_inps = imponibile_lordo * aliquota_inps
    imponibile_netto = imponibile_lordo - contributi_inps
    imposta = imponibile_netto * aliquota_sostitutiva
    netto = fatturato - contributi_inps - imposta

    return {
        "imponibile_lordo": imponibile_lordo,
        "contributi_inps": contributi_inps,
        "imponibile_netto": imponibile_netto,
        "imposta": imposta,
        "netto": netto,
    }


def format_breakdown(result: dict, fatturato: float) -> str:
    """Return a human-readable breakdown string (rounded to 2 decimals)."""
    lines = [
        f"Fatturato annuo:        € {fatturato:>12.2f}",
        f"Imponibile lordo:       € {result['imponibile_lordo']:>12.2f}",
        f"Contributi INPS:      - € {result['contributi_inps']:>12.2f}",
        f"Imponibile netto:       € {result['imponibile_netto']:>12.2f}",
        f"Imposta sostitutiva:  - € {result['imposta']:>12.2f}",
        "─" * 42,
        f"Netto reale:            € {result['netto']:>12.2f}",
    ]
    return "\n".join(lines)
