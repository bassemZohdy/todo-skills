import unittest

from auth.tokens import InvalidToken, sign, verify


class VerifyTest(unittest.TestCase):
    def test_valid(self):
        self.assertEqual(verify(sign("ada", 100, "k"), "k", 1), "ada")

    def test_rejects_expired(self):
        with self.assertRaises(InvalidToken):
            verify(sign("ada", 100, "k"), "k", 100)

    def test_rejects_other_secret(self):
        with self.assertRaises(InvalidToken):
            verify(sign("ada", 100, "k"), "x", 1)

    def test_rejects_malformed(self):
        with self.assertRaises(InvalidToken):
            verify("a.b", "k", 1)


if __name__ == "__main__":
    unittest.main()
