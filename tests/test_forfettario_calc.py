"""Tests for forfettario_calc.py — regime forfettario Italian tax calculator."""
import pytest
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "forfettario-tax-calculator", "scripts"))

from forfettario_calc import calculate


class TestCase1Canonical:
    """fatturato=50000, coeff=0.78, inps=0.2607, aliquota=0.05"""

    def setup_method(self):
        self.result = calculate(
            fatturato=50000,
            coefficiente=0.78,
            aliquota_inps=0.2607,
            aliquota_sostitutiva=0.05,
        )

    def test_imponibile_lordo(self):
        assert self.result["imponibile_lordo"] == pytest.approx(39000.0)

    def test_contributi_inps(self):
        assert self.result["contributi_inps"] == pytest.approx(10167.30)

    def test_imponibile_netto(self):
        assert self.result["imponibile_netto"] == pytest.approx(28832.70)

    def test_imposta(self):
        assert self.result["imposta"] == pytest.approx(1441.635)

    def test_netto(self):
        assert self.result["netto"] == pytest.approx(38391.065)


class TestCase2NoContributi:
    """fatturato=30000, coeff=0.78, inps=0, aliquota=0.15 — isola la deduzione contributi"""

    def setup_method(self):
        self.result = calculate(
            fatturato=30000,
            coefficiente=0.78,
            aliquota_inps=0.0,
            aliquota_sostitutiva=0.15,
        )

    def test_imponibile_netto(self):
        assert self.result["imponibile_netto"] == pytest.approx(23400.0)

    def test_imposta(self):
        assert self.result["imposta"] == pytest.approx(3510.0)

    def test_netto(self):
        assert self.result["netto"] == pytest.approx(26490.0)

    def test_contributi_zero(self):
        assert self.result["contributi_inps"] == pytest.approx(0.0)


class TestCase3ZeroFatturato:
    """fatturato=0 deve dare tutti gli output a zero"""

    def test_all_zero(self):
        result = calculate(fatturato=0)
        for key in ("imponibile_lordo", "contributi_inps", "imponibile_netto", "imposta", "netto"):
            assert result[key] == pytest.approx(0.0), f"{key} expected 0.0"


class TestCase4Negativo:
    """fatturato negativo deve sollevare ValueError"""

    def test_raises_value_error(self):
        with pytest.raises(ValueError):
            calculate(fatturato=-1)


class TestReturnKeys:
    """Il dict restituito deve contenere tutte le chiavi attese"""

    def test_keys_present(self):
        result = calculate(fatturato=10000)
        expected = {"imponibile_lordo", "contributi_inps", "imponibile_netto", "imposta", "netto"}
        assert expected.issubset(result.keys())
