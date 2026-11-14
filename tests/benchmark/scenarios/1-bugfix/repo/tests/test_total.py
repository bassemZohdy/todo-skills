import unittest

from pricing.total import order_total


class OrderTotalTest(unittest.TestCase):
    def test_small_order_has_no_discount(self):
        self.assertEqual(order_total(50), 50)

    def test_order_of_100_gets_ten_percent_off(self):
        self.assertEqual(order_total(100), 90.0)


if __name__ == "__main__":
    unittest.main()
