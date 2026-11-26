"""Prints the setup cost, the cost per task and the cost per node of the batch of TASK-139 as Markdown, from the published benchmark rows.

Usage: python3 tests/benchmark/setup_cost.py docs/evals/benchmark/results/results.csv --since <YYYY-MM-DD>
           --price input=<price>,cached=<price>,output=<price> --price-date <YYYY-MM-DD>
           --nodes <run id>=<n>,<run id>=<n>,...
       python3 tests/benchmark/setup_cost.py docs/evals/benchmark/results/results.csv --since <YYYY-MM-DD> --pending

The batch is the published rows dated on or after --since (UTC); older rows of the same arms are other versions of the skill
text and are not used. Two arms are compared on the same scenario: todo-skills, which sets the backlog up in the run, and
todo-skills-existing, which starts in a project whose backlog is already set up (its start commit holds what /todo-init
writes). Every figure is a median over the runs of a cell, rounded half away from zero (Decimal ROUND_HALF_UP, so the tie
-421.5 is printed as -422); no mean and no total is printed. A median of an odd number of values (the 3 runs of a cell) is one
of them, so only the USD figures change by rounding (four decimals); a median of an even number of values (the 6 scenarios) is
the mean of the two middle values, which are already rounded, and that mean is rounded again. Only the scored rows (PASS or
FAIL) of a cell enter its median, its run count and its dates; an INFRA_ERROR or UNVERIFIED row is not counted.

- Cost per task: the medians of todo-skills-existing per scenario 1 to 6, and the median of those six medians.
- Setup cost: the median of todo-skills minus the median of todo-skills-existing, same scenario (the difference of the rounded
  medians), for scenarios 1 to 6 and for 7 on its own line, with the lowest and highest USD of each cell so that the reader can
  see whether the cells overlap. One line is the median of the per-scenario differences and of the per-scenario shares (the
  share is the USD difference over the USD median of todo-skills). The dates of the first and last run of each cell are
  printed, because the cells were not run on one day.
- Cost per node: a run of todo-skills-existing on 7-text-helpers divided by the number of nodes it drained. The node counts
  are given with --nodes, one per run id: they are not in the published rows, so they are a local measurement (the Includes
  line of the drain commit in the run's repository), and the script refuses a run that has none.
- USD is computed from published pricing: the tokens of each run at the given prices (uncached input, cached input and output,
  per one million tokens) on the given date. It is not a bill.
- A cell with fewer than 3 scored runs is marked [[PENDING-5-6]]: it marks a cell that was still short when the page was
  generated. The mark is printed by this script, never typed.
- --pending prints, one per line, the cells of the batch that have fewer than 3 scored runs, as <arm>/<scenario>: the lines
  of coverage-pending.txt.
"""
import argparse
import csv
import statistics
import sys
from decimal import ROUND_HALF_UP, Decimal

sys.dont_write_bytecode = True   # importing cost.py must not leave a __pycache__ folder next to the scripts
from cost import PARTS, day, prices, uncached
from tokens import num

MARK = "[[PENDING-5-6]]"
ARM, EXISTING = "todo-skills", "todo-skills-existing"
SINGLE = ["1-bugfix", "2-api-feature", "3-security-token", "4-multi-module", "5-interrupted", "6-ambiguous"]
MULTI = "7-text-helpers"
ARMS7 = [ARM, "todo-skills-flow", EXISTING, "lean-baseline", "no-methodology"]
NEED = 3


def cells_needed():
    """The cells the batch has to fill, three runs each: five arms on the multi-node scenario, two arms on the others."""
    return [(a, s) for s in SINGLE + [MULTI] for a in (ARMS7 if s == MULTI else (ARM, EXISTING))]


def half_up(x):
    """Rounds to an integer, ties away from zero (the Decimal ROUND_HALF_UP rule: 0.5 -> 1 and -421.5 -> -422)."""
    return int(Decimal(str(x)).quantize(Decimal(1), rounding=ROUND_HALF_UP))


def usd_of(row, price):
    spent = {"input": uncached(row), "cached": num(row, "cached_tokens"), "output": num(row, "output_tokens")}
    return sum(Decimal(spent[p]) * price[p] for p in PARTS) / 1000000


def money(x):
    return str(Decimal(x).quantize(Decimal("0.0001"), rounding=ROUND_HALF_UP))


def med_usd(values):
    return Decimal(str(statistics.median(values))).quantize(Decimal("0.0001"), rounding=ROUND_HALF_UP)


def one_decimal(x):
    return Decimal(str(x)).quantize(Decimal("0.1"), rounding=ROUND_HALF_UP)


def fmt(x):
    return f"{x:,}"


def signed(x):
    return f"{x:,}" if x >= 0 else f"-{-x:,}"


class Cell:
    def __init__(self, rows, price):
        self.n = len(rows)
        self.passes = sum(r["final_outcome"] == "PASS" for r in rows)
        self.m = {}
        self.span = self.dates = "-"
        if rows:
            got = lambda f: [f(r) for r in rows]
            usds = got(lambda r: usd_of(r, price))
            self.m = {"input": half_up(statistics.median(got(lambda r: num(r, "input_tokens")))),
                      "uncached": half_up(statistics.median(got(uncached))),
                      "output": half_up(statistics.median(got(lambda r: num(r, "output_tokens")))),
                      "calls": half_up(statistics.median(got(lambda r: num(r, "llm_calls")))),
                      "seconds": half_up(statistics.median(got(lambda r: int(r["duration_s"])))),
                      "usd": med_usd(usds)}
            self.span = f"{money(min(usds))} to {money(max(usds))}"
            days = sorted(r["date_utc"][:10] for r in rows)
            self.dates = days[0] if days[0] == days[-1] else f"{days[0]} to {days[-1]}"


def scored(rows):
    return [r for r in rows if r["final_outcome"] in ("PASS", "FAIL")]


def load(path, since):
    """The scored rows (PASS or FAIL) dated on or after since: an INFRA_ERROR or UNVERIFIED row never enters a median or a run count."""
    with open(path, encoding="utf-8", newline="") as f:
        return scored([r for r in csv.DictReader(f) if r["date_utc"][:10] >= since])


def main():
    ap = argparse.ArgumentParser(description="Setup cost, cost per task and cost per node of the TASK-139 batch.")
    ap.add_argument("results")
    ap.add_argument("--since", type=day, required=True, metavar="YYYY-MM-DD", help="the first day of the batch (UTC)")
    ap.add_argument("--price", type=prices, metavar="input=<price>,cached=<price>,output=<price>")
    ap.add_argument("--price-date", type=day, metavar="YYYY-MM-DD")
    ap.add_argument("--nodes", metavar="<run id>=<n>,...")
    ap.add_argument("--pending", action="store_true", help="print the cells with fewer than 3 scored runs and nothing else")
    a = ap.parse_args()
    by = {}
    for r in load(a.results, a.since):
        by.setdefault((r["arm"], r["scenario"]), []).append(r)
    if a.pending:
        for arm, s in cells_needed():
            if len(by.get((arm, s), [])) < NEED:
                print(f"{arm}/{s}")
        return 0
    if not a.price or not a.price_date or not a.nodes:
        ap.error("--price, --price-date and --nodes are required unless --pending is given")
    nodes = {}
    for item in a.nodes.split(","):
        rid, _, n = item.partition("=")
        if not n.isdigit() or int(n) < 1 or rid in nodes:
            ap.error(f"bad --nodes item: {item}")
        nodes[rid] = int(n)
    empty = Cell([], a.price)
    cells = {k: Cell(v, a.price) for k, v in by.items()}
    cell = lambda arm, s: cells.get((arm, s), empty)
    pend = lambda *ks: MARK if any(cell(*k).n < NEED for k in ks) else ""
    tag = lambda text, *ks: (text + " " + pend(*ks)).strip()
    priced = "USD per run (computed from published pricing of %s)" % a.price_date
    out = []

    # 1. cost per task
    out += ["Cost per task: the medians of `todo-skills-existing` on the single-task scenarios.", "",
            f"| Scenario | Runs | PASS | Input tokens | Uncached input | Output tokens | Model calls | Seconds | {priced} | USD per run, lowest to highest |",
            "|---|---|---|---|---|---|---|---|---|---|"]
    task = []
    for s in SINGLE:
        c = cell(EXISTING, s)
        if not c.m:
            out.append(f"| {tag('`' + s + '`', (EXISTING, s))} | 0 | 0 | - | - | - | - | - | - | - |")
            continue
        task.append(c)
        out.append(f"| {tag('`' + s + '`', (EXISTING, s))} | {c.n} | {c.passes} | {fmt(c.m['input'])} | {fmt(c.m['uncached'])} | {fmt(c.m['output'])} | {c.m['calls']} | {c.m['seconds']} | {money(c.m['usd'])} | {c.span} |")

    def over(cs, key):
        v = [c.m[key] for c in cs]
        return money(med_usd(v)) if key == "usd" else fmt(half_up(statistics.median(v)))
    out.append(f"| {tag('Median of the scenario medians', *[(EXISTING, s) for s in SINGLE])} | | | {over(task, 'input')} | {over(task, 'uncached')} | {over(task, 'output')} | {over(task, 'calls')} | {over(task, 'seconds')} | {over(task, 'usd')} | |")
    out.append("")

    # 2. setup cost
    out += ["Setup cost: the median of `todo-skills` minus the median of `todo-skills-existing`, same scenario (difference of the rounded medians).", "",
            "| Scenario | Runs, todo-skills / todo-skills-existing | Input tokens | Uncached input | Output tokens | Model calls | Seconds | USD per run | Share of the todo-skills USD median | USD per run of todo-skills, lowest to highest | USD per run of todo-skills-existing, lowest to highest |",
            "|---|---|---|---|---|---|---|---|---|---|---|"]
    diffs = []

    def setup_row(s, label):
        t, e = cell(ARM, s), cell(EXISTING, s)
        if not t.m or not e.m:
            return f"| {tag(label, (ARM, s), (EXISTING, s))} | {t.n} / {e.n} | - | - | - | - | - | - | - | {t.span} | {e.span} |", None
        d = {k: t.m[k] - e.m[k] for k in t.m}
        d["share"] = half_up(Decimal(100) * d["usd"] / t.m["usd"])
        return (f"| {tag(label, (ARM, s), (EXISTING, s))} | {t.n} / {e.n} | {signed(d['input'])} | {signed(d['uncached'])} | {signed(d['output'])} | "
                f"{signed(d['calls'])} | {signed(d['seconds'])} | {money(d['usd'])} | {d['share']}% | {t.span} | {e.span} |"), d
    for s in SINGLE:
        row, d = setup_row(s, f"`{s}`")
        out.append(row)
        if d:
            diffs.append(d)
    md = lambda key: statistics.median(d[key] for d in diffs)
    both = [(a2, s) for a2 in (ARM, EXISTING) for s in SINGLE]
    out.append(f"| {tag('Median of the per-scenario differences', *both)} | | {signed(half_up(md('input')))} | {signed(half_up(md('uncached')))} | {signed(half_up(md('output')))} | {signed(half_up(md('calls')))} | {signed(half_up(md('seconds')))} | {money(med_usd([d['usd'] for d in diffs]))} | {half_up(md('share'))}% | | |")
    row7, d7 = setup_row(MULTI, f"`{MULTI}`")
    out += [row7, ""]

    out += ["When the cells ran (UTC dates of the first and last run).", "",
            "| Scenario | todo-skills | todo-skills-existing |", "|---|---|---|"]
    for s in SINGLE + [MULTI]:
        out.append(f"| `{s}` | {cell(ARM, s).dates} | {cell(EXISTING, s).dates} |")
    out.append("")

    # 3. cost per node
    ex7 = by.get((EXISTING, MULTI), [])
    known = {r["run_id"] for r in ex7}
    if known != set(nodes):
        sys.exit(f"--nodes must name every run of {EXISTING} on {MULTI} and no other (missing: {sorted(known - set(nodes))}, unknown: {sorted(set(nodes) - known)})")
    out += ["Cost per node: each run of `todo-skills-existing` on `7-text-helpers` divided by the nodes it drained (the node counts are a local measurement, see the text).", "",
            "| Run | Nodes drained | USD per run | USD per node | Model calls per node | Seconds per node | Uncached input plus output per node |",
            "|---|---|---|---|---|---|---|"]
    per = []
    for r in sorted(ex7, key=lambda r: r["run_id"]):
        n = nodes[r["run_id"]]
        usd = usd_of(r, a.price)
        calls, secs = Decimal(num(r, "llm_calls")), Decimal(int(r["duration_s"]))
        tok = Decimal(uncached(r) + num(r, "output_tokens"))
        per.append((n, usd, calls, secs, tok))
        out.append(f"| `{r['run_id']}` | {n} | {money(usd)} | {money(usd / n)} | {one_decimal(calls / n)} | {half_up(secs / n)} | {fmt(half_up(tok / n))} |")
    q = lambda f: statistics.median(f(p) for p in per)
    out.append(f"| Median | {half_up(q(lambda p: p[0]))} | {money(med_usd([p[1] for p in per]))} | {money(med_usd([p[1] / p[0] for p in per]))} | {one_decimal(q(lambda p: p[2] / p[0]))} | {half_up(q(lambda p: p[3] / p[0]))} | {fmt(half_up(q(lambda p: p[4] / p[0])))} |")
    out.append("")

    # 4. the five arms on the multi-node scenario
    out += ["The five arms on `7-text-helpers`, medians.", "",
            f"| Arm | Runs | PASS | Input tokens | Uncached input | Output tokens | Model calls | Seconds | {priced} | USD per run, lowest to highest | Dates (UTC) |",
            "|---|---|---|---|---|---|---|---|---|---|---|"]
    for arm in ARMS7:
        c = cell(arm, MULTI)
        if not c.m:
            sys.exit(f"no row of {arm} on {MULTI} in the batch")
        out.append(f"| `{arm}` | {c.n} | {c.passes} | {fmt(c.m['input'])} | {fmt(c.m['uncached'])} | {fmt(c.m['output'])} | {c.m['calls']} | {c.m['seconds']} | {money(c.m['usd'])} | {c.span} | {c.dates} |")
    out.append("")

    # 5. headline lines, generated so that no figure in the text is typed by hand
    ex = cell(EXISTING, MULTI)
    out += [f"Headline figures (medians; USD computed from published pricing of {a.price_date}):", "",
            f"- **Setup cost, scenarios 1 to 6, median of the per-scenario differences:** {signed(half_up(md('uncached')))} uncached input tokens, {signed(half_up(md('output')))} output tokens, {signed(half_up(md('calls')))} model calls, {signed(half_up(md('seconds')))} seconds, USD {money(med_usd([d['usd'] for d in diffs]))} per run; the median of the per-scenario shares of the `todo-skills` USD median is {half_up(md('share'))}%. {pend(*both)}".rstrip(),
            f"- **Setup cost on `7-text-helpers`:** USD {money(d7['usd'])} per run, {d7['share']}% of the `todo-skills` USD median there.",
            f"- **Cost per task, `todo-skills-existing`, median of the scenario medians 1 to 6:** USD {over(task, 'usd')} per run, {over(task, 'calls')} model calls, {over(task, 'seconds')} seconds. {pend(*[(EXISTING, s) for s in SINGLE])}".rstrip(),
            f"- **Cost per node, `todo-skills-existing` on `7-text-helpers`:** USD {money(med_usd([p[1] / p[0] for p in per]))} per node (median of the runs, {half_up(q(lambda p: p[0]))} nodes each), {fmt(half_up(q(lambda p: p[4] / p[0])))} uncached input plus output tokens per node; the whole run is USD {money(ex.m['usd'])} (median), against USD {money(cell('no-methodology', MULTI).m['usd'])} for `no-methodology` and USD {money(cell('lean-baseline', MULTI).m['usd'])} for `lean-baseline` on the same scenario."]
    print("\n".join(out))
    return 0


if __name__ == "__main__":
    sys.exit(main())
