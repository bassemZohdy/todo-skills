#!/usr/bin/env bash
# Benchmark adapter for pi (https://github.com/badlogic/pi-mono): one fresh `pi -p` process in the scratch repository, the
# model glm-5.3 on provider zai by default (BENCH_MODEL overrides; BENCH_PI_PROVIDER overrides the provider; needs
# ZAI_API_KEY). Unlike tests/trials/run-pi.sh it does NOT pass --no-skills or --no-context-files: the `todo-skills` arm puts
# the skills in .claude/skills and .agents/skills and a pointer in AGENTS.md, and a real pi user gets exactly that, while the
# other arms have neither. Extensions, prompt templates and themes stay off, and pi has no user-level skills or AGENTS.md on
# the machine this was written for (check `pi list` and ~/.pi/agent before comparing results from another machine).
# pi has no permission prompts and no OS sandbox, so runs are "provisional". pi keeps its own session log (every tool call
# and usage record); the adapter prints one summary line from it, so usage.sh reads pi's own numbers and never estimates.
# Usage: bash pi.sh <repo> <prompt-file> <report-file> | bash pi.sh --version
set -u
if [ "${1:-}" = --version ]; then pi --version; exit; fi
repo="${1:?repo}"; pf="${2:?prompt file}"; out="${3:?report file}"
model="glm-5.3"; [ -z "${BENCH_MODEL:-}" ] || [ "$BENCH_MODEL" = unavailable ] || model="$BENCH_MODEL"
provider="${BENCH_PI_PROVIDER:-zai}"
case "$(uname -s 2>/dev/null)" in MINGW*|MSYS*|CYGWIN*) tools="read,powershell,edit,write" ;; *) tools="read,bash,edit,write" ;; esac
sess="$(mktemp -d "$repo.pi-session.XXXXXX")"   # one folder per invocation: a retry must not add the earlier attempt's usage
cd "$repo" || exit 2
pi -p --provider "$provider" --model "$model" --tools "${BENCH_PI_TOOLS:-$tools}" --session-dir "$sess" \
   --no-extensions --no-prompt-templates --no-themes -- "$(cat "$pf")" < /dev/null | tee "$out"
rc=${PIPESTATUS[0]}
python3 - "$sess" <<'PY'
import glob, json, sys
i = o = c = turns = calls = 0
for f in glob.glob(sys.argv[1] + "/*.jsonl"):
    for line in open(f, encoding="utf-8", errors="replace"):
        try: m = json.loads(line).get("message") or {}
        except ValueError: continue
        if m.get("role") == "assistant":
            u = m.get("usage") or {}
            i += u.get("input", 0) + u.get("cacheRead", 0) + u.get("cacheWrite", 0)
            o += u.get("output", 0); c += u.get("cacheRead", 0); turns += 1
            calls += sum(1 for p in m.get("content") or [] if isinstance(p, dict) and p.get("type") == "toolCall")
print(json.dumps({"type": "pi.summary", "input_tokens": i, "output_tokens": o, "cached_tokens": c, "llm_calls": turns, "tool_calls": calls}, separators=(",", ":")))
PY
exit "$rc"
