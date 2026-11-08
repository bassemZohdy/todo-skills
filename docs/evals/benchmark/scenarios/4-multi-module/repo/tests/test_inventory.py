import unittest

from inventory.stock import Stock


class StockTest(unittest.TestCase):
    def test_available(self):
        self.assertEqual(Stock({"pen": 3}).available("pen"), 3)
        self.assertEqual(Stock({}).available("pen"), 0)


if __name__ == "__main__":
    unittest.main()
