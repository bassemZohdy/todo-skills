import os, sys, unittest
sys.path.insert(0, os.getcwd())
from textutil.slug import slugify


class Accept(unittest.TestCase):
    def test_slugify(self):
        for text, want in (("  Hello, World! ", "hello-world"), ("a--b", "a-b"), ("Already-slug", "already-slug"),
                           ("Mix 3 Numbers 42", "mix-3-numbers-42"), ("--x--", "x"), ("", "")):
            self.assertEqual(slugify(text), want, text)


unittest.main()
