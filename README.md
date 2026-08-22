# pstack

A port of [pstack](https://github.com/cursor/plugins/tree/main/pstack) by [poteto](https://github.com/poteto) (Lauren Tan) for **Claude Code** and **Codex**.

Upstream pstack is a Cursor plugin: 44 skills for rigorous agent engineering — planning, verification, review panels, PR babysitting, overnight runs. This repo carries all 44 to two other hosts. It is a port, not a rewrite; the skills are poteto's.

## Install

Two independent plugins live here. Install the one for your host.

**Claude Code** — the CLI and the Claude desktop app are the same surface, so this covers both:

```bash
claude plugin marketplace add yashptel/pstack
```

Then `/plugin install pstack@pstack` and `/reload-plugins`.

**Codex** — `--sparse` checks out only the Codex tree:

```bash
codex plugin marketplace add yashptel/pstack --sparse codex/
codex plugin add pstack@pstack
```

Skills are namespaced on both hosts. Claude Code invokes them as `/pstack:poteto-mode`; Codex as `$pstack:poteto-mode`.

## Get started

1. Run `setup-pstack` and choose your models. It writes `~/.claude/pstack-models.md` or `~/.codex/pstack-models.md`, a small file every skill reads. Skip it and the inline defaults apply.
2. Use `poteto-mode` whenever the work needs rigor. It reads your request, picks a playbook, and pulls in the other skills as the steps need them.

The [guide](./docs/guide/README.md) walks a first real task end to end.

## Layout

```
claude-code/    a complete Claude Code plugin  (.claude-plugin/plugin.json)
codex/          a complete Codex plugin        (.codex-plugin/plugin.json)
docs/guide/     the guide, shared
```

The two trees **share no files**. Each is written for its host, so the text you read is the text that runs — no build step, no placeholder substitution. The cost is that every upstream change is applied twice, by hand.

## What this port cannot do

Upstream runs on Cursor, which offers two things neither host here does: a **model panel spanning several vendors** (Anthropic, OpenAI, xAI) and, for Codex, **cloud agents**. Skills that depend on those still run, with the weaker mechanism, and say so where it bites.

| Skill | Claude Code | Codex |
|---|---|---|
| `swarm` | full — cloud workers via `isolation: "remote"` | **local workers only**; keep the fan-out small (2–3, not 10) |
| `poteto-mode` › `orchestrate`, `shipping`, `autopilot-*` | full | local workers only; same caution |
| `arena`, `architect`, `interrogate`, `how` critics | review panel of 3, **single vendor** | review panel of 3, **single vendor** |
| `reflect`, `show-me-your-work`, `figure-it-out` | reviewer on a different model, same vendor | same |
| `recall`, `reflect`, `automate-me`, `show-me-your-work` | transcripts scoped by workspace directory | transcripts filtered by each session's `payload.cwd` — Codex files sessions by date, not by workspace |
| `reflect`, `automate-me`, `poteto-mode` › `authoring-a-skill` | skill authoring inlined — no built-in `create-skill` | same |
| `poteto-mode` UI/CLI verification | harness inlined — no `control-ui` / `control-cli` | same |

Where upstream says "a different model family", this port says "a different model". On a single-vendor host the stronger claim would simply be false, and a review you trust for the wrong reason is worse than one you don't.

**Not ported:** `automations/benny/`, upstream's Slack triage and repro pack. It is built on Cursor's automations product — the skills are prompts fired by Slack events, not skills anyone invokes — and neither host has an equivalent trigger. It stays [upstream](https://github.com/cursor/plugins/tree/main/pstack/automations/benny).

## Versioning and syncing

Versions track upstream with a port suffix: `0.14.2-port.1` is upstream `0.14.2` plus port revision 1. The upstream commit this port has been reconciled against lives in [`.sync-baseline.json`](./.sync-baseline.json).

## License

MIT. Copyright remains with Lauren Tan for the original work; the port adds its own line. See [LICENSE](./LICENSE).
