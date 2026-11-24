import os, sys, unittest
sys.path.insert(0, os.getcwd())

# One class per function of the requirement. Each class imports only its own function (from the package, and once from its module),
# inside setUp, so a repository that lacks one function fails that class alone. Run one class with: python3 test_accept.py SlugAccept


class SlugAccept(unittest.TestCase):
    def setUp(self):
        from textkit import slugify
        self.slugify = slugify

    def test_importable_from_its_module(self):
        from textkit.slug import slugify
        self.assertEqual(slugify("A b"), "a-b")

    def test_example_with_surrounding_noise(self):
        self.assertEqual(self.slugify("  Hello, World! "), "hello-world")

    def test_lowercases(self):
        self.assertEqual(self.slugify("ABC Def"), "abc-def")

    def test_runs_collapse_to_one_dash(self):
        self.assertEqual(self.slugify("a--b__c  d"), "a-b-c-d")
        self.assertEqual(self.slugify("one / two & three"), "one-two-three")

    def test_digits_are_kept(self):
        self.assertEqual(self.slugify("Python 3.12 rocks"), "python-3-12-rocks")

    def test_only_ascii_letters_and_digits_are_kept(self):
        self.assertEqual(self.slugify("caf\u00e9 au lait"), "caf-au-lait")

    def test_no_dash_at_the_ends(self):
        self.assertEqual(self.slugify("--a--"), "a")
        self.assertEqual(self.slugify("!!!"), "")
        self.assertEqual(self.slugify(""), "")

    def test_a_slug_is_unchanged(self):
        self.assertEqual(self.slugify("abc-123"), "abc-123")


class WrapAccept(unittest.TestCase):
    def setUp(self):
        from textkit import wrap
        self.wrap = wrap

    def test_importable_from_its_module(self):
        from textkit.wrap import wrap
        self.assertEqual(wrap("a b", 5), ["a b"])

    def test_examples(self):
        self.assertEqual(self.wrap("the quick brown fox", 10), ["the quick", "brown fox"])
        self.assertEqual(self.wrap("ab cd", 5), ["ab cd"])

    def test_width_is_inclusive(self):
        self.assertEqual(self.wrap("ab cd", 4), ["ab", "cd"])

    def test_lines_are_filled_greedily(self):
        self.assertEqual(self.wrap("aaa bb c dddd", 6), ["aaa bb", "c dddd"])
        self.assertEqual(self.wrap("a b c d e", 3), ["a b", "c d", "e"])

    def test_long_word_stands_alone_and_whole(self):
        self.assertEqual(self.wrap("a unbelievable b", 5), ["a", "unbelievable", "b"])
        self.assertEqual(self.wrap("unbelievable", 3), ["unbelievable"])

    def test_whitespace_separates_words_and_is_joined_by_single_spaces(self):
        self.assertEqual(self.wrap("a  b\nc\td", 20), ["a b c d"])
        self.assertEqual(self.wrap("  padded  words  ", 20), ["padded words"])

    def test_a_word_with_a_hyphen_is_not_cut(self):
        self.assertEqual(self.wrap("a well-known b", 5), ["a", "well-known", "b"])

    def test_width_one(self):
        self.assertEqual(self.wrap("a b c", 1), ["a", "b", "c"])

    def test_no_words(self):
        self.assertEqual(self.wrap("", 5), [])
        self.assertEqual(self.wrap("  \n ", 5), [])

    def test_width_below_one_raises_value_error(self):
        for width in (0, -3):
            with self.assertRaises(ValueError):
                self.wrap("some text", width)
        with self.assertRaises(ValueError):
            self.wrap("", 0)


class TopWordsAccept(unittest.TestCase):
    def setUp(self):
        from textkit import top_words
        self.top_words = top_words

    def test_importable_from_its_module(self):
        from textkit.counts import top_words
        self.assertEqual(top_words("a", 1), [("a", 1)])

    def test_example_with_apostrophes_and_case(self):
        self.assertEqual(self.top_words("It's 'fine', it's FINE!", 2), [("fine", 2), ("it's", 2)])

    def test_most_frequent_first(self):
        self.assertEqual(self.top_words("x y y z z z", 2), [("z", 3), ("y", 2)])

    def test_counts_are_case_insensitive(self):
        self.assertEqual(self.top_words("b a B A c", 3), [("a", 2), ("b", 2), ("c", 1)])

    def test_ties_are_alphabetical_not_in_order_of_appearance(self):
        self.assertEqual(self.top_words("pear apple fig", 3), [("apple", 1), ("fig", 1), ("pear", 1)])
        self.assertEqual(self.top_words("pear fig pear fig apple apple", 2), [("apple", 2), ("fig", 2)])

    def test_other_characters_end_a_word(self):
        self.assertEqual(self.top_words("one, two; one2 one", 5), [("one", 3), ("two", 1)])

    def test_apostrophe_inside_a_word_is_kept(self):
        self.assertEqual(self.top_words("don't stop", 5), [("don't", 1), ("stop", 1)])

    def test_apostrophes_only_between_letters(self):
        self.assertEqual(self.top_words("rock''n roll", 5), [("n", 1), ("rock", 1), ("roll", 1)])

    def test_only_ascii_letters_make_a_word(self):
        self.assertEqual(self.top_words("caf\u00e9 na\u00efve", 5), [("caf", 1), ("na", 1), ("ve", 1)])

    def test_n_larger_than_the_number_of_words(self):
        self.assertEqual(self.top_words("a b a", 10), [("a", 2), ("b", 1)])

    def test_n_zero_and_empty_text(self):
        self.assertEqual(self.top_words("a b", 0), [])
        self.assertEqual(self.top_words("", 3), [])
        self.assertEqual(self.top_words("123 !!!", 3), [])

    def test_negative_n_raises_value_error(self):
        with self.assertRaises(ValueError):
            self.top_words("a b", -1)

    def test_pairs_are_tuples(self):
        result = self.top_words("a a b", 2)
        self.assertIsInstance(result, list)
        self.assertTrue(all(isinstance(pair, tuple) for pair in result))


class ParseRowAccept(unittest.TestCase):
    def setUp(self):
        from textkit import parse_row
        self.parse_row = parse_row

    def test_importable_from_its_module(self):
        from textkit.rows import parse_row
        self.assertEqual(parse_row("a,b"), ["a", "b"])

    def test_plain_fields(self):
        self.assertEqual(self.parse_row("a,b,c"), ["a", "b", "c"])
        self.assertEqual(self.parse_row("abc"), ["abc"])

    def test_example_with_quotes(self):
        self.assertEqual(self.parse_row('a,"b,c","say ""hi"""'), ["a", "b,c", 'say "hi"'])

    def test_quoted_field_with_a_comma(self):
        self.assertEqual(self.parse_row('"a,b",c'), ["a,b", "c"])
        self.assertEqual(self.parse_row('x,"y,z,w"'), ["x", "y,z,w"])

    def test_doubled_quote_is_one_quote(self):
        self.assertEqual(self.parse_row('"say ""hi"""'), ['say "hi"'])
        self.assertEqual(self.parse_row('""""'), ['"'])

    def test_empty_quoted_field(self):
        self.assertEqual(self.parse_row('""'), [""])
        self.assertEqual(self.parse_row('"",x'), ["", "x"])

    def test_fields_are_not_trimmed_and_empty_fields_are_kept(self):
        self.assertEqual(self.parse_row("a, b,,"), ["a", " b", "", ""])
        self.assertEqual(self.parse_row(""), [""])
        self.assertEqual(self.parse_row(",a"), ["", "a"])

    def test_one_trailing_newline_is_ignored(self):
        self.assertEqual(self.parse_row("a,b\n"), ["a", "b"])
        self.assertEqual(self.parse_row("a,b\r\n"), ["a", "b"])
        self.assertEqual(self.parse_row('a,"b"\n'), ["a", "b"])
        self.assertEqual(self.parse_row("a,\n"), ["a", ""])

    def test_only_one_trailing_newline_is_ignored(self):
        self.assertEqual(self.parse_row("a,b\n\n"), ["a", "b\n"])
        self.assertEqual(self.parse_row("a,b\r"), ["a", "b\r"])

    def test_fields_are_not_trimmed(self):
        self.assertEqual(self.parse_row(" a,b "), [" a", "b "])

    def test_a_quote_elsewhere_in_a_field_is_ordinary(self):
        self.assertEqual(self.parse_row('a"b,c'), ['a"b', "c"])
        self.assertEqual(self.parse_row(' "a,b"'), [' "a', 'b"'])

    def test_unterminated_quote_raises_value_error(self):
        for line in ('"abc', 'a,"b', '"ab""', 'a,"b,c\n'):
            with self.assertRaises(ValueError):
                self.parse_row(line)


unittest.main()
