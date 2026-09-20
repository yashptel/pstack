#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
skills_root="$root/.agents/skills"

fail() {
	printf 'portable verification failed: %s\n' "$*" >&2
	exit 1
}

[ -d "$skills_root" ] || fail "missing .agents/skills"

stray_entry=$(find "$skills_root" -mindepth 1 -maxdepth 1 ! -type d -print -quit)
[ -z "$stray_entry" ] || fail "catalog contains a non-skill entry: ${stray_entry#$root/}"

first_skill=$(find "$skills_root" -mindepth 1 -maxdepth 1 -type d -print -quit)
[ -n "$first_skill" ] || fail "catalog contains no skill directories"

symlink=$(find "$skills_root" -type l -print -quit)
[ -z "$symlink" ] || fail "catalog contains a symlink: ${symlink#$root/}"

names=''
skill_count=0
while IFS= read -r skill_dir; do
	skill_file="$skill_dir/SKILL.md"
	[ -f "$skill_file" ] || fail "missing SKILL.md: ${skill_dir#$root/}"

	name=$(
		awk '
			NR == 1 {
				if ($0 != "---") exit 1
				open = 1
				next
			}
			open && $0 == "---" {
				closed = 1
				exit
			}
			open && $0 ~ /^name:[[:space:]]*[^[:space:]]/ {
				value = $0
				sub(/^name:[[:space:]]*/, "", value)
				sub(/[[:space:]]+$/, "", value)
				name = value
				name_count++
			}
			open && $0 ~ /^description:[[:space:]]*[^[:space:]]/ {
				description_count++
			}
			END {
				if (!open || !closed || name_count != 1 || description_count != 1) exit 1
				print name
			}
		' "$skill_file"
	) || fail "invalid SKILL.md frontmatter: ${skill_file#$root/}"

	[ "$(basename "$skill_dir")" = "$name" ] || fail "directory and frontmatter name differ: ${skill_dir#$root/} -> $name"
	names="${names}${name}"$'\n'
	skill_count=$((skill_count + 1))
done < <(find "$skills_root" -mindepth 1 -maxdepth 1 -type d -print | LC_ALL=C sort)

duplicates=$(printf '%s' "$names" | LC_ALL=C sort | uniq -d)
[ -z "$duplicates" ] || fail "duplicate skill names: $(printf '%s' "$duplicates" | tr '\n' ' ')"

forbidden_pattern='(\$pstack:|/pstack:|~/.codex|~/.claude|\.codex/|\.claude/|(^|[^[:alnum:]_])(codex|claude)([^[:alnum:]_]|$)|(^|[^[:alnum:]_])Cursor([^[:alnum:]_]|$)|CURSOR_AUTOMATION_ID|cursor_automation_id|AskQuestion|Agent[- ]tool|Task (subagent|call)|WebFetch|WebSearch|`(Task|Read|Write|Edit|Bash|Glob|Grep)`|(^|[^[:alnum:]_])(gpt-[0-9][[:alnum:]._-]*|claude-[[:alnum:]._-]+|o[1-9][[:alnum:]._-]*|sonnet|opus|haiku|gemini|deepseek|qwen|mistral|llama)([^[:alnum:]_]|$))'
set +e
forbidden=$(LC_ALL=C grep -RinE -- "$forbidden_pattern" "$skills_root" 2>/dev/null)
grep_status=$?
set -e
[ "$grep_status" -eq 1 ] || [ "$grep_status" -eq 0 ] || fail "could not scan portable files"
if [ -n "$forbidden" ]; then
	printf 'portable verification failed: host-specific content found\n%s\n' "$forbidden" >&2
	exit 1
fi

poteto_root="$skills_root/poteto-mode"
[ -d "$poteto_root" ] || fail "missing poteto-mode skill"

expected_poteto_files=$(cat <<'EOF'
SKILL.md
playbooks/authoring-a-skill.md
playbooks/autonomous-run.md
playbooks/autopilot-full.md
playbooks/autopilot-stack.md
playbooks/babysit.md
playbooks/bug-fix.md
playbooks/eval.md
playbooks/feature.md
playbooks/hillclimb.md
playbooks/investigation.md
playbooks/multi-phase-plan.md
playbooks/opening-a-pr.md
playbooks/orchestrate.md
playbooks/pause-safely.md
playbooks/perf-issue.md
playbooks/prototype.md
playbooks/refactoring.md
playbooks/runtime-forensics.md
playbooks/session-pickup.md
playbooks/shipping.md
playbooks/trace-forensics.md
playbooks/visual-parity.md
playbooks/worktree-cleanup.md
references/bugbot-triage.md
references/plan.md
scripts/bootstrap.ts
scripts/bun.lock
scripts/orch/orch.test.ts
scripts/orch/orch.ts
scripts/orch/store.ts
scripts/package.json
scripts/watch-pr/cli.test.ts
scripts/watch-pr/cli.ts
scripts/watch-pr/fakes.test-helper.ts
scripts/watch-pr/github.test.ts
scripts/watch-pr/github.ts
scripts/watch-pr/policy.test.ts
scripts/watch-pr/policy.ts
scripts/watch-pr/render.ts
scripts/watch-pr/tsconfig.json
scripts/watch-pr/types.compile.ts
scripts/watch-pr/types.ts
scripts/watch-pr/watch-pr
scripts/worktree-audit.sh
EOF
)
actual_poteto_files=$(cd "$poteto_root" && find . -type f -print | sed 's#^\./##' | LC_ALL=C sort)
expected_poteto_files=$(printf '%s\n' "$expected_poteto_files" | sed '/^$/d' | LC_ALL=C sort)
[ "$actual_poteto_files" = "$expected_poteto_files" ] || {
	printf 'portable verification failed: poteto-mode file closure differs\n' >&2
	diff -u <(printf '%s\n' "$expected_poteto_files") <(printf '%s\n' "$actual_poteto_files") >&2 || true
	exit 1
}

printf 'portable catalog verified: %s skills\n' "$skill_count"
