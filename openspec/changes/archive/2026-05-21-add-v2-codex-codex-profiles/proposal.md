# Change: Add V2 Codex-Codex Profiles

## Why
V1 already provides the strongest Codex-first experience through `codex-codex-*` profiles, while V2 currently only exposes the lighter `codex-dev` profile. Users who primarily work in Codex need those Codex-native workflows promoted into V2 without losing V2 manifest, drift detection, backup, and layered configuration benefits.

## What Changes
- Add first-class V2 support for the V1 Codex-native profiles: `codex-codex-dev`, `codex-codex-claude-flow-dev`, `codex-codex-claude-flow-gpt55-dev`, and `codex-codex-python-dev`.
- Extend V2 project setup and switching so Codex-native profiles install full `.codex/` assets, root `AGENTS.md`, session-state templates, hooks, tools, agents, commands, and skills.
- Preserve or migrate existing `.codex/session-state.md` during profile switches unless the user explicitly requests a reset.
- Keep V1 `scripts/switch-plugin_codex.sh` as a compatibility path, while documenting V2 as the recommended Codex-first path.
- Add tests or scripted verification for V2 Codex profile layout, profile rejection, manifest updates, and session-state behavior.

## Impact
- Affected specs: `plugin-profiles`
- Affected code: `v2/setup-project.sh`, `v2/scripts/switch-plugin.sh`, `v2/scripts/plugin-profiles/`, `README.md`, tests for shell/profile layout behavior
