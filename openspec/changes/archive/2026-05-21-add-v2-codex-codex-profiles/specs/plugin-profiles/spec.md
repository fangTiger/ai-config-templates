## ADDED Requirements

### Requirement: V2 Codex-Native Profile Support

The system SHALL provide V2 first-class support for Codex-native `codex-codex-*` profiles while preserving the behavior of the existing V1 Codex profile templates.

#### Scenario: List Codex-native V2 profiles
- **GIVEN** the user is in a V2-capable project
- **WHEN** the user runs `v2/scripts/switch-plugin.sh --list`
- **THEN** the output includes `codex-codex-dev`, `codex-codex-claude-flow-dev`, `codex-codex-claude-flow-gpt55-dev`, and `codex-codex-python-dev`
- **AND** the output distinguishes them as installable V2 profiles

#### Scenario: Install GPT-5.5 Codex-native profile through V2 setup
- **GIVEN** V2 global configuration is installed
- **WHEN** the user runs `v2/setup-project.sh --mode=codex-codex-claude-flow-gpt55-dev`
- **THEN** the project receives root `AGENTS.md`
- **AND** `.codex/config.toml` configures the profile model routing
- **AND** `.codex/agents/worker-codex.toml` and `.codex/agents/review-codex.toml` are installed
- **AND** `.codex/hooks.json`, `.codex/hooks/graphify-query-hook.sh`, `.codex/hooks/post-tool-use-tracker.sh`, `.codex/hooks/skill-activation-prompt.sh`, and `.codex/hooks/skill-activation-prompt.cjs` are installed
- **AND** `.codex/tools/runtime-verification-summary.sh` and `.codex/tools/graphify-java-project.sh` are installed
- **AND** `.codex/session-state.md` and `.codex/session-state.template.md` are installed
- **AND** the project V2 manifest records `mode` as `codex-codex-claude-flow-gpt55-dev`

#### Scenario: Install Python Codex-native profile through V2 setup
- **GIVEN** V2 global configuration is installed
- **WHEN** the user runs `v2/setup-project.sh --mode=codex-codex-python-dev`
- **THEN** `.codex/tools/detect-python-project.sh`, `.codex/tools/verify-python-project.sh`, and `.codex/tools/graphify-python-project.sh` are installed
- **AND** `.codex/skills/codex-python-bootstrap/SKILL.md`, `.codex/skills/codex-python-project/SKILL.md`, `.codex/skills/codex-python-testing/SKILL.md`, and `.codex/skills/codex-python-security/SKILL.md` are installed
- **AND** the project V2 manifest records `mode` as `codex-codex-python-dev`

### Requirement: V2 Codex-Native Profile Switching

The V2 switcher SHALL switch between Claude-oriented profiles and Codex-native profiles without requiring the V1 Codex switcher.

#### Scenario: Switch from V2 codex-dev to Codex-native profile
- **GIVEN** a project has a V2 project manifest with `mode` set to `codex-dev`
- **WHEN** the user runs `v2/scripts/switch-plugin.sh codex-codex-claude-flow-gpt55-dev`
- **THEN** the switcher backs up managed profile assets
- **AND** installs the target profile root `AGENTS.md` and `.codex/` assets
- **AND** updates the project manifest `mode` to `codex-codex-claude-flow-gpt55-dev`
- **AND** reports the active profile as `codex-codex-claude-flow-gpt55-dev`

#### Scenario: Switch from Codex-native profile back to superpowers
- **GIVEN** a project has a V2 project manifest with `mode` set to `codex-codex-claude-flow-gpt55-dev`
- **WHEN** the user runs `v2/scripts/switch-plugin.sh superpowers`
- **THEN** Codex-native managed assets that are not part of the target profile are removed or replaced
- **AND** superpowers `CLAUDE.md`, settings, skills, agents, hooks, commands, and rules are installed
- **AND** the project manifest `mode` is updated to `superpowers`

#### Scenario: Preserve Codex session state during compatible switch
- **GIVEN** `.codex/session-state.md` exists and matches the target profile required fields
- **WHEN** the user switches to a Codex-native V2 profile without requesting reset
- **THEN** the existing `.codex/session-state.md` is preserved
- **AND** missing fields required by the target template are added with default values

#### Scenario: Reset Codex session state explicitly
- **GIVEN** `.codex/session-state.md` exists
- **WHEN** the user switches to a Codex-native V2 profile with an explicit reset option
- **THEN** `.codex/session-state.md` is recreated from `.codex/session-state.template.md`
- **AND** the switcher reports that session state was reset

### Requirement: V2 Codex Documentation

The repository documentation SHALL present V2 as the recommended path for Codex-first users once Codex-native profiles are available in V2.

#### Scenario: README recommends V2 Codex-native profile
- **GIVEN** a user reads `README.md`
- **WHEN** they look for Codex-specific setup
- **THEN** the recommended command uses `v2/setup-project.sh --mode=codex-codex-claude-flow-gpt55-dev`
- **AND** the README identifies V1 `scripts/switch-plugin_codex.sh` as a compatibility path
