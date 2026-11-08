#!/usr/bin/env bash
# Exercises controller behavior with a fake Codex executable, not an agent trial.
set -eu
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export TRIAL_WINDOWS_ISOLATION=0   # stub-only bookkeeping test: no sandbox needed on Windows hosts
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
for scenario in ts-lifecycle java-lifecycle; do
  TRIAL_ONE_INVOCATION=1 bash "$here/prompt.sh" /work "$scenario" > "$tmp/$scenario"
  grep -q 'exactly one invocation' "$tmp/$scenario" || { echo "FAIL  $scenario prompt"; exit 1; }
done
mkdir "$tmp/bin" "$tmp/runs"
cat > "$tmp/bin/codex" <<'MOCK'
#!/usr/bin/env bash
repo=; out=
while [ "$#" -gt 0 ]; do
  case "$1" in -C) repo="$2"; shift 2 ;; -o) out="$2"; shift 2 ;; *) shift ;; esac
done
n=0; [ ! -f "$repo/.mock-count" ] || n="$(cat "$repo/.mock-count")"
n=$((n + 1)); echo "$n" > "$repo/.mock-count"
if [ "${MOCK_REPEAT:-0}" = 1 ]; then echo 'session id: mock-repeated'; else echo "session id: mock-$n"; fi
echo 'mock report' > "$out"
if [ "${MOCK_CACHE_FAILURE:-0}" = 1 ]; then echo '[ERROR] Could not create local repository at /root/.m2/repository'; exit 0; fi
if [ "$n" -eq 1 ]; then
  echo progress >> "$repo/README.md"
  git -C "$repo" add README.md
  git -C "$repo" -c user.name=trial -c user.email=trial@example.invalid commit -qm 'chore: mock progress'
  exit 0
fi
if [ "${MOCK_REPEAT:-0}" = 1 ]; then exit 0; fi
exit 42
MOCK
chmod +x "$tmp/bin/codex"
# The controller checks tool availability independently; fake binaries keep this
# controller-only test independent of the host's Java and Node installations.
printf '#!/usr/bin/env bash\nexit 0\n' > "$tmp/bin/mvn"
printf '#!/usr/bin/env bash\nexit 0\n' > "$tmp/bin/node"
chmod +x "$tmp/bin/mvn" "$tmp/bin/node"
for scenario in ts-lifecycle java-lifecycle; do
  PATH="$tmp/bin:$PATH" bash "$here/run-codex-multi.sh" "$tmp/runs" "$scenario" > "$tmp/$scenario.run" 2>&1 && { echo "FAIL  $scenario incorrectly passed"; exit 1; }
  controller="$(find "$tmp/runs/$scenario" -maxdepth 1 -type d -name 'controller-*')"
  [ -f "$controller/outcome.txt" ] || { cat "$tmp/$scenario.run"; echo "FAIL  $scenario has no controller outcome"; exit 1; }
  [ "$(cat "$controller/outcome.txt")" = INFRA_ERROR ] || { echo "FAIL  $scenario did not retain process failure"; exit 1; }
  [ "$(wc -l < "$controller/sessions.txt" | tr -d ' ')" = 2 ] || { echo "FAIL  $scenario did not use two sessions"; exit 1; }
  while IFS= read -r ev; do
    for f in prompt.txt session-id.txt agent-exit.txt assert.log assert-exit.txt git-state.txt SHA256SUMS; do
      [ -s "$ev/$f" ] || { echo "FAIL  missing $f"; exit 1; }
    done
    grep -q 'exactly one invocation' "$ev/prompt.txt" || { echo 'FAIL  recorded prompt'; exit 1; }
    (cd "$ev" && sha256sum -c SHA256SUMS >/dev/null) || { echo 'FAIL  evidence checksums'; exit 1; }
  done < "$controller/evidence-paths.txt"
done
mkdir "$tmp/repeated"
MOCK_REPEAT=1 PATH="$tmp/bin:$PATH" bash "$here/run-codex-multi.sh" "$tmp/repeated" ts-lifecycle > "$tmp/repeated.log" 2>&1 && { echo 'FAIL  repeated session passed'; exit 1; }
controller="$(find "$tmp/repeated/ts-lifecycle" -maxdepth 1 -type d -name 'controller-*')"
[ "$(cat "$controller/outcome.txt")" = UNVERIFIED ] || { echo 'FAIL  repeated session was not unverified'; exit 1; }
bash "$here/score.sh" "$tmp/repeated" | grep -q '^UNVERIFIED  *ts-lifecycle' || { echo 'FAIL  scorer ignored unverified sequence'; exit 1; }
last="$(find "$tmp/repeated/ts-lifecycle/evidence" -mindepth 1 -maxdepth 1 -type d | sort | tail -1)"
rm "$last/multi-outcome.txt"
bash "$here/score.sh" "$tmp/repeated" | grep -q '^UNVERIFIED  *ts-lifecycle' || { echo 'FAIL  interrupted controller was counted as complete'; exit 1; }
mkdir "$tmp/cache-failure"
MOCK_CACHE_FAILURE=1 PATH="$tmp/bin:$PATH" bash "$here/run-codex-multi.sh" "$tmp/cache-failure" java-lifecycle > "$tmp/cache-failure.log" 2>&1 && { echo 'FAIL  Maven cache failure passed'; exit 1; }
controller="$(find "$tmp/cache-failure/java-lifecycle" -maxdepth 1 -type d -name 'controller-*')"
[ "$(cat "$controller/outcome.txt")" = INFRA_ERROR ] && grep -q 'Could not create local repository' "$controller/infra-signature.txt" || { echo 'FAIL  Maven cache failure not classified as infrastructure'; exit 1; }
mv "$tmp/bin/mvn" "$tmp/bin/mvn-disabled"
mkdir "$tmp/missing-tool"
limited_path="$tmp/bin:$(dirname "$(command -v git)"):/usr/bin:/bin"
if PATH="$limited_path" command -v mvn >/dev/null 2>&1; then
  echo 'SKIP  cannot hide host Maven from PATH'
  echo '8 passed, 0 failed, 1 skipped'
else
  PATH="$limited_path" bash "$here/run-codex-multi.sh" "$tmp/missing-tool" java-lifecycle > "$tmp/missing-tool.log" 2>&1 && { echo 'FAIL  missing Maven passed'; exit 1; }
  controller="$(find "$tmp/missing-tool/java-lifecycle" -maxdepth 1 -type d -name 'controller-*')"
  [ "$(cat "$controller/outcome.txt")" = INFRA_ERROR ] && grep -q 'required executable unavailable: mvn' "$controller/infra-signature.txt" || { echo 'FAIL  missing Maven not classified as infrastructure'; exit 1; }
  echo '9 passed, 0 failed'
fi
