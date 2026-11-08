#!/usr/bin/env bash
# Harmless Linux boundary probes. No real authentication volume is mounted.
set -eu
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$here/assert-exec.sh" ] || { echo 'FAIL  isolated assertion runner missing'; exit 1; }
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/controller/tests/trials" "$tmp/controller/tools"
cp "$here/assert-exec.sh" "$here/assert.sh" "$here/lane-evidence.sh" "$tmp/controller/tests/trials/"
cp "$here/../../tools/todo-lint.sh" "$tmp/controller/tools/"
# A Windows checkout may have CRLF; the audit copies the exact script logic as LF.
for f in "$tmp/controller"/tests/trials/*.sh "$tmp/controller/tools/todo-lint.sh"; do sed -i 's/\r$//' "$f"; done
src="$tmp/controller"; if command -v cygpath >/dev/null 2>&1; then src="$(cygpath -m "$src")"; fi
image="${TRIAL_AUDIT_IMAGE:-todo-codex-linux:0.167.0}"
MSYS_NO_PATHCONV=1 docker run --rm -i --network none --security-opt seccomp=unconfined \
  --mount "type=bind,src=$src,dst=/controller,readonly" --entrypoint /bin/bash "$image" <<'AUDIT'
set -eu
mkdir -p /probe-config /runs/case/repo /runs/case/evidence /runs/other /root/.codex
printf 'dummy\n' > /root/.codex/sentinel
printf 'dummy\n' > /runs/case/evidence/sentinel
printf 'dummy\n' > /runs/other/sentinel
cat > /probe-config/config.toml <<'CONFIG'
default_permissions = "trial"
[permissions.trial.filesystem]
":root" = "read"
"/root/.codex" = "deny"
"/controller" = "deny"
"/runs" = "deny"
"/runs/case/repo" = "write"
"/runs/case/repo/.git" = "write"
[permissions.trial.network]
enabled = false
CONFIG
cd /runs/case/repo
git init -q -b main
printf '# Active Backlog\n\n## Task Tree\n' > TODO.md
printf '# Changelog\n\n## [Unreleased]\n' > CHANGELOG.md
git add TODO.md CHANGELOG.md
git -c user.name=trial -c user.email=trial@example.invalid commit -qm init
python3 -m http.server 18765 --bind 127.0.0.1 >/dev/null 2>&1 & server=$!
trap 'kill "$server" 2>/dev/null || true' EXIT
for n in 1 2 3 4 5 6 7 8 9 10; do
  if python3 -c 'import socket; s=socket.create_connection(("127.0.0.1",18765),1); s.close()' 2>/dev/null; then break; fi
  sleep .2
done
python3 -c 'import socket; s=socket.create_connection(("127.0.0.1",18765),1); s.close()'
# Show the original, unsandboxed verifier boundary using dummy data only.
test -r /root/.codex/sentinel && printf 'changed\n' > /runs/case/evidence/sentinel
echo 'FINDING  unisolated test processes can read dummy login and overwrite evidence'
printf 'dummy\n' > /runs/case/evidence/sentinel
cat > /runs/case/repo/agent-probe.sh <<'PROBE'
set -eu
for p in /root/.codex/sentinel /controller/tests/trials/assert.sh /runs/case/evidence/sentinel /runs/other/sentinel; do
  if cat "$p" >/dev/null 2>&1; then echo "FAIL  agent read $p"; exit 1; fi
  if (printf x > "$p") 2>/dev/null; then echo "FAIL  agent wrote $p"; exit 1; fi
  echo "PASS  agent denied read and write: $p"
done
ln -s /runs/case/evidence/sentinel escape-link
if cat escape-link >/dev/null 2>&1 || (printf x > escape-link) 2>/dev/null; then echo 'FAIL  agent symlink escape'; exit 1; fi
echo 'PASS  agent symlink escape denied'
if python3 -c 'import socket; socket.create_connection(("127.0.0.1",18765),1)' >/dev/null 2>&1; then echo 'FAIL  agent network'; exit 1; fi
echo 'PASS  agent network denied'
echo scratch > note.txt; git add note.txt
git -c user.name=trial -c user.email=trial@example.invalid commit -qm 'chore: probe'
git switch -qc todo/probe
git worktree add -q -b todo/lane lane
echo 'PASS  scratch Git commit, branch and worktree'
PROBE
CODEX_HOME=/probe-config codex sandbox -P trial -C /runs/case/repo -- bash /runs/case/repo/agent-probe.sh
# Run real assert.sh via the isolated wrapper. The scratch Makefile's test is a
# controlled hostile child: it reports whether it could escape into sentinels.
cat > /runs/case/repo/Makefile <<'MAKE'
test:
	@bash verifier-probe.sh
MAKE
cat > /runs/case/repo/verifier-probe.sh <<'PROBE'
set -eu
for p in /root/.codex/sentinel /runs/case/evidence/sentinel /runs/other/sentinel; do
  if cat "$p" >/dev/null 2>&1 || (printf x > "$p") 2>/dev/null; then echo "FAIL verifier escaped $p" > verifier-result; exit 1; fi
done
test -r /controller/tests/trials/assert.sh
if (printf x > /controller/tests/trials/assert.sh) 2>/dev/null; then echo 'FAIL verifier changed controller' > verifier-result; exit 1; fi
if python3 -c 'import socket; socket.create_connection(("127.0.0.1",18765),1)' >/dev/null 2>&1; then echo 'FAIL verifier network' > verifier-result; exit 1; fi
echo PASS > verifier-result
PROBE
TRIAL_LINUX_ISOLATION=1 CODEX_HOME=/probe-config bash /controller/tests/trials/assert-exec.sh /runs/case/repo status-readonly >/dev/null 2>&1 || true
test "$(cat /runs/case/repo/verifier-result)" = PASS
test "$(cat /runs/case/evidence/sentinel)" = dummy
echo 'PASS  isolated verifier child cannot read or modify protected sentinels or use network'
mkdir -p /runs/case/evidence/session
printf 'baseline red: test_add; FIX suggested\n' > /runs/case/evidence/session/report.txt
TRIAL_REPORT=/runs/case/evidence/session/report.txt TRIAL_LINUX_ISOLATION=1 CODEX_HOME=/probe-config \
  bash /controller/tests/trials/assert-exec.sh /runs/case/repo baseline-red > /tmp/verify-report.log 2>&1 || true
grep -q '^PASS  an agent report was provided and is not empty' /tmp/verify-report.log || { cat /tmp/verify-report.log; exit 1; }
grep -q '^PASS  report says the baseline is red and names the failing test' /tmp/verify-report.log || { cat /tmp/verify-report.log; exit 1; }
grep -q '^PASS  report suggests a fix' /tmp/verify-report.log || { cat /tmp/verify-report.log; exit 1; }
echo 'PASS  verifier can read the explicitly permitted report'
echo '9 passed, 0 failed; 1 boundary failure observed before isolation'
AUDIT
