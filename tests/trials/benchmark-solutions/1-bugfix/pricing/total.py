def order_total(subtotal):
    """Return the amount to charge for an order. Orders of 100 or more get 10% off, once."""
    if subtotal >= 100:
        return round(subtotal * 0.9, 2)
    return round(subtotal, 2)
