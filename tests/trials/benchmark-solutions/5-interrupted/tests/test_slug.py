import unittest

from textutil.slug import slugify


class SlugTest(unittest.TestCase):
    def test_lowercases(self):
        self.assertEqual(slugify("Hello"), "hello")

    def test_punctuation_and_spaces(self):
        self.assertEqual(slugify("  Hello, World! "), "hello-world")


if __name__ == "__main__":
    unittest.main()
