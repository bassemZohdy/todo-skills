import os, sys, unittest
sys.path.insert(0, os.getcwd())
from inventory.stock import OutOfStock, Stock
from orders.service import place_order


class Accept(unittest.TestCase):
    def test_reserve_lowers_levels(self):
        s = Stock({"pen": 3, "ink": 2})
        s.reserve([("pen", 2), ("ink", 2)])
        self.assertEqual((s.available("pen"), s.available("ink")), (1, 0))

    def test_reserve_is_all_or_nothing(self):
        s = Stock({"pen": 3, "ink": 1})
        with self.assertRaises(OutOfStock):
            s.reserve([("pen", 2), ("ink", 2)])
        self.assertEqual((s.available("pen"), s.available("ink")), (3, 1))

    def test_unknown_sku_is_out_of_stock(self):
        with self.assertRaises(OutOfStock):
            Stock({"pen": 3}).reserve([("cap", 1)])

    def test_place_order_reserves(self):
        s = Stock({"pen": 3})
        self.assertEqual(place_order(s, [("pen", 2)]), {"lines": [("pen", 2)], "status": "placed"})
        self.assertEqual(s.available("pen"), 1)

    def test_place_order_short_changes_nothing(self):
        s = Stock({"pen": 3, "ink": 0})
        with self.assertRaises(OutOfStock):
            place_order(s, [("pen", 1), ("ink", 1)])
        self.assertEqual((s.available("pen"), s.available("ink")), (3, 0))


unittest.main()
