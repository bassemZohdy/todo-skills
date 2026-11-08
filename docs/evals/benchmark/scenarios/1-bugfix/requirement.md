Customers report that orders of 200 or more are discounted twice: `order_total(250)` in `pricing/total.py` returns
202.5 instead of 225.0. Every order of 100 or more must get 10% off exactly once, and smaller orders get no discount.
Fix the bug and add a regression test that fails on the current code. Run the tests with `python3 -m unittest discover -s tests -t .`.
