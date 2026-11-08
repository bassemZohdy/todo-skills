class OutOfStock(Exception):
    """Raised when a reservation asks for more than is available."""


class Stock:
    """Stock levels per SKU."""

    def __init__(self, levels):
        self._levels = dict(levels)

    def available(self, sku):
        return self._levels.get(sku, 0)

    def reserve(self, lines):
        for sku, qty in lines:
            if qty > self.available(sku):
                raise OutOfStock(sku)
        for sku, qty in lines:
            self._levels[sku] = self.available(sku) - qty
