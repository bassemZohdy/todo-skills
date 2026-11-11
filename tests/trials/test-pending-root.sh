#!/usr/bin/env bash
# FIX-035: pending backlog roots survive claim publication and competing claims.
set -eu
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
python3 - "$root" <<'PY'
import pathlib
import subprocess
import sys
import tempfile
import unittest

root = pathlib.Path(sys.argv[1])
sys.argv = sys.argv[:1]


def git(repo, *args, check=True):
    return subprocess.run(['git', '-c', 'user.name=trial', '-c', 'user.email=trial@example.invalid',
                           '-C', str(repo), *args], text=True, capture_output=True, check=check)


class PendingRootTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.repo = pathlib.Path(self.tmp.name)
        git(self.repo, 'init', '-q', '-b', 'main')
        (self.repo / 'TODO.md').write_text('# Active Backlog\n\n## Task Tree\n', encoding='utf-8')
        (self.repo / 'README.md').write_text('baseline\n', encoding='utf-8')
        git(self.repo, 'add', 'TODO.md', 'README.md')
        git(self.repo, 'commit', '-qm', 'init')
        self.pending = '# Active Backlog\n\n## Task Tree\n- [ ] **FEAT-001** · P1 · low · New task\n  - Done when: covered; `python3 tests/test_feature.py`\n'
        (self.repo / 'TODO.md').write_text(self.pending, encoding='utf-8')

    def claim(self):
        git(self.repo, 'switch', '-qc', 'todo/FEAT-001-new-task')
        with (self.repo / 'TODO.md').open('a', encoding='utf-8') as f:
            f.write('  - State: branch todo/FEAT-001-new-task from main; next: start FEAT-001\n')
        git(self.repo, 'add', 'TODO.md')
        git(self.repo, 'commit', '-qm', 'chore(backlog): claim FEAT-001 on todo/FEAT-001-new-task')
        git(self.repo, 'switch', '-q', 'main')

    def test_normal_claim_publishes_pending_root_without_prior_commit(self):
        self.claim()
        git(self.repo, 'merge', '--ff-only', 'todo/FEAT-001-new-task')
        self.assertIn('**FEAT-001**', git(self.repo, 'show', 'main:TODO.md').stdout)
        self.assertEqual(git(self.repo, 'log', '--format=%s', '-1').stdout.strip(),
                         'chore(backlog): claim FEAT-001 on todo/FEAT-001-new-task')

    def test_competing_claim_keeps_rival_and_pending_work(self):
        self.claim()
        (self.repo / 'TODO.md').write_text(self.pending + '  - State: branch todo/FEAT-001-rival from main; next: start FEAT-001\n', encoding='utf-8')
        git(self.repo, 'add', 'TODO.md')
        git(self.repo, 'commit', '-qm', 'chore(backlog): rival claim')
        rival = git(self.repo, 'rev-parse', 'main').stdout.strip()
        self.assertNotEqual(git(self.repo, 'merge', '--ff-only', 'todo/FEAT-001-new-task', check=False).returncode, 0)
        self.assertEqual(git(self.repo, 'rev-parse', 'main').stdout.strip(), rival)
        self.assertIn('todo/FEAT-001-rival', git(self.repo, 'show', 'main:TODO.md').stdout)
        self.assertIn('todo/FEAT-001-new-task', git(self.repo, 'show', 'todo/FEAT-001-new-task:TODO.md').stdout)
        self.assertIn('New task', git(self.repo, 'show', 'todo/FEAT-001-new-task:TODO.md').stdout)

    def test_unrelated_base_advance_rebases_the_claim(self):
        self.claim()
        (self.repo / 'README.md').write_text('baseline\nrival note\n', encoding='utf-8')
        git(self.repo, 'add', 'README.md')
        git(self.repo, 'commit', '-qm', 'docs: unrelated update')
        self.assertNotEqual(git(self.repo, 'merge', '--ff-only', 'todo/FEAT-001-new-task', check=False).returncode, 0)
        git(self.repo, 'rebase', 'main', 'todo/FEAT-001-new-task')
        git(self.repo, 'switch', '-q', 'main')
        git(self.repo, 'merge', '--ff-only', 'todo/FEAT-001-new-task')
        self.assertIn('rival note', (self.repo / 'README.md').read_text(encoding='utf-8'))
        self.assertIn('todo/FEAT-001-new-task', (self.repo / 'TODO.md').read_text(encoding='utf-8'))

    def test_skill_allows_pending_root_and_preserves_non_bare_claim(self):
        instructions = (root / 'plugin/skills/todo-continue/SKILL.md').read_text(encoding='utf-8')
        flow = ''.join((root / 'plugin/skills/todo/reference' / name).read_text(encoding='utf-8') for name in ('git-flow.md', 'git-flow-edge.md'))
        self.assertIn('uncommitted root on the base', instructions)
        self.assertIn('preserve the pending backlog', flow)


if __name__ == '__main__':
    unittest.main(verbosity=2)
PY
