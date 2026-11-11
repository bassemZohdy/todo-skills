#!/usr/bin/env bash
# todo-lint.sh - deterministic, read-only check of the todo invariants I1-I10.
# Usage: bash todo-lint.sh [--progress] [TODO.md] [CHANGELOG.md]     (run from the repository root)
# --progress also prints one read-only line (FEAT-042), whatever the lint result, without changing the exit code:
#   Progress: [<10 cells>] <done>/<total> leaves · <n> active · <n> blocked · <n> roots open · <n> drained in [Unreleased]
#   Leaves are tasks without children. Done = [x] leaves plus the leaves of roots drained into ## [Unreleased] (an entry's
#   Includes: IDs that are no other included ID's parent, or the entry itself without Includes:). Cells: # for done
#   (rounded down), ! for blocked leaves (rounded, at least 1 when any is blocked), - for the rest.
# Needs only bash, awk, grep, sed and tr. Prints one "FAIL I<n>: ..." line per violation.
# Prints WARN lines (W1 presence-only check, W2 name-filtered tests, W3 unfamiliar runner, W4 piped test runner, W5 no negative case on a high or security node, W6 a command that may download and run remote code) that never change the exit code.
# Exit codes: 0 all invariants hold, 1 violations found, 2 TODO.md not found.
progress=0
if [ "${1:-}" = "--progress" ]; then progress=1; shift; fi
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
function isrunner(norm) { return norm ~ /^(npm|pnpm|yarn|bun|bunx|npx|node|deno|tsc|eslint|prettier|vitest|jest|mocha|python|python3|pytest|uv|uvx|tox|nox|ruff|mypy|pylint|flake8|black|go|golangci-lint|cargo|mvn|mvnw|gradle|gradlew|dotnet|make|cmake|ctest|ninja|bundle|rake|rspec|rubocop|ruby|php|composer|phpunit|swift|xcodebuild|bash|sh|zsh|shellcheck|markdownlint|yamllint|hadolint|tflint|ansible-lint|grep|egrep|fgrep|cat|ls|test|wc|head|tail|find|stat)$/ }
# FIX-065: a chain is vetted segment by segment. Quoted text is dropped first, then the text is split at && || ; | and &.
# Every segment after the first needs a known runner (W3; a few harmless helpers are allowed there), and a redirect to a
# path outside the repository (absolute, ~, $HOME or ..) is refused (I10); /dev/null, /dev/stdout and /dev/stderr are fine.
function chain(c, lab,   t, n, a, k, w, wi, norm, seg) {
  t = c
  gsub(/"[^"]*"/, "", t); gsub(/\047[^\047]*\047/, "", t)
  gsub(/[0-9]*>&[0-9-]*|&>>?/, "", t)
  gsub(/>>? *\/dev\/(null|stdout|stderr)/, "", t)
  if (t ~ />>? *(~|\$HOME|\/|\.\.)/) fail("I10", "line " NR ": " lab ": output redirected outside the repository in Done when: " c)
  gsub(/&&|\|\||[;|&]/, "\n", t)
  n = split(t, a, "\n")
  for (k = 2; k <= n; k++) {
    seg = a[k]; gsub(/^[ \t(]+/, "", seg)
    if (k == 2 && trim(a[1]) ~ /^cd( |$)/) continue
    split(seg, w, " "); wi = 1
    while (w[wi] ~ /^[A-Za-z_][A-Za-z0-9_]*=/ && length(w[wi + 1]) > 0) wi++
    norm = w[wi]
    if (norm == "") continue
    sub(/^(\.\/)?(\.venv|venv|env)\/bin\//, "", norm); sub(/^(\.\/)?node_modules\/\.bin\//, "", norm)
    if (norm == "./gradlew" || norm == "./mvnw") sub(/^\.\//, "", norm)
    if (!isrunner(norm) && norm !~ /^(cd|echo|printf|export|set|sleep|tee|sort|uniq|sed|awk|cut|tr|xargs)$/) {
      warn("W3", "line " NR ": " lab ": Done when runs " norm " after a chain operator, which is not a known test, lint, typecheck or build runner; confirm it only tests or builds")
      break
    }
  }
}
function checkcmds(i, s, lab,   p, q, c, n, first, w, pres, filt, wi, norm) {
  n = 0; pres = 0; filt = 0
  while ((p = index(s, "`")) > 0) {
    s = substr(s, p + 1)
    q = index(s, "`")
    if (q == 0) break
    c = trim(substr(s, 1, q - 1))
    s = substr(s, q + 1)
    n++
    chain(c, lab)
    split(c, w, " ")
    first = w[1]
    if (first !~ /^[A-Za-z0-9_.\/~=-]+$/ || c ~ /^[A-Za-z_][A-Za-z0-9_.]*[(]/)
      fail("I3", "line " NR ": " lab ": backticks must hold a runnable shell command, not code or prose: " c)
    if (c ~ /^(true|:|echo( .*)?|ls( .*)?|manual|n\/a|exit 0)$/) fail("I3", "line " NR ": " lab ": vacuous command in Done when: " c)
    if (c ~ /(^|[^A-Za-z])sudo([^A-Za-z]|$)/ || c ~ /(^|[ ;&|(])(\/[^ ]*\/)?rm +-[A-Za-z]*[rRfF]/ || c ~ /(^|[ ;&|(])(\/[^ ]*\/)?rm +.*--(recursive|force)/ || c ~ /(curl|wget)[^|]*[|] *(sudo +)?(sh|bash|zsh|dash|python[0-9.]*|perl|ruby)/ || c ~ /(curl|wget)[^;&]*[|][^;&]*[|] *(sudo +)?(sh|bash|zsh|dash|python[0-9.]*|perl|ruby)/ || c ~ /<\( *(curl|wget)/ || c ~ /(^|[ ;&|(])(ba|z|da)?sh +<\(/ || c ~ /(^|[ ;&|(])(source|\.) +<\(/ || c ~ /(wget|curl +[^|;&]*(-[A-Za-z]*[oO]|--output|--remote-name))[^|]*(&&|;) *(sudo +)?(sh|bash|zsh|dash|source|\.\/)/ || c ~ /git( +-[cC] +[^ ]+)* +push/ || c ~ /git +reset +--hard/ || c ~ /git +clean( |$)/ || c ~ /(^|[;&|] *)(eval|exec)( |$)/ || c ~ /(^|[ ;&|])(ba|z)?sh +-[a-z]*c/ || c ~ /python[0-9.]*( +-[A-Za-z]+)* +-[A-Za-z]*c( |$)/ || c ~ /-exec(dir)? +rm( |$)/ || c ~ /(ruby|perl) +-e/ || c ~ /php +-r/ || c ~ /node +(-[a-z]*[ep]( |$)|--eval|--print)/ || c ~ /chmod +-R/ || c ~ /(^|[ ;&|])mkfs([. ]|$)/ || c ~ /dd +if=/ || c ~ /git +-C +[^ ]+ +push/ || c ~ /(^| )-delete( |$)/ || c ~ /(npm|yarn|pnpm|cargo|poetry|gem) +(npm +)?(publish|push)/ || c ~ /twine +upload/ || c ~ /(docker|podman) +push/ || c ~ /nuget +push/ || c ~ /mvnw? .*deploy( |$)/ || c ~ /[.]ssh\/|id_rsa|[.]aws\/credentials/)
      fail("I10", "line " NR ": " lab ": forbidden command in Done when: " c)
    if (c ~ /(\|\| *(true|:|exit +0)|;[ ]*(true|:|exit +0)[ ]*$|&& *(true|:)[ ]*$)/) fail("I3", "line " NR ": " lab ": the command masks failures (|| true, ; true, ; exit 0): " c)
    if (c ~ /(unittest|pytest|jest|vitest|go test|cargo test|rspec|mocha|dotnet test|(npm|yarn|pnpm|bun)( run)? test|bash tests?\/|make (test|check))[^|]*[|][^|]/ && c !~ /\|\|/) warn("W4", "line " NR ": " lab ": a test runner piped into another command hides its exit status unless pipefail is set; run the runner alone: " c)
    if (c ~ /(^|[ ;&|(])npx +([^;&|]* )?(--yes|-y)( |$)/ || c ~ /(pnpm|yarn) +dlx( |$)/ || c ~ /(^|[ ;&|(])(bunx|uvx)( |$)/ || c ~ /deno +run +[^;&|]*https?:\/\// || c ~ /go +run +[^ ]+@[^ ]+/ || c ~ /(^|[ ;&|(])pip3? +install( |$)/ || c ~ /-m +pip +install( |$)/ || c ~ /(^|[ ;&|(])npm +(install|i|add)( |$)/)
      warn("W6", "line " NR ": " lab ": Done when may download and run code from the network; use a package already in the lockfile (npx --no-install) and install dependencies before the task: " c)
    runner = first
    if (c ~ /^cd +[^ ;&|]+ *&& */) { sub(/^cd +[^ ;&|]+ *&& */, "", c); split(c, w, " "); first = w[1]; runner = first
      if (c ~ /^(true|:|echo( .*)?|ls( .*)?|exit 0)$/) fail("I3", "line " NR ": " lab ": vacuous command in Done when: " c) }
    wi = 1
    while (w[wi] ~ /^[A-Za-z_][A-Za-z0-9_]*=/ && length(w[wi + 1]) > 0) wi++
    runner = w[wi]; norm = runner
    sub(/^(\.\/)?(\.venv|venv|env)\/bin\//, "", norm)
    sub(/^(\.\/)?node_modules\/\.bin\//, "", norm)
    if (norm == "./gradlew" || norm == "./mvnw") sub(/^\.\//, "", norm)
    if (!isrunner(norm))
      warn("W3", "line " NR ": " lab ": Done when runs " runner ", which is not a known test, lint, typecheck or build runner; confirm it only tests or builds")
    if (norm ~ /^(grep|egrep|fgrep|cat|ls|test|wc|head|tail|find|stat)$/) pres++
    if (c ~ /(unittest|pytest|jest|vitest|go test|cargo test|mvn|gradle|rspec|dotnet test|mocha|(npm|yarn|pnpm|bun)( run)? test)/ && (c ~ /(^| )-k[ =]/ || c ~ /-run[ =]/ || c ~ /--filter/ || c ~ /--testNamePattern/ || c ~ /(^| )-t /)) filt++
  }
  if (n == 0) fail("I3", "line " NR ": " lab ": Done when has no backticked command")
  if (n > 0 && pres == n) warn("W1", "line " NR ": " lab ": Done when only checks that text or files exist; add a command that runs the behavior")
  if (filt > 0) warn("W2", "line " NR ": " lab ": Done when selects tests by name filter; some runners exit 0 when nothing matches, so target a test id or path that errors when missing")
}
# W5 (a heuristic, FEAT-060): an open high-complexity node, or one whose title names a security subject, whose criteria
# (the text before the first command) name no negative case. Known false positives: "author" and "tokenizer" match.
function checkneg(i, s, lab,   p) {
  if (nmark[i] == "x") return
  if (ncx[i] != "high" && ntitle[i] !~ /(^|[^a-z])(auth|login|password|passwd|token|secret|credential|permission|session)|crypt/) return
  p = index(s, "`"); if (p > 0) s = substr(s, 1, p - 1)
  if (tolower(s) ~ /reject|den(y|ies|ied)|fail|refus|rais|unauthori[sz]ed|invalid/) return
  warn("W5", "line " NR ": " lab ": the Done when of a high or security node names no negative case (rejects, denies, fails, refuses, raises, unauthorized, invalid); add one as a criterion or a child node")
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
    pri = parts[2]; sz = parts[3]; ts = 4   # sz: the complexity token
    if (pri !~ /^P[0-2]$/) fail("I3", "line " NR ": " id ": root task needs a priority P0, P1 or P2")
  } else {
    sz = parts[2]; ts = 3
    if (sz ~ /^P[0-2]$/) { fail("I3", "line " NR ": " id ": priority is allowed on root tasks only"); sz = parts[3]; ts = 4 }
  }
  size = ""   # optional size token right after the complexity
  if (np > ts && parts[ts] ~ /^(S|M|L|XL)$/) { size = parts[ts]; ts++ }
  title = ""
  for (k = ts; k <= np; k++) title = title (k > ts ? " · " : "") parts[k]
  if (trim(title) == "") fail("I3", "line " NR ": " id ": empty title")
  if (sz == "S" || sz == "M" || sz == "L" || sz == "XL") fail("I3", "line " NR ": " id ": the complexity (low, mid or high) comes first and the size is optional after it; run /todo-init to migrate (found: " sz ")")
  else if (sz != "low" && sz != "mid" && sz != "high") fail("I3", "line " NR ": " id ": complexity must be low, mid or high (found: " sz ")")
  nn++
  nid[nn] = id; nmark[nn] = mk; nsz[nn] = size; nlvl[nn] = lvl; nline[nn] = NR; nlines[nn] = 1
  ncx[nn] = sz; ntitle[nn] = tolower(title)
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
    if (npar[par]) kidk[npar[par]] = 1
    if (mk != "x") nopen[par]++
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
  if (key == "Done when") { ndw[cur] = 1; checkcmds(cur, val, id); checkneg(cur, val, id) }
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
      if (kw == "attempts" || kw == "baseline" || kw == "tier" || kw == "branch" || kw == "hyp" || kw == "files" || kw == "docs" || kw == "next")
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
  for (i = 1; i <= nn; i++) if (ndec[i] && npar[i]) { kidk[npar[i]] = 1; ndecp[npar[i]] = 1 }   # a node waiting to be decomposed counts as a parent
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
    if (nsz[i] != "") {   # an optional size must match the tree
      if (nkid[i] > 0 || ndecp[i]) {
        want = kidk[i] ? "XL" : "L"
        if (nsz[i] != want) fail("I8", "line " nline[i] ": " id ": size " nsz[i] " but its children imply " want)
      } else if ((nsz[i] == "L" || nsz[i] == "XL") && !ndec[i]) fail("I8", "line " nline[i] ": " id ": leaf size must be S or M (or L/XL with State next: decompose), found " nsz[i])
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
if [ "$progress" -eq 1 ]; then
  tree="$(awk '{ sub(/\r$/, "") }
    /^ *- \[.\] \*\*[A-Z]+-[0-9]+(\.[0-9]+)*\*\*/ { match($0, /^ */); n++; lv[n] = RLENGTH / 2; mk[n] = substr($0, RLENGTH + 4, 1) }
    END { for (i = 1; i <= n; i++) { if (lv[i] == 0) r++; if (mk[i] == "/") a++
            if (i == n || lv[i + 1] <= lv[i]) { l++; if (mk[i] == "x") d++; if (mk[i] == "!") b++ } }
          print l + 0, d + 0, b + 0, a + 0, r + 0 }' "$todo")"
  drained="0 0"
  if [ -f "$changelog" ]; then
    drained="$(awk '{ sub(/\r$/, "") }
      /^## \[Unreleased\]/ { on = 1; next }
      /^## / { on = 0 }
      on && /^- \*\*[A-Z]+-[0-9]+(\.[0-9]+)*\*\*/ {
        r++; n = 0; p = index($0, "Includes:")
        if (p > 0) { s = substr($0, p + 9); while (match(s, /[A-Z]+-[0-9]+(\.[0-9]+)*/)) { ids[++n] = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH) } }
        if (n == 0) l++
        for (i = 1; i <= n; i++) { par = 0; for (j = 1; j <= n; j++) if (j != i && index(ids[j], ids[i] ".") == 1) par = 1; if (!par) l++ }
      }
      END { print r + 0, l + 0 }' "$changelog")"
  fi
  awk -v t="$tree" -v u="$drained" 'BEGIN {
    split(t, a, " "); split(u, c, " ")
    total = a[1] + c[2]; done = a[2] + c[2]; blocked = a[3]; nd = 0; nb = 0
    if (total > 0) { nd = int(10 * done / total); nb = int(10 * blocked / total + 0.5); if (blocked > 0 && nb < 1) nb = 1; if (nb > 10 - nd) nb = 10 - nd }
    bar = ""; for (i = 0; i < nd; i++) bar = bar "#"; for (i = 0; i < nb; i++) bar = bar "!"; while (length(bar) < 10) bar = bar "-"
    printf "Progress: [%s] %d/%d leaves · %d active · %d blocked · %d roots open · %d drained in [Unreleased]\n", bar, done, total, a[4], blocked, a[5], c[1] }'
fi
exit "$rc"
