#!/usr/bin/env bash
# TASK-045: the Windows Codex lifecycle batch with the default isolated verifier (windows-assert-exec.sh).
# Runs from the exported controller; the runs folder and the controller are outside the Windows temp folder.
set -u
W=/c/Users/<user>/todo-trials/win-20261108
C="$W/controller/tests/trials"; R="$W/runs2"   # attempt 2; attempt 1 is runs/ with logs in attempt1-logs/
export PYTHONNOUSERSITE=1                                   # the agent's own Python: a host package shadows `tests`
export TRIAL_PYTHON='C:\Users\<user>\AppData\Local\Programs\Python\Python313\python.exe'   # the verifier's (FIX-052)
# The agent's own sandbox cannot start the Microsoft Store python3 alias either (attempt 1): a venv of the same regular
# Python, with python3.exe beside python.exe, goes first on PATH. Maven in that sandbox resolved its local repository
# as C:\.m2 (attempt 1): name the warmed host cache explicitly.
export PATH="$W/agent-python/Scripts:$PATH"
export MAVEN_OPTS="-Dmaven.repo.local=C:/Users/<user>/.m2/repository"
unset TRIAL_WINDOWS_ISOLATION TRIAL_LINUX_ISOLATION
log="$W/batch.log"; : > "$log"
{ date -u +%FT%TZ; codex --version; uname -a; git --version; node --version; mvn -v 2>&1 | head -1; java -version 2>&1 | head -1
  "$TRIAL_PYTHON" --version; python3 -c "import sys; print(sys.executable)"; echo "MAVEN_OPTS=$MAVEN_OPTS"; echo "controller $(cat "$W/controller-sha.txt")"; } > "$W/environment.txt" 2>&1
# Warm the host Maven cache once, outside any sandbox, so the agents and the verifier need no network for Maven.
for s in java-lifecycle multi-module; do
  rm -rf "$W/warm/$s"; mkdir -p "$W/warm"; bash "$C/setup.sh" "$W/warm/$s" "$s" >/dev/null 2>&1
  (cd "$W/warm/$s" && mvn -B -q test) > "$W/warm-$s.log" 2>&1; echo "warm $s exit $?" >> "$log"
done
rm -rf "$W/warm"
for s in happy-path baseline-red interrupted-merge race-claim-conflict ci-local multi-module; do
  echo "$(date -u +%TZ) start $s" >> "$log"
  bash "$C/run-codex.sh" "$R" "$s" > "$W/run-$s.log" 2>&1; echo "$(date -u +%TZ) end $s exit $?" >> "$log"
done
for s in ts-lifecycle java-lifecycle; do
  echo "$(date -u +%TZ) start $s" >> "$log"
  bash "$C/run-codex-multi.sh" "$R" "$s" > "$W/run-$s.log" 2>&1; echo "$(date -u +%TZ) end $s exit $?" >> "$log"
done
bash "$C/score.sh" "$R" > "$W/score.txt" 2>&1; echo "score exit $?" >> "$log"
echo done >> "$log"
