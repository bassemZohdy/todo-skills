# Native Windows verifier prototype, 2026-11-08

This is an experimental, opt-in verifier for FIX-041, not a claim that the
task is complete. The skill files do not require this verifier, Docker, or
GitHub Actions.

GitHub Actions tested commit `0e846de96bf112120dc498efdb0aa673a184b4c7`
with Codex CLI 0.167.0 and the elevated Windows sandbox on disposable
windows-2022 and windows-2025 runners. Each runner reported 8 passed, 0
failed: four dummy file boundaries, controller write protection, dummy
environment token exclusion, execution of a scratch project test, and
baseline report access. See
https://github.com/bassemZohdy/todo-skills/actions/runs/42453794803.
These are controlled verifier probes, not fresh-agent end-to-end scenarios.

The user's Windows host supported an MXC sentinel probe, but Git Bash failed
to start inside MXC with `0xc0000142`. The elevated sandbox setup completed
on that host, but an elevated sandbox command timed out; the hosted runners
successfully ran Git Bash with the elevated sandbox. MXC was unavailable on
both hosted runner versions. The host's elevated setup created Codex sandbox
accounts and firewall rules. Host probe logs are published with their checksums in
[fix-evidence-2026-11-08/fix-041-probe](fix-evidence-2026-11-08/fix-041-probe/) (TASK-046).

Limitations: the verifier is opt-in, permits general OS reads, denies the
specified Codex home and existing siblings of the standard scratch layout,
and does not establish protection for arbitrary authentication locations or
paths created after policy construction. The controller remains readable.
The probes do not establish a complete security boundary. Keep FIX-041 blocked
until its acceptance criteria and the default verification behavior are met.
