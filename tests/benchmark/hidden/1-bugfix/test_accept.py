import os, sys, unittest
sys.path.insert(0, os.getcwd())
from pricing.total import order_total


class Accept(unittest.TestCase):
    def test_discount_applies_exactly_once(self):
        for subtotal, want in ((0, 0), (99.99, 99.99), (100, 90.0), (150, 135.0), (200, 180.0), (250, 225.0), (1000, 900.0)):
            self.assertAlmostEqual(order_total(subtotal), want, places=2, msg=subtotal)


unittest.main()
