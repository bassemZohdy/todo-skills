#!/usr/bin/env bash
# Verify the recorded Linux Codex trials without running an agent or accessing its credentials.
set -eu
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/../.." && pwd)"
ev="$root/docs/evals/codex-linux-2026-11-08"
source_commit=3a8b215ef3fc1b06ec2759d700151ee944000043

git -C "$root" cat-file -e "$source_commit^{commit}"
git -C "$root" merge-base --is-ancestor "$source_commit" HEAD
bash "$here/test-codex-evidence.sh" "$ev"

python3 - "$ev" "$here/prompt.sh" "$source_commit" <<'PY'
import json
import pathlib
import re
import subprocess
import sys

ev = pathlib.Path(sys.argv[1])
prompt_script, source_commit = sys.argv[2:]
results = json.loads((ev / 'results.json').read_text(encoding='utf-8'))
assert results['project_commit'] == source_commit, 'tested source commit changed'
assert results['agent'] == 'codex-cli 0.167.0' and results['model'] == 'gpt-6.1-terra'
assert results['trust'] == 'provisional'
assert len(results['scenarios']) == 8

ids = []
checks = 0
for scenario in results['scenarios']:
    name = scenario['scenario']
    run = ev / 'runs' / name
    assert scenario['outcome'] == 'PASS' and scenario['agent_exit'] == scenario['assert_exit'] == 0
    lines = (run / 'assert.log').read_text(encoding='utf-8').splitlines()
    passes = sum(line.startswith('PASS  ') for line in lines)
    failures = sum(line.startswith('FAIL  ') for line in lines)
    assert (passes, failures) == (scenario['assertions_passed'], scenario['assertions_failed'])
    checks += passes
    assert subprocess.check_output(['bash', prompt_script, '/work', name]) == (run / 'prompt.txt').read_bytes()
    events = [json.loads(line) for line in (run / 'session.log').read_text(encoding='utf-8').splitlines() if line]
    assert next(e['thread_id'] for e in events if e['type'] == 'thread.started') == scenario['session_id']
    assert any(e['type'] == 'turn.completed' for e in events)
    assert '-m gpt-6.1-terra' in (run / 'runner.sh').read_text(encoding='utf-8')
    assert re.fullmatch(r'[0-9a-f]{40}', scenario['initial_commit'])
    ids.extend(scenario['session_ids'])
    if name in ('ts-lifecycle', 'java-lifecycle'):
        assert len(scenario['session_ids']) == 3
        for number, session_id in enumerate(scenario['session_ids'], 1):
            invocation = run / 'invocations' / str(number)
            first = json.loads((invocation / 'codex.jsonl').read_text(encoding='utf-8').splitlines()[0])
            assert first['thread_id'] == session_id
            assert (invocation / 'prompt.txt').read_bytes() == (run / 'prompt.txt').read_bytes()
            assert (invocation / 'agent-exit.txt').read_text().strip() == '0'
            assert 'exactly one /todo-continue invocation' in (invocation / 'runner.sh').read_text()
assert checks == 105 and len(ids) == len(set(ids)) == 12
print('PASS  eight exact prompts, 105 assertion lines and 12 distinct sessions')

expected = {'todo', 'todo-add', 'todo-continue', 'todo-init', 'todo-plan',
            'todo-release', 'todo-report', 'todo-status', 'todo-update'}
for mode in ('without-tools', 'with-tools'):
    install = ev / 'installations' / mode
    discovery = install / 'discovery'
    task = install / 'task'
    assert (discovery / 'agent-exit.txt').read_text().strip() == '0'
    assert (task / 'agent-exit.txt').read_text().strip() == '0'
    assert (task / 'assert-exit.txt').read_text().strip() == '0'
    messages = [json.loads(line) for line in (discovery / 'codex.jsonl').read_text(encoding='utf-8').splitlines() if line]
    discovery_id = next(e['thread_id'] for e in messages if e['type'] == 'thread.started')
    text = ' '.join(e['item']['text'] for e in messages if e.get('type') == 'item.completed' and e.get('item', {}).get('type') == 'agent_message')
    names = set(re.findall(r'(?<![a-z-])todo(?:-[a-z]+)?(?![a-z-])', text))
    assert expected <= names
    assert sum(line.startswith('PASS  ') for line in (task / 'assert.log').read_text().splitlines()) == 12
    events = [json.loads(line) for line in (task / 'codex.jsonl').read_text(encoding='utf-8').splitlines() if line]
    task_id = next(e['thread_id'] for e in events if e['type'] == 'thread.started')
    ids.extend((discovery_id, task_id))
    if mode == 'with-tools':
        assert any(e.get('type') == 'item.completed' and e.get('item', {}).get('exit_code') == 0 and 'bash .todo/check.sh' in e['item'].get('command', '') for e in events)
print('PASS  both installations discovered nine skills and completed their checks')

rep = ev / 'representative-eval-skills'
metadata = results['representative_project']
assert metadata['outcome'] == 'PASS_WITH_WORKAROUND'
assert metadata['source_commit'] == '1d4040b6584c94ae7143534911835f5b9053d3de'
assert len(set(metadata['sessions'].values())) == 4
for name, session_id in metadata['sessions'].items():
    first = json.loads((rep / name / 'codex.jsonl').read_text(encoding='utf-8').splitlines()[0])
    assert first['thread_id'] == session_id
    assert (rep / name / 'agent-exit.txt').read_text().strip() == '0'
    ids.append(session_id)
assert len(ids) == len(set(ids)) == 20
assert (rep / 'independent-check-exit.txt').read_text().strip() == '0'
assert (rep / 'final-regression-exit.txt').read_text().strip() == '0'
assert '14 unique expected targets' in (rep / 'independent-check.log').read_text()
baseline = (rep / 'baseline.stderr.log').read_text(encoding='utf-8')
final = (rep / 'final-regression.stderr.log').read_text(encoding='utf-8')
assert 'Ran 244 tests' in baseline and 'skipped=4' in baseline
assert 'Ran 246 tests' in final and 'skipped=4' in final
state = (rep / 'independent-git-state.txt').read_text(encoding='utf-8')
blob = metadata['legacy_backlog_blob']
assert f'SOURCE TODO\n{blob}\nLEGACY TODO\n{blob}' in state.replace('\r\n', '\n')
assert 'A\ttests/test_sync_list.py' in state and not re.search(r'^M\ttests/', state, re.M)
print('PASS  existing-project behavior, regression, legacy backlog and workaround evidence')
PY
