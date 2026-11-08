class Stock:
    """Stock levels per SKU."""

    def __init__(self, levels):
        self._levels = dict(levels)

    def available(self, sku):
        return self._levels.get(sku, 0)
