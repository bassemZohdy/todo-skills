Implement `auth.tokens.verify(token, secret, now)`. It returns the user name of a valid token made by `auth.tokens.sign`.
It must raise `auth.tokens.InvalidToken`, never another exception, when the token is expired (`now >= expires_at`), its
signature does not match, it was signed with a different secret, or it is malformed (not three parts, a non-integer expiry
or an empty user). Compare signatures in constant time. Add tests, including each rejection case. Run the tests with
`python3 -m unittest discover -s tests -t .`.
