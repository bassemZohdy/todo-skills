# Independent CI verification

GitHub Actions [run 42427977126](https://github.com/bassemZohdy/todo-skills/actions/runs/42427977126) passed on 2026-11-08. Its pull-request head was `89aa4021c8ca4dbb108faa38a95ce90db59483a6`; the evaluated source was pinned to ancestor `3a8b215ef3fc1b06ec2759d700151ee944000043`.

Separate hosted [Ubuntu](https://github.com/bassemZohdy/todo-skills/actions/runs/42427977126/job/128570289919) and [macOS](https://github.com/bassemZohdy/todo-skills/actions/runs/42427977126/job/128570290249) runners passed the project suite, harness self-test, and trial harness tests. Their logs show `test-linux-codex-evidence.sh` checking the evidence hashes, eight generated prompts, 105 assertion lines, 12 distinct scenario sessions, installation checks, and the representative-project evidence. The workflow used a read-only contents permission and did not launch the tested agent or mount its login.

This verifies the retained evidence at the cited commit; it does not independently rerun the agent or establish a complete adversarial sandbox audit. The trial results remain provisional as explained in [summary.md](summary.md).
