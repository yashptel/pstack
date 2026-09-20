---
name: setup-pstack
description: Configure which models pstack uses per role. Detects your available models and writes an always-applied rule that overrides the skill defaults. Use for "configure pstack models" or changing pstack's model choices.
---

# Setup pstack

Use the host's native model-configuration mechanism to set pstack's model per role. Skills read the configured role when available and fall back to the current host's model when it is absent, so this is an override layer, not a requirement.

## Steps

### 1. Detect available models

Enumerate the model identifiers you can pass to a subagent in this session; that is the dependable source. If the host exposes a models API or interface that lists your entitled models, prefer it for completeness. If you cannot detect any, ask the user to provide the identifiers they can use. Never write an identifier you have not confirmed is available. The aliases `inherit-parent` and `auto` are always valid even though they are not detected identifiers.

### 2. Load current state

The default role-to-model mapping is the rule shape shown in step 5 below. Load the host's current pstack model configuration when it exists and treat its values as the current choices. Otherwise start from those defaults.

### 3. Map and confirm

Show every role with its current model, marking any real identifier not in the detected set as needing a choice. Ask whether to accept it or change specific roles, offering the detected models plus `inherit-parent` and `auto` (both mean this role runs on the parent chat model) as the options. Use the host's native clarification mechanism. For panel roles (how critics, arena runners, architect runners, interrogate reviewers) the value is a list, and one subagent runs per entry, alias entries included, so the list length sets the count. `arena cross-judge pool` is also a list, but Arena selects one value from it whose model family differs from the parent's when possible. `swarm workers` is the default model for every worker unless a race or comparison assigns another model per arm.

### 4. Validate

Every real identifier written must be in the detected set; `inherit-parent` and `auto` always pass. If a chosen identifier is not available, stop and ask again. A rule pointing at a model the user cannot use breaks every delegation that reads it.

### 5. Write the rule

Apply the configuration through the host's native mechanism and use one line per role when it supports a text-based rule. Overwrite the whole rule so re-runs stay idempotent. Shape:

```
---
description: pstack per-role model choices (overrides skill defaults)
alwaysApply: true
---
# pstack model configuration. One line per role. Delete a line to fall back to the host default.
# `inherit-parent` or `auto` as a value means the role runs on the parent chat model.
feature, refactoring: <configured model>
bug-fix: <configured model>
perf-issue: <configured model>
hillclimb: <configured model>
judgment and prose: <configured model>
hardest tasks: <configured model>
how explorer: <configured model>
how explainer: <configured model>
how critics: <configured model>, <configured model>
why investigators: <configured model>
why synthesizer: <configured model>
reflect tooling: <configured model>
reflect judgment, divergent, synthesizer: <configured model>
arena runners: <configured model>, <configured model>
arena cross-judge pool: <configured model>, <configured model>
swarm workers: <configured model>
architect runners: <configured model>, <configured model>
interrogate reviewers: <configured model>, <configured model>
```

### 6. Confirm

Tell the user the rule was written and that it applies to new sessions. Re-running this skill updates it.

### 7. Offer a verification skill (optional)

Check whether the project has a way to drive the real app for proof (a `verify-*` skill, or an existing harness). If not, offer once: "want a project-local verification skill, so agents can drive the app the way a user does and prove changes work? I can generate one with the `create-verification-skill` skill." On yes, invoke that skill through the host's native skill mechanism. On no, move on without pushing.
