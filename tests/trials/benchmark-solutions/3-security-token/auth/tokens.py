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
    parts = token.split(".")
    if len(parts) != 3 or not parts[0] or not parts[1].isdigit():
        raise InvalidToken("malformed token")
    user, expires_at, sig = parts
    want = sign(user, int(expires_at), secret).split(".")[2]
    if not hmac.compare_digest(sig, want):
        raise InvalidToken("bad signature")
    if now >= int(expires_at):
        raise InvalidToken("expired")
    return user
