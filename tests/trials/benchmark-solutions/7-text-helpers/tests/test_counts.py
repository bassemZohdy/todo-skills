import unittest

from textkit.counts import top_words


class TopWordsTest(unittest.TestCase):
    def test_counts_case_insensitively_and_breaks_ties_alphabetically(self):
        self.assertEqual(top_words("It's 'fine', it's FINE!", 2), [("fine", 2), ("it's", 2)])
        self.assertEqual(top_words("b a B A c", 3), [("a", 2), ("b", 2), ("c", 1)])

    def test_n_out_of_range(self):
        self.assertEqual(top_words("a b", 0), [])
        self.assertEqual(top_words("a b", 5), [("a", 1), ("b", 1)])
        with self.assertRaises(ValueError):
            top_words("a b", -1)


if __name__ == "__main__":
    unittest.main()
