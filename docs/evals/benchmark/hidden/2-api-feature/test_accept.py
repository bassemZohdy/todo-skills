import os, sys, unittest
sys.path.insert(0, os.getcwd())
from shop.api import handle


class Accept(unittest.TestCase):
    def test_known_ids(self):
        self.assertEqual(handle("GET", "/items/1"), (200, {"id": 1, "name": "pen", "price": 1.5}))
        self.assertEqual(handle("GET", "/items/2")[0], 200)

    def test_unknown_id(self):
        self.assertEqual(handle("GET", "/items/99"), (404, {"error": "not found"}))

    def test_invalid_ids(self):
        for path in ("/items/abc", "/items/1.5"):
            self.assertEqual(handle("GET", path), (400, {"error": "invalid id"}), path)

    def test_list_still_works(self):
        status, body = handle("GET", "/items")
        self.assertEqual(status, 200)
        self.assertEqual([i["id"] for i in body], [1, 2])


unittest.main()
