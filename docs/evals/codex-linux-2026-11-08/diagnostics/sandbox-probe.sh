set -eu
mkdir -p /probe-config /work /controller /root/.codex
printf 'dummy\n' > /root/.codex/sentinel
printf 'dummy\n' > /controller/sentinel
cat > /probe-config/config.toml <<'EOF'
default_permissions = "trial"
[permissions.trial.filesystem]
":root" = "read"
"/root/.codex" = "deny"
"/controller" = "deny"
"/work" = "write"
"/work/.git" = "write"
[permissions.trial.network]
enabled = false
EOF
cd /work
git init -q -b main
CODEX_HOME=/probe-config codex sandbox -P trial -C /work -- sh -c 'set -e; if test -r /root/.codex/sentinel; then echo AUTH_READABLE; else echo AUTH_DENIED; fi; if test -r /controller/sentinel; then echo CONTROLLER_READABLE; else echo CONTROLLER_DENIED; fi; echo test > note.txt; git add note.txt; git -c user.name=t -c user.email=t@t commit -qm init; git switch -qc todo/FEAT-001-probe; git status --short --branch'