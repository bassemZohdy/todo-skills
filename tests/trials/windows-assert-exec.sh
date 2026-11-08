#!/usr/bin/env bash
# Run the trusted assertion script in the explicitly provisioned Windows sandbox.
# This optional verifier backend fails closed; it never falls back to an unisolated run.
set -u
repo="${1:?repository}"; scenario="${2:?scenario}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) ;; *) echo 'INFRA_ERROR: native Windows required' >&2; exit 2 ;; esac
command -v cygpath >/dev/null 2>&1 && command -v codex >/dev/null 2>&1 || { echo 'INFRA_ERROR: cygpath and Codex are required' >&2; exit 2; }
repo="$(cd "$repo" && pwd -P)" || exit 2
runs="$(cd "$repo/../.." && pwd -P)" || exit 2
# The standard layout is <runs>/<scenario>/repo. Never sandbox the controller
# inside a path writable to the evaluated repository.
[ "$(basename "$repo")" = repo ] || { echo 'INFRA_ERROR: expected <runs>/<scenario>/repo' >&2; exit 2; }
case "$here/" in "$runs/"*) echo 'INFRA_ERROR: controller must be outside the runs directory' >&2; exit 2 ;; esac
case "$here/" in "$repo/"*) echo 'INFRA_ERROR: controller must be outside the repository' >&2; exit 2 ;; esac
repo_w="$(cygpath -m "$repo")"; runs_w="$(cygpath -m "$runs")"; here_w="$(cygpath -m "$here")"
auth_w="$(cygpath -m "${CODEX_HOME:-$USERPROFILE/.codex}")"
bash_w="$(cygpath -m "$(command -v bash)")"
for item in "$repo_w" "$runs_w" "$here_w" "$auth_w"; do
  case "$item" in *'"'*|*'\'*) echo 'INFRA_ERROR: unsupported path characters' >&2; exit 2 ;; esac
done
# Node and other native programs inspect ancestor directories; denying the
# entire batch prevents them from resolving even an allowed repository. Deny
# the existing batch and scenario siblings instead, and keep ancestors read-only.
fs="{\":root\"=\"read\", \"$repo_w\"=\"write\", \"$repo_w/.git\"=\"write\", \"$auth_w\"=\"deny\""
scenario_dir="$(cd "$repo/.." && pwd -P)"
shopt -s nullglob
for item in "$runs"/* "$scenario_dir"/*; do
  [ "$item" != "$scenario_dir" ] && [ "$item" != "$repo" ] || continue
  item_w="$(cygpath -m "$item")"
  case "$item_w" in *'"'*|*'\'*) echo 'INFRA_ERROR: unsupported path characters' >&2; exit 2 ;; esac
  fs="$fs, \"$item_w\"=\"deny\""
done
shopt -u nullglob
fs="$fs}"
report="${TRIAL_REPORT:-}"
if [ -n "$report" ] && [ "$report" != /dev/null ]; then
  report_dir="$(mktemp -d)" || exit 2
  trap 'rm -f "$report_dir/report.txt"; rmdir "$report_dir"' EXIT
  cp -- "$report" "$report_dir/report.txt" || exit 2
  report="$(cygpath -m "$report_dir/report.txt")"
fi
export MSYS_NO_PATHCONV=1
# Exactly this mode is requested: do not silently fall back to unelevated.
mode="${TRIAL_WINDOWS_SANDBOX:-elevated}"
case "$mode" in elevated|mxc) ;; *) echo 'INFRA_ERROR: unsupported Windows sandbox mode' >&2; exit 2 ;; esac
timeout 180 codex -c "windows.sandbox=$mode" -c 'default_permissions="verify"' \
  -c "permissions.verify.filesystem=$fs" -c 'permissions.verify.network.enabled=false' \
  -c 'shell_environment_policy.inherit="core"' -c 'shell_environment_policy.ignore_default_excludes=false' \
  sandbox -P verify -C "$repo_w" -- "$bash_w" -c \
  'export TRIAL_REPORT="$1"; source "$2" "$3" "$4"' _ "$report" "$here_w/assert.sh" "$repo_w" "$scenario"
