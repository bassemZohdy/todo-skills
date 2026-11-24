def parse_row(line):
    """Split one comma-separated line; a field starting with '"' may hold commas and doubled quotes."""
    if line.endswith("\r\n"):
        line = line[:-2]
    elif line.endswith("\n"):
        line = line[:-1]
    fields = []
    i = 0
    while True:
        if line.startswith('"', i):
            i += 1
            value = []
            while True:
                j = line.find('"', i)
                if j < 0:
                    raise ValueError("unterminated quoted field")
                value.append(line[i:j])
                if line.startswith('""', j):
                    value.append('"')
                    i = j + 2
                else:
                    i = j + 1
                    break
            fields.append("".join(value))
            j = line.find(",", i)
        else:
            j = line.find(",", i)
            fields.append(line[i:] if j < 0 else line[i:j])
        if j < 0:
            return fields
        i = j + 1
