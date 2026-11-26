#!/usr/bin/env bash
# todo-limit.sh - optional: runs one command line under a time limit, so a hung test cannot hold a session for ever.
# It needs no timeout program (stock macOS has none): bash, sleep, kill, ps and awk are enough.
# Usage: bash todo-limit.sh <seconds> '<command line>'      (from the directory the command expects)
#   The command line runs with bash and gets no input: a command that waits for input reads end of file.
#   Its output passes through unchanged. In time: this script exits with the command's own exit status.
#   Over the limit: the command and the processes below it are stopped (TERM, then KILL after a grace of
#   TODO_LIMIT_GRACE seconds, default 2), one line on stderr says so, and this script exits 124, the status the
#   timeout program uses. Exit 2: wrong usage.
#   This script runs the command line as given: judge its safety first, as for any Done when command.
# Limits: a process that left the command's tree (a daemon, or a child whose parent already ended) is not found; where ps
# cannot list parents, only the command itself is stopped and the stop line says so; a signal sent to this script is
# not passed on to the command.
# On Windows (Git Bash) a program that is not a Git Bash program cannot take TERM, so it and the Windows processes below
# it are ended at once with taskkill.
# --version prints the release this copy comes from (FEAT-088); tests/run.sh checks it against the manifests.
todo_skills_version="0.6.4"
if [ "${1:-}" = "--version" ]; then echo "todo-limit.sh $todo_skills_version"; exit 0; fi
usage() { echo "usage: bash todo-limit.sh <seconds> '<command line>'" >&2; exit 2; }
[ "$#" -eq 2 ] || usage
limit="$1"; cmd="$2"
case "$limit" in ''|*[!0-9]*) usage ;; esac
[ "$limit" -gt 0 ] || usage
[ -n "$cmd" ] || usage
grace="${TODO_LIMIT_GRACE:-2}"
case "$grace" in ''|*[!0-9]*) grace=2 ;; esac

# pairs: one "pid parent" line per process, or nothing where ps cannot say. Linux and macOS take -o; the ps of Git Bash
# does not, but its -ef has the two columns. A listing without two numbers per line is not used.
pairs() {
  local out
  out="$(ps -e -o pid= -o ppid= 2>/dev/null | awk 'NF == 2 && $1 ~ /^[0-9]+$/ && $2 ~ /^[0-9]+$/')"
  [ -n "$out" ] || out="$(ps -ef 2>/dev/null | awk '$2 ~ /^[0-9]+$/ && $3 ~ /^[0-9]+$/ { print $2, $3 }')"
  [ -z "$out" ] || printf '%s\n' "$out"
}
# tree <pid>...: the given process ids and every process below them, from one listing.
tree() {
  pairs | awk -v roots="$*" '
    BEGIN { n = split(roots, r, " "); for (i = 1; i <= n; i++) if (!(r[i] in want)) { want[r[i]] = 1; order[++m] = r[i] } }
    { parent[$1] = $2; ids[++c] = $1 }
    END {
      do {
        grew = 0
        for (i = 1; i <= c; i++) if (!(ids[i] in want) && (parent[ids[i]] in want)) { want[ids[i]] = 1; order[++m] = ids[i]; grew = 1 }
      } while (grew)
      for (i = 1; i <= m; i++) print order[i]
    }'
}
# end_windows_tree <pid> [all]: Git Bash only. Ends a program that is not a Git Bash program (with "all": any program),
# and the Windows processes below it.
end_windows_tree() {
  local w exe
  if [ ! -r "/proc/$1/winpid" ] || ! command -v taskkill >/dev/null 2>&1; then return 0; fi
  exe="$(cat "/proc/$1/exename" 2>/dev/null)"
  case "$exe" in /usr/*|/bin/*|'') [ "${2:-}" = all ] || return 0 ;; esac
  w="$(cat "/proc/$1/winpid" 2>/dev/null)"
  [ -z "$w" ] || MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' taskkill /PID "$w" /T /F >/dev/null 2>&1
}
alive() { local p; for p in "$@"; do kill -0 "$p" 2>/dev/null && return 0; done; return 1; }

# The watchdog tells this script that the limit fell with USR1, so that this script never stops a watchdog that is busy
# stopping the command. Where USR1 cannot be caught (ignored on entry), the watchdog's exit status says it instead, at
# the price of up to one second after a command that ended in time.
fired=0; probe=0
trap 'probe=1' USR1
kill -USR1 "$$" 2>/dev/null
if [ "$probe" -eq 1 ]; then signalled=1; trap 'fired=1' USR1; else signalled=0; trap '' USR1; fi

bash -c "$cmd" < /dev/null &
pid=$!
(
  trap - USR1
  i=0
  while [ "$i" -lt "$limit" ]; do
    sleep 1
    i=$((i + 1))
    kill -0 "$pid" 2>/dev/null || exit 1   # the command ended in time
  done
  kill -USR1 "$$" 2>/dev/null
  # shellcheck disable=SC2046  # a list of process ids, split on purpose
  set -- $(tree "$pid")
  [ "$#" -gt 0 ] || set -- "$pid"
  for p in "$@"; do end_windows_tree "$p"; done
  kill -TERM "$@" 2>/dev/null
  i=0
  while [ "$i" -lt "$grace" ] && alive "$@"; do sleep 1; i=$((i + 1)); done
  # shellcheck disable=SC2046  # once more from every process seen: one may have started others during the grace
  set -- "$@" $(tree "$@")
  for p in "$@"; do end_windows_tree "$p" all; done
  kill -KILL "$@" 2>/dev/null
  exit 0
) > /dev/null 2>&1 &
watch=$!
{ wait "$pid"; } 2>/dev/null   # a command that a signal ended is reported by bash 3.2 as well: discarded
rc=$?
# Ended in time, as far as this script knows: stop the watchdog. If the limit fell in this very moment, USR1 says so. The
# shell of macOS (bash 3.2) reports a job that a signal ended ("Terminated: 15 ( trap ...") on its own stderr, when the job
# is reaped, which no redirection of the wait alone catches: the kill and the waits are groups with their stderr discarded.
{ if [ "$signalled" -eq 1 ] && [ "$fired" -eq 0 ]; then kill "$watch"; fi; wait "$watch"; } 2>/dev/null
wrc=$?
if [ "$fired" -eq 1 ] && [ "$wrc" -ne 0 ]; then { wait "$watch"; } 2>/dev/null; wrc=$?; fi   # the first wait was cut short by USR1
if [ "$fired" -eq 1 ] || [ "$wrc" -eq 0 ]; then
  { wait "$pid"; } 2>/dev/null
  note=""
  [ -n "$(pairs)" ] || note=" (ps lists no parents here: only the command itself was stopped, not what it started)"
  echo "todo-limit.sh: stopped after ${limit}s: $cmd$note" >&2
  exit 124
fi
exit "$rc"
