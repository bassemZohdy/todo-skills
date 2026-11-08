#!/bin/sh
set -eu
exec codex exec -m gpt-6.1-terra --ephemeral --ignore-user-config \
  -c 'default_permissions="trial"' \
  -c 'permissions.trial.filesystem={":root"="read", "/root/.codex"="deny", "/runner.sh"="deny", "/prompt.txt"="deny", "/work"="write", "/work.todo"="write", "/work/.git"="write"}' \
  -c 'permissions.trial.network.enabled=false' \
  -C /work --json - < /prompt.txt