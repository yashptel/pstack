#!/usr/bin/env bash
set -euo pipefail

MODE=${1:---dry-run}
case "$MODE" in
  --dry-run|--publish) ;;
  *) echo "usage: $0 [--dry-run|--publish]" >&2; exit 2 ;;
esac
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BASE=$(python3 -c "import json;print(json.load(open('.sync-baseline.json'))['baseline_sha'])")

git remote get-url upstream >/dev/null 2>&1 || git remote add upstream https://github.com/cursor/plugins
git fetch -q upstream main
HEAD_SHA=$(git rev-parse upstream/main)

if [ "$BASE" = "$HEAD_SHA" ]; then
  echo "up to date at $BASE"
  exit 0
fi

# --name-status, not --name-only: the status letter is what tells a deletion
# apart from an edit. Without it an upstream delete reads as a routine hunk.
# --no-renames keeps renames as a delete plus an add, which is what the
# checklist wants anyway (two files to act on, in two trees).
CHANGED=$(git diff --no-renames --name-status "$BASE" "$HEAD_SHA" -- pstack/ || true)
if [ -z "$CHANGED" ]; then
  echo "upstream moved ($BASE -> $HEAD_SHA) but nothing under pstack/ changed"
  exit 0
fi

# Where an upstream path lands in this repo. Echoes zero or more local paths.
destinations() {
  case "$1" in
    pstack/automations/*) return 0 ;;                       # not ported
    pstack/docs/guide/*)  echo "docs/${1#pstack/docs/}" ;;   # single shared copy
    pstack/skills/*)
      rel="${1#pstack/}"
      echo "claude-code/$rel"
      echo "codex/$rel"
      echo ".agents/$rel" ;;
    pstack/agents/*)
      rel="${1#pstack/}"
      echo "claude-code/$rel"
      echo "codex/$rel" ;;
    pstack/README.md)     echo "README.md" ;;
    pstack/.cursor-plugin/plugin.json)
      echo "claude-code/.claude-plugin/plugin.json"
      echo "codex/.codex-plugin/plugin.json" ;;
    *) return 0 ;;
  esac
}

# Did we keep this file as upstream had it at the baseline, or rewrite it?
# Comparing against the BASELINE (not upstream HEAD) is the point: a difference
# means a deliberate port edit, not just upstream drift.
classify() {
  local local_path="$1" upstream_path="$2"
  [ -e "$local_path" ] || { echo dropped; return; }
  local n
  n=$(git show "$BASE:$upstream_path" 2>/dev/null | diff - "$local_path" 2>/dev/null | grep -c '^[<>]' || true)
  if [ "${n:-0}" -eq 0 ]; then echo "verbatim 0"
  elif [ "${n:-0}" -le 6 ]; then echo "light $n"
  else echo "rewritten $n"
  fi
}

{
  echo "## Upstream pstack moved"
  echo
  echo "\`$BASE\` → \`$HEAD_SHA\`"
  echo
  echo "Nothing here is merged automatically. Work the checklist, apply each change to the host trees and portable catalog"
  echo "by hand, then merge this PR — merging is what records the new baseline."
  echo
  echo "### Checklist"
  echo

  mechanical=0; decisions=0; dropped=0; removals=0; additions=0
  while IFS=$'\t' read -r status up; do
    [ -n "$up" ] || continue
    dests=$(destinations "$up")
    if [ -z "$dests" ]; then
      echo "- [ ] \`$up\` ($status) — **not carried by this port** (benny, or a Cursor-only file); confirm it should stay that way"
      dropped=$((dropped+1))
      continue
    fi
    while IFS= read -r d; do
      [ -n "$d" ] || continue

      case "$status" in
        D*)
          if [ -e "$d" ]; then
            echo "- [ ] \`$d\` — **upstream DELETED this file**; delete your copy (check nothing in this tree still references it)"
          else
            echo "- [ ] \`$d\` — upstream deleted it and this tree does not have it; nothing to do"
          fi
          removals=$((removals+1)); continue ;;
        A*)
          if [ -e "$d" ]; then
            echo "- [ ] \`$d\` — upstream ADDED this file and this tree already has one; reconcile the two"
          else
            echo "- [ ] \`$d\` — **new upstream file**; port it into this tree (apply the sigil, path, model, and spawn passes)"
          fi
          additions=$((additions+1)); continue ;;
      esac

      read -r kind n <<< "$(classify "$d" "$up")"
      case "$kind" in
        verbatim)
          echo "- [ ] \`$d\` — identical to upstream at baseline, so this is **mechanical**: apply the hunk"
          mechanical=$((mechanical+1)) ;;
        light)
          echo "- [ ] \`$d\` — diverges from baseline by only $n lines (likely the sigil/path pass), so this is **probably mechanical**; check the hunk does not touch a ported line"
          mechanical=$((mechanical+1)) ;;
        rewritten)
          echo "- [ ] \`$d\` — **rewritten for this host** ($n lines diverge); re-make the decision, do not paste the hunk"
          decisions=$((decisions+1)) ;;
        dropped)
          echo "- [ ] \`$d\` — missing locally; decide whether it should now exist"
          dropped=$((dropped+1)) ;;
      esac
    done <<< "$dests"
  done <<< "$CHANGED"

  echo
  echo "$mechanical mechanical or near-mechanical, $decisions needing a decision, $additions added upstream, $removals deleted upstream, $dropped not carried."
  echo
  echo "### Upstream diff"
  echo
  echo '```diff'
  git diff "$BASE" "$HEAD_SHA" -- pstack/ | head -c 40000
  echo '```'
  echo
  echo "_Diff truncated at 40 KB if longer; run \`git diff $BASE $HEAD_SHA -- pstack/\` for the rest._"
} > sync-report.md

echo "wrote sync-report.md ($(wc -l < sync-report.md) lines)"

if [ "$MODE" = "--dry-run" ]; then exit 0; fi

BRANCH="sync/upstream-${HEAD_SHA:0:7}"
git checkout -qB "$BRANCH"
python3 - "$HEAD_SHA" <<'PY'
import json,sys,datetime
p='.sync-baseline.json'; d=json.load(open(p))
d['baseline_sha']=sys.argv[1]
d['baseline_date']=datetime.date.today().isoformat()
json.dump(d,open(p,'w'),indent=2); open(p,'a').write('\n')
PY
git add .sync-baseline.json
git -c user.name="pstack sync" -c user.email="noreply@github.com" \
  commit -qm "Sync baseline to upstream ${HEAD_SHA:0:7}"
git push -qf origin "$BRANCH"
# -R is not optional: the `upstream` remote points at cursor/plugins, and gh
# will happily resolve to it and try to open the PR against poteto's repo.
ORIGIN_REPO=$(git remote get-url origin | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##')
gh pr create -R "$ORIGIN_REPO" \
  --title "Upstream sync: ${HEAD_SHA:0:7}" \
  --body-file sync-report.md --head "$BRANCH" --base main
