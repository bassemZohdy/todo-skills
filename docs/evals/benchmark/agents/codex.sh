#!/usr/bin/env bash
# Benchmark adapter for Codex CLI: one fresh `codex exec` process, writes confined to the scratch repository, JSON events on
# stdout so usage.sh can read the token usage. The sandbox flags are those of tests/trials/codex-exec.sh (see its comments
# for what was verified on codex-cli 0.167.0, including that the unelevated Windows sandbox cannot deny reads, which makes a
# run "provisional"). Not yet run for the benchmark.
# Usage: bash codex.sh <repo> <prompt-file> <report-file> | bash codex.sh --version
set -u
if [ "${1:-}" = --version ]; then codex --version; exit; fi
repo="${1:?repo}"; pf="${2:?prompt file}"; out="${3:?report file}"
nat() { if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"; else printf '%s\n' "$1"; fi; }
args=(exec --json --ephemeral -s workspace-write
  -c sandbox_workspace_write.exclude_tmpdir_env_var=true -c sandbox_workspace_write.exclude_slash_tmp=true
  -C "$(nat "$repo")" -o "$(nat "$out")")
[ -z "${BENCH_MODEL:-}" ] || [ "$BENCH_MODEL" = unavailable ] || args+=(-m "$BENCH_MODEL")
[ -d "$repo.todo" ] && args+=(--add-dir "$(nat "$repo.todo")")
codex "${args[@]}" "$(cat "$pf")" < /dev/null
