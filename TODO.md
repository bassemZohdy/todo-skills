# Active Backlog

## 🌳 Task Tree

- [ ] **TASK-119** · P1 · low · Publish the token cost of a todo-skills run split into the parts a reader can act on: uncached input, cached input and output per arm, one-time setup (todo-init and todo-add, calls before the first branch) against per-node work, and calls by activity (git, backlog files, tests, skill reads) with counts only and no tool output text (the 2026-11-12 medians: 1.04M input tokens against 41K for no methodology, 95 percent cached, 18.3K output tokens against 1.7K)
  - Done when: tests/benchmark/README.md links a dated breakdown that quotes only numbers recomputable from docs/evals/benchmark/results/results.csv and marks every figure that needed the raw logs, which stay off GitHub, as measured locally, labels any money figure as computed from published pricing with its date, and holds no profile name, mail address or tool output text, and tests/run.sh fails on a copy that adds a mail address; `bash tests/run.sh`
  - Links: Ref: docs/evals/pi-glm-2026-11-13-load-cut/summary.md#cost-what-the-cut-changed · From: TASK-110
- [ ] **TASK-120** · P1 · mid · Cut the model calls of a node by batching its lifecycle steps in the skill text, with no new script: one shell command block for claim, fast-forward of the base and start, and one for drain and merge, with the commit subjects and bodies unchanged (git and backlog-file calls were 74 of 162 calls and about 53 percent of input tokens in the six runs of 2026-11-13, and the logs predict at most about 40 percent fewer input tokens if those calls shrink to four per node)
  - Done when: todo-continue or a reference file it names gives each of the two blocks and tests/run.sh pins them, the 34 trial scenarios still set up and fail on an untouched repository, and a fresh pi benchmark of the six scenarios records fewer median model calls than the 31 of 2026-11-13; `bash tests/run.sh`
  - Links: Ref: docs/evals/pi-glm-2026-11-13-load-cut/summary.md#cost-what-the-cut-changed · Depends: TASK-119 · From: TASK-110
- [ ] **TASK-121** · P1 · high · Publish only the results of a test run, never its evidence: docs/evals keeps one summary.md per batch and the results CSV files, and the per-run folders (prompts, session logs, Git state, checksums, about 12 MB in 2,900 files) leave the repository and stay on the machine that ran them (the six tests that verify committed evidence go with them, and the benchmark publisher stops requiring an evidence folder)
  - Done when: docs/evals/README.md states the rule, every link in README.md and docs reaches a file that exists, and tests/run.sh fails on a copy that adds another file type under docs/evals or a link to a missing file; `bash tests/run.sh`
  - Links: Ref: tests/benchmark/README.md · From: TASK-119
  - State: branch todo/TASK-121-results-only from main; next: build children
  - [x] **TASK-121.1** · mid · Move the benchmark harness (arms, scenarios, hidden, run.sh, publish.sh, summarize.sh, usage.sh, verify.sh, agents and its README) from docs/evals/benchmark to tests/benchmark, leaving results/ where it is, because tests do not belong under docs
    - Done when: tests/benchmark/run.sh exists, docs/evals/benchmark holds only results/, and no file in the repository names the old harness path; `bash tests/trials/test-benchmark-harness.sh`
  - [/] **TASK-121.2** · mid · Make the benchmark publisher independent of evidence folders: publish.sh add and check read only the CSV files, and results.csv drops evidence_dir and keeps evidence_sha256 as the identity of the archive kept on the machine that ran it
    - Done when: publish.sh check passes on results.csv with no evidence folder on disk and fails on a row without evidence_sha256; `bash tests/trials/test-benchmark-harness.sh`
    - Links: Depends: TASK-121.1
    - State: attempts 0/3; baseline 252 passing; branch todo/TASK-121.2-publisher-without-evidence from todo/TASK-121-results-only; next: read docs
  - [ ] **TASK-121.3** · low · Delete the six tests that verify committed evidence (test-codex-evidence.sh, test-linux-codex-evidence.sh, test-windows-codex-evidence.sh, test-fix-evidence.sh, test-existing-project-evidence.sh, test-lane-concurrency-evidence.sh) and their rows in tests/trials/README.md
    - Done when: none of the six files exists and tests/trials/README.md names none of them; `bash tests/run.sh`
  - [ ] **TASK-121.4** · low · Point README.md, docs/trials.md and tests/trials/README.md at summary.md files and results CSV files instead of evidence folders
    - Done when: none of the three links into docs/evals other than a summary.md, a results CSV or the policy README; `bash tests/run.sh`
    - Links: Depends: TASK-121.3
  - [ ] **TASK-121.5** · low · Point docs/agent-compatibility.md, docs/COMPARISON.md, docs/DEVELOPMENT.md and docs/distribution.md at summary.md files and results CSV files instead of evidence folders
    - Done when: none of the four links into docs/evals other than a summary.md, a results CSV or the policy README; `bash tests/run.sh`
    - Links: Depends: TASK-121.3
  - [ ] **TASK-121.6** · mid · Remove the per-run folders under docs/evals with a script (about 2,900 files, one mechanical change) and turn links to them inside the summaries into plain text
    - Done when: git ls-files docs/evals lists only Markdown and CSV files and every link inside docs/evals resolves, and tests/run.sh fails on a copy that adds another file type; `bash tests/run.sh`
    - Links: Depends: TASK-121.1, TASK-121.2, TASK-121.4, TASK-121.5
- [ ] **TASK-087** · P2 · mid · Widen the Claude Code evidence: every recorded batch ran on Windows 11 with Git Bash, none on Linux or macOS, and no Claude Code lane run has the worker-activity records that prove concurrency (docs/agent-compatibility.md)
  - Done when: a dated docs/evals folder holds a checksummed Linux or macOS batch that agent-compatibility.md cites, and a lane run without worker-activity records fails to read as concurrent; `bash tests/trials/test-lane-evidence.sh`
- [ ] **TASK-116** · P2 · mid · Rerun the trial scenarios on the revised skill text with Codex: on this Windows host Codex cannot run python3 in its sandbox (probe of 2026-11-13 stopped at the baseline), and a Linux run needs a container with Codex set up in it
  - Done when: a dated docs/evals folder holds a checksummed Codex batch on the revised text that docs/trials.md and docs/agent-compatibility.md cite; `bash tests/run.sh`
  - Links: From: TASK-112
