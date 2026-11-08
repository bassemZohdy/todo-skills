"""A tiny request handler: handle(method, path) returns (status, body)."""

ITEMS = {
    1: {"id": 1, "name": "pen", "price": 1.5},
    2: {"id": 2, "name": "notebook", "price": 4.0},
}


def handle(method, path):
    if method == "GET" and path == "/items":
        return 200, [ITEMS[k] for k in sorted(ITEMS)]
    if method == "GET" and path.startswith("/items/"):
        raw = path[len("/items/"):]
        if not raw.isdigit():
            return 400, {"error": "invalid id"}
        item = ITEMS.get(int(raw))
        return (200, item) if item else (404, {"error": "not found"})
    return 404, {"error": "not found"}
