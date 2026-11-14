import unittest

from billing.discount import price


class PriceTest(unittest.TestCase):
    def test_full_price(self):
        self.assertEqual(price({"id": 1, "orders": 0, "since": "2026-01-01"}, 10), 10)


if __name__ == "__main__":
    unittest.main()
