#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

model_pattern='(^|[^[:alnum:]_])(gpt-[0-9][[:alnum:]._-]*|claude-[[:alnum:]._-]+|grok-[0-9][[:alnum:]._-]*|o[1-9][[:alnum:]._-]*|sonnet|opus|haiku|fable|gemini|deepseek|qwen|mistral|llama)([^[:alnum:]_]|$)'
set +e
matches=$(LC_ALL=C grep -RinE -- "$model_pattern" "$root/claude-code/skills" "$root/codex/skills" 2>/dev/null)
status=$?
set -e

if [ "$status" -ne 1 ] && [ "$status" -ne 0 ]; then
	printf 'model-neutral verification failed: could not scan host catalogs\n' >&2
	exit 1
fi

if [ -n "$matches" ]; then
	printf 'model-neutral verification failed: hardcoded model identifiers found\n%s\n' "$matches" >&2
	exit 1
fi

printf 'host catalogs are model-neutral\n'
