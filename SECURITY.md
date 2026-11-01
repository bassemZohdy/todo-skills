# Security

## What the skills can do

The skills are Markdown instructions plus two optional read-only shell scripts (`skills/todo/scripts/`) and one HTML template. They are written to never touch the network, tag, push, or run destructive commands. An agent still runs the `Done when` and test commands found in a repository, so review `TODO.md` the way you review code: a task from an untrusted source can name any command. The lint rejects an obvious set (`sudo`, `rm -r`, `git push`, download-to-shell and similar); it is a safety net, not a sandbox.

`/todo-init --ci` writes `.todo/check.sh`, which runs your test command in CI and in the `pre-push` hook. Review changes to it like any CI script.

`/todo-report` writes `docs/status.html`, which renders text from `TODO.md` and `CHANGELOG.md` with `textContent` only and loads nothing from the network.

## Reporting a vulnerability

Please do not open a public issue. Use GitHub's private vulnerability reporting on this repository ("Security" tab, "Report a vulnerability"). Include what you ran, what happened, and the skill text or script involved. You can expect an acknowledgement within a week.
