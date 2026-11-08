import unittest

from inventory.stock import Stock
from orders.service import place_order


class PlaceOrderTest(unittest.TestCase):
    def test_returns_placed(self):
        self.assertEqual(place_order(Stock({"pen": 3}), [("pen", 1)])["status"], "placed")


if __name__ == "__main__":
    unittest.main()
