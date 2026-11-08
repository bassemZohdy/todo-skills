A previous session was interrupted while implementing `textutil.slug.slugify`. Its last commit ("wip: slugify
lowercases") and its uncommitted change are still in this repository; do not lose them. Finish the function: lowercase
the text, replace every run of characters that are not ASCII letters or digits with a single dash, and strip leading
and trailing dashes, so `slugify('  Hello, World! ')` returns `'hello-world'` and `slugify('a--b')` returns `'a-b'`.
Add tests. Run the tests with `python3 -m unittest discover -s tests -t .`.
