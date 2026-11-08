import unittest

from shop.api import handle


class ItemTest(unittest.TestCase):
    def test_known(self):
        self.assertEqual(handle("GET", "/items/1")[0], 200)

    def test_unknown(self):
        self.assertEqual(handle("GET", "/items/99")[0], 404)

    def test_invalid(self):
        self.assertEqual(handle("GET", "/items/abc")[0], 400)


if __name__ == "__main__":
    unittest.main()
