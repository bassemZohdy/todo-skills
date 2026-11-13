# Commands

Every command, its flags, what it does step by step, when it stops, and what it writes and commits. The model follows the `SKILL.md` files in [`plugin/skills/`](../plugin/skills/); this page is the readable summary. Formats are in [REFERENCE.md](REFERENCE.md) and the file map is in [FILES.md](FILES.md).

Common to all commands:

- Each command first loads the `todo` core skill, checks for git (`git rev-parse --is-inside-work-tree`) and runs the invariant check (the lint, `.todo/todo-lint.sh` when it exists, otherwise by reading). Outside a git repository it warns once and runs in [no-git mode](GIT-FLOW.md#no-git-mode).
- A command runs only itself and never chains into another unprompted.
- On an invariant violation a command reports it, changes nothing and asks. The one repair: a writing command (`/todo-continue`, `/todo-add`, `/todo-update`, `/todo-plan`) deletes a subtree from `TODO.md` when its IDs are exactly the root and `Includes:` IDs of one CHANGELOG entry (a drain that was interrupted), and says so.
- When a rule conflicts with an explicit instruction from you, the agent states the conflict and asks.
- In Claude Code with the plugin, commands are namespaced (`/todo-skills:todo-add`). In Codex, start them with `$todo-add` or plain language.

## `/todo`

The core rules. Run directly it is read-only: it lists the commands, runs the invariant check on `TODO.md` if it exists, and reports. The other commands load it for the task format, complexity, IDs, git mode, invariants and guardrails.

## `/todo-init [--plan] [--ci]`

Sets up or checks the backlog workspace. Idempotent: run it again at any time.

1. Checks git. Outside a repository it says the skills will run in no-git mode; it runs `git init` only if you ask.
2. Looks for `README.md`, `docs/`, `TODO.md` and `CHANGELOG.md`, and creates only what is missing: `TODO.md` with its two headings, `CHANGELOG.md` with the Keep a Changelog intro and `## [Unreleased]`. A `CHANGELOG.md` without `[Unreleased]` gets that heading above the newest version and nothing else. New files stay uncommitted (they are backlog files).
3. Never overwrites an existing `TODO.md`:
   - **Old three-section format** (In Progress, Ready, Blocked; Scope, Out of Scope, Validation, Progress): offers a migration to roots of the task tree. Complexity is rated (`mid` when unsure), every `Done when` must pass lint before anything is written, and each Out of Scope item is moved into a `docs/` note or dropped only as you decide.
   - **Size-only format** (`· S ·` where the complexity now goes): offers to insert a complexity before each size.
   - **Anything else** (a free-form list): offers to move it aside to `TODO.legacy.md`.
4. Never creates `README.md` or `docs/`; reports them as missing.
5. Detects the runtime, package manager and test command. Precedence: the README `Tests:` line, a command stated in README or CONTRIBUTING, the CI config's command, then the first marker file that matches (`pom.xml` → `mvn test`, `build.gradle` → `./gradlew test`, `package.json` with a test script → `pnpm`/`yarn`/`bun`/`npm test` by lockfile, `Cargo.toml` → `cargo test`, Python markers → `uv run pytest` or `pytest`, `go.mod` → `go test ./...`, `.csproj`/`.sln` → `dotnet test`, `Gemfile` → `bundle exec rspec` or `rake test`, a `Makefile` test target → `make test`). It names the source, reports the command CI runs and flags a mismatch. Unknown: it asks once and never invents one. It offers to add `Tests: <command>` to README so every later run uses the same command. It does not run the suite.
6. Reports the base branch (offering a README `Base:` line when you name another) and whether the tree is clean.
7. Looks for a heading named exactly `Definition of Done` followed by a checklist in README, CONTRIBUTING or `docs/`. It never creates one.
8. Runs the invariant check and prints one report: what was created, git mode, base branch, test command and its source, docs found, Definition of Done, whether `.todo/todo-lint.sh` and `.todo/check.sh` exist, the tree summary and any violations.

| Flag | Effect |
|---|---|
| `--plan` | Also when the tree is empty and your message states a goal. Asks at most 3 short questions the repo does not answer (goal and done-state, out of scope, parallel lanes) and offers to save them as `docs/plans/PROJECT.md`. Then points to `/todo-plan` |
| `--ci` | Sets up `.todo/check.sh`, a CI job or a local `pre-push` hook, each on your yes, and runs `.todo/check.sh` once. Rules in [TOOLS.md](TOOLS.md#ci-todo-init---ci) |

It adds, starts or changes no task (apart from a migration you confirmed).

## `/todo-plan [<goal>] [--revise [<reason>]]`

Turns a goal into a plan doc and a proposed tree, or changes the plan when it no longer fits. It never starts work and never touches code. Details: [PLANNING.md](PLANNING.md).

**Plan (default).**

1. Reads README, `docs/`, `TODO.md`, `CHANGELOG.md` and `docs/plans/PROJECT.md`.
2. Asks at most 3 short questions the repo does not answer: the goal and its done-state, what is out of scope, which parts can run in parallel. For an unclear request it also runs the ambiguity checklist (undefined terms, acceptance criteria, actors, error and boundary cases, scope) and stops before writing anything when a business rule is missing, incompatible implementations fit, or authorization is unstated; questions are numbered with their trade-offs, at most 3 per round, and a question that must wait goes to the plan doc's Open questions or a `[!]` node.
3. Drafts `docs/plans/PROJECT.md` (sections Goal, Scope, Out of scope, Lanes, Decisions, Open questions, Revisions), or proposes edits when it exists. It asks before creating `docs/`.
4. Proposes the tree by the `/todo-add` rules: each root gets `Ref: docs/plans/PROJECT.md` and, outside lane `main`, a `Lane:`. Independent lanes do not depend on each other. With an existing tree it proposes only new roots (and children under open roots of unclaimed trees). A tree that would pass 120 lines is proposed as roots and first levels with `next: decompose`. With an RTM, it links roots to requirements and shows the row changes.
5. Waits for your confirmation, writes only what you confirmed, and lints. Nothing is committed.

**Revise (`--revise [<reason>]`).** Usable at any time, even mid-tree. Only `[ ]` nodes change; `[/]`, `[x]`, `[!]` and drained work are never edited, and a node with any descendant that is not `[ ]` is not dropped, merged or moved. The change is shown as a diff (nodes added, dropped, split, merged, re-rated, re-ordered or moved to another lane, plan-doc lines changed). IDs are kept; a dropped ID is never reused, and every `Depends:`/`From:` on it is removed or re-pointed in the same diff. On your yes it applies the change, appends `- <date> · <your reason> · <what changed>` under **Revisions**, and lints.

**Design review (optional).** For a `high` root, or one touching security, data migration or concurrency, or changing an existing public interface (adding one does not count), it offers once a review by a fresh-context subagent (or an external design-review tool the project already uses). It never blocks a plan on it. Accepted findings go through `--revise`; the rest are recorded under **Open questions**. `/todo-continue` offers the matching root review before such a root drains ([PLANNING.md](PLANNING.md#root-review-optional)).

New roots, and changes to unclaimed trees, are written only on the base branch. Nodes of a claimed tree can change only from that tree's branch; elsewhere they are listed as locked.

## `/todo-add <description> [flags]`

Adds work to the tree. It never starts work.

| Flag | Effect |
|---|---|
| `--priority P0\|P1\|P2` | Root priority (default `P1`) |
| `--type feat\|fix\|task` | ID prefix `FEAT`, `FIX` or `TASK`. Without it the description decides: a first word starting with test, doc, refactor, rename or chore → `TASK`; fix as the first word, or bug, crash, regression or broken anywhere → `FIX`; add, implement or support first, or new anywhere → `FEAT`; otherwise `TASK` |
| `--ref <docs-path>` | The governing doc, linked as `Ref:` (anchors allowed). The path must exist. Without it, a doc in `docs/` that clearly governs the work is proposed |
| `--from <ID>` | Provenance, written as `From:`. The ID must exist in `TODO.md` or `CHANGELOG.md` |
| `--parent <ID>` | Adds a child under an open `[ ]` node with at most one dot in its ID, in a tree nobody else has claimed. Children inherit the root's prefix, priority and lane, so `--priority`, `--lane` and `--type` are refused |
| `--lane <name>` | Puts a root in a lane (lowercase letters, digits, dashes) |
| `--clarify` | Always asks one round of questions first |

1. Resolves `--ref`, an RTM link (only when an RTM exists), `--from` and `--parent`.
2. Asks one message of at most 3 short questions when the behavior, the target module or the verification command cannot be derived. It never guesses to avoid asking. For an unclear request it also runs the ambiguity checklist (undefined terms, acceptance criteria, actors, error and boundary cases, scope) and stops before writing anything when a business rule is missing, incompatible implementations fit, or authorization is unstated; questions are numbered with their trade-offs, at most 3 per round, and a question that must wait goes to the plan doc's Open questions or a `[!]` node.
3. Searches the code and tests to check the work is not already done; if it seems done, it asks.
4. Splits and rates: every leaf is one change that fits one context window and touches at most 5 files; at most 3 levels; each node gets a complexity and a `Done when` with a runnable command that targets a test id or path ([VERIFICATION.md](VERIFICATION.md#writing-a-done-when)). Containers get their own `Done when`. No size unless the tree already uses sizes or you ask.
5. A request that needs more than 6 nodes or more detail than 4 lines: offers a plan file `docs/plans/<ROOT-ID>-<slug>.md` linked with `Ref:`.
6. Keeps `TODO.md` within 120 lines: if the tree would not fit, it adds the root and first level, with `State: next: decompose` on nodes that still need children. If even that does not fit, it refuses.
7. Shows a tree of more than one node and waits for your confirmation; a single new leaf needs none.
8. Assigns IDs (one global sequence, never reused) and inserts roots in order (P0 → P1 → P2, then by ID); children go last under their parent. Nothing is committed: the next claim commit carries it.

New roots, including a `--from` follow-up without `--parent`, are added only on the base branch.

## `/todo-continue [flags]`

Executes the next workable node end to end. It completes at most one node per invocation, except lane runs.

| Flag | Effect |
|---|---|
| `--plan` | Stops after reading, with a plan of at most 10 lines committed as `chore(backlog): plan <ID>`, and continues after you approve it. Not with a lane flag |
| `--lane <name>` | Only roots of that lane, in order |
| `--all-lanes [--seq]` | One subagent per lane, in parallel (`--seq`: one after another), each in its own worktree; the main thread coordinates and lands the roots. See [PLANNING.md](PLANNING.md#lanes) |
| `--worktree` | Works in `../<repo>.todo/<ID>`; the main checkout is never switched. Not with a lane flag |
| `--delegate` | Build, review and verify run in a subagent on the model the node's complexity maps to (README `Models:` line); the main thread reruns the verify commands itself |
| `--merge` | When a root finishes, also merges it into the base. Without it the merge commands are printed |

An invalid combination is reported and nothing runs.

1. **Git mode and invariants.** A violation only on a `[/]` node's `State:` line gets a proposed fix; the interrupted-drain I5 repair applies; anything else stops.
2. **Select by status.** First interrupted work: an `[x]` node whose merge into its parent did not happen is merged and nothing else is done; a root branch with its CHANGELOG entry uncommitted gets its drain commit. Then a `[/]` node is resumed from its `State:` (uncommitted changes that fit its task line are its earlier work; anything else stops). Otherwise the first workable `[ ]` node in order. Claimed trees are skipped with a resume hint, `[!]` nodes are skipped, `[x]` nodes are never touched. A node with `next: decompose` is broken down, shown to you and written after you confirm; it is not built.
3. **Ready check** for a new node: lint clean, the `Ref:` exists, the tree is clean. A node of an unclaimed tree starts from the base branch. A `Depends:` satisfied only by the base's CHANGELOG first merges the base into the start branch. The **baseline**: the regression command runs on the start branch. Green records the pass count; no tests records `baseline none`. Red stops everything, except a `FIX` node whose `Done when` runs one of the failing tests (`baseline red: <ids>`); otherwise it suggests a `/todo-add … --type fix --priority P0`.
4. **Branch first.** In an unclaimed tree: root branch, tree claim commit, fast-forward of the base; only after that succeeds, the missing ancestor branches and the node's branch ([GIT-FLOW.md](GIT-FLOW.md#tree-claims)).
5. **Start.** On the node's branch: `[/]`, a new `State:` (`attempts 0/3; baseline …; branch … from …; next: read docs`), commit `chore(backlog): start <ID>`.
6. **Read before write.** The `Ref:` doc and the README/docs sections that govern the area, then only the code the node needs. A missing `Ref:` or a doc that contradicts the task line stops it.
7. **Build.** Red: tests first, failing for the expected reason (`TASK` refactors get characterization tests). A test that already passes stops it. Green: implement only the task line. Refactor with tests green. A parent's integration step adds no feature code.
8. **Review** the whole diff against the task line and `Done when`: a fresh-context subagent when one exists (it never edits or runs tests), otherwise a self-review. Valid findings are fixed, at most 2 rounds.
9. **Verify**, in full and unnarrowed: `Done when`, the regression against the baseline, the project's Definition of Done, the RTM Verification cell, documentation drift. Failures: at most 3 diagnosed attempts, then `[!]` ([VERIFICATION.md](VERIFICATION.md#test-failures-and-blocking)).
10. **Complete.** A non-root node: `[x]`, `State:` removed, node commit, `git merge --no-ff` into the parent's branch, child branch deleted, stop. A root (a leaf root, or its integration step just passed): refresh from the base (rerun on changes), run `.todo/check.sh` as the last gate when it exists, drain it into `CHANGELOG.md` (one entry, the subtree deleted from `TODO.md`, commit `chore(backlog): drain <ID>`), then with `--merge` merge it into the base; never push.
11. **Report:** the node, the commands and their results against the baseline, files changed, branch and commit, `children done/total`, the merge commands for a root without `--merge`, adjacent problems as `/todo-add "…" --from <ID>` commands (it never adds them itself), the next workable node, and a suggestion to clear the context.

## `/todo-update <ID> [--status …] [--note "…"]`

Manual changes to one node. Dotted IDs (`FEAT-002.1`) are allowed. With neither flag it shows the node and changes nothing. An ID already in `CHANGELOG.md` is never reopened; it suggests `/todo-add "…" --type fix --from <ID>`.

| Status | Effect |
|---|---|
| `in-progress` | For a workable node only (not with another `[/]` node, open children, unmet `Depends:`, a blocked ancestor, a tree claimed by another branch, or `next: decompose`). Runs the `/todo-continue` ready check, branch, claim and start steps, and builds nothing |
| `ready` | On a claimed `[ ]` root: **releases the claim** (stale or, after an explicit yes, live), committing `chore(backlog): release <ID>` on the base. On `[/]` or `[!]`: back to `[ ]` with `State: attempts 0/3; branch …; next: resume` (the branch is kept; the `Blocked:` gist goes into the reply). On any other `[ ]`: nothing to do |
| `blocked` | `[!]` with a `Blocked:` line built from `--note` and the last failing command (`n/a (manual)` without one). Stops autonomous work |
| `drop` | Deletes the node and its subtree after you confirm, with a reason in `--note`. Refused on `[/]`, `[x]`, a claimed root, or a node with any descendant that is not `[ ]`. References to the dropped IDs are removed or re-pointed, ancestor sizes updated, and the IDs logged under Revisions in `docs/plans/PROJECT.md` (offered when the file is missing) so they are never reused. A node's own branch is listed with the `git branch -D` command for you to run. Never written to CHANGELOG |
| `revert` | For an `[x]` node under a `[ ]` parent: the node and its descendants go back to `[ ]` with `next: redo after revert`. To undo the code too it prints the `git revert` steps for you |

`ready`, `blocked` and `revert` act where the node's state lives: on the tree's branches for a claimed tree (it names the branch and stops if you are elsewhere), on the base for an unclaimed tree. On a `todo/` branch the change is committed (`chore(backlog): ready|block|drop|revert <ID>`); on the base it stays an uncommitted backlog edit, except the claim release.

**Field edits.** `--note` without a status, starting with `Title:`, `Done when:`, `Ref:`, `Depends:`, `From:`, `State:`, `Complexity:`, `Size:`, `Priority:` or `Lane:`, replaces that part with your text verbatim. Any other note is not applied. The usual rules hold: a `Done when` keeps a runnable, allowed command; a `Ref:` path and `Depends:`/`From:` IDs must exist; no dependency cycle; `Lane:` and `Priority:` on roots only. A `State:` edit is one way to reset the attempt counter. Field edits are refused on `[x]` nodes and, from outside the tree's branch, on a claimed tree. The skill never rewrites a `Done when` on its own.

## `/todo-status [--search <text>] [--last <N>]`

Read-only: no edits, no bootstrapping, no git writes. Without a `TODO.md` it suggests `/todo-init`.

- **Lint** result in one line, followed by the overall progress line (from `todo-lint.sh --progress` when `.todo/todo-lint.sh` exists, else computed by the same definition; see [TOOLS.md](TOOLS.md#todo-lintsh)).
- **Tree** grouped by lane, with a progress bar per lane: each root with marker, complexity, title, its own progress bar of done/total leaves, priority and, when claimed, `claimed by <branch>` with the branch's last commit date (stale when the branch is gone). Claims are read from the base branch, so a tree branch also sees other trees as claimed. Finished subtrees collapse to a count.
- **Active:** the `[/]` node, its ancestors, its `State:`, and in git mode the checked-out branch and whether it has changes.
- **Next:** `resume <ID>`, or the first workable node with its `Done when`, or what blocks the tree.
- **Blocked:** each `[!]` node with its reason and the action required.
- **Recently drained:** the newest `--last <N>` CHANGELOG entries (default 5).

`--search <text>` prints only matching task lines and CHANGELOG entries (case-insensitive) from those two files.

The progress bars use 10 cells: `#` done, `!` blocked, `-` the rest. They are shown, never written to `TODO.md`.

## `/todo-report`

Writes `docs/status.html` and nothing else, from the template inside the skill: a self-contained page with KPIs and the overall progress line (the same line as `todo-lint.sh --progress`, with a bar), lanes with progress (click to filter), the task tree with search and a status filter, `Done when`, links, state and blockers, release history, claims, open branches, the test command, lint result and the plan. Text is inserted encoded (`&` → `&amp;`, then `<` → `&lt;`) so it cannot close the page's script blocks, and the page renders it with `textContent` only. It loads nothing from the network. It writes through `docs/status.html.tmp` and renames it, asks before creating `docs/`, reports a lint violation in the page rather than repairing it, and reminds you that the page is a snapshot. The optional `tools/todo-report.sh` does the same filling deterministically.

## `/todo-release [--version X.Y.Z]`

Releasing is your decision: the skill acts only after you confirm the version in the conversation. In Claude Code it is marked `disable-model-invocation`, so the model never starts it on its own.

1. **Preconditions.** In git mode the base branch is checked out and `git status` shows nothing but backlog files and untracked files. `[Unreleased]` has at least one entry. A `[/]` task or a claimed tree is a warning (that work is not in the release).
2. **Proposal.** Major for `BREAKING CHANGE`, a `type!` or any `### Removed` entry (minor while the version is `0.x`); else minor for any `### Added` or `(feat)` entry; else patch. `0.1.0` for a first release. `--version` replaces the proposal but still needs the confirmation. The version must be digits only, greater than the previous one, and not already tagged.
3. **Write.** `## [Unreleased]` becomes `## [X.Y.Z] - YYYY-MM-DD` with a new empty `## [Unreleased]` above it. If the file ends with compare links, they are updated from the existing `[Unreleased]:` line. Older sections are not touched.
4. **Version files** (`package.json`, `pyproject.toml`, `Cargo.toml`, `pom.xml`) that mention the previous version are listed for you to bump; none is edited.
5. **Commit** `CHANGELOG.md` alone as `chore(release): X.Y.Z`, after the lint passes again.
6. **Report** the new section and print, without running them, `git tag -a vX.Y.Z -m "X.Y.Z"` and `git push --follow-tags`.
