"""TASK-147: the parser behind tdd-order.sh (read its header for the verdicts and the rules). Python 3, standard library only."""
import json
import posixpath
import re
import sys

EDIT_TOOLS = {"edit", "write", "multiedit", "notebookedit", "apply_patch", "str_replace_editor", "str_replace"}
SHELL_TOOLS = {"powershell", "bash", "shell", "bash_tool", "run_shell_command"}

TEST_CMD = re.compile(
    r"\b(unittest|pytest|py\.test|nosetests|jest|vitest|mocha|rspec|phpunit|mvn|mvnw|gradle|gradlew|ctest)\b"
    r"|\b(npm|yarn|pnpm|bun)\s+(run\s+)?test\b|\bnode\s+--test\b|\b(go|cargo|dotnet)\s+test\b|\bmake\s+test\b"
    r"|\b(bash|sh)\s+\S*tests?/\S*\.sh\b")
# a command segment that starts with one of these only reads or searches, so a runner name in it is not a test run
NOT_A_RUN = {"grep", "egrep", "rg", "which", "where", "cat", "ls", "find", "echo", "type", "head", "tail", "sed", "awk", "wc",
             "git", "man", "printf", "get-content", "select-string", "get-childitem", "test", "command", "file", "diff"}
SEGMENT = re.compile(r"&&|\|\||[;|]")
WRAPPER = re.compile(r"^\s*(\S*(bash|sh|zsh)\s+-l?c\s+)?['\"]?\s*")
REDIRECT = re.compile(r"(?<!>)>>?(?![&=])\s*([^\s|;&)'\"]+)")
OTHER_WRITE = re.compile(
    r"\bsed\b[^|;&]*\s(-[A-Za-z]*i[A-Za-z]*|--in-place)(\s|=|$)|\btee\b|\b(Set|Add)-Content\b|\bOut-File\b|\bNew-Item\b"
    r"|\bapply_patch\b|\bgit\s+(apply|restore)\b|\bgit\s+checkout\s+(\S+\s+)?--\s|(^|[;&|(]\s*)patch\b|\b(cp|mv)\s"
    r"|\bperl\s+-[A-Za-z]*i|\.write\(|\bwrite_text\b|\bwrite_bytes\b|\bopen\([^)]*['\"][wax]|\bdd\s[^|;]*\bof=|\btruncate\b"
    r"|\brsync\b|\bsponge\b|\bcurl\s[^|;]*\s-o\b")
PATH_LIKE = re.compile(r"[A-Za-z0-9_$~./\\:-]*[A-Za-z0-9_]\.[A-Za-z][A-Za-z0-9]*")
TEST_NAME = re.compile(r"^(test_.*|.*_test\.\w+|.*\.(test|spec)\.\w+|.*Tests?\.\w+|conftest\.py)$")
TEST_DIRS = {"test", "tests", "__tests__", "spec", "specs"}
ABS = re.compile(r"^(/|[A-Za-z]:/)")


def norm(path):
    return path.strip().strip("'\"").replace("\\", "/")


def is_test_run(cmd):
    """True when a segment of the command runs a test runner (not a grep, cat or git that only names one)."""
    for seg in SEGMENT.split(cmd):
        if not TEST_CMD.search(seg):
            continue
        words = WRAPPER.sub("", seg, count=1).split()
        if words and posixpath.basename(words[0].strip("'\"")).lower() not in NOT_A_RUN:
            return True
    return False


def ignored(path):
    p = norm(path)
    return p in ("/dev/null", "$null", "NUL", "nul") or p.endswith(".log")


def is_source(path):
    """True when editing this path (relative to the project) is a source edit: not a test, a backlog or a generated file."""
    p = norm(path)
    if ignored(p):
        return False
    parts = [x for x in p.split("/") if x]
    if not parts:
        return True
    if parts[-1] in ("TODO.md", "CHANGELOG.md") or "/docs/plans/" in "/" + p:
        return False
    if any(x.lower() in TEST_DIRS for x in parts[:-1]) or TEST_NAME.match(parts[-1]):
        return False
    return ".git" not in parts


def shell_writes(cmd):
    """The paths a shell command writes to ([] when it writes nothing); [""] when it writes to an unknown target."""
    targets = [m.group(1) for m in REDIRECT.finditer(cmd)]
    if OTHER_WRITE.search(cmd):
        targets += PATH_LIKE.findall(cmd) or [""]
    return targets


class Log:
    """Events in the order the tools were called: ["edit", path] and ["run", is_test, failed, command]."""

    def __init__(self):
        self.events = []
        self.pending = {}
        self.cwd = ""
        self.seen_edits = set()

    def edit(self, path, key=None):
        if (key, path) in self.seen_edits and key is not None:
            return
        self.seen_edits.add((key, path))
        self.events.append(["edit", path or ""])

    def shell(self, key, cmd):
        run = ["run", is_test_run(cmd), False, cmd]
        for t in shell_writes(cmd):
            self.events.append(["edit", t])
        self.events.append(run)
        if key is not None:
            self.pending[key] = run

    def result(self, key, failed):
        run = self.pending.get(key)
        if run is not None:
            run[2] = bool(failed)

    def source_events(self):
        """The events with only the source edits left. A path is judged below the project root: the log's cwd when it has
        one, else the folder that all absolute edit paths share, so a workspace that lives under a tests/ folder is not
        mistaken for a test path. An absolute path outside that root is judged by its file name alone."""
        paths = [norm(e[1]) for e in self.events if e[0] == "edit" and ABS.match(norm(e[1])) and not ignored(e[1])]
        root = norm(self.cwd).rstrip("/")
        if not root and paths:
            try:
                root = posixpath.commonpath([posixpath.dirname(p) for p in paths])
            except ValueError:
                root = ""
        out = []
        for e in self.events:
            if e[0] != "edit":
                out.append(e)
                continue
            p = norm(e[1])
            if ignored(p):
                continue
            if ABS.match(p):
                if root and p.lower().startswith(root.lower().rstrip("/") + "/"):
                    p = p[len(root.rstrip("/")) + 1:]
                else:
                    p = posixpath.basename(p)
            if is_source(p):
                out.append(["edit", e[1] or "(a shell write to an unknown target)"])
        return out


def parse_pi(objs, log):
    for d in objs:
        if d.get("type") == "session":
            log.cwd = str(d.get("cwd") or "")
        m = d.get("message") or {}
        if d.get("type") != "message":
            continue
        if m.get("role") == "assistant" and isinstance(m.get("content"), list):
            for p in m["content"]:
                if p.get("type") != "toolCall":
                    continue
                name, args = str(p.get("name", "")).lower(), p.get("arguments") or {}
                if name in EDIT_TOOLS:
                    log.edit(args.get("path") or args.get("file_path") or "")
                elif name in SHELL_TOOLS:
                    log.shell(p.get("id"), str(args.get("command", "")))
        elif m.get("role") == "toolResult":
            text = " ".join(str(c.get("text", "")) for c in m.get("content") or [] if isinstance(c, dict))
            failed = m.get("isError") is True or re.search(r"exited with code [1-9]", text)
            log.result(m.get("toolCallId"), failed)


def parse_claude(objs, log):
    for d in objs:
        if d.get("type") == "system" and d.get("cwd"):
            log.cwd = str(d["cwd"])
        content = (d.get("message") or {}).get("content")
        if not isinstance(content, list):
            continue
        for p in content:
            if not isinstance(p, dict):
                continue
            if d.get("type") == "assistant" and p.get("type") == "tool_use":
                name, inp = str(p.get("name", "")).lower(), p.get("input") or {}
                if name in EDIT_TOOLS:
                    log.edit(inp.get("file_path") or inp.get("notebook_path") or inp.get("path") or "")
                elif name in SHELL_TOOLS:
                    log.shell(p.get("id"), str(inp.get("command", "")))
            elif d.get("type") == "user" and p.get("type") == "tool_result":
                text = p.get("content")
                text = text if isinstance(text, str) else json.dumps(text)
                log.result(p.get("tool_use_id"), p.get("is_error") is True or re.match(r"Exit code [1-9]", text))


def parse_codex(objs, log):
    seen = set()
    for d in objs:
        it = d.get("item") or {}
        kind, key = it.get("type"), it.get("id")
        if kind == "file_change":
            for c in it.get("changes") or []:
                log.edit(c.get("path", ""), key)
        elif kind == "command_execution":
            if key not in seen:
                seen.add(key)
                log.shell(key, str(it.get("command", "")))
            code = it.get("exit_code")
            if d.get("type") == "item.completed" and code is not None:
                log.result(key, code != 0)


def detect(objs):
    for d in objs[:8]:
        t = d.get("type", "")
        if t == "session" or d.get("version") == 3:
            return parse_pi
        if t == "thread.started" or t.startswith(("item.", "turn.")):
            return parse_codex
        if t in ("system", "assistant", "user", "result"):
            return parse_claude
    return None


def main(path):
    objs = []
    with open(path, encoding="utf-8-sig", errors="replace") as f:
        for line in f:
            try:
                d = json.loads(line)
            except ValueError:
                continue
            if isinstance(d, dict):
                objs.append(d)
    parse = detect(objs)
    if parse is None:
        print("ERROR: unrecognized log format (pi session, Claude Code stream-json and Codex exec --json are read)")
        return 2
    log = Log()
    parse(objs, log)
    events = log.source_events()
    first = next((i for i, e in enumerate(events) if e[0] == "edit"), None)
    if first is None:
        print("N/A: no source edit in the log, so there is no order to score")
        return 0
    edited = events[first][1]
    before = [e for e in events[:first] if e[0] == "run" and e[1]]
    if any(e[2] for e in before):
        print("PASS: a test run failed before the first source edit (%s)" % edited)
        return 0
    if before:
        why = "test runs came before it but none failed, so there was no red run"
    elif any(e[0] == "run" and e[1] and e[2] for e in events[first:]):
        why = "the first failing test run came after it"
    else:
        why = "no failing test run came before it"
    print("FAIL: source edited (%s) before a red run: %s" % (edited, why))
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
