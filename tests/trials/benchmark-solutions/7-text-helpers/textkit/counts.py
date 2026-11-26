import re

_WORD = re.compile(r"[a-z]+(?:'[a-z]+)*")


def top_words(text, n):
    """The n most frequent words as (word, count) tuples, ties in alphabetical order."""
    if n < 0:
        raise ValueError("n must not be negative")
    counts = {}
    for word in _WORD.findall(text.lower()):
        counts[word] = counts.get(word, 0) + 1
    ranked = sorted(counts.items(), key=lambda item: (-item[1], item[0]))
    return ranked[:n]
