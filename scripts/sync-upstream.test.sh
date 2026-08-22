#!/usr/bin/env bash
# Checks that sync-upstream.sh distinguishes an upstream delete and an upstream
# add from an ordinary edit. A deletion reported as "apply the hunk" is the
# failure this guards: it reads as a routine edit and silently means "remove
# your copy". Run: scripts/sync-upstream.test.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

# A fake upstream: baseline has edited.md and doomed.md; HEAD edits one,
# deletes the other, and adds a third.
UP="$TMP/upstream"; mkdir -p "$UP/pstack/skills"
git -C "$UP" init -q
printf 'baseline\n' > "$UP/pstack/skills/edited.md"
printf 'goes away\n' > "$UP/pstack/skills/doomed.md"
git -C "$UP" add -A
git -C "$UP" -c user.email=t@t -c user.name=t commit -qm base
BASE=$(git -C "$UP" rev-parse HEAD)
printf 'baseline changed\n' > "$UP/pstack/skills/edited.md"
rm "$UP/pstack/skills/doomed.md"
printf 'brand new\n' > "$UP/pstack/skills/fresh.md"
git -C "$UP" add -A
git -C "$UP" -c user.email=t@t -c user.name=t commit -qm head

# A fake port that carries the two baseline files verbatim.
PORT="$TMP/port"; mkdir -p "$PORT/claude-code/skills" "$PORT/codex/skills" "$PORT/scripts"
cp "$ROOT/scripts/sync-upstream.sh" "$PORT/scripts/"
for t in claude-code codex; do
  printf 'baseline\n' > "$PORT/$t/skills/edited.md"
  printf 'goes away\n' > "$PORT/$t/skills/doomed.md"
done
cat > "$PORT/.sync-baseline.json" <<JSON
{ "baseline_sha": "$BASE" }
JSON
git -C "$PORT" init -q
git -C "$PORT" remote add upstream "$UP"
git -C "$PORT" add -A
git -C "$PORT" -c user.email=t@t -c user.name=t commit -qm port

# The script fetches upstream/main; the fake upstream's branch may be master.
git -C "$UP" branch -M main 2>/dev/null || true

( cd "$PORT" && ./scripts/sync-upstream.sh --dry-run >/dev/null )
REPORT="$PORT/sync-report.md"

fail=0
check() { if grep -q "$2" "$REPORT"; then echo "  ok   $1"; else echo "  FAIL $1"; fail=1; fi; }

echo "sync-upstream report classification:"
check "upstream delete is called a delete"        'skills/doomed.md` — \*\*upstream DELETED this file\*\*'
check "upstream add is called new"                'skills/fresh.md` — \*\*new upstream file\*\*'
check "ordinary edit still classifies mechanical" 'skills/edited.md` — identical to upstream at baseline'
if grep -A0 'doomed.md' "$REPORT" | grep -q 'apply the hunk'; then
  echo "  FAIL deletion still reads as 'apply the hunk'"; fail=1
else
  echo "  ok   deletion never reads as 'apply the hunk'"
fi

[ "$fail" -eq 0 ] && echo "PASS" || { echo "FAIL"; exit 1; }
