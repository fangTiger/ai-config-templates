# Change: Add Independent Codex GPT-5.6 Sol Profile

## Why

The maintained Codex-native profiles stop at GPT-5.5 for the architecture thread and GPT-5.4 for worker and review agents. Codex now exposes GPT-5.6 Sol, so users need an independent profile that adopts the new architecture model without changing or removing the existing GPT-5.5 profile.

## What Changes

- Add `codex-codex-claude-flow-gpt56-sol-dev` as an independent Codex-native profile.
- Route Architecture Codex to `gpt-5.6-sol` with `xhigh` reasoning.
- Route `worker-codex` and `review-codex` to `gpt-5.5` with `xhigh` reasoning.
- Support the new profile through both the V2 setup/switch flow and the V1 Codex compatibility switcher.
- Preserve the existing `codex-codex-claude-flow-gpt55-dev` profile and its current model routing.
- Add source-level and installed-runtime tests for profile discovery, switching, session state, and actual TOML model routing.
- Document the V2 and V1 commands for the new profile.

## Impact

- Affected specs: `plugin-profiles`
- Affected code: `.gitignore`, `scripts/switch-plugin_codex.sh`, `scripts/plugin-profiles/codex-codex-claude-flow-gpt56-sol-dev/**`, `v2/scripts/plugin-profiles/codex-codex-claude-flow-gpt56-sol-dev/**`, `tests/test_v1_codex_profiles.py`, `tests/test_v2_codex_profiles.py`, `README.md`
- Compatibility: additive; no existing profile is renamed, removed, or rerouted
