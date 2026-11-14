#!/usr/bin/env bash
# Reads token usage and call counts from an agent CLI's OWN output (FEAT-055). Never estimates: a value the CLI did not
# report is "unavailable". Usage: bash usage.sh <session.log>   prints key=value lines.
#   Codex (`codex exec --json`): every turn.completed event's usage; input_tokens include the cached ones, as Codex reports
#     them; llm_calls = turn.completed events; subagent_calls unavailable.
#   pi (agents/pi.sh): the pi.summary line the adapter prints from pi's own session log (assistant usage summed; input_tokens
#     include the cached ones; llm_calls = assistant messages; subagent_calls unavailable).
#   Claude Code (`--output-format stream-json` or json): the final result event; input_tokens = input_tokens +
#     cache_creation_input_tokens + cache_read_input_tokens, cached_tokens = cache_read_input_tokens; llm_calls = num_turns;
#     subagent_calls = subagent_stats.spawned.
# Formats checked against recorded sessions: docs/evals/fix-evidence-2026-11-08 (Codex 0.167.0) and
# docs/evals/claude-code-2026-11-07 (Claude Code result events).
set -u
f="${1:?usage: usage.sh <session.log>}"
num() { grep -o "\"$1\":[0-9]*" | head -1 | sed 's/.*://'; }
codex="$(grep '"type":"turn.completed"' "$f" 2>/dev/null)"
result="$(grep '"type":"result"' "$f" 2>/dev/null | tail -1)"
pi="$(grep '"type":"pi.summary"' "$f" 2>/dev/null | tail -1)"
if [ -n "$codex" ]; then
  printf '%s\n' "$codex" | awk '
    { n++; for (k = 1; k <= 3; k++) { key = (k == 1 ? "input_tokens" : k == 2 ? "cached_input_tokens" : "output_tokens")
        if (match($0, "\"" key "\":[0-9]+")) v[k] += substr($0, RSTART + length(key) + 3, RLENGTH - length(key) - 3) } }
    END { printf "input_tokens=%d\noutput_tokens=%d\ncached_tokens=%d\nllm_calls=%d\nsubagent_calls=unavailable\nusage_source=codex turn.completed\n", v[1], v[3], v[2], n }'
elif [ -n "$pi" ]; then
  echo "input_tokens=$(printf '%s' "$pi" | num input_tokens)"; echo "output_tokens=$(printf '%s' "$pi" | num output_tokens)"
  echo "cached_tokens=$(printf '%s' "$pi" | num cached_tokens)"; echo "llm_calls=$(printf '%s' "$pi" | num llm_calls)"
  echo "subagent_calls=unavailable"; echo "usage_source=pi session log (summed assistant usage)"
elif [ -n "$result" ]; then
  usage="$(printf '%s' "$result" | grep -o '"usage":{[^}]*' | head -1)"
  i="$(printf '%s' "$usage" | num input_tokens)"; cc="$(printf '%s' "$usage" | num cache_creation_input_tokens)"
  cr="$(printf '%s' "$usage" | num cache_read_input_tokens)"; o="$(printf '%s' "$usage" | num output_tokens)"
  t="$(printf '%s' "$result" | num num_turns)"; s="$(printf '%s' "$result" | grep -o '"subagent_stats":{"spawned":[0-9]*' | sed 's/.*://')"
  if [ -n "$i" ] && [ -n "$o" ]; then
    echo "input_tokens=$((i + ${cc:-0} + ${cr:-0}))"; echo "output_tokens=$o"; echo "cached_tokens=${cr:-unavailable}"
  else printf 'input_tokens=unavailable\noutput_tokens=unavailable\ncached_tokens=unavailable\n'; fi
  echo "llm_calls=${t:-unavailable}"; echo "subagent_calls=${s:-unavailable}"; echo "usage_source=claude result event"
else
  printf 'input_tokens=unavailable\noutput_tokens=unavailable\ncached_tokens=unavailable\nllm_calls=unavailable\nsubagent_calls=unavailable\nusage_source=none\n'
fi
