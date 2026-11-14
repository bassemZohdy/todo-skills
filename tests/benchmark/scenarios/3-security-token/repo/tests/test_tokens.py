import unittest

from auth.tokens import sign


class SignTest(unittest.TestCase):
    def test_sign_has_three_parts(self):
        self.assertEqual(len(sign("ada", 100, "s3cret").split(".")), 3)


if __name__ == "__main__":
    unittest.main()
