#!/usr/bin/env bash
# Controller evidence, not interleaved Git events, is needed to establish concurrency.
set -eu
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
repo="$tmp/repo"; mkdir "$repo"; git -C "$repo" init -q
main="$(git -C "$repo" rev-parse --show-toplevel)"
printf '1 checkout %s/a a\n2 checkout %s/b b\n3 commit %s/a a\n4 commit %s/b b\n' "$tmp" "$tmp" "$tmp" "$tmp" > "$repo/.git/trial-events"
execution() { bash "$here/lane-evidence.sh" "$repo" "${1:-}" | sed -n 's/^execution: //p'; }
[ "$(execution)" = unverified ] || { echo 'FAIL  interleaved sequential events must be unverified'; exit 1; }
printf 'worker-a lane-a 1 4\nworker-b lane-b 2 5\n' > "$tmp/activity"
[ "$(execution "$tmp/activity")" = concurrent ] || { echo 'FAIL  independent overlapping activity'; exit 1; }
printf 'worker-a lane-a 1 2\nworker-b lane-b 3 4\n' > "$tmp/activity"
[ "$(execution "$tmp/activity")" = sequential ] || { echo 'FAIL  independent sequential activity'; exit 1; }
printf 'worker-a lane-a 1 4\nworker-a lane-b 2 5\n' > "$tmp/activity"
[ "$(execution "$tmp/activity")" = unverified ] || { echo 'FAIL  duplicate worker identity'; exit 1; }
printf 'worker-a lane-a 4 1\nworker-b lane-b 2 5\n' > "$tmp/activity"
[ "$(execution "$tmp/activity")" = unverified ] || { echo 'FAIL  invalid activity interval'; exit 1; }
echo '5 passed, 0 failed'
