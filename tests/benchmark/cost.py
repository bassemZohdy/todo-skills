"""Prints what one successful benchmark run cost, as a Markdown table with one row per batch and arm (TASK-137).

Usage: python3 tests/benchmark/cost.py docs/evals/benchmark/results/results.csv
           [--price input=<price>,cached=<price>,output=<price> --price-date <YYYY-MM-DD>]

The batches are those of tokens.py: the runs of one arm that are less than six hours apart, dated by the first run.
Every row of the results table is counted, whatever its outcome.

- Counts: the runs, the runs that were PASS on the first attempt (first_outcome) and at the end (final_outcome), the
  attempts beyond the first (the sum of attempts minus the runs, which is the retries the harness made after a FAIL) and
  the runs that were not scored (INFRA_ERROR and UNVERIFIED).
- Per PASS: what the whole batch spent, divided by the number of its runs that ended in PASS. Failed and unscored runs
  stay in the total, because their cost was paid. A results row already holds the sum over the attempts of its run.
  Uncached input is input_tokens - cached_tokens, as in tokens.py. Results are rounded half up.
- A batch without a PASS prints a dash in the per-PASS cells; nothing is divided by zero.
- A run that does not report a count (the value is "unavailable") is never dropped: it stays in the runs, in the
  outcome counts and in the PASS divisor. A total with an unknown part is unknown, so the per-PASS cell of that count
  says "unavailable" for the whole batch instead of showing a figure that is too low.

Money is printed only with --price and --price-date, which belong together. The prices are US dollars per one million
tokens of uncached input, cached input and output. The extra column is the batch's tokens at those prices, divided by
its PASS runs, and its header says that it is computed from published pricing, with the date. It is not a bill.
"""
import argparse
import re
import sys
from datetime import datetime
from decimal import ROUND_HALF_UP, Decimal

sys.dont_write_bytecode = True   # importing tokens.py must not leave a __pycache__ folder next to the scripts
from tokens import batches, num

PARTS = ("input", "cached", "output")
NOT_SCORED = ("INFRA_ERROR", "UNVERIFIED")
HEAD = ["Date", "Arm", "Runs", "PASS on the first attempt", "PASS at the end", "Attempts beyond the first", "Runs not scored",
        "Uncached input per PASS", "Cached input per PASS", "Output tokens per PASS", "Model calls per PASS", "Seconds per PASS"]


def prices(text):
    items = [item.partition("=") for item in text.split(",")]
    if sorted(k for k, _, _ in items) != sorted(PARTS) or not all(re.fullmatch(r"\d+(\.\d+)?", v) for _, _, v in items):
        raise argparse.ArgumentTypeError("expected input=<price>,cached=<price>,output=<price>, each per one million tokens")
    return {k: Decimal(v) for k, _, v in items}


def day(text):
    try:
        if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", text):
            raise ValueError(text)
        datetime.strptime(text, "%Y-%m-%d")   # a real calendar day, not only the shape
    except ValueError:
        raise argparse.ArgumentTypeError("expected the date the prices were read, as YYYY-MM-DD") from None
    return text


def total(rows, value):
    """The sum of value(row) over the rows, or None when one of them does not report it."""
    values = [value(r) for r in rows]
    return None if None in values else sum(values)


def uncached(row):
    read, hit = num(row, "input_tokens"), num(row, "cached_tokens")
    return None if None in (read, hit) else read - hit


def per_pass(spent, passes, places=0):
    if passes == 0:
        return "-"
    if spent is None:
        return "unavailable"
    return f"{(Decimal(spent) / passes).quantize(Decimal(1).scaleb(-places), rounding=ROUND_HALF_UP):,}"


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description="The cost of one successful benchmark run per batch and arm, as a Markdown table.")
    ap.add_argument("results", help="a results.csv of the benchmark")
    ap.add_argument("--price", type=prices, metavar="input=<price>,cached=<price>,output=<price>",
                    help="US dollars per one million tokens; adds the money column")
    ap.add_argument("--price-date", type=day, metavar="YYYY-MM-DD", help="the date the prices were read")
    args = ap.parse_args()
    if (args.price is None) != (args.price_date is None):
        ap.error("--price and --price-date belong together")
    head = HEAD + ([f"USD per PASS (computed from published pricing of {args.price_date})"] if args.price else [])
    print("| " + " | ".join(head) + " |")
    print("|" + "---|" * len(head))
    for date, arm, rows in batches(args.results):
        passes = sum(r["final_outcome"] == "PASS" for r in rows)
        attempts = total(rows, lambda r: num(r, "attempts"))
        spent = {"input": total(rows, uncached), "cached": total(rows, lambda r: num(r, "cached_tokens")),
                 "output": total(rows, lambda r: num(r, "output_tokens"))}
        cells = [date, arm, len(rows), sum(r["first_outcome"] == "PASS" for r in rows), passes,
                 "unavailable" if attempts is None else attempts - len(rows), sum(r["final_outcome"] in NOT_SCORED for r in rows)]
        cells += [per_pass(spent[part], passes) for part in PARTS]
        cells += [per_pass(total(rows, lambda r: num(r, "llm_calls")), passes, 1),
                  per_pass(total(rows, lambda r: num(r, "duration_s")), passes)]
        if args.price:
            money = None if None in spent.values() else sum(spent[part] * args.price[part] for part in PARTS) / 1000000
            cells.append(per_pass(money, passes, 4))
        print("| " + " | ".join(str(c) for c in cells) + " |")
