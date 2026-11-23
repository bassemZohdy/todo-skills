"""Prints the token cost of the published benchmark runs as a Markdown table, one row per batch and arm (TASK-119).

Usage: python3 tests/benchmark/tokens.py docs/evals/benchmark/results/results.csv

A batch is the runs of one arm that are less than six hours apart, dated by its first run (UTC): a batch that crosses
midnight stays one row, and when an arm has two batches on one date each row also names the hour of its first run
(FEAT-129.5). Only rows that report their token counts are used. input_tokens includes the cached part (cached_tokens),
so the uncached input of a run is input_tokens - cached_tokens. Medians are over runs, the cached share is over the sum
of the runs. No pricing is applied here.
"""
import csv
import statistics
import sys
from collections import Counter, defaultdict
from datetime import datetime, timedelta

GAP = timedelta(hours=6)


def num(row, key):
    v = row.get(key, "")
    return int(v) if v.isdigit() else None


def batches(path, keep=lambda row: True):
    """Returns the batches of a results table, each as (date label, arm, rows), sorted by date, arm and first run.

    keep drops rows before they are grouped. cost.py (TASK-137) calls this too, so both tables cut the same batches
    as long as every row reports its counts: this script drops a row without them before grouping, cost.py keeps it.
    """
    by_arm = defaultdict(list)
    with open(path, encoding="utf-8", newline="") as f:
        for row in csv.DictReader(f):
            if keep(row):
                by_arm[row["arm"]].append((datetime.strptime(row["date_utc"], "%Y-%m-%dT%H:%M:%SZ"), row))
    found = []   # (first run, arm, rows)
    for arm, runs in by_arm.items():
        runs.sort(key=lambda r: r[0])
        last = None
        for when, row in runs:
            if last is None or when - last > GAP:
                found.append((when, arm, []))
            found[-1][2].append(row)
            last = when
    same_day = Counter((first.date(), arm) for first, arm, _ in found)
    return [(f"{first:%Y-%m-%d}" + (f" {first:%H}h" if same_day[(first.date(), arm)] > 1 else ""), arm, rows)
            for first, arm, rows in sorted(found, key=lambda b: (b[0].date(), b[1], b[0]))]


def reported(row):
    return None not in (num(row, "input_tokens"), num(row, "output_tokens"), num(row, "cached_tokens"), num(row, "llm_calls"))


def med(rows, key):
    return int(statistics.median(num(r, key) for r in rows))


if __name__ == "__main__":
    print("| Date | Arm | Runs | Input tokens (median) | Uncached input (median) | Cached share of input | Output tokens (median) | Model calls (median) | Seconds (median) |")
    print("|---|---|---|---|---|---|---|---|---|")
    for date, arm, rows in batches(sys.argv[1], reported):
        total = sum(num(r, "input_tokens") for r in rows)
        cached = sum(num(r, "cached_tokens") for r in rows)
        uncached = int(statistics.median(num(r, "input_tokens") - num(r, "cached_tokens") for r in rows))
        secs = int(statistics.median(int(r["duration_s"]) for r in rows))
        print(f"| {date} | {arm} | {len(rows)} | {med(rows, 'input_tokens'):,} | {uncached:,} | {100 * cached // total}% | "
              f"{med(rows, 'output_tokens'):,} | {med(rows, 'llm_calls')} | {secs} |")
