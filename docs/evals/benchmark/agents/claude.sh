#!/usr/bin/env bash
# Benchmark adapter for Claude Code: one fresh `claude -p` process in the scratch repository, with the flags of the recorded
# Claude Code trials (docs/evals/claude-code-2026-11-07/runs/*/command.txt): stream-json output (its final result event
# carries usage, num_turns and subagent_stats), acceptEdits with a fixed tool list, project and local settings only, no MCP
# servers and no saved session. Claude Code's permission mode is not an OS sandbox, so runs are "provisional" unless the
# maintainer runs them in one. Not yet run for the benchmark.
# Usage: bash claude.sh <repo> <prompt-file> <report-file> | bash claude.sh --version
set -u
if [ "${1:-}" = --version ]; then claude --version; exit; fi
repo="${1:?repo}"; pf="${2:?prompt file}"; out="${3:?report file}"
args=(-p "$(cat "$pf")" --output-format stream-json --verbose --permission-mode acceptEdits
  --allowedTools "Bash,Read,Write,Edit,Glob,Grep" --add-dir "$repo" --setting-sources project,local --strict-mcp-config
  --no-session-persistence)
[ -z "${BENCH_MODEL:-}" ] || [ "$BENCH_MODEL" = unavailable ] || args+=(--model "$BENCH_MODEL")
cd "$repo" || exit 2
log="$(mktemp)"; trap 'rm -f "$log"' EXIT
claude "${args[@]}" < /dev/null | tee "$log"; rc=${PIPESTATUS[0]}
# The final message is the result event's "result" string.
python3 -c 'import json,sys
for line in open(sys.argv[1], encoding="utf-8", errors="replace"):
    try: e = json.loads(line)
    except ValueError: continue
    if e.get("type") == "result": open(sys.argv[2], "w", encoding="utf-8").write(e.get("result") or "")' "$log" "$out"
exit "$rc"
