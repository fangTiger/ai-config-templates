## MODIFIED Requirements

### Requirement: V2 Codex-Native Profile Support

The system SHALL provide V2 first-class support for Codex-native `codex-codex-*` profiles while preserving the behavior of the existing V1 Codex profile templates and SHALL install common Codex-native runtime assets from a shared Codex asset layer before applying profile-specific overrides.

#### Scenario: List Codex-native V2 profiles
- **GIVEN** the user is in a V2-capable project
- **WHEN** the user runs `v2/scripts/switch-plugin.sh --list`
- **THEN** the output includes `codex-codex-dev`, `codex-codex-claude-flow-dev`, and `codex-codex-claude-flow-gpt55-dev`
- **AND** the output distinguishes them as installable V2 profiles

#### Scenario: Install GPT-5.5 Codex-native profile through V2 setup
- **GIVEN** V2 global configuration is installed
- **WHEN** the user runs `v2/setup-project.sh --mode=codex-codex-claude-flow-gpt55-dev`
- **THEN** the project receives root `AGENTS.md`
- **AND** `.codex/config.toml` configures the profile model routing
- **AND** `.codex/agents/worker-codex.toml` and `.codex/agents/review-codex.toml` are installed
- **AND** `.codex/hooks.json`, `.codex/hooks/graphify-query-hook.sh`, `.codex/hooks/post-tool-use-tracker.sh`, `.codex/hooks/skill-activation-prompt.sh`, and `.codex/hooks/skill-activation-prompt.cjs` are installed
- **AND** `.codex/tools/runtime-verification-summary.sh` and `.codex/tools/graphify-java-project.sh` are installed
- **AND** common Codex workflow skills are installed from the shared Codex asset layer unless overridden by the target profile
- **AND** `.codex/session-state.md` and `.codex/session-state.template.md` are installed
- **AND** the project V2 manifest records `mode` as `codex-codex-claude-flow-gpt55-dev`

#### Scenario: Shared Codex runtime assets stay profile-independent
- **GIVEN** V2 global configuration is installed
- **WHEN** the user installs any maintained Codex-native V2 profile
- **THEN** `.codex/tools/runtime-verification-summary.sh` is installed from the shared Codex asset layer
- **AND** common Codex workflow skills are installed from the shared Codex asset layer unless overridden by the target profile
