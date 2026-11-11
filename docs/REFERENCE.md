# Reference

The formats and rules of the todo-skills. The model reads the rules in [`plugin/skills/todo/SKILL.md`](../plugin/skills/todo/SKILL.md) and its [`reference/`](../plugin/skills/todo/reference/) files; this page is the version for people. New here? Start with [GETTING-STARTED.md](GETTING-STARTED.md). For what each command does, see [COMMANDS.md](COMMANDS.md); for the files involved, [FILES.md](FILES.md).

## TODO.md

```markdown
# Active Backlog

## 🌳 Task Tree

- [ ] **FEAT-002** · P1 · mid · XL · Add token refresh to the auth service
  - Done when: old token rejected after refresh; `npx jest tests/auth`; regression: `npm test`
  - Links: Ref: docs/auth.md#refresh · Depends: TASK-001 · From: FIX-001
  - State: branch todo/FEAT-002-add-token-refresh-auth from main; next: build children
  - [ ] **FEAT-002.1** · mid · L · Refresh endpoint
    - Done when: endpoint covered by an integration test; `npx jest tests/auth/refresh.test.ts`
    - [x] **FEAT-002.1.1** · low · S · Token store interface
      - Done when: store round-trips a token; `npx jest tests/auth/store.test.ts`
    - [/] **FEAT-002.1.2** · high · M · Rotate refresh tokens
      - Done when: reuse of a rotated token fails; `npx jest tests/auth/rotate.test.ts`
      - State: attempts 1/3; baseline 42 passing; branch todo/FEAT-002.1.2-rotate-refresh-tokens from todo/FEAT-002.1-refresh-endpoint; next: build
```

The file is exactly the heading `# Active Backlog` and one section whose heading ends in `Task Tree`. There are no In Progress, Ready or Blocked sections: the marker on each task is its state. An empty tree is the two headings and no tasks. The whole file stays within **120 lines** (about 30 tasks); longer plans go into `docs/` and are linked with `Ref:`.

### A task

A task is 2 to 4 lines: a header and up to three fields.

**Header:** `- [m] **ID** · [P0-P2 · (roots only)] COMPLEXITY [· SIZE] · what to do, in one sentence`

| Part | Rule |
|---|---|
| Marker `[m]` | `[ ]` open, `[/]` active (at most one in the file), `[!]` blocked, `[x]` verified and merged into its parent, waiting for its root to drain |
| Priority | `P0`, `P1` or `P2`, on roots only; children inherit it |
| Complexity | Required: `low`, `mid` or `high` (below) |
| Size | Optional: `S`, `M`, `L` or `XL` (below) |
| `Done when:` | **Required.** Criteria, then `; ` and at least one exact command in backticks. Optional `; regression: \`cmd\``; without it the regression is the project's full suite. Rules: [VERIFICATION.md](VERIFICATION.md#writing-a-done-when) |
| `Links:` | Optional. `Ref: <path#anchor>`, `Depends: <IDs>`, `From: <ID>`, `Lane: <name>` (roots only), separated by ` · ` |
| `State:` | Optional; survives a context reset. Grammar below |
| `Blocked:` | On `[!]` tasks only, in place of `State:`: `<reason> → <command in backticks> <error, at most 5 lines joined with " / "> → <action required>`. A manual block writes `n/a (manual)` in the middle |

Only these four fields exist, and a task never has both `State:` and `Blocked:`. More than 4 lines is design prose: put it in `docs/` and link it.

### State grammar

Items separated by `; `, each at most once, in this order:

| Item | Meaning |
|---|---|
| `attempts n/3` | Failed verification attempts so far |
| `baseline <n> passing`, `baseline none` or `baseline red: <ids>` | The regression result before work started |
| `tier: low\|mid\|high` | Only once escalated above the node's complexity |
| `hyp: <one line>` | The current hypothesis while fixing a failure |
| `branch todo/<ID>-<slug> from <branch>` | The node's branch and the branch it was created from |
| `no git` | No-git mode |
| `files: <paths>`, `docs: <paths>` | Touched files, in no-git mode (a root keeps its finished children's until the drain) |
| `next: <step>` | One of `start <ID>`, `build children`, `read docs`, `plan proposed`, `build`, `drain`, `decompose`, `resume`, `redo after revert` |

A later claim or start **replaces** the whole line. The only exception is no-git mode, where a root keeps the `files:` and `docs:` rolled up from its finished children.

### Tree, levels and sizes

A node at level L has its header indented `2L` spaces and its fields `2L + 2`. At most 3 levels. Child IDs append `.n` to the parent's ID, so the number of dots equals the level.

**Scope rule:** every leaf is one change that fits one context window and touches at most 5 files. Bigger work is split into children. A node too big to split yet carries `State: next: decompose` until `/todo-continue` breaks it down.

| Size | Meaning | Where |
|---|---|---|
| `S` | One change, at most 2 files | Leaf |
| `M` | One context window, at most 5 files | Leaf |
| `L` | Has children, all leaves | Parent |
| `XL` | Has grandchildren | Parent |

Sizes are optional. When present they must match the tree, and adding or dropping a node updates every ancestor's size. A leaf with `next: decompose` may carry `L` or `XL`.

### Complexity and model routing

Complexity says how hard the reasoning is, not how big the change is, so an agent can pick a fitting model.

| Complexity | Meaning | Examples |
|---|---|---|
| `low` | Mechanical: the cause and the change are already known | Rename, docs, config, a guard or small function whose fix the task line states |
| `mid` | Ordinary work that needs some investigation or design (the default) | A new endpoint, a bug whose cause must be found |
| `high` | Hard reasoning or high risk | Concurrency, security, data migration, unclear spec, design across modules, tricky algorithms |

A parent is rated by its integration step alone (usually `low` or `mid`). A one-file race condition is `high`; a five-file rename is `low`.

**Model routing (optional).** A README line such as `Models: low=haiku, mid=sonnet, high=opus` (any names the agent understands) maps levels to models. With that line and a subagent tool, `/todo-continue --delegate` and lane runs give each node a subagent on the mapped model, the reviewer runs at the node's tier or higher, and after a failed attempt the next one runs one tier higher (`low` → `mid` → `high`, recorded as `tier:`). Without either, complexity is only a hint and the work runs in the current model.

## IDs

- Roots are `<PREFIX>-<NNN>`: one global sequence across all prefixes, 3 digits. Children append `.n` (`FEAT-002.1`, `FEAT-002.1.2`) and use their root's prefix.
- IDs are never reused. The next root number is the highest FEAT/FIX/TASK number found in `TODO.md`, `CHANGELOG.md` (IDs after `Includes:` count), `docs/plans/*.md` (dropped IDs are named under Revisions) and, in git mode, every commit subject (`git log --all --format=%s`), plus 1. Child numbers work the same way under their parent.

| Prefix | Meaning | CHANGELOG heading | Commit type |
|---|---|---|---|
| `FEAT` | New capability | `### Added` | `feat` |
| `FIX` | Bug or regression | `### Fixed` | `fix` |
| `TASK` | Refactor, chore, docs, test, perf, build | `### Changed` | Whichever fits |

## Order and the next node

Roots run P0 → P1 → P2, then by ID number (ignoring the prefix); within a root, depth-first in document order. A node is **workable** when it is `[ ]`, all its children are `[x]`, every `Depends:` ID is satisfied (in `CHANGELOG.md`, in the base branch's `CHANGELOG.md`, or `[x]` in `TODO.md`), no ancestor is `[!]`, and, in git mode, its tree is not claimed by another branch. A parent whose children are all `[x]` is workable: that is its **integration step**.

A tree is **claimed** when its root's `State:` in the base branch's `TODO.md` names a branch; it is workable only from a branch of that tree. How claims are made, read and released is in [GIT-FLOW.md](GIT-FLOW.md#tree-claims).

## Lifecycle by status

| Status | `/todo-continue` | `/todo-update` | `/todo-add --parent` |
|---|---|---|---|
| `[ ]` workable | Branch, claim, build, review, verify, complete | `in-progress`, `blocked`, `drop`, edits | Allowed |
| `[ ]` waiting | Skip, say what it waits for | `blocked`, `drop`, edits | Allowed |
| `[ ]` in a tree claimed by another branch | Skip, report the branch | `ready` on the root releases the claim | Refused |
| `[/]` | Resume from `State:` | `ready`, `blocked`, edits; no `drop` | Refused |
| `[!]` | Skip, report `Blocked:` | `ready`, `drop`, edits | Refused |
| `[x]` | Never touch | `revert` only | Refused |

The steps and the diagram are in [LIFECYCLE.md](LIFECYCLE.md).

## CHANGELOG.md

The file follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and is append-only. Only `## [Unreleased]` changes: a root drain inserts one entry there, and the confirmed `/todo-release` renames it to a version, adds a new empty `[Unreleased]` above it and updates the link lines at the end. Released sections are never rewritten.

One entry per finished root, inserted as the first `- ` item of the matching `###` list under `## [Unreleased]`, newest first, with no blank lines between entries. A missing heading is created in Keep a Changelog order (Added, Changed, Deprecated, Removed, Fixed, Security):

```markdown
- **FEAT-002** (feat): Add token refresh to the auth service. Ref: docs/auth.md#refresh. Validated: `npx jest tests/auth`. Docs: updated docs/auth.md. Includes: FEAT-002.1, FEAT-002.1.1, FEAT-002.1.2.
```

Parts in this order, each only when it applies: `Ref:` (the root's), `Validated:` (the root's `Done when` commands, without a `regression:` command), `From:`, `Docs: updated …` (README/`docs/` files the tree changed, backlog files excluded), and last `Includes:` with every descendant ID. Entries written by hand (without an ID) are kept as they are.

## Invariants

Every command checks these first. `.todo/todo-lint.sh` (a copy of [`tools/todo-lint.sh`](../tools/todo-lint.sh)) checks them deterministically; without it the agent checks them by reading.

| # | Invariant |
|---|---|
| I1 | At most one `[/]` task, and a `[/]` parent has no open children |
| I2 | Every ID is unique in `TODO.md` |
| I3 | Each task has a non-vacuous `Done when` with a backticked command, at most 4 lines, only the four fields, no `State:` together with `Blocked:`, a `Blocked:` line on every `[!]`, a priority on roots only, a complexity of `low`, `mid` or `high`, an optional valid size and a title |
| I4 | `TODO.md` is at most 120 lines |
| I5 | No ID is in both `TODO.md` and `CHANGELOG.md` (IDs after `Includes:` count) |
| I6 | The file is exactly `# Active Backlog` plus one `## … Task Tree` section |
| I7 | Every ID in `Depends:` or `From:` exists in `TODO.md` or `CHANGELOG.md` |
| I8 | Tree integrity: child ID = parent ID + `.n`, depth at most 3, even indentation, no `[x]` root, no `[x]` node with open children, and any size matches the tree |
| I9 | No dependency cycles, counting "a parent waits for its children" |
| I10 | No forbidden command in `Done when`: `sudo`, `rm -r`/`-f`, a downloaded script that reaches a shell (piped, even through `tee`; run through `<( )`; or saved and then run), any shell that reads `<( )`, `git push` (also `git -C … push` and `git -c k=v push`), `rm -r`/`-f` also inside `( )`, `$( )` or by absolute path, `git reset --hard`, `git clean`, `chmod -R`, `mkfs`, `dd if=`, `eval`, `exec` (`bundle exec`, `npm exec`, `pnpm exec` are fine), the one-liner code flags of shells and interpreters (`sh -c`, `bash -c`, `python -c`, `node -e`, `ruby -e`, `perl -e`, `php -r`), `find -exec rm`, `find -delete`, publish or upload commands (`npm`/`yarn`/`pnpm`/`cargo`/`poetry publish`, `twine upload`, `gem push`, `docker`/`podman push`, `nuget push`, `mvn deploy`), and reads of credential files (SSH keys, cloud credentials) |

The lint also rejects a `Done when` whose command masks failures (`|| true`, `; true`, `; exit 0`, `&& true`) under I3. A lint failure after an edit means the edit is wrong: the agent fixes or undoes it before it stops. A passing lint does not replace judging a command's safety ([VERIFICATION.md](VERIFICATION.md#command-safety)).

### Warnings

The lint prints `WARN` lines that never change its exit code:

| # | Warns about |
|---|---|
| W1 | A `Done when` that only checks that text or files exist (`grep`, `test -f`) |
| W2 | Tests selected by a name filter, which some runners accept with zero matches; target a test id or path instead |
| W3 | A command that is not a known test, lint, typecheck or build runner; confirm it only tests or builds (the agent records `Checked: <command>` in the node commit) |
| W4 | A test runner piped into another command, which hides its exit status unless `pipefail` is set |
| W5 | An open node that is `high` or whose title names a security subject (auth, login, password, token, secret, credential, permission, session, crypt) and whose criteria name no negative case (rejects, denies, fails, refuses, raises, unauthorized, invalid). A wording heuristic: "author" and "tokenizer" also match, and a negative case covered by a child node still warns on the parent |

## Requirements traceability (optional)

A project that wants requirement → task → test links keeps a table in `docs/RTM.md`, or, when that file is absent, in a `## RTM` section of README (`docs/RTM.md` wins when both exist). No command asks for one, creates one, or fails because it is missing.

```markdown
| Req | Requirement | Tasks | Verification |
|---|---|---|---|
| R-001 | Refresh returns a new token and rejects the old one | FEAT-002, FEAT-002.1 | tests/auth/refresh.test.ts |
```

- **Req** is a stable ID, never renumbered or reused.
- **Tasks** holds task IDs only, never markers, status or copied text: the task's marker in `TODO.md` (or its CHANGELOG entry) is the only state. An ID stays after its task is drained and resolves through `CHANGELOG.md`.
- **Verification** names the test files or ids that prove the requirement. It may be empty while the tasks are open.

`/todo-plan` and `/todo-add` link a root with `Ref: docs/RTM.md#R-001` and propose the row change in the same confirmation; `/todo-continue` adds the node's test paths to Verification in the node's commit; a dropped ID is removed from Tasks in the same change. `bash tools/todo-rtm.sh` checks the table ([TOOLS.md](TOOLS.md#todo-rtmsh)).

## Definition of Done (optional)

If `README.md`, `CONTRIBUTING.md` or a file in `docs/` has a heading named exactly `Definition of Done` followed by a list, every item applies to every node on top of its `Done when`. Command items run under the command safety rules; statements are checked by inspection and reported one by one. A missing item blocks the node.

## Versioning

This project follows [Semantic Versioning](https://semver.org/). The public interface is what an existing project depends on: the `TODO.md` and `CHANGELOG.md` formats, the command names and flags, the `State:` grammar, the invariants the lint enforces, and the script exit codes.

- **MAJOR** when a valid `TODO.md` or `CHANGELOG.md` can become invalid, a command or flag changes meaning or is removed, or an invariant gets stricter in a way old files fail. While the version is `0.x`, such changes bump MINOR.
- **MINOR** for a new command, flag, optional field, warning or script that existing valid files still pass.
- **PATCH** for wording fixes, bug fixes and documentation.

The version lives in `plugin/.claude-plugin/plugin.json` and `plugin/.codex-plugin/plugin.json` and must equal the newest `## [X.Y.Z]` heading in `CHANGELOG.md` (`tests/run.sh` checks this; Codex caches an install by version, so bump it on every release). Releases are cut with `/todo-release` and tagged by a person ([DEVELOPMENT.md](DEVELOPMENT.md#releasing-this-repository)).

## Design rules

- The repository is the state machine. Nothing outside the project's files and git stores state.
- One active task at a time, enforced by file state.
- A node closes only when its `Done when` command and the regression run pass. A run that executes zero tests does not count.
- Nothing reaches the base branch before its root is verified. The base receives only tree claims, claim releases, the confirmed release commit and the merge of a verified root.
- Backlog changes come only from a user command or a completed code transition. The agent never invents tasks; adjacent findings are returned as ready-to-run `/todo-add "…" --from <ID>` commands.
- `Done when` commands are limited to test, lint, typecheck and build commands, because `TODO.md` text can be influenced by docs and pull requests.
- Nothing is required beyond Markdown. Git is used when present. The skills never tag, release on their own, fetch, pull or push; sharing is git's job.

## Issue reconciliation

- [Issue #11](https://github.com/bassemZohdy/todo-skills/issues/11) asks for the TASK-007 submission date and reference. Both are recorded in [distribution.md](distribution.md); TASK-007 is archived in CHANGELOG.md. Closed as satisfied. Review comments from the directory become new backlog tasks when they arrive.
- [Issue #5](https://github.com/bassemZohdy/todo-skills/issues/5) proposed progress bars in the backlog. Decided and built as FEAT-042: the bars appear only in the read-only views (`todo-lint.sh --progress`, `/todo-status` and the `docs/status.html` KPIs), and progress is never written to `TODO.md`. The format, I6 and the invariants are unchanged, and no new invariant is added. Progress counts leaves; `!` cells mark blocked leaves; the overall line also counts the roots drained into `[Unreleased]`. The definition is in [TOOLS.md](TOOLS.md#todo-lintsh).
