#!/usr/bin/env bash
# Fills template.html with TODO.md, CHANGELOG.md, the plan docs (docs/plans/PROJECT.md and each docs/plans/*.md that a
# Ref: in TODO.md names) and META lines, encoded so text cannot
# break out of the page's script blocks (& -> &amp;, < -> &lt;; the page decodes them).
# Usage, from the repository root:  bash tools/todo-report.sh < meta.txt > docs/status.html
#   meta.txt: one "key: value" per line (may be empty). Writes only to stdout. Needs bash and sed.
# --version prints the release this copy comes from (FEAT-088); tests/run.sh checks it against the manifests.
todo_skills_version="0.6.3"
if [ "${1:-}" = "--version" ]; then echo "todo-report.sh $todo_skills_version"; exit 0; fi
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tpl="$here/template.html"
[ -f "$tpl" ] || { echo "template.html not found next to $0" >&2; exit 1; }
[ -f TODO.md ] || { echo "todo-report: TODO.md not found in $(pwd); run from the repository root" >&2; exit 1; }
meta="$(cat)"
enc() { sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g'; }
fill() {   # $1 placeholder, rest of line handled by caller
  case "$1" in
    __META__) printf '%s' "$meta" | enc ;;
    __TODO__) [ -f TODO.md ] && enc < TODO.md ;;
    __CHANGELOG__) [ -f CHANGELOG.md ] && enc < CHANGELOG.md ;;
    __PLAN__) plan_n=0   # PROJECT.md first, then each docs/plans/*.md a Ref: in TODO.md names, under a line with its path
      while IFS= read -r plan_p; do
        [ -n "$plan_p" ] && [ -f "$plan_p" ] || continue
        [ "$plan_n" = 0 ] || printf '\n'
        [ "$plan_p" = docs/plans/PROJECT.md ] || printf -- '----- %s -----\n' "$plan_p"
        enc < "$plan_p"; plan_n=$((plan_n + 1))
      done <<EOF
$( { echo docs/plans/PROJECT.md; grep -oE 'Ref: docs/plans/[A-Za-z0-9._-]+\.md' TODO.md | cut -c6-; } | awk '!seen[$0]++')
EOF
      [ "$plan_n" -gt 0 ] || printf '__PLAN__' ;;
  esac
}
while IFS= read -r line || [ -n "$line" ]; do
  done_line=0
  for ph in __META__ __TODO__ __CHANGELOG__ __PLAN__; do
    case "$line" in
      *">$ph<"*)
        printf '%s>' "${line%%>"$ph"<*}"
        fill "$ph"
        printf '<%s\n' "${line#*>"$ph"<}"
        done_line=1; break ;;
    esac
  done
  [ "$done_line" = 1 ] || printf '%s\n' "$line"
done < "$tpl"
