#!/usr/bin/env bash
# TASK-045: verify the Windows Codex lifecycle batch run with the default isolated verifier, without running an agent.
# Checks the eight scenarios with test-codex-evidence.sh (checksums, fresh sessions, verdicts that agree with their
# evidence), that every assertion log, including each multi-node invocation's, ran in windows-assert-exec.sh's elevated
# sandbox, that every verdict has a recorded cause, the multi-node controllers, and the batch-level checksums.
# Usage: bash tests/trials/test-windows-codex-evidence.sh [<evidence-dir>]
set -eu
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/../.." && pwd)"
ev="${1:-$root/docs/evals/codex-windows-2026-11-08}"
[ -d "$ev" ] || { echo "FAIL  no evidence folder: $ev"; exit 1; }
(cd "$ev" && if command -v sha256sum >/dev/null 2>&1; then sha256sum -c --quiet SHA256SUMS; else shasum -a 256 -c --quiet SHA256SUMS; fi) \
  || { echo "FAIL  checksum mismatch in $ev"; exit 1; }
echo "PASS  the batch SHA256SUMS verifies"
bash "$here/test-codex-evidence.sh" "$ev" | tail -4
[ "${PIPESTATUS[0]}" = 0 ] || { echo "FAIL  test-codex-evidence.sh"; exit 1; }
python3 - "$ev" "$root" <<'PY'
import json, pathlib, re, subprocess, sys
ev, root = map(pathlib.Path, sys.argv[1:])
r = json.loads((ev / 'results.json').read_text(encoding='utf-8'))
assert r['agent'] == 'codex-cli 0.167.0' and r['verifier'].startswith('windows-assert-exec.sh, elevated'), 'agent or verifier'
subprocess.run(['git', '-C', str(root), 'merge-base', '--is-ancestor', r['controller_commit'], 'HEAD'], check=True)
assert (ev / 'controller-sha.txt').read_text().strip() == r['controller_commit'], 'controller-sha.txt'
assert len(r['scenarios']) == 8, 'eight scenarios'
logs = 0
for s in r['scenarios']:
    d = ev / 'runs' / s['scenario']
    assert (d / 'outcome.txt').read_text().strip() == s['outcome'], f"{s['scenario']}: outcome"
    assert s['outcome'] in ('PASS', 'FAIL', 'INFRA_ERROR'), f"{s['scenario']}: {s['outcome']} is not scored"
    assert s['outcome'] == 'PASS' or s['cause'].strip(), f"{s['scenario']}: no cause recorded"
    lines = (d / 'assert.log').read_text(encoding='utf-8').splitlines()
    assert (sum(l.startswith('PASS  ') for l in lines), sum(l.startswith('FAIL  ') for l in lines)) == (s['assertions_passed'], s['assertions_failed'])
    for log in [d / 'assert.log', *sorted(d.glob('invocations/*/assert.log'))]:
        first = log.read_text(encoding='utf-8').splitlines()[0]
        assert first.startswith('INFO  verifier: windows-assert-exec.sh, elevated Windows sandbox'), f'{log}: {first}'
        logs += 1
    if s['scenario'] in ('ts-lifecycle', 'java-lifecycle'):
        inv = sorted((d / 'invocations').iterdir(), key=lambda p: int(p.name))
        ids = [(p / 'session-id.txt').read_text().strip() for p in inv]
        assert ids == s['session_ids'] and len(set(ids)) == len(ids), f"{s['scenario']}: invocation sessions"
        assert (d / 'controller' / 'outcome.txt').read_text().strip() == s['outcome'], f"{s['scenario']}: controller outcome"
text = json.dumps(r) + ''.join(p.read_text(encoding='utf-8', errors='replace') for p in ev.rglob('*') if p.is_file() and p.suffix in ('.txt', '.log', '.md', '.json'))
assert not re.search(r'(?i)users[\\/]+bassem', text), 'a user name is left in a path'
print(f'PASS  {logs} assertion logs ran in the elevated Windows verifier; every verdict is scored with its cause')
PY
