Add four functions to the `textkit` package, each in the module named here and each importable from the package itself (`from
textkit import slugify, wrap, top_words, parse_row`). `textkit.slug.slugify(text)` returns the text as a URL slug: lowercase,
every run of characters that are not ASCII letters or digits replaced by a single `-`, and no `-` at the start or end, so
`slugify('  Hello, World! ')` is `'hello-world'`, `slugify('caf\u00e9 au lait')` is `'caf-au-lait'` and `slugify('!!!')` is
`''`. `textkit.wrap.wrap(text, width)` word-wraps the text into a list of lines. Words are the pieces of the text between
whitespace; each line takes whole words for as long as the line, with a single space between the words, stays within `width`
characters, so `wrap('the quick brown fox', 10)` is `['the quick', 'brown fox']` and `wrap('ab cd', 5)` is `['ab cd']`. A
word longer than `width` is never cut: it stands alone on its own line (`wrap('a unbelievable b', 5)` is `['a',
'unbelievable', 'b']`). Text with no words gives `[]`, and a `width` below 1 raises `ValueError`, even for empty text.
`textkit.counts.top_words(text, n)` returns the `n` most frequent words of the text as a list of `(word, count)` tuples, most
frequent first, with equal counts in alphabetical (plain string) order. A word is a run of ASCII letters that may hold single
apostrophes between letters, and it is counted in lowercase; any other character ends a word, including an apostrophe at the
start or end of a run, so `top_words("It's 'fine', it's FINE!", 2)` is `[('fine', 2), ("it's", 2)]`. When the text has fewer
than `n` different words, all of them are returned; `n` of 0 gives `[]`, and a negative `n` raises `ValueError`.
`textkit.rows.parse_row(line)` splits one line of comma-separated values into a list of strings. A field that starts with a
double quote is quoted: its commas do not split it, a doubled quote (`""`) inside it is one double quote, and the quotes
around it are dropped, so `parse_row('a,"b,c","say ""hi"""')` is `['a', 'b,c', 'say "hi"']`. A closing quote is always
followed by a comma or the end of the line, and a double quote anywhere else in a field is an ordinary character. Fields are
not trimmed and empty fields are kept: `parse_row('a, b,,')` is `['a', ' b', '', '']` and `parse_row('')` is `['']`. One
trailing `\n` or `\r\n` is ignored. A quoted field that is never closed raises `ValueError`. Add tests for each. Run the
tests with `python3 -m unittest discover -s tests -t .`.
