import unittest

from textkit.case import title_case


class TitleCaseTest(unittest.TestCase):
    def test_capitalises_each_word(self):
        self.assertEqual(title_case("hello wORLD"), "Hello World")

    def test_empty_text(self):
        self.assertEqual(title_case(""), "")


if __name__ == "__main__":
    unittest.main()
