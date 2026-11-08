#!/usr/bin/env bash
# TASK-044: verify the recorded concurrent Codex lane trial without running an agent or touching its login.
# run-codex-lanes.sh ran `multi-module`: a fresh coordinator, then one fresh Codex process per lane started at the same
# time, then a fresh finishing coordinator. This checks the hashes, the sessions, each worker's write roots, recomputes
# every worker's activity from its own stamped event stream, and asks lane-evidence.sh for the verdict.
# Usage: bash tests/trials/test-lane-concurrency-evidence.sh [<evidence-dir>]
set -eu
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/../.." && pwd)"
pub="${1:-$root/docs/evals/lanes-codex-2026-11-08}"
[ -d "$pub" ] || { echo "FAIL  no evidence folder: $pub"; exit 1; }
check() { (cd "$1" && if command -v sha256sum >/dev/null 2>&1; then sha256sum -c --quiet SHA256SUMS; else shasum -a 256 -c --quiet SHA256SUMS; fi) \
  || { echo "FAIL  checksum mismatch in $1"; exit 1; }; }
check "$pub"
run="$pub/run"; check "$run"
echo "PASS  the published and the run's own checksums verify"
ctl="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["controller_commit"])' "$pub/results.json")"
git -C "$root" cat-file -e "$ctl^{commit}" && git -C "$root" merge-base --is-ancestor "$ctl" HEAD \
  || { echo "FAIL  controller commit $ctl is not in this history"; exit 1; }
echo "PASS  the controller commit $ctl is an ancestor of HEAD"
git -C "$root" show "$ctl:tests/trials/run-codex-lanes.sh" | cmp -s - "$pub/run-codex-lanes.sh" \
  || { echo "FAIL  run-codex-lanes.sh differs from the controller commit"; exit 1; }
echo "PASS  the published runner is the one at the controller commit"

python3 - "$pub" <<'PY'
import json, pathlib, re, sys
pub = pathlib.Path(sys.argv[1]); run = pub / 'run'
r = json.loads((pub / 'results.json').read_text(encoding='utf-8'))
assert r['agent'] == 'codex-cli 0.167.0' and r['model'] == 'gpt-6.1-terra', 'agent or model changed'
assert r['scenario'] == 'multi-module' and r['outcome'] == 'PASS' and r['execution'] == 'concurrent', 'recorded verdict'
assert (run / 'outcome.txt').read_text().strip() == 'PASS', 'outcome.txt'
assert (run / 'execution.txt').read_text().strip() == 'concurrent', 'execution.txt'
assert (run / 'assert-exit.txt').read_text().strip() == '0', 'assertions'
alog = (run / 'assert.log').read_text(encoding='utf-8')
assert 'FAIL' not in alog and re.search(r'^\d+ passed, 0 failed', alog, re.M), 'assert.log'

def events(d):
    out = []
    for line in (d / 'events.log').read_text(encoding='utf-8').splitlines():
        t, _, e = line.partition(' ')
        out.append((float(t), json.loads(e)))
    return out

agents = {'coordinate': run / 'coordinate', 'finish': run / 'finish'}
accepted = [l.split() for l in (run / 'dispatch.txt').read_text(encoding='utf-8').splitlines() if l.startswith('accepted ')]
assert len(accepted) == 2 and sorted(a[3] for a in accepted) == ['core', 'text'], f'dispatch: {accepted}'
for a in accepted:
    agents[a[1]] = run / 'lanes' / a[1]
sessions = {}
for name, d in agents.items():
    ev = events(d)
    assert (d / 'agent-exit.txt').read_text().strip() == '0', f'{name}: agent exit'
    sid = next(e['thread_id'] for _, e in ev if e['type'] == 'thread.started')
    assert sid == (d / 'session-id.txt').read_text().strip(), f'{name}: session id'
    assert any(e['type'] == 'turn.completed' for _, e in ev), f'{name}: turn did not complete'
    fs = re.search(r'^filesystem: \{(.*)\}$', (d / 'command.txt').read_text(encoding='utf-8'), re.M).group(1)
    roots = dict(re.findall(r'"([^"]+)"="(\w+)"', fs))
    assert roots.get(':root') == 'read' and all(roots.get(p) == 'deny' for p in ('/root/.codex', '/controller', '/runs/multi-module/evidence')), f'{name}: denials'
    cmd = (d / 'command.txt').read_text(encoding='utf-8')
    assert 'network.enabled=false' in cmd and '--ephemeral' in cmd and 'gpt-6.1-terra' in cmd, f'{name}: command'
    sessions[name] = (sid, ev, {p for p, m in roots.items() if m == 'write'})
assert len({s[0] for s in sessions.values()}) == 4, 'four distinct fresh sessions expected'
repo = '/runs/multi-module/repo'
for name in ('coordinate', 'finish'):
    assert sessions[name][2] == {repo, repo + '/.git', repo + '.todo'}, f'{name}: write roots'
print('PASS  four fresh sessions (coordinator, two lane workers, finishing coordinator) with exit 0 and the trial profile')

tool = ('command_execution', 'file_change')
activity = {}
for _, rid, _, lane, *_ in accepted:
    sid, ev, writes = sessions[rid]
    assert writes == {f'{repo}.todo/{rid}', repo + '/.git', f'{repo}/.git/worktrees/{rid}'}, f'{rid}: write roots {writes}'
    starts = [t for t, e in ev if e['type'] == 'item.started' and e.get('item', {}).get('type') in tool]
    ends = [t for t, e in ev if e['type'] == 'item.completed' and e.get('item', {}).get('type') in tool]
    activity[sid] = (lane, min(starts), max(ends), len(ends))
    others = [a[1] for a in accepted if a[1] != rid]
    done = [e['item'] for _, e in ev if e['type'] == 'item.completed' and e.get('item', {}).get('type') in tool]
    paths = [c['path'] for it in done if it['type'] == 'file_change' for c in it.get('changes', [])]
    assert paths and all(p.startswith(f'{repo}.todo/{rid}/') for p in paths), f'{rid}: a file change outside its worktree'
    assert not any(f'repo.todo/{o}' in it['command'] for it in done if it['type'] == 'command_execution' for o in others), \
        f'{rid}: a command names another lane worktree'
    assert any('mvn' in it['command'] for it in done if it['type'] == 'command_execution'), f'{rid}: the worker ran no Maven build'
recorded = {}
for line in (run / 'activity.txt').read_text(encoding='utf-8').splitlines():
    sid, lane, s, e = line.split()
    recorded[sid] = (lane, float(s), float(e))
assert set(recorded) == set(activity), 'activity.txt sessions differ from the worker streams'
for sid, (lane, s, e, n) in activity.items():
    assert recorded[sid] == (lane, s, e), f'{sid}: activity.txt does not match its event stream'
(a, b) = activity.values()
overlap = min(a[2], b[2]) - max(a[1], b[1])
assert overlap > 0, 'worker activity does not overlap'
launch = [float(l.split()[0]) for l in (run / 'launches.txt').read_text().splitlines()]
assert len(launch) == 2 and max(launch) < min(a[2], b[2]), 'a worker was launched after the other had finished'
print(f'PASS  activity recomputed from both worker streams matches activity.txt; '
      f'{a[3]} and {b[3]} tool events, overlapping for {overlap:.0f} s')
after = (run / 'after-lanes-git-state.txt').read_text(encoding='utf-8')
for _, rid, *_ in accepted:
    assert re.search(rf'todo/{rid}-\S+', after), f'{rid}: no root branch after the lanes'
final = (run / 'git-state.txt').read_text(encoding='utf-8')
assert 'Merge FEAT-001 into main' in final and 'Merge FEAT-002 into main' in final, 'roots not merged'
print('PASS  both lane roots were built in their worktrees, then drained and merged by the finishing coordinator')
PY
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
git init -q "$tmp/repo"
verdict="$(bash "$here/lane-evidence.sh" "$tmp/repo" "$run/activity.txt" | sed -n 's/^execution: //p')"
[ "$verdict" = concurrent ] || { echo "FAIL  lane-evidence.sh says $verdict"; exit 1; }
echo "PASS  lane-evidence.sh reports execution: concurrent from the recorded worker activity"
