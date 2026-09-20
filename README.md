# pstack

A port of [pstack](https://github.com/cursor/plugins/tree/main/pstack) by [poteto](https://github.com/poteto) (Lauren Tan) for **Claude Code**, **Codex**, and Agent Skills-compatible harnesses.

Upstream pstack is a Cursor plugin for rigorous agent engineering — planning, verification, review panels, PR babysitting, overnight runs. This repo carries 46 host-compatible skills to Claude Code, Codex, and any harness that implements the Agent Skills format. It is a port, not a rewrite; the skills are poteto's.

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

**Codex also needs its subagents installed by hand.** Codex plugins do not activate shipped subagents: on codex-cli 0.149.0 the plugin's `agents/*.toml` are copied into the plugin cache but never registered, and the same file placed in `~/.codex/agents/` registers immediately. Copy them across:

```bash
cp ~/.codex/plugins/cache/pstack/pstack/*/agents/*.toml ~/.codex/agents/
```

Without this, `no-comments` and `poteto-mode` will reference subagents Codex cannot spawn.

**Any Agent Skills-compatible harness** — install the portable catalog with the [Skills CLI](https://www.skills.sh/docs/cli):

```bash
npx skills add yashptel/pstack --all
```

The portable catalog lives in `.agents/skills/`, so the CLI can target Claude Code, Codex, Cursor, Gemini CLI, GitHub Copilot, and other supported harnesses. Use `--agent` to select a target or `--skill` to install only the skills you need. This installs skill prompts and their adjacent assets; host plugin manifests and Codex subagent registrations still require the native install above.

Skills are namespaced on both hosts. Claude Code invokes them as `/pstack:poteto-mode`; Codex as `$pstack:poteto-mode`.

## Get started

1. Run `setup-pstack` and choose any available models, or choose `inherit-parent`/`auto` to follow the current host model. It writes `~/.claude/pstack-models.md` or `~/.codex/pstack-models.md`, a small file every skill reads. Skip it and the host chooses the current model.
2. Use `poteto-mode` whenever the work needs rigor. It reads your request, picks a playbook, and pulls in the other skills as the steps need them.

The [guide](./docs/guide/README.md) walks a first real task end to end.

## Layout

```
claude-code/    a complete Claude Code plugin  (.claude-plugin/plugin.json)
codex/          a complete Codex plugin        (.codex-plugin/plugin.json)
.agents/skills/ portable Agent Skills catalog  (npx skills add)
docs/guide/     the guide, shared
```

The host trees **share no files**. Each is written for its host, so the text you read is the text that runs — no build step, no placeholder substitution. `.agents/skills/` is a third, host-neutral catalog for the common installer surface; it intentionally omits host plugin manifests, subagent registrations, and host-specific tool syntax. The sync report names every maintained destination so an upstream change is not applied to only one catalog.

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
| `comment-sicko`, `poteto-agent` subagents | ship with the plugin | **must be copied to `~/.codex/agents/` by hand** — plugin subagents do not activate |

Where upstream says "a different model family", this port says "a different model". On a single-vendor host the stronger claim would simply be false, and a review you trust for the wrong reason is worse than one you don't.

**Not ported:** `automations/benny/`, upstream's Slack triage and repro pack, `make-bot-ui`, which depends on Cursor-only routines, webhooks, and UI tooling, and the expanded Cursor-specific multi-phase plan checker. They are not honest portable behavior. Benny stays [upstream](https://github.com/cursor/plugins/tree/main/pstack/automations/benny).

### A note on Codex skill budget

46 skills is a lot for one plugin. Codex warns that *"skill descriptions were shortened to fit the skills context budget"* when pstack is installed alongside other plugins. Everything still works — Codex sees every skill — but if you rely on model-invoked triggering rather than typing `$pstack:<name>`, consider disabling plugins you are not using.

## Versioning and syncing

Versions track upstream with a port suffix: `0.15.2-port.2` is upstream `0.15.2` plus port revision 2. The upstream commit this port has been reconciled against lives in [`.sync-baseline.json`](./.sync-baseline.json). `scripts/sync-upstream.sh` is report-only by default. CI passes `--publish` after the report has been reviewed so local audits cannot create branches or pull requests by accident.

Maintainers can verify the three contracts directly:

```bash
scripts/verify-portable.sh
scripts/verify-model-neutral.sh
scripts/verify-skills-cli.sh
scripts/sync-upstream.test.sh
```

## License

MIT. Copyright remains with Lauren Tan for the original work; the port adds its own line. See [LICENSE](./LICENSE).
