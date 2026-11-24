def wrap(text, width):
    """Greedy word wrap into a list of lines; a word longer than width stays whole on its own line."""
    if width < 1:
        raise ValueError("width must be at least 1")
    lines = []
    line = ""
    for word in text.split():
        if line and len(line) + 1 + len(word) <= width:
            line += " " + word
        else:
            if line:
                lines.append(line)
            line = word
    if line:
        lines.append(line)
    return lines
