# Tools and CI

The plugin is Markdown only and needs nothing installed. This repository also keeps optional helper scripts in [`tools/`](../tools/) (read-only, except that `todo-replay.sh --run` runs commands), and `/todo-init --ci` can wire a check into CI or a git hook. Nothing on this page is required: without any of it the agent checks the invariants by reading and runs the tests itself.

The skills never download these scripts. Copy the ones you want into your project yourself (most projects put the lint in `.todo/`), and copy them again when you upgrade: `tests/run.sh` in this repository checks that its own `.todo/todo-lint.sh` equals `tools/todo-lint.sh`, and your copy should stay in step the same way. Every script prints the release it comes from with `--version` (for example `bash tools/todo-lint.sh --version` prints `todo-lint.sh 0.5.0`); between releases a copy can carry later, unreleased changes. Every script needs only bash and standard tools (awk, grep, sed, tr), never touches the network and never edits files; `todo-replay.sh --run` also runs the Validated commands it accepts, which may do whatever your tests do.

## `todo-lint.sh`

```bash
bash .todo/todo-lint.sh [--progress] [TODO.md] [CHANGELOG.md]     # from the repository root
```

Checks the invariants I1-I10 deterministically and prints one `FAIL I<n>: line <n>: …` line per violation, plus `WARN W<n>: …` lines that never change the result ([REFERENCE.md](REFERENCE.md#invariants)).

| Exit | Meaning |
|---|---|
| 0 | All invariants hold (warnings may be printed) |
| 1 | Violations found |
| 2 | `TODO.md` not found |

When `.todo/todo-lint.sh` exists, every command runs it instead of checking by reading, and its failures win over the agent's own reading. A missing `CHANGELOG.md` is fine. Use it also as a pre-commit hook or a CI step.

`todo-lint.sh --progress` also prints one read-only progress line after the lint result, whether the lint passed or failed. The exit code doesn't change, so a CI log can show progress without a separate step:

```text
Progress: [######!---] 6/9 leaves · 1 active · 1 blocked · 2 roots open · 2 drained in [Unreleased]
```

| Part | Meaning |
|---|---|
| leaves | Tasks without children. Done counts the `[x]` leaves in `TODO.md`, plus the leaves of roots drained into `## [Unreleased]` in `CHANGELOG.md`. For an entry with `Includes:`, those leaves are the included IDs that are not the parent of another included ID; without `Includes:`, the entry itself counts. Entries without an ID and released versions don't count |
| bar | 10 cells: `#` for done (rounded down), `!` for blocked leaves (rounded, at least one when any leaf is blocked), `-` for the rest |
| active, blocked | `[/]` nodes at any depth; `[!]` leaves |
| roots open | Roots still in `TODO.md` |
| drained in [Unreleased] | CHANGELOG entries with an ID under `## [Unreleased]` |

`/todo-status` and `docs/status.html` use the same definition, and `tests/run.sh` checks that all three give the same line for `tests/fixtures/progress/`. The line is never written to `TODO.md`.

## `todo-verify.sh`

```bash
<run the command, keep its output and exit status>
printf '%s\n' "$output" | bash tools/todo-verify.sh [--strict] <exit-status> '<command that was run>'
```

Classifies a finished `Done when` or regression run. It runs nothing itself. It prints `ACCEPT` (exit 0) or one `REJECT <reason>` line (exit 1) for a non-zero exit status, a command that masks failures (`|| true`, `; true`, `; exit 0`, `|| :`), a named test target (a `tests/`, `test/` or `spec/` path, a script or test file) that does not exist (a glob after `cd <dir> &&` is matched in `<dir>`, and one that matches nothing counts as missing), output that reports zero tests and no passing test (including Maven `Tests run: 0` and dotnet `No test is available`), a collect-only run (`--collect-only`, `--co`, or `N tests collected`), or a run that only skipped tests.

`--strict` also rejects output with no recognizable passing count, an unchecked pipe (`cmd | tail` and similar, unless `pipefail` or `PIPESTATUS` is used), `set +e`, and `|| echo` or `|| printf` masks. Without it, runners that print no count are still accepted.

## `todo-rtm.sh`

```bash
bash tools/todo-rtm.sh [repo-root]
```

Finds the optional requirements matrix (`docs/RTM.md`, else the `## RTM` section of README, else none), prints `RTM: <location>` or `RTM: none`, and one `FAIL R<n>: …` line per problem:

| Check | Problem |
|---|---|
| R1 | A task ID in the matrix is in neither `TODO.md` nor `CHANGELOG.md` (a stale link) |
| R2 | Every task of a row is archived in `CHANGELOG.md`, but its Verification cell is empty |
| R3 | The same Req ID appears in more than one row |

Exit 0 when there is no matrix or no problem, 1 otherwise. Tables in README outside the `## RTM` section are ignored.

## `todo-report.sh` and `template.html`

```bash
bash tools/todo-report.sh < meta.txt > docs/status.html     # from the repository root
```

Fills `template.html` (it must sit next to the script) with `TODO.md`, `CHANGELOG.md`, `docs/plans/PROJECT.md` and the `key: value` lines of `meta.txt` (`project`, `generated`, `base`, `branch`, `mode`, `tests`, `lint`, `Definition of Done`, `claim`, `branches`, `version`; any may be left out). Text is encoded (`&` → `&amp;`, `<` → `&lt;`) so it cannot break out of the page's script blocks. It writes only to standard output and exits 1 without a `TODO.md` in the current directory. `/todo-report` does the same encoding itself when the script is absent; the skill carries the same template in `plugin/skills/todo-report/template.md`. The page's `progressLine` function, set apart by `// ---- progress` markers, computes the same line as `todo-lint.sh --progress`; `tests/run.sh` runs it under node when node is installed.

## `todo-replay.sh` (optional, FEAT-059)

```bash
bash .todo/todo-replay.sh [--run] <rev> [CHANGELOG.md]       # from the repository root; todo-lint.sh must sit next to it
```

Replays the `Validated:` commands of the CHANGELOG entries added since `<rev>` (entries whose ID is not in `git show <rev>:CHANGELOG.md`), so CI re-proves what a newly landed root claimed. Without `--run` it only lists them. Each command first goes through the lint as a `Done when`: anything the lint fails (I3 vacuous or masked, I10 forbidden) or flags as an unfamiliar runner (W3), a piped runner (W4) or a command that may download and run remote code (W6) is printed as `REFUSED` and never run (W1, W2 and W5 do not refuse). Review those and run them yourself if they are safe. A command that runs a script (`bash <file>`, `make <target>`, `npm test`) runs whatever that file holds, which the lint does not read, so read those scripts as you read `check.sh`. No revision (an unset variable) or no new entry means nothing runs. Exit 0 when nothing was replayed or everything passed, 1 when a replayed command failed, 2 on a usage or git error, 3 when commands were refused.

## `todo-stop-hook.sh`

A Claude Code Stop hook that keeps a session from ending on a corrupted backlog. Copy it next to `todo-lint.sh` (it calls the lint from its own folder) and add it to `.claude/settings.json`, using the path where you put it:

```json
{ "hooks": { "Stop": [ { "hooks": [
  { "type": "command", "command": "bash .todo/todo-stop-hook.sh" }
] } ] } }
```

It allows the stop (no output) when `stop_hook_active` is true (whatever the JSON whitespace), so it can never loop, when there is no `TODO.md`, or when the lint passes. Otherwise it prints a `block` decision with the lint output quoted as data. `TODO_FILE` and `CHANGELOG_FILE` override the file names. Codex has no equivalent wired up here.

## CI: `/todo-init --ci`

One entrypoint, `.todo/check.sh`, runs the backlog lint and the project's tests. CI runs it on pushes to the base branch and on pull requests; without CI a `pre-push` hook runs it locally. Every file below is written only on your yes, and a later `--ci` shows the difference before replacing a file that changed. The rules the model follows are in [`plugin/skills/todo/reference/ci.md`](../plugin/skills/todo/reference/ci.md).

1. **`.todo/todo-lint.sh`:** not written by the skill. If it is missing, the agent tells you to save `tools/todo-lint.sh` there, and the lint line is left out of `check.sh` until it exists.
2. **`.todo/check.sh`** (made executable) with the detected test command, after checking that command against the [command safety](VERIFICATION.md#command-safety) rules. It is run once after writing, and the result is reported:

   ```bash
   #!/usr/bin/env bash
   # Backlog lint + tests. Used by CI and by /todo-continue before a root lands. Generated by /todo-init --ci.
   set -eu
   cd "$(dirname "$0")/.."
   bash .todo/todo-lint.sh TODO.md CHANGELOG.md   # only when .todo/todo-lint.sh exists
   <test command>
   ```

   **Optional replay** (FEAT-059, only on your yes and when you have copied `tools/todo-replay.sh` to `.todo/`): one more line, `bash .todo/todo-replay.sh --run "${TODO_REPLAY_FROM:-}"`, re-runs the Validated commands of entries added since `TODO_REPLAY_FROM`. Locally the variable is unset, so the line does nothing. In GitHub Actions, set it to `${{ github.event.before }}` on `push` (or `origin/${{ github.base_ref }}` on `pull_request`) and check out with `fetch-depth: 0`. A refused command fails the job until you review it.

3. **CI**, by the first row that matches:

   | Found | Written |
   |---|---|
   | `.github/workflows/` with a job that already runs the tests | `.github/workflows/todo-check.yml` with a single lint job |
   | `.github/workflows/` without tests, or no CI and an `origin` on `github.com` | `.github/workflows/todo-check.yml` that sets up the runtime, installs dependencies when the project does, and runs `bash .todo/check.sh` |
   | `.gitlab-ci.yml` | A `todo-check` job (`script: [bash .todo/check.sh]`), shown first and added on your yes |
   | Other CI (`Jenkinsfile`, `azure-pipelines.yml`, `.circleci/`, …) | Nothing; the one step to add is printed: `bash .todo/check.sh` |
   | No CI and no `origin` on `github.com` | The local fallback |

   The GitHub workflow runs on `push` to the base and on `pull_request` with `permissions: contents: read`, using `actions/checkout@v4` and the setup step for the runtime: `actions/setup-node@v4` (`package.json`), `actions/setup-python@v5` (Python markers or a `python`/`pytest`/`uv` test command), `actions/setup-java@v4` with Temurin 21 (`pom.xml`, `build.gradle`), `actions/setup-go@v5` (`go.mod`), none for Cargo, Make or plain bash.

4. **Local fallback:** a git `pre-push` hook (`.git/hooks/pre-push`, not versioned) that runs `bash .todo/check.sh` and refuses the push when it fails. An existing hook is never overwritten; when the hook cannot be written, its two lines and the `chmod +x` command are printed for you.

Outside a git repository only `.todo/` is written. Commit `.todo/` and the CI file yourself, on the base or through a pull request: they are project files, so no claim commit carries them, and the first CI run starts when you push. A red first run usually means a missing install step; the report says which line to edit.

Whatever the CI, `/todo-continue` runs `bash .todo/check.sh` as the last gate before a root's drain, after the refresh from the base, so the same lint and tests run whether or not CI exists.

## Line endings

`.gitattributes` keeps `*.sh` files LF, so scripts copied from a Windows checkout run on Linux. If an older checkout or an already-copied script has CRLF endings, refresh it from a clean checkout or convert it to LF.
