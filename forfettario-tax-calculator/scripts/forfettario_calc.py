"""Forfettario tax calculator — regime forfettario italiano (logica pura, niente I/O)."""


# Default parameters documented in SKILL.md
_DEFAULT_COEFFICIENTE = 0.78       # attività professionali e servizi, ATECO 64-88
_DEFAULT_ALIQUOTA_INPS = 0.2607    # Gestione Separata 2024
_DEFAULT_ALIQUOTA_SOSTITUTIVA = 0.15  # regime ordinario forfettario


def calculate(
    fatturato: float,
    coefficiente: float = _DEFAULT_COEFFICIENTE,
    aliquota_inps: float = _DEFAULT_ALIQUOTA_INPS,
    aliquota_sostitutiva: float = _DEFAULT_ALIQUOTA_SOSTITUTIVA,
) -> dict:
    """Calcola il netto reale di un freelance in regime forfettario.

    Sequenza vincolante:
      1. imponibile_lordo  = fatturato * coefficiente
      2. contributi_inps   = imponibile_lordo * aliquota_inps
      3. imponibile_netto  = imponibile_lordo - contributi_inps  (INPS deducibile)
      4. imposta           = imponibile_netto * aliquota_sostitutiva
      5. netto             = fatturato - contributi_inps - imposta

    Args:
        fatturato: Fatturato annuo lordo in EUR. Deve essere >= 0.
        coefficiente: Coefficiente di redditività forfettario (default 0.78).
        aliquota_inps: Aliquota contributi INPS Gestione Separata (default 0.2607).
        aliquota_sostitutiva: Aliquota imposta sostitutiva (0.05 prime attività / 0.15 ordinario).

    Returns:
        Dict con chiavi: imponibile_lordo, contributi_inps, imponibile_netto, imposta, netto.
        I valori sono float senza arrotondamento — arrotondare solo in presentazione.

    Raises:
        ValueError: Se fatturato < 0.
    """
    if fatturato < 0:
        raise ValueError(f"fatturato deve essere >= 0, ricevuto: {fatturato}")

    imponibile_lordo = fatturato * coefficiente
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
