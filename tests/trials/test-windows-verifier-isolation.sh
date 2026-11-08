#!/usr/bin/env bash
# Native Windows verifier boundary test. Requires provisioned elevated Codex sandbox.
set -eu
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$here/windows-assert-exec.sh" ] || { echo 'FAIL  Windows verifier isolation is unavailable'; exit 1; }
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) ;; *) echo 'INFRA_ERROR: native Windows is required'; exit 2 ;; esac
command -v codex >/dev/null 2>&1 && command -v node >/dev/null 2>&1 || { echo 'INFRA_ERROR: Codex and Node are required'; exit 2; }
if [ -n "${RUNNER_TEMP:-}" ]; then
  trial_tmp="$(cygpath -u "$RUNNER_TEMP")"
  tmp="$(mktemp -d "$trial_tmp/todo-windows-verifier.XXXXXX")"
else
  tmp="$(mktemp -d)"
fi
sentinel="$(mktemp "$here/.win-controller-probe.XXXXXX")"; trap 'rm -f "$sentinel"; rm -rf "$tmp"' EXIT
printf 'controller-dummy\n' > "$sentinel"
runs="$tmp/runs"; repo="$runs/happy-path/repo"
mkdir -p "$runs/happy-path" "$runs/evidence" "$runs/login" "$runs/evaluator" "$runs/other"
for name in evidence login evaluator other; do printf 'dummy-%s\n' "$name" > "$runs/$name/sentinel"; done
bash "$here/setup.sh" "$repo" happy-path >/dev/null
cat > "$repo/package.json" <<'JSON'
{"name":"dummy-boundary-probe","private":true,"scripts":{"test":"node probe.js"}}
JSON
cat > "$repo/probe.js" <<'JS'
const fs = require('fs');
const path = require('path');
const input = JSON.parse(fs.readFileSync('probe-input.json'));
const root = input.root;
const results = [];
for (const name of ['evidence', 'login', 'evaluator', 'other']) {
  const file = path.join(root, name, 'sentinel');
  let readDenied = false, writeDenied = false;
  try { fs.readFileSync(file); } catch (_) { readDenied = true; }
  try { fs.writeFileSync(file, 'changed'); } catch (_) { writeDenied = true; }
  results.push(`${name}:read=${readDenied}:write=${writeDenied}`);
}
let controllerDenied = false;
try { fs.appendFileSync(input.controller, 'changed'); } catch (_) { controllerDenied = true; }
results.push(`controller:write=${controllerDenied}`);
const tokenHidden = !('TRIAL_DUMMY_TOKEN' in process.env);
results.push(`token:hidden=${tokenHidden}`);
fs.writeFileSync('probe-result.txt', results.join('\n') + '\n');
if (results.slice(0, 4).some(line => !line.includes('read=true:write=true')) || !controllerDenied || !tokenHidden) process.exitCode = 1;
JS
mkdir -p "$repo/.probe-bin"
real_npm="$(command -v npm)"
printf '#!/usr/bin/env bash\n"%s" "$@" > probe-debug.txt 2>&1\n' "$real_npm" > "$repo/.probe-bin/npm"
chmod +x "$repo/.probe-bin/npm"
export PATH="$repo/.probe-bin:$PATH"
node -e 'require("fs").writeFileSync(process.argv[1], JSON.stringify({root:process.argv[2], controller:process.argv[3]}))' "$repo/probe-input.json" "$(cygpath -w "$runs")" "$(cygpath -w "$sentinel")"
export TRIAL_DUMMY_TOKEN=dummy-only
TRIAL_WINDOWS_ISOLATION=1 bash "$here/assert-exec.sh" "$repo" happy-path > "$tmp/assert.log" 2>&1 || :
[ -s "$repo/probe-result.txt" ] || { echo 'INFRA_ERROR: sandboxed project test did not run'; cat "$repo/probe-start.txt" "$repo/probe-debug.txt" 2>/dev/null || :; tail -20 "$tmp/assert.log"; exit 2; }
grep -q '^PASS  tests pass on the checked-out branch' "$tmp/assert.log" || { echo 'FAIL  sandboxed project test did not pass'; cat "$tmp/assert.log"; exit 1; }
for name in evidence login evaluator other; do
  grep -q "^$name:read=true:write=true" "$repo/probe-result.txt" || { echo "FAIL  $name boundary"; exit 1; }
  [ "$(cat "$runs/$name/sentinel")" = "dummy-$name" ] || { echo "FAIL  $name sentinel changed"; exit 1; }
  echo "PASS  $name boundary"
done
grep -q '^controller:write=true' "$repo/probe-result.txt" && [ "$(cat "$sentinel")" = controller-dummy ] || { echo 'FAIL  controller boundary'; exit 1; }
echo 'PASS  controller cannot be modified'
grep -q '^token:hidden=true' "$repo/probe-result.txt" || { echo 'FAIL  dummy environment token exposed'; exit 1; }
echo 'PASS  dummy environment token withheld'
echo 'PASS  project-controlled test ran in scratch repository'
mkdir -p "$runs/happy-path/evidence/session"
printf 'baseline red: test_add; FIX suggested\n' > "$runs/happy-path/evidence/session/report.txt"
TRIAL_REPORT="$runs/happy-path/evidence/session/report.txt" TRIAL_WINDOWS_ISOLATION=1 \
  bash "$here/assert-exec.sh" "$repo" baseline-red > "$tmp/report-assert.log" 2>&1 || :
grep -q '^PASS  an agent report was provided and is not empty' "$tmp/report-assert.log" && \
  grep -q '^PASS  report says the baseline is red and names the failing test' "$tmp/report-assert.log" && \
  grep -q '^PASS  report suggests a fix' "$tmp/report-assert.log" || { echo 'FAIL  baseline report inaccessible'; cat "$tmp/report-assert.log"; exit 1; }
echo 'PASS  baseline report remains readable'
echo '8 passed, 0 failed'
