# Evidence for FIX-035 to FIX-041 (TASK-046)

Until now some of this evidence lived only on the evaluation host (`%TEMP%/todo-fix035-20261108-041850`,
`%TEMP%/todo-fix041-mxc-probe`), which is not durable. This folder publishes it with checksums. Fixes whose evidence was
already published point to it. `bash tests/trials/test-fix-evidence.sh` checks everything here without running an agent,
and the Ubuntu and macOS CI jobs run it like every other trial-harness test.

| Fix | What it changed | Published evidence | Checks |
|---|---|---|---|
| **FIX-035** | Claim a newly added, uncommitted root without a separate backlog commit | [fix-035/](fix-035/): the `/todo-add` and `/todo-continue` sessions and the race run of [fix-035.md](../fix-035.md), byte-identical to the logs it cites by SHA-256 | `bash tests/trials/test-fix-evidence.sh`, `bash tests/trials/test-pending-root.sh` |
| **FIX-036** | Report lane concurrency only from independent worker activity | [the sequential Linux multi-module run](../codex-linux-2026-11-08/runs/multi-module/) it re-labelled; the concurrent run that followed is [lanes-codex-2026-11-08](../lanes-codex-2026-11-08/) | `bash tests/trials/test-lane-concurrency.sh`, `bash tests/trials/test-lane-evidence.sh`, `bash tests/trials/test-lane-concurrency-evidence.sh` |
| **FIX-037** | Score only scenario folders and keep incomplete scenarios and every verdict | none: a scoring change with no agent run; its harness tests are the evidence | `bash tests/trials/test-score-layout.sh`, `bash tests/trials/test-score-outcomes.sh` |
| **FIX-038** | Keep shell scripts LF in Windows checkouts | [the CRLF install diagnostic](../codex-linux-2026-11-08/diagnostics/install-with-tools-crlf/) that found it, and [the LF install](../codex-linux-2026-11-08/installations/with-tools/) after it | `bash tests/trials/test-shell-line-endings.sh`, `bash tests/trials/test-linux-codex-evidence.sh` |
| **FIX-039** | One fresh Codex session per multi-node invocation | [ts-lifecycle](../codex-linux-2026-11-08/runs/ts-lifecycle/invocations/) and [java-lifecycle](../codex-linux-2026-11-08/runs/java-lifecycle/invocations/), three sessions each | `bash tests/trials/test-codex-fresh-invocations.sh`, `bash tests/trials/test-linux-codex-evidence.sh` |
| **TASK-040** | The 040 slot: the Linux trial boundary audit (there is no FIX-040) | [linux-boundary-2026-11-08.md](../linux-boundary-2026-11-08.md) | `bash tests/trials/test-linux-boundary.sh` (needs Docker and the Codex image, run by hand) |
| **FIX-041** | Isolated Windows trial verification by default | [fix-041-probe/](fix-041-probe/): the dummy-sentinel MXC and elevated probes of the [prototype notes](../windows-verifier-prototype-2026-11-08.md); [fix-041-checks/](fix-041-checks/): the verifier checks recorded on this host | `bash tests/trials/test-fix-evidence.sh`, `bash tests/trials/test-windows-verifier-isolation.sh` (native Windows, its own workflow), `bash tests/trials/test-verifier-failures.sh` |

## What was changed when publishing

- **FIX-035:** the files are copied unchanged, except that the two `git-state.txt` files had the evaluation host's temp
  path (`C:/Users/<user>/AppData/Local/Temp/`) replaced by `%TEMP%/`. The session logs and assertion logs are UTF-16, as
  PowerShell wrote them; `.gitattributes` keeps every byte, so the hashes `fix-035.md` cites still match.
- **FIX-041 probe:** the 20 files its own `SHA256SUMS` lists, plus `launch.sh` and the four dummy sentinels. The probe's
  scratch repository (its `.git` internals and bytecode) is left out. No real credentials were used in the probe.
- **FIX-041 checks:** `test-windows-verifier-isolation.sh` and `test-verifier-failures.sh` run on this host at the commit
  in `checks.json`, which includes FIX-052's Python probes. The original FIX-041 numbers are in [fix-041.md](../fix-041.md).

`SHA256SUMS` covers every file in this folder.
