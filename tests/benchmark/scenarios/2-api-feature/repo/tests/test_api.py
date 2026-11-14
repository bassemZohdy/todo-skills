import unittest

from shop.api import handle


class ListItemsTest(unittest.TestCase):
    def test_list_items(self):
        status, body = handle("GET", "/items")
        self.assertEqual(status, 200)
        self.assertEqual([i["id"] for i in body], [1, 2])


if __name__ == "__main__":
    unittest.main()
