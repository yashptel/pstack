# pstack

A port of [pstack](https://github.com/cursor/plugins/tree/main/pstack) by [poteto](https://github.com/poteto) (Lauren Tan) for **Claude Code** and **Codex**. Upstream pstack is a Cursor plugin; this repo carries the same skills to two other hosts.

> Skeleton only right now — the trees are empty. The port is in progress.

## Layout

Two complete plugin roots, one per host. They do not share files: each tree is written for its host, so the text you read is the text that runs.

```
claude-code/    a Claude Code plugin  (.claude-plugin/plugin.json)
codex/          a Codex plugin        (.codex-plugin/plugin.json)
```

## Install

Nothing to install yet. When the trees are populated:

**Claude Code** — the CLI and the Claude desktop app are the same surface; these instructions cover both.

```bash
claude plugin marketplace add yashptel/pstack
```

**Codex** — `--sparse` checks out just the Codex tree.

```bash
codex plugin marketplace add yashptel/pstack --sparse codex/
```

## Versioning

Versions track upstream with a port suffix: `0.14.2-port.1` is upstream `0.14.2` plus port-side revision 1. The exact upstream commit this port has been reconciled against lives in [`.sync-baseline.json`](./.sync-baseline.json).

## What is not here

Some upstream features cannot travel. This section will list them as the port lands — including `automations/benny/`, which is built on Cursor's automations product and has no equivalent on either host.

## License

MIT. Copyright remains with Lauren Tan for the original work; the port carries an additional copyright line. See [LICENSE](./LICENSE).
