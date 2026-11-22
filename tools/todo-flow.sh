#!/usr/bin/env bash
# Optional helper for /todo-continue: one call makes the git and backlog writes of one lifecycle step, as the skills prescribe
# them. It decides nothing: the agent selects the node, checks the tree, runs the tests and the review and writes the commit
# subject. Anything but the plain case is refused before a file changes (exit 2: do that step by hand); a failing git step
# stops it there (exit 1) in the state the skills recover from. Every run ends with the commits it made, the checked-out
# branch, whether the tree is clean and the todo branches left, so the result needs no recheck.
# Usage, from the root of the main checkout, on the branch the skills name for the step:
#   bash .todo/todo-flow.sh start <ID> <n> | none | red: <ids>
#       the argument is the baseline. Unclaimed tree (run on the base): tree claim, fast-forward of the base. Then the
#       missing branches down to the node, [/] with its State, and the start commit.
#   bash .todo/todo-flow.sh complete <ID> -m '<type>(<scope>): <title>' [-b '<body line>']... [-- <path>...]
#       after review and a green verify, on the node's branch: commits the paths and the changed backlog files (body "Refs: <ID>"
#       plus the -b lines: Red:, Reviewed:, Checked:). A child is set [x] and merged into its parent's branch; a root is
#       refreshed from the base (rerun the checks when it says the base brought changes).
#   bash .todo/todo-flow.sh drain <ROOT-ID> [-t <type>] [--merge]
#       after the last gate, on the root branch: the CHANGELOG entry (type: feat or fix by prefix; give -t for a TASK),
#       the subtree removed from TODO.md, the drain commit; with --merge the merge into the base, else its commands.
# TODO_BASE names the base when it is not the README "Base:" line or main, master, trunk, develop. Needs bash, git, awk, sed, grep. No network, tag, push or forced delete.
todo_skills_version="0.6.1"
if [ "${1:-}" = "--version" ]; then echo "todo-flow.sh $todo_skills_version"; exit 0; fi
set -u; nl="$(printf '\n.')"; nl="${nl%.}"
refuse() { echo "todo-flow: refused, nothing changed: $*" >&2; exit 2; }; stop() { echo "todo-flow: stopped: $*" >&2; exit 1; }
# T <ID> <op> [marker] [state]: reads or rewrites one node of the TODO.md text on stdin (no carriage returns). Ops: marker,
# title, state, done, links, kids (descendants as "ID marker"), set (a new marker and State; "" keeps, a State of "-"
# deletes it), drop (removes the subtree, leaving at most one blank line there and none at the end of the file).
T() {
  MK="${3-}" ST="${4-}" LC_ALL=C awk -v id="$1" -v op="$2" '
    function head(s,   r, t, e) {   # a task header: sets its indent, marker, ID and the text after the ID
      H_n = match(s, /[^ ]/) - 1; r = substr(s, H_n + 1); t = substr(r, 9); e = index(t, "**")
      if (substr(r, 1, 3) != "- [" || substr(r, 5, 4) != "] **" || !e) return 0
      H_m = substr(r, 4, 1); H_id = substr(t, 1, e - 1); H_rest = substr(t, e + 2); return 1
    }
    function title(s,   a, k, i, o) {   # after the ID: [P0-P2 ·] complexity [· size] · title
      k = split(s, a, " · "); i = (a[2] ~ /^P[0-2]$/) ? 4 : 3; if (i < k && a[i] ~ /^(S|M|L|XL)$/) i++
      o = a[i]; while (++i <= k) o = o " · " a[i]; return o
    }
    function out(s) {   # prints only in the writing ops
      if (!w) return; if (s == "") { blank++; return }
      if (gap && blank > 1) blank = 1; for (gap = 0; blank > 0; blank--) print ""; print s
    }
    function endfields() { if (at == 1 && op == "set" && st != "" && st != "-" && !wrote) { out(sprintf("%" (n + 2) "s- State: %s", "", st)); wrote = 1 } }
    BEGIN { mk = ENVIRON["MK"]; st = ENVIRON["ST"]; w = (op == "set" || op == "drop") }
    {
      h = head($0)
      if (at == 0 && h && H_id == id) {
        at = 1; n = H_n; if (op == "marker") print H_m; if (op == "title") print title(H_rest)
        if (op == "set" && mk != "") $0 = substr($0, 1, n + 3) mk substr($0, n + 5)
        if (op == "drop") { gap = 1; next }
      } else if (at == 1 || at == 2) {
        if ($0 == "" || match($0, /[^ ]/) - 1 <= n) { endfields(); at = 3 }
        else if (h) { endfields(); at = 2; if (op == "kids") print H_id, H_m }
        else if (at == 1) {
          f = substr($0, n + 5); if (op == "done" && f ~ /^Done when: /) print substr(f, 12)
          if ((op == "state" && f ~ /^State: /) || (op == "links" && f ~ /^Links: /)) print substr(f, 8)
          if (op == "set" && st != "" && f ~ /^State: /) { wrote = 1; if (st == "-") next; $0 = substr($0, 1, n + 4) "State: " st }
        }
        if (op == "drop" && at < 3) next
      }
      out($0)
    }
    END { endfields(); if (op != "drop") while (blank-- > 0) print "" }'
}
Q() { tr -d '\r' < TODO.md | T "$@"; }
refile() {   # <file> <filter...>: rewrites the file through the filter; a CRLF file is filtered without them and gets them back
  local f="$1" cr; shift; cr="$(head -1 "$f" | tr -cd '\r' | wc -c)"
  tr -d '\r' < "$f" | "$@" > "$f.flow" || stop "could not rewrite $f"
  if [ "$cr" -gt 0 ]; then awk '{ printf "%s\r\n", $0 }' "$f.flow" > "$f" && rm -f "$f.flow"; else mv "$f.flow" "$f"; fi
}
edit() { refile TODO.md T "$@"; }
slug() {   # git-flow: lowercase, punctuation to spaces, small words dropped, the first 4 words, "task" when none is left
  Q "$1" title | LC_ALL=C awk '{ s = tolower($0); gsub(/[^a-z0-9]+/, " ", s); k = split(s, a, " "); o = ""; c = 0
    for (i = 1; i <= k && c < 4; i++) if (a[i] !~ /^(a|an|the|to|of|and|for|with)$/) o = o (c++ ? "-" : "") a[i]
    print (o == "" ? "task" : o) }'
}
has() { git show-ref -q --verify "refs/heads/$1"; }; join() { awk '{ o = o (NR > 1 ? ", " : "") $0 } END { print o }'; }
branch_of() { sed -nE 's/^(.*; )?branch (todo\/[^ ;]+) from .*$/\2/p'; }
readme_only() {   # <diff range>: README.md changed there, and only by added Tests: and Base: lines
  local d; d="$(git diff "$1" -U0 -- README.md 2>/dev/null | tr -d '\r' | grep '^[+-]' | grep -vE '^(\+\+\+|---)')"
  [ -n "$d" ] && ! printf '%s\n' "$d" | grep -qvE '^\+((Tests|Base):.*)?$'
}
backlog() {   # the changed backlog files (core "Backlog files")
  local f; for f in TODO.md CHANGELOG.md docs/plans/PROJECT.md docs/plans/"$root"-*.md; do [ -e "$f" ] && [ -n "$(git status --porcelain -- "$f")" ] && printf '%s\n' "$f"; done
  if readme_only HEAD; then echo README.md; fi
}
C() {   # <entry> <heading>: the CHANGELOG on stdin with the entry first under "### <heading>" of "## [Unreleased]"; a missing heading is created in Keep a Changelog order
  E="$1" H="$2" LC_ALL=C awk '
    BEGIN { e = ENVIRON["E"]; h = "### " ENVIRON["H"]; n = split("Added Changed Deprecated Removed Fixed Security", o, " "); for (i = 1; i <= n; i++) rank["### " o[i]] = i }
    { L[NR] = $0 }
    END {
      for (us = 1; us <= NR && L[us] !~ /^## \[Unreleased\]/; us++) ;; for (ue = us + 1; ue <= NR && L[ue] !~ /^## /; ue++) ;
      at = us; mode = "end"   # at: the last line of the section with text, unless the heading or a later one is found
      for (i = us + 1; i < ue; i++) {
        if (L[i] != "") at = i
        if (L[i] ~ /^### / && rank[L[i]] > rank[h]) { mode = "before"; at = i; break }
        if (L[i] != h) continue
        mode = "empty"; at = i; for (j = i + 1; j < ue && L[j] !~ /^### /; j++) if (L[j] ~ /^- /) { mode = "item"; at = j; break }
        break
      }
      for (i = 1; i <= NR; i++) {
        if (i == at && mode == "item") print e; if (i == at && mode == "before") { print h; print ""; print e; print "" }
        print L[i]
        if (i == at && mode == "empty") { print ""; print e }; if (i == at && mode == "end") { print ""; print h; print ""; print e }
      }
    }'
}
commit() {   # <subject> <body> [path...]: lints, then commits the paths and the changed backlog files by explicit path
  local subj="$1" body="$2" f p=(); shift 2; for f in ${1+"$@"}; do p+=("$f"); done
  while IFS= read -r f; do [ -z "$f" ] || p+=("$f"); done <<EOF
$(backlog)
EOF
  [ "${#p[@]}" -gt 0 ] && [ -n "$(git status --porcelain -- "${p[@]}")" ] || return 0
  if [ -f .todo/todo-lint.sh ] && ! f="$(bash .todo/todo-lint.sh 2>&1)"; then printf '%s\n' "$f" | grep FAIL >&2; stop "the lint fails; not committed: $subj"; fi
  git add -- "${p[@]}" && git commit -q -m "$subj" ${body:+-m "$body"} -- "${p[@]}" || stop "git could not commit: $subj"
}
report() {
  local d b; d="$(git status --porcelain --untracked-files=no | cut -c4- | join)"; b="$(git branch --list 'todo/*' --format='%(refname:short)' | join)"
  git log --reverse --format='%h %s' "$h0..HEAD"; echo "now on $(git symbolic-ref --short HEAD), tree ${d:+not }clean${d:+: $d}; todo branches: ${b:-none}"
}
cmd="${1:-}"; id="${2:-}"; [ $# -ge 2 ] && shift 2
[ "$(git rev-parse --git-dir 2>/dev/null)" = ".git" ] || refuse "run it from the root of the main checkout of a git repository"
[ -f TODO.md ] && [ -n "$id" ] && m="$(Q "$id" marker)" && [ -n "$m" ] || refuse "no task $id in TODO.md"
root="${id%%.*}"; h0="$(git rev-parse HEAD)"; cur="$(git symbolic-ref -q --short HEAD)" || refuse "no branch is checked out"
base="${TODO_BASE:-$(sed -nE 's/^.*Base: *[^A-Za-z0-9]?([A-Za-z0-9._/-]+).*$/\1/p' README.md 2>/dev/null | head -1)}"
for b in main master trunk develop; do [ -n "$base" ] || ! has "$b" || base="$b"; done
[ -n "$base" ] && has "$base" || refuse "no base branch found; set TODO_BASE"
[ ! -f .todo/todo-lint.sh ] || bash .todo/todo-lint.sh >/dev/null 2>&1 || refuse "the lint fails: run bash .todo/todo-lint.sh and fix that first"
st="$(Q "$id" state)"; nb="$(printf '%s\n' "$st" | branch_of)"
case "$cmd" in
start)
  bl="${*-}"; bl="${bl% passing}"; case "$bl" in none|red:\ ?*) ;; *[!0-9]*|"") refuse "the baseline must be <n>, none or red: <ids>" ;; *) bl="$bl passing" ;; esac
  [ "$m" = " " ] || refuse "$id is not an open [ ] task"
  grep -q '^ *- \[/\] \*\*' TODO.md && refuse "another task is active [/]"
  Q "$id" kids | grep -qv ' x$' && refuse "$id has open children"
  rb="$(git show "$base:TODO.md" 2>/dev/null | tr -d '\r' | T "$root" state | branch_of)"
  if [ -z "$rb" ]; then   # an unclaimed tree: root branch, tree claim commit, fast-forward of the base
    [ "$cur" = "$base" ] || refuse "an unclaimed tree starts from $base, and $cur is checked out"
    [ -z "$(git branch --list "todo/$root-*" "todo/$root.*")" ] || refuse "a todo/$root branch exists: read reference/git-flow-edge.md, Existing root branch"
    rb="todo/$root-$(slug "$root")"; nx="start $root"; [ -z "$(Q "$root" kids)" ] || nx="build children"
    git switch -q -c "$rb" || stop "could not create $rb"
    edit "$root" set "" "branch $rb from $base; next: $nx"; commit "chore(backlog): claim $root on $rb" ""
    git switch -q "$base" && git merge -q --ff-only "$rb" || stop "the fast-forward of $base failed; $base is checked out: read reference/git-flow-edge.md, Failed fast-forward"
  else
    case "$cur" in "$rb"|"todo/$root."*) ;; *) refuse "$root is claimed by $rb; run this on a branch of that tree" ;; esac; has "$rb" || refuse "the claimed branch $rb does not exist here"
  fi
  git switch -q "$rb" || stop "could not switch to $rb"
  prev="$rb"; from="$base"; x="$root"; rest="${id#"$root"}"
  while [ -n "$rest" ]; do   # the branch chain below the root, each branch from its parent's
    rest="${rest#.}"; x="$x.${rest%%.*}"; rest="${rest#"${rest%%.*}"}"; nb="$(git branch --list "todo/$x-*" --format='%(refname:short)' | head -1)"
    if [ -n "$nb" ]; then git switch -q "$nb" || stop "could not switch to $nb"
    else
      nb="todo/$x-$(slug "$x")"; git switch -q -c "$nb" || stop "could not create $nb"
      [ "$x" = "$id" ] || edit "$x" set "" "branch $nb from $prev; next: build children"
    fi
    from="$prev"; prev="$nb"
  done
  edit "$id" set / "attempts 0/3; baseline $bl; branch $prev from $from; next: read docs"; commit "chore(backlog): start $id" ""
  report; echo "State: $(Q "$id" state)" ;;
complete)
  subj=""; body="Refs: $id"; while [ $# -gt 0 ]; do case "$1" in -m) subj="${2-}"; shift; shift ;; -b) body="$body$nl${2-}"; shift; shift ;; --) shift; break ;; *) refuse "unknown option $1 (-m, -b, --)" ;; esac; done
  [ -n "$subj" ] || refuse "complete needs -m '<type>(<scope>): <title>'"
  for f in ${1+"$@"}; do [ -e "$f" ] || git ls-files --error-unmatch -- "$f" >/dev/null 2>&1 || refuse "no such path: $f"; done
  [ "$m" = "/" ] || refuse "$id is not the active [/] task"
  [ "$cur" = "$nb" ] || refuse "$id works on ${nb:-no branch}, and $cur is checked out"
  Q "$id" kids | grep -qv ' x$' && refuse "$id has open children"
  if [ "$id" != "$root" ]; then   # a child: [x], its commit, the merge into its parent's branch
    from="$(printf '%s\n' "$st" | sed -nE 's/^.* from ([^ ;]+).*$/\1/p')"; has "$from" || refuse "the parent's branch ${from:-?} does not exist"
    edit "$id" set x -; commit "$subj" "$body" ${1+"$@"}; git switch -q "$from" && git merge -q --no-ff -m "Merge $id into ${id%.*}" "$nb" || stop "the merge of $nb into $from did not finish: resolve it as reference/git-flow-edge.md, Git conflicts, says, then git commit --no-edit and git branch -d $nb"
    git branch -q -d "$nb" || stop "could not delete $nb"
  else   # a root: its commit, then the refresh from the base
    commit "$subj" "$body" ${1+"$@"}; h1="$(git rev-parse HEAD)"
    git merge -q -m "Merge $base into $root" "$base" || stop "the refresh from $base did not finish: resolve it as reference/git-flow-edge.md, Git conflicts, says, then git commit --no-edit and rerun the checks"
    if [ "$(git rev-parse HEAD)" = "$h1" ]; then echo "refresh: $base brought nothing"; else echo "refresh: $base brought changes: rerun Done when and the regression before the drain"; fi
  fi
  report ;;
drain)
  typ=""; mg=0; while [ $# -gt 0 ]; do case "$1" in -t) typ="${2-}"; shift; shift ;; --merge) mg=1; shift ;; *) refuse "unknown option $1 (-t, --merge)" ;; esac; done
  [ "$id" = "$root" ] || refuse "only a root is drained"
  [ "$m" = "/" ] || refuse "$id is not the active [/] root"
  [ "$cur" = "$nb" ] || refuse "$id works on ${nb:-no branch}, and $cur is checked out"
  Q "$id" kids | grep -qv ' x$' && refuse "$id has open children"
  [ -f CHANGELOG.md ] && grep -q '^## \[Unreleased\]' CHANGELOG.md || refuse "CHANGELOG.md has no ## [Unreleased] section"
  grep -q "^- \*\*$id\*\* " CHANGELOG.md && refuse "CHANGELOG.md already has an entry for $id: finish that drain by hand"
  git status --porcelain --untracked-files=no | cut -c4- | grep -qvE '^(TODO\.md|CHANGELOG\.md|README\.md|docs/plans/.*)$' && refuse "uncommitted changes: run complete first"
  case "$id" in FEAT-*) hd=Added; t=feat ;; FIX-*) hd=Fixed; t=fix ;; *) hd=Changed; t=task ;; esac
  ttl="$(Q "$id" title)"; dw="$(Q "$id" 'done')"; ln="$(Q "$id" links)"; inc="$(Q "$id" kids | cut -d' ' -f1 | join)"
  val="$(printf '%s\n' "${dw%%; regression:*}" | grep -o '`[^`]*`' | join)"
  ref="$(printf '%s\n' "$ln" | sed -nE 's/^(.* )?Ref: ([^ ]+).*$/\2/p')"; frm="$(printf '%s\n' "$ln" | sed -nE 's/^(.* )?From: ([^ ]+).*$/\2/p')"
  docs="$(git diff --name-only "$base...HEAD" | grep -E '^(README\.md$|docs/)' | grep -vE "^docs/plans/(PROJECT\.md$|$id-)" | while IFS= read -r f; do if [ "$f" != README.md ] || ! readme_only "$base...HEAD"; then printf '%s\n' "$f"; fi; done | join)"
  entry="- **$id** (${typ:-$t}): ${ttl%.}.${ref:+ Ref: $ref.}${val:+ Validated: $val.}${frm:+ From: $frm.}${docs:+ Docs: updated $docs.}${inc:+ Includes: $inc.}"
  refile CHANGELOG.md C "$entry" "$hd"; edit "$id" drop; commit "chore(backlog): drain $id" "Refs: $id${inc:+${nl}Includes: $inc}"
  mc="git switch $base && git merge --no-ff -m \"Merge $id into $base\" $nb && git branch -d $nb"
  if [ "$mg" = 1 ]; then
    git merge-base --is-ancestor "$base" HEAD || stop "$base moved since the refresh: refresh and verify again, then: $mc"
    [ -z "$(git status --porcelain --untracked-files=no)" ] || stop "the checkout is not clean: commit or stash, then: $mc"
    git switch -q "$base" && git merge -q --no-ff -m "Merge $id into $base" "$nb" && git branch -q -d "$nb" || stop "the merge into $base did not finish"
  else echo "to merge: $mc"; fi
  echo "entry: $entry"; report ;;
*) refuse "unknown command '$cmd' (start, complete, drain)" ;;
esac
