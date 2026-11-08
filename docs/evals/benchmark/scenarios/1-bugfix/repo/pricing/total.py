def order_total(subtotal):
    """Return the amount to charge for an order. Orders of 100 or more get 10% off."""
    total = subtotal
    if subtotal >= 100:
        total = total * 0.9
    if subtotal >= 200:
        total = total * 0.9
    return round(total, 2)
