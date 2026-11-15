# Active Backlog

## 🛤️ Lanes

- main: skills, lint, docs and the trial harness of this repository, one agent in order

## 🌳 Task Tree

- [/] **FEAT-129** · P1 · mid · Add an optional helper script `tools/todo-flow.sh` that makes a node's lifecycle commits in one call per step, and keep it only if fresh agents use fewer model calls with it
  - Done when: the pi batch is summarised under docs/evals with a keep-or-reject decision and every child is verified; `bash tests/run.sh`
  - State: attempts 0/3; baseline 331 passing; branch todo/FEAT-129-add-optional-helper-script from main; next: read docs
  - [x] **FEAT-129.1** · mid · `todo-flow.sh start <ID> <baseline>` makes the tree claim, the fast-forward of the base, the branch chain and the start commit as git-flow prescribes, and refuses anything unusual before it changes a file
    - Done when: scratch-repository checks pass for a leaf root, a child of a claimed tree and each refusal; `bash tests/run.sh`
  - [x] **FEAT-129.2** · mid · `todo-flow.sh complete` commits a node and merges it into its parent (a root: refreshes from the base), and `todo-flow.sh drain` writes the CHANGELOG entry, removes the subtree and commits the drain, merging into the base only with `--merge`
    - Done when: scratch-repository checks pass for a child, a leaf root, a parent root with its Includes list and a merge conflict left for recovery; `bash tests/run.sh`
  - [x] **FEAT-129.3** · low · `/todo-continue` uses `.todo/todo-flow.sh` when it exists and works unchanged without it; the core, SECURITY.md and the docs list the script as optional and say what it writes
    - Done when: the skill text names the helper and its fallback, every load budget holds and the docs checks pass; `bash tests/run.sh`
  - [x] **FEAT-129.4** · mid · The trial setup and a benchmark arm can install the helper, and a scripted lifecycle run through the helper passes the existing `happy-path` and `decompose` follow-up assertions unchanged
    - Done when: the selftest and the harness checks pass with the helper switch on and off; `bash tests/run.sh`
  - [x] **FEAT-129.5** · mid · Measure the helper with fresh pi agents against a fresh baseline of the same 18 benchmark cells plus the lifecycle trials, after fitting the helper to what a pilot run shows (one read, an end-state report), and publish the results and the decision
    - Done when: the summary is linked from docs/trials.md, its run rows are in the published table and the token table is regenerated; `bash tests/run.sh`
