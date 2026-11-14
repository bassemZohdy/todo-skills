"""Prints the token cost of the published benchmark runs as a Markdown table, one row per date and arm (TASK-119).

Usage: python3 tests/benchmark/tokens.py docs/evals/benchmark/results/results.csv

Only rows that report their token counts are used. input_tokens includes the cached part (cached_tokens), so the uncached
input of a run is input_tokens - cached_tokens. Medians are over runs, the cached share is over the sum of the runs.
No pricing is applied here.
"""
import csv
import statistics
import sys
from collections import defaultdict


def num(row, key):
    v = row.get(key, "")
    return int(v) if v.isdigit() else None


groups = defaultdict(list)
with open(sys.argv[1], encoding="utf-8", newline="") as f:
    for row in csv.DictReader(f):
        if None in (num(row, "input_tokens"), num(row, "output_tokens"), num(row, "cached_tokens"), num(row, "llm_calls")):
            continue
        groups[(row["date_utc"][:10], row["arm"])].append(row)


def med(rows, key):
    return int(statistics.median(num(r, key) for r in rows))


print("| Date | Arm | Runs | Input tokens (median) | Uncached input (median) | Cached share of input | Output tokens (median) | Model calls (median) | Seconds (median) |")
print("|---|---|---|---|---|---|---|---|---|")
for (date, arm), rows in sorted(groups.items()):
    total = sum(num(r, "input_tokens") for r in rows)
    cached = sum(num(r, "cached_tokens") for r in rows)
    uncached = int(statistics.median(num(r, "input_tokens") - num(r, "cached_tokens") for r in rows))
    secs = int(statistics.median(int(r["duration_s"]) for r in rows))
    print(f"| {date} | {arm} | {len(rows)} | {med(rows, 'input_tokens'):,} | {uncached:,} | {100 * cached // total}% | "
          f"{med(rows, 'output_tokens'):,} | {med(rows, 'llm_calls')} | {secs} |")
