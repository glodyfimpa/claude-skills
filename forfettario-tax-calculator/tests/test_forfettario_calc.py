"""Behavioral tests on certified rules (Istruzioni Redditi PF 2026 fasc. 3, circ. INPS 8/2026)."""
import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "scripts"))
from forfettario_calc import (  # noqa: E402
    calculate, coefficiente_per_ateco, format_breakdown, incassi_coperti_da_acconti,
    sanzione_ravvedimento_gs,
)


class TestCertifiedChain(unittest.TestCase):
    def test_tax_deducts_contributions_paid_in_the_year_not_computed_ones(self):
        r = calculate(20000, coefficiente_redditivita=0.67, aliquota_sostitutiva=0.05,
                      aliquota_inps=0.2607, contributi_versati=6000)
        self.assertAlmostEqual(r["imponibile_lordo"], 13400.00, places=2)
        self.assertAlmostEqual(r["contributi_inps"], 3493.38, places=2)  # INPS on lordo (LM34 col. 2)
        self.assertAlmostEqual(r["imponibile_netto"], 7400.00, places=2)  # lordo - versati (LM35)
        self.assertAlmostEqual(r["imposta"], 370.00, places=2)

    def test_paid_contributions_above_income_floor_taxable_at_zero(self):
        r = calculate(10000, coefficiente_redditivita=0.67, aliquota_sostitutiva=0.05,
                      contributi_versati=9000)
        self.assertEqual(r["imponibile_netto"], 0.0)
        self.assertEqual(r["imposta"], 0.0)

    def test_without_paid_contributions_uses_steady_state_approximation(self):
        r = calculate(50000, coefficiente_redditivita=0.78, aliquota_sostitutiva=0.05)
        self.assertAlmostEqual(r["contributi_inps"], 10167.30, places=2)
        self.assertAlmostEqual(r["imposta"], 1441.64, places=2)

    def test_negative_revenue_rejected(self):
        with self.assertRaises(ValueError):
            calculate(-1)

    def test_steady_state_full_chain(self):
        # 50000 * 0.78 = 39000 (LM34); GS 39000 * 0.2607 = 10167.30; steady state: paid = computed,
        # so LM35 gives 39000 - 10167.30 = 28832.70; tax 5% = 1441.635; net 50000 - 10167.30 - 1441.635.
        r = calculate(50000, coefficiente_redditivita=0.78, aliquota_sostitutiva=0.05,
                      aliquota_inps=0.2607)
        self.assertAlmostEqual(r["imponibile_lordo"], 39000.00, places=2)
        self.assertAlmostEqual(r["imponibile_netto"], 28832.70, places=2)
        self.assertAlmostEqual(r["imposta"], 1441.635, places=3)
        self.assertAlmostEqual(r["netto"], 38391.065, places=3)

    def test_no_contributions_paid_at_standard_15_percent_rate(self):
        # Nothing paid in the year (LM35 = 0): 30000 * 0.78 = 23400 taxed in full, 23400 * 0.15 = 3510.
        r = calculate(30000, coefficiente_redditivita=0.78, aliquota_sostitutiva=0.15,
                      contributi_versati=0)
        self.assertAlmostEqual(r["imponibile_netto"], 23400.00, places=2)
        self.assertAlmostEqual(r["imposta"], 3510.00, places=2)

    def test_zero_revenue_gives_all_zero(self):
        r = calculate(0)
        for key in ("imponibile_lordo", "contributi_inps", "imponibile_netto", "imposta", "netto"):
            with self.subTest(key=key):
                self.assertEqual(r[key], 0.0)


class TestCoefficientTable(unittest.TestCase):
    """Certified table: Istruzioni Redditi PF 2026 fasc. 3 (allegato 2 L. 145/2018)."""

    def test_software_development_is_other_activities(self):
        self.assertEqual(coefficiente_per_ateco("62.10.00"), 0.67)

    def test_groups(self):
        cases = {
            "69.20.11": 0.78, "86.21.00": 0.78, "64.19": 0.78, "85.59": 0.78,
            "93.11": 0.67, "99.00": 0.67, "63.11": 0.67,
            "68.20.01": 0.86, "41.20": 0.86,
            "46.18": 0.62,
            "47.81": 0.40, "47.82": 0.54, "47.89": 0.54,
            "46.90": 0.40, "47.11": 0.40, "47.91": 0.40, "45.20": 0.40,
            "10.11": 0.40, "11.01": 0.40, "55.10": 0.40, "56.10": 0.40,
        }
        for code, expected in cases.items():
            with self.subTest(code=code):
                self.assertEqual(coefficiente_per_ateco(code), expected)

    def test_unknown_code_raises(self):
        with self.assertRaises(ValueError):
            coefficiente_per_ateco("abc")



class TestRavvedimentoGS(unittest.TestCase):
    """Art. 116 c. 8 L. 388/2000, circ. INPS 98/2026: TUR 2,65% from 16/09/2026."""

    def test_within_120_days_single_payment_uses_tur_only(self):
        self.assertAlmostEqual(sanzione_ravvedimento_gs(3000, giorni=120, tur=0.0265), 26.14, places=2)

    def test_after_120_days_adds_5_5_points(self):
        self.assertAlmostEqual(sanzione_ravvedimento_gs(3000, giorni=121, tur=0.0265),
                               3000 * 0.0815 * 121 / 365, places=6)

    def test_capped_at_40_percent(self):
        self.assertEqual(sanzione_ravvedimento_gs(1000, giorni=3650, tur=0.0265), 400.0)


class TestCoperturaAcconti(unittest.TestCase):
    """Max incassi of the year already covered by the acconti paid (previsionale safety margin)."""

    def test_gs_and_tax_margins(self):
        r = incassi_coperti_da_acconti(
            acconti_gs_versati=3000, acconti_imposta_versati=600, contributi_versati=6000,
            coefficiente_redditivita=0.67, aliquota_sostitutiva=0.05, aliquota_inps=0.2607)
        self.assertAlmostEqual(r["gs"], 3000 / 0.8 / 0.2607 / 0.67, places=6)   # GS acconto = 80% of due
        self.assertAlmostEqual(r["imposta"], (600 / 0.05 + 6000) / 0.67, places=6)  # tax acconto = 100% of due
        self.assertAlmostEqual(r["limite"], min(r["gs"], r["imposta"]), places=6)


class TestFormatBreakdown(unittest.TestCase):
    def test_shows_revenue_and_net_lines(self):
        r = calculate(50000, coefficiente_redditivita=0.78, aliquota_sostitutiva=0.05,
                      aliquota_inps=0.2607)
        output = format_breakdown(r, fatturato=50000)
        self.assertIn("Netto reale", output)
        self.assertIn("50000.00", output)


if __name__ == "__main__":
    unittest.main()
