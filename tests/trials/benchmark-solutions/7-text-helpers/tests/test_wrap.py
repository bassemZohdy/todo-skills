import unittest

from textkit.wrap import wrap


class WrapTest(unittest.TestCase):
    def test_wraps_greedily_within_width(self):
        self.assertEqual(wrap("the quick brown fox", 10), ["the quick", "brown fox"])
        self.assertEqual(wrap("ab cd", 5), ["ab cd"])

    def test_long_word_stays_whole(self):
        self.assertEqual(wrap("a unbelievable b", 5), ["a", "unbelievable", "b"])

    def test_no_words(self):
        self.assertEqual(wrap("   ", 5), [])

    def test_width_below_one(self):
        with self.assertRaises(ValueError):
            wrap("", 0)


if __name__ == "__main__":
    unittest.main()
