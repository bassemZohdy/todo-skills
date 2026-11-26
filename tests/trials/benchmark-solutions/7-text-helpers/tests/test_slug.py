import unittest

from textkit.slug import slugify


class SlugifyTest(unittest.TestCase):
    def test_lowercases_and_joins_with_one_dash(self):
        self.assertEqual(slugify("  Hello, World! "), "hello-world")
        self.assertEqual(slugify("a--b__c  d"), "a-b-c-d")

    def test_only_ascii_letters_and_digits_stay(self):
        self.assertEqual(slugify("caf\u00e9 au lait"), "caf-au-lait")

    def test_nothing_left(self):
        self.assertEqual(slugify("!!!"), "")


if __name__ == "__main__":
    unittest.main()
