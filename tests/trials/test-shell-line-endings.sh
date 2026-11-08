#!/usr/bin/env bash
# Simulate an autocrlf Windows checkout, then run a copied tool on Linux.
set -eu
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/source/tools" "$tmp/out"
cp "$root/tools/todo-lint.sh" "$tmp/source/tools/"
[ ! -f "$root/.gitattributes" ] || cp "$root/.gitattributes" "$tmp/source/"
git -C "$tmp/source" init -q
git -C "$tmp/source" config core.autocrlf true
git -C "$tmp/source" add -- tools/todo-lint.sh
if [ -f "$tmp/source/.gitattributes" ]; then git -C "$tmp/source" add -- .gitattributes; fi
git -C "$tmp/source" checkout-index --all --prefix="$tmp/out/"
sed 's/\r$//' "$root/tools/todo-lint.sh" > "$tmp/control.sh"
cp "$root/TODO.md" "$tmp/valid.md"
cp "$root/CHANGELOG.md" "$tmp/CHANGELOG.md"
cp "$tmp/valid.md" "$tmp/invalid.md"
printf '\n- [ ] **FIX-999** · P1 · low · Missing verification\n' >> "$tmp/invalid.md"
cat > "$tmp/verify.sh" <<'VERIFY'
set -eu
cd /trial
if LC_ALL=C grep -q "$(printf '\r')" out/tools/todo-lint.sh; then echo 'FAIL  checkout contains CRLF'; exit 1; fi
mkdir -p out/.todo
cp out/tools/todo-lint.sh out/.todo/todo-lint.sh
for fixture in valid invalid; do
  set +e
  bash control.sh "$fixture.md" CHANGELOG.md > "$fixture.expected" 2>&1; expected=$?
  bash out/.todo/todo-lint.sh "$fixture.md" CHANGELOG.md > "$fixture.actual" 2>&1; actual=$?
  set -e
  [ "$expected" = "$actual" ] && cmp "$fixture.expected" "$fixture.actual" || { echo "FAIL  $fixture lint behavior differs"; exit 1; }
  if [ "$fixture" = valid ]; then [ "$actual" = 0 ]; else [ "$actual" != 0 ]; fi
  echo "PASS  $fixture lint behavior matches"
done
echo '3 passed, 0 failed'
VERIFY
if [ "$(uname -s)" = Linux ]; then
  # The verification script uses /trial to match the isolated Linux container.
  sed "s|cd /trial|cd '$tmp'|" "$tmp/verify.sh" > "$tmp/verify-local.sh"
  bash "$tmp/verify-local.sh"
else
  src="$tmp"; if command -v cygpath >/dev/null 2>&1; then src="$(cygpath -m "$tmp")"; fi
  MSYS_NO_PATHCONV=1 docker run --rm --network none --mount "type=bind,src=$src,dst=/trial" \
    --entrypoint /bin/bash "${TRIAL_AUDIT_IMAGE:-todo-codex-linux:0.167.0}" /trial/verify.sh
fi
