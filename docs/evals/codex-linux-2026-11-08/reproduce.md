# Reproducing the Linux Codex trials

The source under test is commit `3a8b215ef3fc1b06ec2759d700151ee944000043`. Use a separate controller checkout at that commit, an authenticated Codex login in a dedicated Docker volume, and a new scratch directory. The agent must not receive a mount of the controller or evidence. Review the sandbox limitations in [summary.md](summary.md) before treating a result as trusted.

For example, from a Linux shell in the controller checkout, build the image and prepare `happy-path`:

```bash
docker build -t todo-codex-linux:0.167.0 - <<'EOF'
FROM node:22
RUN npm install -g @openai/codex@0.167.0
WORKDIR /work
EOF
mkdir -p /tmp/todo-linux-trial/happy-path /tmp/todo-linux-trial/evidence
bash tests/trials/setup.sh /tmp/todo-linux-trial/happy-path/repo happy-path
bash tests/trials/prompt.sh /work happy-path > /tmp/todo-linux-trial/evidence/prompt.txt
cp docs/evals/codex-linux-2026-11-08/runs/happy-path/runner.sh /tmp/todo-linux-trial/evidence/runner.sh
```

The runner explicitly selects `gpt-6.1-terra` and a permission profile that denies the login, prompt and runner paths to agent commands, permits scratch Git writes and disables agent-command networking. The Codex client itself needs network access. A dummy-only boundary probe and the default Docker seccomp failure are in `diagnostics/`. The successful run used `seccomp=unconfined` so Codex could create its own Linux sandbox; audit that tradeoff for your host before use.

```bash
docker run --rm --security-opt seccomp=unconfined \
  --mount type=bind,source=/tmp/todo-linux-trial/happy-path/repo,target=/work \
  --mount type=bind,source=/tmp/todo-linux-trial/evidence/runner.sh,target=/runner.sh,readonly \
  --mount type=bind,source=/tmp/todo-linux-trial/evidence/prompt.txt,target=/prompt.txt,readonly \
  --mount source=todo-codex-auth,target=/root/.codex \
  todo-codex-linux:0.167.0 sh /runner.sh \
  > /tmp/todo-linux-trial/evidence/session.jsonl 2> /tmp/todo-linux-trial/evidence/stderr.log
echo "$?" > /tmp/todo-linux-trial/evidence/agent-exit.txt
bash tests/trials/assert.sh /tmp/todo-linux-trial/happy-path/repo happy-path
```

Run assertions from the controller, not in the tested session. Preserve the assertion exit, Git state and hashes as well. The other scenario prompts and runners are under `runs/`: the TypeScript and Java runners apply one invocation per fresh session while preserving the generated prompt; the Maven trials need Java, Maven and a separate prepopulated cache per scratch repository. The multi-module run also mounts a separate scratch worktree directory at `/work.todo`. Its lanes ran sequentially; event-window overlap alone does not prove parallel agents.

To verify the retained bundle without an agent, use `bash tests/trials/test-linux-codex-evidence.sh` from a checkout containing this evidence and the pinned source commit in its Git history. The verifier checks the hashes, exact prompts, session IDs, assertion counts, installation checks and representative-project evidence; it does not reproduce an agent run or prove a complete sandbox audit.
