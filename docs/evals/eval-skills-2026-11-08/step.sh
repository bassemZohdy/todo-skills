#!/usr/bin/env bash
# step.sh <name>: runs one fresh Codex session on the scratch repo with $E/<name>/prompt.txt and records its evidence.
set -u
W="$(cygpath -u "$TEMP")/todo-task043-20261108"; E="$W/evidence"; d="$E/$1"; repo="$W/repo"
before="$(git -C "$repo" rev-parse HEAD)"
MSYS_NO_PATHCONV=1 docker run --rm --security-opt seccomp=unconfined \
  --mount "type=bind,source=$(cygpath -w "$repo"),target=/work" \
  --mount "type=bind,source=$(cygpath -w "$d/runner.sh"),target=/runner.sh,readonly" \
  --mount "type=bind,source=$(cygpath -w "$d/prompt.txt"),target=/prompt.txt,readonly" \
  --mount source=todo-codex-auth,target=/root/.codex \
  todo-codex-linux:0.167.0 sh /runner.sh > "$d/codex.jsonl" 2> "$d/codex.stderr.log"
echo "$?" > "$d/agent-exit.txt"
{ echo "BEFORE $before"; echo "AFTER $(git -C "$repo" rev-parse main)"; echo "== status"; git -C "$repo" status --short --branch --untracked-files=all -- . ':!.agents'
  echo "== branches"; git -C "$repo" branch -a -vv; echo "== main log"; git -C "$repo" log --format='%H %s' main; } > "$d/git-state.txt" 2>&1
cat "$d/agent-exit.txt"
