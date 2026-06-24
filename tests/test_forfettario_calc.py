"""TDD tests for forfettario_calc.py — Italian forfettario tax regime calculator."""

import sys
import os
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "forfettario-tax-calculator", "scripts"))

from forfettario_calc import calculate


class TestForfettarioCalcCase1(unittest.TestCase):
    """Case 1: 50k fatturato, standard professional coefficients."""

    def setUp(self):
        self.result = calculate(
            fatturato=50000,
            coefficiente_redditivita=0.78,
            aliquota_inps=0.2607,
            aliquota_sostitutiva=0.05,
        )

    def test_imponibile_lordo(self):
        self.assertAlmostEqual(self.result["imponibile_lordo"], 39000.0, places=5)

    def test_contributi_inps(self):
        self.assertAlmostEqual(self.result["contributi_inps"], 10167.3, places=4)

    def test_imponibile_netto(self):
        self.assertAlmostEqual(self.result["imponibile_netto"], 28832.7, places=4)

    def test_imposta(self):
        self.assertAlmostEqual(self.result["imposta"], 1441.635, places=5)

    def test_netto(self):
        self.assertAlmostEqual(self.result["netto"], 38391.065, places=4)


class TestForfettarioCalcCase2(unittest.TestCase):
    """Case 2: 30k fatturato, zero INPS — isolates contribution deduction."""

    def setUp(self):
        self.result = calculate(
            fatturato=30000,
            coefficiente_redditivita=0.78,
            aliquota_inps=0.0,
            aliquota_sostitutiva=0.15,
        )

    def test_imponibile_netto(self):
        self.assertAlmostEqual(self.result["imponibile_netto"], 23400.0, places=5)

    def test_imposta(self):
        self.assertAlmostEqual(self.result["imposta"], 3510.0, places=5)

    def test_netto(self):
        self.assertAlmostEqual(self.result["netto"], 26490.0, places=5)


class TestForfettarioCalcCase3(unittest.TestCase):
    """Case 3: zero fatturato — all outputs must be zero."""

    def test_all_zero(self):
        result = calculate(fatturato=0)
        for key, value in result.items():
            self.assertEqual(value, 0.0, msg=f"{key} should be 0.0")


class TestForfettarioCalcCase4(unittest.TestCase):
    """Case 4: negative fatturato must raise ValueError."""

    def test_negative_raises(self):
        with self.assertRaises(ValueError):
            calculate(fatturato=-1000)


class TestForfettarioCalcOutputKeys(unittest.TestCase):
    """Result dict must contain all expected keys."""

    def test_keys_present(self):
        result = calculate(fatturato=10000)
        expected_keys = {
            "imponibile_lordo",
            "contributi_inps",
            "imponibile_netto",
            "imposta",
            "netto",
        }
        self.assertEqual(set(result.keys()), expected_keys)


if __name__ == "__main__":
    unittest.main()
