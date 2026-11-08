"""Signed tokens: "<user>.<expires_at>.<hex HMAC-SHA256 of '<user>.<expires_at>'>"."""
import hashlib
import hmac


class InvalidToken(Exception):
    """Raised when a token cannot be accepted."""


def sign(user, expires_at, secret):
    payload = f"{user}.{int(expires_at)}"
    sig = hmac.new(secret.encode(), payload.encode(), hashlib.sha256).hexdigest()
    return f"{payload}.{sig}"


def verify(token, secret, now):
    raise NotImplementedError
