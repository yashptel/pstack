#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
expected=$(find "$root/.agents/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')

output=$(npx --yes skills add "$root" --list 2>&1 | sed $'s/\033\\[[0-9;]*m//g')
if ! grep -Eq "Found[[:space:]]+$expected[[:space:]]+skills" <<< "$output"; then
	printf 'skills CLI verification failed: expected %s skills\n%s\n' "$expected" "$output" >&2
	exit 1
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
(cd "$tmp" && npx --yes skills add "$root" --agent claude-code --skill poteto-mode --copy --yes --json > install.json)
installed="$tmp/.claude/skills/poteto-mode/SKILL.md"
[ -f "$installed" ] || {
	printf 'skills CLI verification failed: targeted install did not create %s\n' "$installed" >&2
	exit 1
}
cmp -s "$root/.agents/skills/poteto-mode/SKILL.md" "$installed" || {
	printf 'skills CLI verification failed: targeted install differs from portable source\n' >&2
	exit 1
}

printf 'skills CLI discovered %s portable skills and copied poteto-mode correctly\n' "$expected"
