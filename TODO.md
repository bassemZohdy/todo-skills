# Active Backlog

## 🌳 Task Tree

- [ ] **TASK-073** · P1 · mid · Add static analysis for the shell code: about 3,900 lines in tools/, tests/ and tests/trials/ have no shellcheck run, and five of the six tools set neither -e nor -u; add a CI step and fix or annotate what it reports
  - Done when: test.yml runs shellcheck over tools, tests and .todo, run.sh runs it when installed, and a seeded unquoted-variable finding fails it; `bash tests/run.sh`
  - State: next: decompose
- [ ] **TASK-075** · P1 · mid · Record real runs of the agent benchmark: docs/evals/benchmark has six scenarios and three arms but results.csv holds only its header, so COMPARISON.md still rests on reviewer estimates made for 0.2.0
  - Done when: results.csv has a row per arm and scenario with checksummed evidence, and a row whose evidence is missing fails the harness check; `bash tests/trials/test-benchmark-harness.sh`
- [ ] **TASK-085** · P2 · mid · Slim what an install clones, after the owner picks the target: docs/evals holds 1,643 of the 1,839 tracked files (12 MB, 1,366 of them raw run logs and diagnostics) and every marketplace install or npx skills add clones them; keep summaries and results on main and move raw runs to a separate branch or release assets
  - Done when: tracked files under docs/evals fall below the agreed count, every README and docs link still resolves, and a dangling evidence link fails the check; `bash tests/run.sh`
  - State: next: decompose
- [ ] **TASK-086** · P2 · mid · Add resume and regression-failure trial variants outside Python: ts-lifecycle, java-lifecycle and multi-module have no red-baseline or interrupted-run scenario (docs/trials.md, limits)
  - Done when: selftest sets up a red-baseline and an interrupted variant for TypeScript and for Java, and doing nothing fails each; `bash tests/trials/selftest.sh`
- [ ] **TASK-087** · P2 · mid · Widen the Claude Code evidence: every recorded batch ran on Windows 11 with Git Bash, none on Linux or macOS, and no Claude Code lane run has the worker-activity records that prove concurrency (docs/agent-compatibility.md)
  - Done when: a dated docs/evals folder holds a checksummed Linux or macOS batch that agent-compatibility.md cites, and a lane run without worker-activity records fails to read as concurrent; `bash tests/trials/test-lane-evidence.sh`
- [ ] **FEAT-088** · P2 · mid · L · Stamp the copied scripts with their release: users copy tools/*.sh by hand and nothing says which version a copy is, and a release needs hand edits in three places (0.4.0 took a separate manifest-bump commit, 8b5a2fd); add a version line and a --version flag to each tool and one helper that sets the manifests, README and stamps together
  - Done when: run.sh fails when a tool's stamp, either manifest or the newest CHANGELOG heading disagree, and each tool prints its version; `bash tests/run.sh`
  - State: branch todo/FEAT-088-stamp-copied-scripts-their from main; next: build children
  - [/] **FEAT-088.1** · low · S · Stamp todo-lint.sh and its vendored copy with the release version and a --version flag, and check the stamp against both manifests and the newest CHANGELOG heading
    - Done when: todo-lint.sh --version prints the manifest version and a stamp that disagrees with the manifests fails the check; `bash tests/run.sh`
    - State: attempts 0/3; baseline 239 passing; branch todo/FEAT-088.1-stamp-todo-lint-sh from todo/FEAT-088-stamp-copied-scripts-their; next: read docs
  - [ ] **FEAT-088.2** · low · S · Stamp the other five tools (verify, rtm, replay, report, stop-hook) the same way and require every script in tools to be stamped
    - Done when: each tool prints its version, and an unstamped script in tools fails the check; `bash tests/run.sh`
  - [ ] **FEAT-088.3** · mid · S · Add tests/set-version.sh, one helper that sets both manifests, the README version statements and the stamps, and name it in the release steps
    - Done when: the helper run on a scratch copy of the repository makes the version check pass for a new version and refuses a malformed one; `bash tests/run.sh`
- [ ] **TASK-091** · P2 · mid · Add a two-clone claim scenario to the trial harness: team use is unverified (README Status) and every claim trial runs in one clone; use a bare remote and two clones whose claims and new root IDs collide after a pull
  - Done when: selftest sets up the scenario with its bare remote and doing nothing fails it; `bash tests/trials/selftest.sh`
