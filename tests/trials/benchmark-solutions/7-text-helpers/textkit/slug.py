import re


def slugify(text):
    """Lowercase URL slug: runs of anything but ASCII letters and digits become one '-', none at the ends."""
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")
