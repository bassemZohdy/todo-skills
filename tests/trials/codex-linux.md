# Running the Codex trials in a Linux container

The Linux batch of 2026-11-08 ran each scenario in a Docker container instead of `run-codex.sh` ([its results](../../docs/evals/codex-linux-2026-11-08/summary.md)). This is how to do it again. Use a separate controller checkout, a Codex login kept in a dedicated Docker volume (or `codex login --with-api-key` with a key you supply yourself), and a new scratch directory. The agent must not receive a mount of the controller or of the evidence. Review the sandbox limitations in the batch summary before treating a result as trusted.

From a Linux shell in the controller checkout, build the image and prepare `happy-path`:

```bash
docker build -t todo-codex-linux:0.167.0 - <<'EOF'
FROM node:22
RUN npm install -g @openai/codex@0.167.0
WORKDIR /work
EOF
mkdir -p /tmp/todo-linux-trial/happy-path /tmp/todo-linux-trial/evidence
bash tests/trials/setup.sh /tmp/todo-linux-trial/happy-path/repo happy-path
bash tests/trials/prompt.sh /work happy-path > /tmp/todo-linux-trial/evidence/prompt.txt
cat > /tmp/todo-linux-trial/evidence/runner.sh <<'EOF'
#!/bin/sh
set -eu
exec codex exec -m gpt-6.1-terra --ephemeral --ignore-user-config \
  -c 'default_permissions="trial"' \
  -c 'permissions.trial.filesystem={":root"="read", "/root/.codex"="deny", "/runner.sh"="deny", "/prompt.txt"="deny", "/work"="write", "/work/.git"="write"}' \
  -c 'permissions.trial.network.enabled=false' \
  -C /work --json - < /prompt.txt
EOF
```

The runner selects `gpt-6.1-terra` and a permission profile that denies the login, prompt and runner paths to agent commands, permits scratch Git writes and disables agent-command networking. The Codex client itself needs network access. The successful run used `seccomp=unconfined` so Codex could create its own Linux sandbox; the default Docker seccomp profile stops it. Audit that tradeoff for your host before use.

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

Run the assertions from the controller, not in the tested session, and keep the assertion exit, the Git state and hashes with the run. The TypeScript and Java scenarios apply one invocation per fresh session with the generated prompt; the Maven trials need Java, Maven and a separate prepopulated cache per scratch repository. The multi-module run also mounts a separate scratch worktree directory at `/work.todo`. Its lanes ran sequentially; event-window overlap alone does not prove parallel agents. The evidence of a run stays on the machine that ran it; publish only the results.
