import unittest

from textkit.rows import parse_row


class ParseRowTest(unittest.TestCase):
    def test_quoted_fields(self):
        self.assertEqual(parse_row('a,"b,c","say ""hi"""'), ["a", "b,c", 'say "hi"'])

    def test_empty_fields_and_trailing_newline(self):
        self.assertEqual(parse_row("a, b,,\r\n"), ["a", " b", "", ""])
        self.assertEqual(parse_row(""), [""])

    def test_unterminated_quote(self):
        with self.assertRaises(ValueError):
            parse_row('a,"b')


if __name__ == "__main__":
    unittest.main()
