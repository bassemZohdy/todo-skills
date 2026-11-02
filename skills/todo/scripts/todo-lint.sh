#!/usr/bin/env bash
# todo-lint.sh - deterministic, read-only check of the todo invariants I1-I10.
# Usage: bash todo-lint.sh [TODO.md] [CHANGELOG.md]     (run from the repository root)
# Needs only bash, awk, grep, sed and tr. Prints one "FAIL I<n>: ..." line per violation.
# Prints WARN lines (W1 presence-only check, W2 name-filtered tests, W3 unfamiliar runner) that never change the exit code.
# Exit codes: 0 all invariants hold, 1 violations found, 2 TODO.md not found.
todo="${1:-TODO.md}"
changelog="${2:-CHANGELOG.md}"

if [ ! -f "$todo" ]; then
  echo "FAIL: $todo not found"
  exit 2
fi

# IDs already archived: the leading **ID** of each entry plus every ID after "Includes:".
cl=" "
if [ -f "$changelog" ]; then
  cl=" $( { grep -oE '^- \*\*[A-Z]+-[0-9]+(\.[0-9]+)*\*\*' "$changelog" | grep -oE '[A-Z]+-[0-9]+(\.[0-9]+)*'
            grep -E 'Includes:' "$changelog" | sed 's/.*Includes://' | grep -oE '[A-Z]+-[0-9]+(\.[0-9]+)*'
          } | tr '\n' ' ') "
fi

awk -v cl="$cl" '
function fail(code, msg) { print "FAIL " code ": " msg; bad++ }
function trim(s) { gsub(/^ +/, "", s); gsub(/ +$/, "", s); return s }
function dfs(u,   k, n, a, v) {
  color[u] = 1
  n = split(adj[u], a, " ")
  for (k = 1; k <= n; k++) {
    v = a[k]
    if (color[v] == 1) { cyc = u " -> " v; return }
    if (color[v] == 0) { dfs(v); if (cyc != "") return }
  }
  color[u] = 2
}
# Record every ID found in text s into list variable named by kind (D = depends, F = from).
function addrefs(i, kind, s,   x) {
  while (match(s, /[A-Z]+-[0-9]+(\.[0-9]+)*/)) {
    x = substr(s, RSTART, RLENGTH)
    s = substr(s, RSTART + RLENGTH)
    if (kind == "D") deps[i] = deps[i] " " x
    refs[i] = refs[i] " " x
  }
}
function warn(code, msg) { print "WARN " code ": " msg; nwarn++ }
function checkcmds(i, s, lab,   p, q, c, n, first, w, pres, filt) {
  n = 0; pres = 0; filt = 0
  while ((p = index(s, "`")) > 0) {
    s = substr(s, p + 1)
    q = index(s, "`")
    if (q == 0) break
    c = trim(substr(s, 1, q - 1))
    s = substr(s, q + 1)
    n++
    split(c, w, " ")
    first = w[1]
    if (first !~ /^[A-Za-z0-9_.\/~=-]+$/ || c ~ /^[A-Za-z_][A-Za-z0-9_.]*[(]/)
      fail("I3", "line " NR ": " lab ": backticks must hold a runnable shell command, not code or prose: " c)
    if (c ~ /^(true|:|echo( .*)?|ls( .*)?|manual|n\/a|exit 0)$/) fail("I3", "line " NR ": " lab ": vacuous command in Done when: " c)
    if (c ~ /(^|[^A-Za-z])sudo([^A-Za-z]|$)/ || c ~ /(^|[ ;&|])rm +-[A-Za-z]*[rRfF]/ || c ~ /(^|[ ;&|])rm +.*--(recursive|force)/ || c ~ /(curl|wget)[^|]*[|] *(sh|bash)/ || c ~ /git +push/ || c ~ /git +reset +--hard/ || c ~ /git +clean( |$)/ || c ~ /(^|[ ;&|])(eval|exec)( |$)/ || c ~ /(^|[ ;&|])(ba|z)?sh +-c/ || c ~ /python[0-9.]* +-c/ || c ~ /node +(-e|--eval)/ || c ~ /chmod +-R/ || c ~ /(^|[ ;&|])mkfs([. ]|$)/ || c ~ /dd +if=/ || c ~ /git +-C +[^ ]+ +push/ || c ~ /(^| )-delete( |$)/ || c ~ /(npm|yarn|pnpm|cargo|poetry|gem) +(npm +)?(publish|push)/ || c ~ /twine +upload/ || c ~ /(docker|podman) +push/ || c ~ /nuget +push/ || c ~ /mvnw? .*deploy( |$)/ || c ~ /[.]ssh[/]|id_rsa|[.]aws[/]credentials/)
      fail("I10", "line " NR ": " lab ": forbidden command in Done when: " c)
    runner = first
    if (c ~ /^cd +[^ ;&|]+ *&& */) { sub(/^cd +[^ ;&|]+ *&& */, "", c); split(c, w, " "); first = w[1]; runner = first }
    if (first ~ /^[A-Za-z_][A-Za-z0-9_]*=/ && length(w[2]) > 0) runner = w[2]
    if (runner !~ /^(npm|pnpm|yarn|bun|bunx|npx|node|deno|tsc|eslint|prettier|vitest|jest|mocha|python|python3|pytest|uv|uvx|tox|nox|ruff|mypy|pylint|flake8|black|go|golangci-lint|cargo|mvn|mvnw|gradle|gradlew|dotnet|make|cmake|ctest|ninja|bundle|rake|rspec|rubocop|ruby|php|composer|phpunit|swift|xcodebuild|bash|sh|zsh|shellcheck|markdownlint|yamllint|hadolint|tflint|ansible-lint|grep|egrep|fgrep|cat|ls|test|wc|head|tail|find|stat)$/ && runner !~ /^[.][/]/ && runner !~ /[/]gradlew$/ && runner !~ /[/]mvnw$/)
      warn("W3", "line " NR ": " lab ": Done when runs " runner ", which is not a known test, lint, typecheck or build runner; confirm it only tests or builds")
    if (first ~ /^(grep|egrep|fgrep|cat|ls|test|wc|head|tail|find|stat)$/) pres++
    if (c ~ /(unittest|pytest|jest|vitest|go test|cargo test|mvn|gradle|rspec|dotnet test|mocha)/ && (c ~ /(^| )-k[ =]/ || c ~ /-run[ =]/ || c ~ /--filter/ || c ~ /--testNamePattern/ || c ~ /(^| )-t /)) filt++
  }
  if (n == 0) fail("I3", "line " NR ": " lab ": Done when has no backticked command")
  if (n > 0 && pres == n) warn("W1", "line " NR ": " lab ": Done when only checks that text or files exist; add a command that runs the behavior")
  if (filt > 0) warn("W2", "line " NR ": " lab ": Done when selects tests by name filter; some runners exit 0 when nothing matches, so target a test id or path that errors when missing")
}
BEGIN { cur = 0; prevlvl = -1; nn = 0 }
{ sub(/\r$/, "") }
/^[ \t]*$/ { next }
/^# / { h1++; if ($0 != "# Active Backlog") fail("I6", "line " NR ": first heading must be exactly: # Active Backlog"); next }
/^## / { h2++; if ($0 !~ /Task Tree$/) fail("I6", "line " NR ": section heading must end in Task Tree (found: " $0 ")"); next }
/^#+ / { fail("I6", "line " NR ": unexpected heading: " $0); next }
/^ *- \[[^]]\] / {
  if ($0 !~ /^ *- \[[^]]\] \*\*[A-Z]+-[0-9]+(\.[0-9]+)*\*\*/) { fail("I3", "line " NR ": malformed task header"); next }
  match($0, /^ */); ind = RLENGTH
  mk = substr($0, ind + 4, 1)
  match($0, /\*\*[A-Z]+-[0-9]+(\.[0-9]+)*\*\*/)
  id = substr($0, RSTART + 2, RLENGTH - 4)
  rest = substr($0, RSTART + RLENGTH)
  if (mk != " " && mk != "/" && mk != "!" && mk != "x") fail("I3", "line " NR ": " id ": invalid marker [" mk "]")
  if (ind % 2 != 0) fail("I8", "line " NR ": " id ": indent must be a multiple of 2")
  lvl = int(ind / 2)
  if (lvl > 2) fail("I8", "line " NR ": " id ": deeper than 3 levels")
  if (lvl > prevlvl + 1) fail("I8", "line " NR ": " id ": indent jumps more than one level")
  np = split(rest, parts, " · ")
  if (lvl == 0) {
    pri = parts[2]; sz = parts[3]; ts = 4
    if (pri !~ /^P[0-2]$/) fail("I3", "line " NR ": " id ": root task needs a priority P0, P1 or P2")
  } else {
    sz = parts[2]; ts = 3
    if (sz ~ /^P[0-2]$/) { fail("I3", "line " NR ": " id ": priority is allowed on root tasks only"); sz = parts[3]; ts = 4 }
  }
  title = ""
  for (k = ts; k <= np; k++) title = title (k > ts ? " · " : "") parts[k]
  if (trim(title) == "") fail("I3", "line " NR ": " id ": empty title")
  if (sz != "S" && sz != "M" && sz != "L" && sz != "XL") fail("I3", "line " NR ": " id ": size must be S, M, L or XL (found: " sz ")")
  nn++
  nid[nn] = id; nmark[nn] = mk; nsz[nn] = sz; nlvl[nn] = lvl; nline[nn] = NR; nlines[nn] = 1
  if (id in idx) fail("I2", "line " NR ": duplicate ID " id)
  else idx[id] = nn
  d = id; dots = gsub(/\./, ".", d)
  if (dots != lvl) fail("I8", "line " NR ": " id ": number of dots in the ID must equal its nesting level " lvl)
  par = 0
  if (lvl > 0 && lvl <= prevlvl + 1) par = sidx[lvl - 1]
  if (lvl > 0 && par) {
    pre = nid[par] "."
    if (substr(id, 1, length(pre)) != pre || index(substr(id, length(pre) + 1), ".") > 0)
      fail("I8", "line " NR ": " id ": not a direct child of the task above it (" nid[par] ")")
  } else if (lvl > 0) fail("I8", "line " NR ": " id ": has no parent")
  npar[nn] = par
  if (par) {
    nkid[par]++
    if (mk != "x") nopen[par]++
    if (npar[par]) kidk[npar[par]] = 1
  }
  sidx[lvl] = nn
  prevlvl = lvl
  cur = nn
  if (mk == "/") { nact++; actlist = actlist " " id }
  next
}
/^ *- (Done when|Links|State|Blocked):/ {
  if (cur == 0) { fail("I3", "line " NR ": field before any task"); next }
  match($0, /^ */); ind = RLENGTH
  key = $0; sub(/^ *- /, "", key); sub(/:.*/, "", key)
  val = $0; sub(/^ *- [^:]*: */, "", val); val = trim(val)
  id = nid[cur]
  if (ind != 2 * nlvl[cur] + 2) fail("I3", "line " NR ": " id ": field " key " must be indented " (2 * nlvl[cur] + 2) " spaces")
  nlines[cur]++
  if (seenkey[cur, key]++) fail("I3", "line " NR ": " id ": duplicate field " key)
  if (key == "Done when") { ndw[cur] = 1; checkcmds(cur, val, id) }
  else if (key == "Links") {
    m = split(val, lp, " · ")
    for (k = 1; k <= m; k++) {
      p = trim(lp[k])
      if (p ~ /^Ref:/) continue
      else if (p ~ /^Depends:/) { sub(/^Depends: */, "", p); addrefs(cur, "D", p) }
      else if (p ~ /^From:/) { sub(/^From: */, "", p); addrefs(cur, "F", p) }
      else if (p ~ /^Lane:/) {
        sub(/^Lane: */, "", p)
        if (nlvl[cur] != 0) fail("I3", "line " NR ": " id ": Lane is allowed on root tasks only")
        else if (p !~ /^[a-z][a-z0-9-]*$/) fail("I3", "line " NR ": " id ": lane name must be lowercase letters, digits and dashes (found: " p ")")
      }
      else fail("I3", "line " NR ": " id ": Links accepts only Ref, Depends, From and Lane (found: " p ")")
    }
  }
  else if (key == "State") {
    nst[cur] = 1
    m = split(val, sp, "; ")
    for (k = 1; k <= m; k++) {
      kw = trim(sp[k]); if (kw == "next: decompose") ndec[cur] = 1; sub(/[ :].*/, "", kw)
      if (kw == "attempts" || kw == "baseline" || kw == "branch" || kw == "hyp" || kw == "files" || kw == "docs" || kw == "next")
        if (seenst[cur, kw]++) fail("I3", "line " NR ": " id ": State repeats the item " kw "; a later claim must replace the State line")
    }
  }
  else if (key == "Blocked") {
    nbl[cur] = 1
    if (split(val, bp, " → ") < 3) fail("I3", "line " NR ": " id ": Blocked must read: reason → command error → action required")
  }
  next
}
{ fail("I3", "line " NR ": unexpected line (tasks allow only Done when, Links, State, Blocked): " $0) }
END {
  if (h1 != 1) fail("I6", "expected exactly one # Active Backlog heading, found " h1 + 0)
  if (h2 != 1) fail("I6", "expected exactly one ## Task Tree section, found " h2 + 0 " second-level headings")
  if (NR > 120) fail("I4", "TODO.md has " NR " lines (max 120)")
  if (nact > 1) fail("I1", "more than one active [/] task:" actlist)
  for (i = 1; i <= nn; i++) if (ndec[i] && npar[i]) kidk[npar[i]] = 1   # a node waiting to be decomposed counts as a parent
  for (i = 1; i <= nn; i++) {
    id = nid[i]
    if (nmark[i] == "/" && nopen[i] > 0) fail("I1", id ": active parent still has " nopen[i] " open child task(s); only the integration step may be active")
    if (!ndw[i]) fail("I3", "line " nline[i] ": " id ": missing Done when")
    if (nmark[i] == "!" && !nbl[i]) fail("I3", "line " nline[i] ": " id ": blocked task needs a Blocked line")
    if (nbl[i] && nmark[i] != "!") fail("I3", "line " nline[i] ": " id ": Blocked line only belongs on a [!] task")
    if (nst[i] && nbl[i]) fail("I3", "line " nline[i] ": " id ": State and Blocked are mutually exclusive")
    if (nlines[i] > 4) fail("I3", "line " nline[i] ": " id ": task has " nlines[i] " lines (max 4)")
    if (nmark[i] == "x" && nopen[i] > 0) fail("I8", "line " nline[i] ": " id ": marked done but has open children")
    if (nmark[i] == "x" && nlvl[i] == 0) fail("I8", "line " nline[i] ": " id ": root task marked done; a finished root must be drained to CHANGELOG.md")
    if (nsz[i] == "S" || nsz[i] == "M" || nsz[i] == "L" || nsz[i] == "XL") {
      if (nkid[i] > 0) {
        want = kidk[i] ? "XL" : "L"
        if (nsz[i] != want) fail("I8", "line " nline[i] ": " id ": size " nsz[i] " but its children imply " want)
      } else if ((nsz[i] == "L" || nsz[i] == "XL") && !ndec[i]) fail("I8", "line " nline[i] ": " id ": leaf task must be S or M (or L/XL with State next: decompose), found " nsz[i])
    }
    if (index(cl, " " id " ") > 0) fail("I5", id " is in both TODO.md and CHANGELOG.md")
    m = split(refs[i], r, " ")
    for (k = 1; k <= m; k++)
      if (!(r[k] in idx) && index(cl, " " r[k] " ") == 0) fail("I7", id ": " r[k] " exists in neither TODO.md nor CHANGELOG.md")
    m = split(deps[i], r, " ")
    for (k = 1; k <= m; k++) if (r[k] in idx) adj[id] = adj[id] " " r[k]
    if (npar[i]) adj[nid[npar[i]]] = adj[nid[npar[i]]] " " id
  }
  for (i = 1; i <= nn && cyc == ""; i++) if (color[nid[i]] == 0) dfs(nid[i])
  if (cyc != "") fail("I9", "dependency cycle (a parent implicitly depends on its children): " cyc)
  exit (bad > 0)
}' "$todo"
rc=$?
if [ "$rc" -eq 0 ]; then echo "OK: invariants I1-I10 hold"; fi
exit "$rc"
