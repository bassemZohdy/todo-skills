Placing an order must reserve its stock. Add `inventory.stock.Stock.reserve(lines)`: it takes a list of `(sku, quantity)`
lines and lowers each level, or raises `inventory.stock.OutOfStock` and changes nothing when any line asks for more than
is available (an unknown SKU has 0). Make `orders.service.place_order(stock, lines)` reserve through it: on success it
returns `{"lines": [...], "status": "placed"}`; when stock is short, `OutOfStock` propagates and every level is unchanged.
Add tests in both packages. Run the tests with `python3 -m unittest discover -s tests -t .`.
