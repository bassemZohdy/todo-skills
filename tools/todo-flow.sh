#!/usr/bin/env bash
# Optional helper for /todo-continue: one call makes the git and backlog commits of one lifecycle step, exactly as the
# skills prescribe them. It decides nothing: the agent selects the node, checks the tree, runs the tests and writes the
# commit subject. Anything but the plain case is refused before a file changes (exit 2: do the step by hand); a git step
# that fails stops it there (exit 1) in the state the skills recover from. Every run prints the commits it made.
# Usage, from the root of the main checkout, on the branch the skills name for the step:
#   bash .todo/todo-flow.sh start <ID> <n> | none | red: <ids>
#       the baseline is the argument. Unclaimed tree (run on the base): tree claim, fast-forward of the base. Then the
#       missing branches down to the node, [/] with its State, and the start commit.
# TODO_BASE names the base branch when it is not the README "Base:" line or one of main, master, trunk, develop.
# Needs bash, git, awk, sed and grep. No network, no tag, no push, no forced delete. --version prints the release.
todo_skills_version="0.5.1"
if [ "${1:-}" = "--version" ]; then echo "todo-flow.sh $todo_skills_version"; exit 0; fi
set -u
refuse() { echo "todo-flow: refused, nothing changed: $*" >&2; exit 2; }
stop() { echo "todo-flow: stopped: $*" >&2; exit 1; }

# T <ID> <op> [marker] [state]: reads or rewrites one node of the TODO.md text on stdin (no carriage returns). Ops: marker, title, state, done, links, kids
# (descendants as "ID marker"), set (new marker and State; "" keeps, a State of "-" deletes it), drop (removes the subtree).
T() {
  MK="${3-}" ST="${4-}" LC_ALL=C awk -v id="$1" -v op="$2" '
    function head(s,   r, t, e) {
      H_n = match(s, /[^ ]/) - 1; r = substr(s, H_n + 1)
      if (substr(r, 1, 3) != "- [" || substr(r, 5, 4) != "] **") return 0
      t = substr(r, 9); e = index(t, "**"); if (!e) return 0
      H_m = substr(r, 4, 1); H_id = substr(t, 1, e - 1); H_rest = substr(t, e + 2); return 1
    }
    function title(s,   a, k, i, o) {
      k = split(s, a, " · "); i = 2
      if (a[i] ~ /^P[0-2]$/) i++
      i++
      if (i < k && a[i] ~ /^(S|M|L|XL)$/) i++
      o = a[i]; while (++i <= k) o = o " · " a[i]
      return o
    }
    function out(s) {
      if (!w) return
      if (s == "") { blank++; return }
      if (gap && blank > 1) blank = 1
      gap = 0; while (blank > 0) { print ""; blank-- }
      print s
    }
    function endfields() { if (at == 1 && op == "set" && st != "" && st != "-" && !wrote) { out(sprintf("%" (n + 2) "s- State: %s", "", st)); wrote = 1 } }
    BEGIN { mk = ENVIRON["MK"]; st = ENVIRON["ST"]; w = (op == "set" || op == "drop") }
    {
      h = head($0)
      if (at == 0 && h && H_id == id) {
        at = 1; n = H_n
        if (op == "marker") print H_m
        if (op == "title") print title(H_rest)
        if (op == "set" && mk != "") $0 = substr($0, 1, n + 3) mk substr($0, n + 5)
        if (op == "drop") { gap = 1; next }
        out($0); next
      }
      if (at == 1 || at == 2) {
        if ($0 == "" || match($0, /[^ ]/) - 1 <= n) { endfields(); at = 3 }
        else if (h) { endfields(); at = 2; if (op == "kids") print H_id, H_m }
        else if (at == 1) {
          f = substr($0, n + 5)
          if (op == "state" && f ~ /^State: /) print substr(f, 8)
          if (op == "done" && f ~ /^Done when: /) print substr(f, 12)
          if (op == "links" && f ~ /^Links: /) print substr(f, 8)
          if (op == "set" && st != "" && f ~ /^State: /) { wrote = 1; if (st == "-") next; $0 = substr($0, 1, n + 4) "State: " st }
        }
        if (op == "drop" && at < 3) next
      }
      out($0)
    }
    END { endfields(); if (op != "drop") while (blank-- > 0) print "" }'
}
Q() { tr -d '\r' < TODO.md | T "$@"; }
# refile <file> <filter...>: rewrites the file through the filter; a CRLF file is filtered without them and gets them back.
refile() {
  local f="$1" cr; shift; cr="$(head -1 "$f" | tr -cd '\r' | wc -c)"
  tr -d '\r' < "$f" | "$@" > "$f.flow" || stop "could not rewrite $f"
  if [ "$cr" -gt 0 ]; then awk '{ printf "%s\r\n", $0 }' "$f.flow" > "$f" && rm -f "$f.flow"; else mv "$f.flow" "$f"; fi
}
edit() { refile TODO.md T "$@"; }
slug() {
  Q "$1" title | LC_ALL=C awk '{ s = tolower($0); gsub(/[^a-z0-9]+/, " ", s); k = split(s, a, " "); o = ""; c = 0
    for (i = 1; i <= k && c < 4; i++) if (a[i] !~ /^(a|an|the|to|of|and|for|with)$/) o = o (c++ ? "-" : "") a[i]
    print (o == "" ? "task" : o) }'
}
has() { git show-ref -q --verify "refs/heads/$1"; }
# Changed backlog files (core "Backlog files"): README.md only while its diff adds nothing but Tests: and Base: lines.
backlog() {
  local f d
  for f in TODO.md CHANGELOG.md docs/plans/PROJECT.md docs/plans/"$root"-*.md; do
    [ -e "$f" ] && [ -n "$(git status --porcelain -- "$f")" ] && printf '%s\n' "$f"
  done
  d="$(git diff HEAD -U0 -- README.md 2>/dev/null | tr -d '\r' | grep '^[+-]' | grep -vE '^(\+\+\+|---)')"
  [ -z "$d" ] || printf '%s\n' "$d" | grep -qvE '^\+((Tests|Base):.*)?$' || echo README.md
}
# commit <subject> <body> [path...]: lints, then commits the paths and the changed backlog files by explicit path.
commit() {
  local subj="$1" body="$2" f p=(); shift 2
  for f in "$@"; do p+=("$f"); done
  while IFS= read -r f; do [ -z "$f" ] || p+=("$f"); done <<EOF
$(backlog)
EOF
  [ "${#p[@]}" -gt 0 ] && [ -n "$(git status --porcelain -- "${p[@]}")" ] || return 0
  if [ -f .todo/todo-lint.sh ] && ! f="$(bash .todo/todo-lint.sh 2>&1)"; then printf '%s\n' "$f" | grep FAIL >&2; stop "the lint fails; not committed: $subj"; fi
  git add -- "${p[@]}" && git commit -q -m "$subj" ${body:+-m "$body"} -- "${p[@]}" || stop "git could not commit: $subj"
}
report() { git log --reverse --format='%h %s' "$h0..HEAD"; echo "on $(git symbolic-ref --short HEAD)"; }

cmd="${1:-}"; id="${2:-}"; [ $# -ge 2 ] && shift 2
[ "$(git rev-parse --git-dir 2>/dev/null)" = ".git" ] || refuse "run it from the root of the main checkout of a git repository"
[ -f TODO.md ] && [ -n "$id" ] && m="$(Q "$id" marker)" && [ -n "$m" ] || refuse "no task $id in TODO.md"
root="${id%%.*}"; h0="$(git rev-parse HEAD)"; cur="$(git symbolic-ref -q --short HEAD)" || refuse "no branch is checked out"
base="${TODO_BASE:-$(sed -nE 's/^.*Base: *[^A-Za-z0-9]?([A-Za-z0-9._/-]+).*$/\1/p' README.md 2>/dev/null | head -1)}"
for b in main master trunk develop; do [ -n "$base" ] || ! has "$b" || base="$b"; done
[ -n "$base" ] && has "$base" || refuse "no base branch found; set TODO_BASE"
branch_of() { sed -nE 's/^(.*; )?branch (todo\/[^ ;]+) from .*$/\2/p'; }
[ ! -f .todo/todo-lint.sh ] || bash .todo/todo-lint.sh >/dev/null 2>&1 || refuse "the lint fails: run bash .todo/todo-lint.sh and fix that first"

case "$cmd" in
start)
  bl="$*"; bl="${bl% passing}"
  case "$bl" in none|red:\ ?*) ;; *[!0-9]*|"") refuse "the baseline must be <n>, none or red: <ids>" ;; *) bl="$bl passing" ;; esac
  [ "$m" = " " ] || refuse "$id is not an open [ ] task"
  grep -q '^ *- \[/\] \*\*' TODO.md && refuse "another task is active [/]"
  Q "$id" kids | grep -qv ' x$' && refuse "$id has open children"
  claimed="$(git show "$base:TODO.md" 2>/dev/null | tr -d '\r' | T "$root" state | branch_of)"
  if [ -z "$claimed" ]; then
    [ "$cur" = "$base" ] || refuse "an unclaimed tree starts from $base, and $cur is checked out"
    [ -z "$(git branch --list "todo/$root-*" "todo/$root.*")" ] || refuse "a todo/$root branch exists: read reference/git-flow-edge.md, Existing root branch"
    rb="todo/$root-$(slug "$root")"
    git switch -q -c "$rb" || stop "could not create $rb"
    if [ -n "$(Q "$root" kids)" ]; then edit "$root" set "" "branch $rb from $base; next: build children"; else edit "$root" set "" "branch $rb from $base; next: start $root"; fi
    commit "chore(backlog): claim $root on $rb" ""
    git switch -q "$base" && git merge -q --ff-only "$rb" || stop "the fast-forward of $base failed; $base is checked out: read reference/git-flow-edge.md, Failed fast-forward"
  else
    rb="$claimed"
    case "$cur" in "$rb"|"todo/$root."*) ;; *) refuse "$root is claimed by $rb; run this on a branch of that tree" ;; esac
    has "$rb" || refuse "the claimed branch $rb does not exist here"
  fi
  git switch -q "$rb" || stop "could not switch to $rb"
  prev="$rb"; from="$base"; x="$root"; rest="${id#"$root"}"
  while [ -n "$rest" ]; do
    rest="${rest#.}"; x="$x.${rest%%.*}"; rest="${rest#"${rest%%.*}"}"
    nb="$(git branch --list "todo/$x-*" --format='%(refname:short)' | head -1)"
    if [ -n "$nb" ]; then git switch -q "$nb" || stop "could not switch to $nb"
    else
      nb="todo/$x-$(slug "$x")"; git switch -q -c "$nb" || stop "could not create $nb"
      [ "$x" = "$id" ] || edit "$x" set "" "branch $nb from $prev; next: build children"
    fi
    from="$prev"; prev="$nb"
  done
  edit "$id" set / "attempts 0/3; baseline $bl; branch $prev from $from; next: read docs"
  commit "chore(backlog): start $id" ""
  report; echo "State: $(Q "$id" state)" ;;
*) refuse "unknown command '$cmd' (start)" ;;
esac
