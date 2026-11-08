#!/bin/sh
set -eu
exec codex exec -m gpt-6.1-terra --ephemeral \
  -c 'developer_instructions="The controller requires exactly one /todo-continue invocation in this fresh session; stop and report afterward even if the prompt requests repeats."' --ignore-user-config \
  -c 'default_permissions="trial"' \
  -c 'permissions.trial.filesystem={":root"="read", "/root/.codex"="deny", "/runner.sh"="deny", "/prompt.txt"="deny", "/work"="write", "/work/.git"="write"}' \
  -c 'permissions.trial.network.enabled=false' \
  -C /work --json - < /prompt.txt