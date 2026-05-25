## 1. Profile Templates
- [x] 1.1 Port `codex-codex-dev` into `v2/scripts/plugin-profiles/`.
- [x] 1.2 Port `codex-codex-claude-flow-dev` into `v2/scripts/plugin-profiles/`.
- [x] 1.3 Port `codex-codex-claude-flow-gpt55-dev` into `v2/scripts/plugin-profiles/`.
- [x] 1.4 Port `codex-codex-python-dev` into `v2/scripts/plugin-profiles/`.

## 2. V2 Installer And Switcher
- [x] 2.1 Extend `v2/setup-project.sh --mode=<profile>` to accept Codex-native profiles.
- [x] 2.2 Extend `v2/scripts/switch-plugin.sh` to list, validate, install, and report Codex-native profiles.
- [x] 2.3 Preserve existing `.codex/session-state.md` by default and add an explicit reset path for incompatible or user-requested resets.
- [x] 2.4 Ensure root `AGENTS.md`, `.codex/config.toml`, `.codex/agents`, `.codex/hooks`, `.codex/tools`, `.codex/commands`, and `.codex/skills` are installed for Codex-native profiles.
- [x] 2.5 Keep `.claude/.harness-manifest.json` updated with the active V2 profile name and template hash.

## 3. Tests And Verification
- [x] 3.1 Add shell or Python tests that install each Codex-native profile into a temporary project and assert required files exist.
- [x] 3.2 Add tests for invalid profile rejection and `--list` / `--status` output.
- [x] 3.3 Add tests for session-state preservation and explicit reset behavior.
- [x] 3.4 Run syntax checks for modified shell scripts.
- [x] 3.5 Run OpenSpec strict validation.

## 4. Documentation
- [x] 4.1 Update `README.md` to make V2 the recommended path for Codex-first users.
- [x] 4.2 Document V1 `scripts/switch-plugin_codex.sh` as compatibility-only.
- [x] 4.3 Document recommended V2 commands for `codex-codex-claude-flow-gpt55-dev` and `codex-codex-python-dev`.
