"""A tiny request handler: handle(method, path) returns (status, body)."""

ITEMS = {
    1: {"id": 1, "name": "pen", "price": 1.5},
    2: {"id": 2, "name": "notebook", "price": 4.0},
}


def handle(method, path):
    if method == "GET" and path == "/items":
        return 200, [ITEMS[k] for k in sorted(ITEMS)]
    return 404, {"error": "not found"}
