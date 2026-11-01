---
name: todo-report
description: Generate an interactive HTML status page for the project at docs/status.html from TODO.md, CHANGELOG.md, git and the plan doc. Use for /todo-report. Shows KPIs, lanes with progress, the filterable task tree with Done when, links, state and blockers, release history, claims, test command and the plan. Self-contained single file, no network. Writes only docs/status.html.
argument-hint: (none)
---

# /todo-report

First load the `todo` core skill (tree format, lanes, git mode). If it is not a skill, read `../todo/SKILL.md`.

Writes exactly one file, `docs/status.html` (create `docs/` if missing), from the template `template.html` in this skill's folder. Never edits TODO.md, CHANGELOG.md or any other file. No network, no fetch.

## Steps

1. Run the invariant check and read the result. In git mode read claims from the base branch (`git show <base>:TODO.md`), as `/todo-status` does.
2. Read `template.html`. It has four placeholders, each inside a `<script type="text/plain">` block: `__META__`, `__TODO__`, `__CHANGELOG__`, `__PLAN__`. The page parses them itself.
3. Write `docs/status.html` as the template with each placeholder replaced by raw text (no escaping needed, but a literal `</script` in the text becomes `<\/script`):
   - `__TODO__`: the full text of `TODO.md`.
   - `__CHANGELOG__`: the full text of `CHANGELOG.md`.
   - `__PLAN__`: the text of `docs/plans/PROJECT.md`, or leave the placeholder `__PLAN__` when there is none.
   - `__META__`: one `key: value` per line, only those you actually know: `project` (repo or folder name), `generated` (today's date), `base`, `branch` (checked out), `mode` (git or no-git), `tests` (the detected test command, see `/todo-init` step 4), `lint` (pass or the failures), `Definition of Done` (where it is), `claim` (one line per claimed root: `<ID> -> <branch>`, add `(stale)` if the branch is gone), `branches` (open `todo/*` branches), `version` (newest released CHANGELOG version).
4. Report the path in one line, and that opening the file in a browser shows it. Mention that it is a snapshot: rerun `/todo-report` to refresh. Suggest committing it only if the team wants it versioned.

Do not summarise the data in chat beyond the one-line counts (roots, in progress, blocked, drained).
