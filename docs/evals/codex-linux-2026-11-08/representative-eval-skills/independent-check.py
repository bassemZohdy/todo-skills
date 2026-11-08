import hashlib, pathlib, subprocess, sys
root = pathlib.Path('/work')
names = ['eval-orchestrator', 'eval-define', 'eval-analyze', 'eval-discover', 'eval-compare', 'eval-report']
expected = {f'skills/{name}/references/workspace-contract.md' for name in names} | {f'skills/{name}/scripts/eval_calc.py' for name in names} | {'skills/eval-report/scripts/export_report.py', 'skills/eval-report/scripts/report_draft.py'}
def snapshot():
    return {p: hashlib.sha256((root / p).read_bytes()).hexdigest() for p in expected}
def run(*args):
    return subprocess.run([sys.executable, '-I', str(root / 'scripts/sync_shared.py'), *args], cwd=root, text=True, capture_output=True)
before = snapshot()
a, b = run('--list'), run('--list')
assert a.returncode == b.returncode == 0, 'list must exit zero'
lines = a.stdout.splitlines()
assert a.stdout == b.stdout, 'list must be deterministic'
assert len(lines) == len(expected) and set(lines) == expected, 'list must contain each expected target exactly once'
assert before == snapshot(), 'list must not modify target files'
check = run('--check')
assert check.returncode == 0 and check.stdout.strip() == 'in sync', 'check must still report in sync'
assert before == snapshot(), 'check must not modify target files'
print('PASS independent list: 14 unique expected targets, deterministic, no target writes')
print('PASS independent check: in sync, no target writes')