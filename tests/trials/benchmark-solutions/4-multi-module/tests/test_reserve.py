import unittest

from inventory.stock import OutOfStock, Stock
from orders.service import place_order


class ReserveTest(unittest.TestCase):
    def test_reserve(self):
        s = Stock({"pen": 2})
        s.reserve([("pen", 2)])
        self.assertEqual(s.available("pen"), 0)

    def test_order_short(self):
        s = Stock({"pen": 1})
        with self.assertRaises(OutOfStock):
            place_order(s, [("pen", 2)])
        self.assertEqual(s.available("pen"), 1)


if __name__ == "__main__":
    unittest.main()
