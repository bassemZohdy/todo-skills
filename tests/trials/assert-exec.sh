#!/usr/bin/env bash
# Run controller assertions; isolate project test code. On native Windows the isolated verifier (windows-assert-exec.sh)
# is the default and fails closed; TRIAL_WINDOWS_ISOLATION=0 opts out explicitly (unisolated, for stub-only harness tests).
# Elsewhere TRIAL_LINUX_ISOLATION=1 selects the Linux trial profile. Exit 0 or 1 is the assertions' verdict; any other
# exit (2 setup refused, 124 timeout) is an infrastructure error.
set -u
repo="${1:?repository}"; scenario="${2:?scenario}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) windows_default=1 ;; *) windows_default=0 ;; esac
if [ "${TRIAL_WINDOWS_ISOLATION:-$windows_default}" = 1 ]; then
  exec bash "$here/windows-assert-exec.sh" "$repo" "$scenario"
fi
if [ "${TRIAL_LINUX_ISOLATION:-0}" != 1 ]; then
  exec bash "$here/assert.sh" "$repo" "$scenario"
fi
repo="$(cd "$repo" && pwd -P)"
case "$repo" in /runs/*) ;; *) echo 'Linux profile requires a repository under /runs' >&2; exit 2 ;; esac
case "$repo" in *'"'*|*'\'*) echo 'unsupported character in repo path' >&2; exit 2 ;; esac
fs="{\":root\"=\"read\", \"/root/.codex\"=\"deny\", \"/controller\"=\"read\", \"/runs\"=\"deny\", \"$repo\"=\"write\", \"$repo/.git\"=\"write\""
report="${TRIAL_REPORT:-}"
case "$report" in
  /runs/*/evidence/*/report.txt|/runs/*/agent.log)
    case "$report" in *'"'*|*'\'*) echo 'unsupported character in report path' >&2; exit 2 ;; esac
    # A denied parent hides file-level exceptions. Copy just the report outside
    # /runs, where the verifier can read it but its sandbox cannot write it.
    report_dir="$(mktemp -d /tmp/todo-verify-report.XXXXXX)" || exit 2
    trap 'rm -f "$report_dir/report.txt"; rmdir "$report_dir"' EXIT
    cp -- "$report" "$report_dir/report.txt" || exit 2
    report="$report_dir/report.txt" ;;
  ""|/dev/null) ;;
  *) echo 'unsupported report path for Linux profile' >&2; exit 2 ;;
esac
fs="$fs}"
if [ -d "$repo/.git" ]; then
  mkdir -p "$repo/.git/trial-tmp"
  export TMPDIR="$repo/.git/trial-tmp"
  export JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS:-} -Djava.io.tmpdir=$TMPDIR"
fi
codex sandbox -P verify -c "permissions.verify.filesystem=$fs" \
  -c 'permissions.verify.network.enabled=false' -C "$repo" -- env "TRIAL_REPORT=$report" bash "$here/assert.sh" "$repo" "$scenario"
