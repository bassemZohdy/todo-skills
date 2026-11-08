import os, sys, unittest
sys.path.insert(0, os.getcwd())
from auth.tokens import InvalidToken, sign, verify


class Accept(unittest.TestCase):
    def test_valid(self):
        self.assertEqual(verify(sign("ada", 100, "k"), "k", 99), "ada")

    def test_expired_at_and_after_expiry(self):
        for now in (100, 101):
            with self.assertRaises(InvalidToken):
                verify(sign("ada", 100, "k"), "k", now)

    def test_tampered_user_and_expiry(self):
        user, exp, sig = sign("ada", 100, "k").split(".")
        for bad in (f"eve.{exp}.{sig}", f"{user}.999.{sig}", f"{user}.{exp}.{sig[:-1]}0"):
            with self.assertRaises(InvalidToken):
                verify(bad, "k", 50)

    def test_other_secret(self):
        with self.assertRaises(InvalidToken):
            verify(sign("ada", 100, "k"), "other", 50)

    def test_malformed(self):
        for bad in ("", "abc", "a.b", "a.x.ff", ".100.ff", "a.100.ff.extra"):
            with self.assertRaises(InvalidToken, msg=bad):
                verify(bad, "k", 50)

    def test_constant_time_compare(self):
        self.assertIn("compare_digest", open(os.path.join("auth", "tokens.py"), encoding="utf-8").read())


unittest.main()
