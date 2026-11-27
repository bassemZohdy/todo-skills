"""TASK-149: prints the final answer of a Claude Code stream-json session (the "result" of its last result event).
Usage: python3 -I claude-result.py <session.jsonl>
A file that holds no result event (an older claude, or a stub that prints plain text) is printed as it is, so that report.txt
still holds what the agent said. Python 3, standard library only."""
import json
import sys


def main(path):
    with open(path, encoding="utf-8-sig", errors="replace") as f:
        text = f.read()
    final = None
    for line in text.splitlines():
        try:
            d = json.loads(line)
        except ValueError:
            continue
        if isinstance(d, dict) and d.get("type") == "result" and isinstance(d.get("result"), str):
            final = d["result"]
    out = text if final is None else (final + "\n" if final.strip() else "")
    sys.stdout.buffer.write(out.encode("utf-8"))   # bytes: a console encoding such as cp1252 must not fail on an arrow or an emoji
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
