#!/usr/bin/env bash
# TASK-043: verify the recorded existing-project trial without running an agent or touching its login.
# A scratch clone of bassemZohdy/eval-skills ran /todo-init, /todo-add and /todo-continue --merge in three fresh Codex
# processes, with no commit of any kind between them (the FIX-035 workaround committed the backlog before continue).
# Usage: bash tests/trials/test-existing-project-evidence.sh [<evidence-dir>]
set -eu
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/../.." && pwd)"
ev="${1:-$root/docs/evals/eval-skills-2026-11-08}"
[ -d "$ev" ] || { echo "FAIL  no evidence folder: $ev"; exit 1; }
(cd "$ev" && if command -v sha256sum >/dev/null 2>&1; then sha256sum -c --quiet SHA256SUMS; else shasum -a 256 -c --quiet SHA256SUMS; fi) \
  || { echo "FAIL  checksum mismatch in $ev"; exit 1; }
echo "PASS  the checksums verify"
skills="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["skills_commit"])' "$ev/results.json")"
git -C "$root" cat-file -e "$skills^{commit}" && git -C "$root" merge-base --is-ancestor "$skills" HEAD \
  || { echo "FAIL  skills commit $skills is not in this history"; exit 1; }
echo "PASS  the tested skills commit $skills is an ancestor of HEAD"

python3 - "$ev" <<'PY'
import json, pathlib, re, sys
ev = pathlib.Path(sys.argv[1])
r = json.loads((ev / 'results.json').read_text(encoding='utf-8'))
assert r['agent'] == 'codex-cli 0.167.0' and r['model'] == 'gpt-6.1-terra', 'agent or model changed'
assert r['source_commit'] == '1d4040b6584c94ae7143534911835f5b9053d3de', 'eval-skills commit changed'
assert r['outcome'] == 'PASS', f"outcome is {r['outcome']}"
steps = ['init', 'add', 'continue']
assert list(r['sessions']) == steps and len(set(r['sessions'].values())) == 3, 'three distinct fresh sessions expected'
heads = {}
for step in steps:
    d = ev / step
    events = [json.loads(l) for l in (d / 'codex.jsonl').read_text(encoding='utf-8').splitlines() if l.strip()]
    assert next(e['thread_id'] for e in events if e['type'] == 'thread.started') == r['sessions'][step], f'{step}: session id'
    assert any(e['type'] == 'turn.completed' for e in events), f'{step}: the turn did not complete'
    assert (d / 'agent-exit.txt').read_text().strip() == '0', f'{step}: agent exit'
    runner = (d / 'runner.sh').read_text(encoding='utf-8')
    assert '-m gpt-6.1-terra' in runner and 'network.enabled=false' in runner and '--ephemeral' in runner, f'{step}: runner'
    prompt = (d / 'prompt.txt').read_text(encoding='utf-8')
    assert 'commit' not in prompt.lower(), f'{step}: the prompt asks for a commit (the workaround)'
    state = (d / 'git-state.txt').read_text(encoding='utf-8').replace('\r\n', '\n')
    m = re.search(r'^BEFORE ([0-9a-f]{40})\nAFTER ([0-9a-f]{40})$', state, re.M)
    assert m, f'{step}: git-state has no BEFORE/AFTER heads'
    heads[step] = m.groups()
print('PASS  three fresh sessions with exit 0, no prompt asks for a commit')
setup = (ev / 'setup-sha.txt').read_text().strip()
assert heads['init'][0] == setup, 'init did not start at the controller setup commit'
assert heads['init'][1] == heads['add'][0] == setup and heads['add'][1] == setup, 'init or add committed: the backlog must stay uncommitted'
assert heads['continue'][0] == setup, 'something committed between add and continue'
assert heads['continue'][1] != setup, 'continue made no commit'
add_state = (ev / 'add' / 'git-state.txt').read_text(encoding='utf-8')
assert re.search(r'^ ?M TODO\.md$', add_state, re.M), 'after add, TODO.md must be an uncommitted change'
print('PASS  init and add left the backlog uncommitted and nothing was committed before continue')
log = (ev / 'continue' / 'git-state.txt').read_text(encoding='utf-8')
assert re.search(r'chore\(backlog\): claim FEAT-001 on todo/FEAT-001-', log), 'continue did not claim FEAT-001'
assert 'chore(backlog): drain FEAT-001' in log and 'Merge FEAT-001 into main' in log, 'FEAT-001 was not drained and merged'
print('PASS  continue claimed, drained and merged FEAT-001 into main')
assert (ev / 'independent-check-exit.txt').read_text().strip() == '0', 'independent check failed'
assert '14 unique expected targets' in (ev / 'independent-check.log').read_text()
base = (ev / 'baseline.stderr.log').read_text(encoding='utf-8')
final = (ev / 'final-regression.stderr.log').read_text(encoding='utf-8')
assert (ev / 'final-regression-exit.txt').read_text().strip() == '0', 'final regression failed'
nb = int(re.search(r'Ran (\d+) tests', base).group(1)); nf = int(re.search(r'Ran (\d+) tests', final).group(1))
assert nb == 244 and 'skipped=4' in base and nf > nb and 'skipped=4' in final, f'regression {nb} -> {nf}'
st = (ev / 'independent-git-state.txt').read_text(encoding='utf-8').replace('\r\n', '\n')
blob = r['legacy_backlog_blob']
assert f'SOURCE TODO\n{blob}\nLEGACY TODO\n{blob}' in st, 'the legacy backlog was not preserved'
assert 'A\ttests/test_sync_list.py' in st and not re.search(r'^[MD]\ttests/', st, re.M), 'existing tests changed'
print(f'PASS  independent check, regression {nb} -> {nf} tests with the same 4 skips, legacy backlog preserved')
PY
