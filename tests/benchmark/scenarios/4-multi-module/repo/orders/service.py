"""Order placement. An order is a list of (sku, quantity) lines."""


def place_order(stock, lines):
    return {"lines": list(lines), "status": "placed"}
