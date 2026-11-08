#!/usr/bin/env bash
# TASK-046: verify the published evidence for FIX-035 to FIX-041 (docs/evals/fix-evidence-2026-11-08) without running an
# agent. Checks the bundle's checksums, the FIX-035 agent runs (the session logs fix-035.md cites by hash, fresh distinct
# threads, exit codes and assertion results), the FIX-041 dummy-sentinel probe against its own checksums, the recorded
# Windows verifier checks, and that every fix in the index points at published evidence and at harness tests that exist.
# Usage: bash tests/trials/test-fix-evidence.sh [<evidence-dir>]
set -eu
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/../.." && pwd)"
ev="${1:-$root/docs/evals/fix-evidence-2026-11-08}"
[ -d "$ev" ] || { echo "FAIL  no evidence folder: $ev"; exit 1; }
sums() { (cd "$1" && if command -v sha256sum >/dev/null 2>&1; then tr -d '\r' < "$2" | sha256sum -c --quiet -; else tr -d '\r' < "$2" | shasum -a 256 -c --quiet -; fi) \
  || { echo "FAIL  checksum mismatch in $1/$2"; exit 1; }; }
sums "$ev" SHA256SUMS; sums "$ev/fix-041-probe" SHA256SUMS
echo "PASS  the bundle's SHA256SUMS and the FIX-041 probe's own SHA256SUMS verify"
python3 - "$ev" "$root" <<'PY'
import hashlib, json, pathlib, re, subprocess, sys
ev, root = map(pathlib.Path, sys.argv[1:])
def text(p):
    b = p.read_bytes()
    return (b.decode('utf-16') if b[:2] in (b'\xff\xfe', b'\xfe\xff') else b.decode('utf-8-sig')).replace('\r\n', '\n')
def threads(p):
    return [json.loads(l)['thread_id'] for l in text(p).splitlines() if l.strip().startswith('{') and '"thread.started"' in l]
f35 = ev / 'fix-035'; doc = (root / 'docs/evals/fix-035.md').read_text(encoding='utf-8')
cited = re.findall(r'`([0-9a-f]{64})`', doc)
got = [hashlib.sha256((f35 / p).read_bytes()).hexdigest() for p in ('normal/continue/codex.jsonl', 'race/codex.jsonl')]
assert got == cited[:2], f'fix-035.md cites {cited[:2]}, the published logs hash to {got}'
ids = {name: threads(f35 / name / 'codex.jsonl') for name in ('normal/add', 'normal/continue', 'race')}
assert all(len(v) == 1 for v in ids.values()) and len({v[0] for v in ids.values()}) == 3, f'sessions: {ids}'
for name, (sid,) in ids.items():
    if name != 'normal/add': assert sid in doc, f'{name}: thread {sid} is not the one fix-035.md names'
    assert text(f35 / name / 'agent-exit.txt').strip() == '0', f'{name}: agent exit'
assert re.search(r'^12 passed, 0 failed', text(f35 / 'normal/assert.log'), re.M) and text(f35 / 'normal/assert-exit.txt').strip() == '0'
assert re.search(r'^6 passed, 0 failed', text(f35 / 'race/assert.log'), re.M)
assert not any('Bassem' in text(p) for p in f35.rglob('*') if p.is_file()), 'a user name is left in the FIX-035 evidence'
print('PASS  FIX-035: the cited session logs, three distinct fresh threads, agent exits 0, 12/12 and 6/6 assertions')
probe = json.loads(text(ev / 'fix-041-probe/results.json'))
assert probe, 'empty probe results'
for d in ('auth', 'evaluator', 'evidence', 'other'):
    assert text(ev / 'fix-041-probe' / d / 'sentinel.txt').startswith('dummy'), f'{d}: the sentinel is not a dummy'
print('PASS  FIX-041: the dummy-sentinel probe outputs verify against their own checksums')
checks = ev / 'fix-041-checks'
meta = json.loads(text(checks / 'checks.json'))
subprocess.run(['git', '-C', str(root), 'merge-base', '--is-ancestor', meta['commit'], 'HEAD'], check=True)
for name, want in meta['logs'].items():
    log = text(checks / name)
    assert re.search(rf'^{want} passed, 0 failed$', log, re.M) and not re.search(r'^(FAIL|INFRA_ERROR)', log, re.M), f'{name}: not {want} passed, 0 failed'
print(f"PASS  FIX-041: the recorded Windows verifier checks pass at {meta['commit'][:7]}, an ancestor of HEAD")
index = text(ev / 'index.md'); rows = {}
for line in index.splitlines():
    m = re.match(r'\| \*\*((?:FIX|TASK)-0\d\d)\*\* \|(.*)\|(.*)\|(.*)\|$', line)
    if m: rows[m.group(1)] = m.group(2, 3, 4)
assert sorted(rows) == ['FIX-035', 'FIX-036', 'FIX-037', 'FIX-038', 'FIX-039', 'FIX-041', 'TASK-040'], f'index rows: {sorted(rows)}'
for fix, (what, published, checks_col) in rows.items():
    for link in re.findall(r'\]\(([^)#]+)', published):
        assert (ev / link).exists(), f'{fix}: {link} does not exist'
    for t in re.findall(r'`(?:bash )?(tests/[^` ]+\.sh)', checks_col):
        assert (root / t).is_file(), f'{fix}: {t} does not exist'
print('PASS  the index covers FIX-035 to FIX-041 (with TASK-040, the 040 slot) and every evidence link and checker exists')
PY
