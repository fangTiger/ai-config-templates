## MODIFIED Requirements

### Requirement: codex-codex-dev 专用切换入口

系统 SHALL 提供 `scripts/switch-plugin_codex.sh` 作为受控 Codex-native profiles 的 V1 兼容切换入口，且该入口不承担 Claude profile 的切换职责。

#### Scenario: 切换到 codex-codex-dev 配置

- **GIVEN** 用户在一个包含 `.claude/` 目录的项目中
- **WHEN** 用户执行 `switch-plugin_codex.sh codex-codex-dev`
- **THEN** 项目的 `AGENTS.md`、`.codex/instructions.md`、`.codex/workflow.md`、`.codex/config.toml` 与 `.codex/session-state.md` 被正确落盘
- **AND** `.codex/hooks`、`.codex/commands/openspec` 与 `.codex/skills` 被正确落盘
- **AND** `.claude/settings.json` 中的 Codex hooks 路径指向 `.codex/hooks/...`
- **AND** `.active-plugin` 被设置为 `codex-codex-dev`

#### Scenario: 通过 V1 入口切换到 GPT-5.6 Sol 配置

- **GIVEN** 用户在一个包含 `.claude/` 目录的项目中
- **WHEN** 用户执行 `switch-plugin_codex.sh codex-codex-claude-flow-gpt56-sol-dev`
- **THEN** 项目的 `AGENTS.md`、`.codex/config.toml`、`.codex/agents/worker-codex.toml`、`.codex/agents/review-codex.toml` 与 `.codex/session-state.md` 被正确落盘
- **AND** `.codex/hooks`、`.codex/commands/openspec`、`.codex/skills` 与 `.codex/tools` 被正确落盘
- **AND** `.active-plugin` 被设置为 `codex-codex-claude-flow-gpt56-sol-dev`
- **AND** V1 layout validation succeeds

#### Scenario: 拒绝非 Codex profile

- **GIVEN** 用户在项目目录中执行 Codex 专用切换脚本
- **WHEN** 用户执行 `switch-plugin_codex.sh superpowers`
- **THEN** 脚本以非零状态退出
- **AND** 提示该入口仅支持受控 Codex profiles
- **AND** 提示 Claude profile 应使用 `switch-plugin_claude.sh`

## ADDED Requirements

### Requirement: Independent GPT-5.6 Sol Codex-Native Profile

The system SHALL provide an independent `codex-codex-claude-flow-gpt56-sol-dev` profile that uses GPT-5.6 Sol for architecture work, GPT-5.5 for implementation and review, and does not modify the existing GPT-5.5 profile.

#### Scenario: List the GPT-5.6 Sol V2 profile

- **GIVEN** the user is in a V2-capable project
- **WHEN** the user runs `v2/scripts/switch-plugin.sh --list`
- **THEN** the output includes `codex-codex-claude-flow-gpt56-sol-dev`
- **AND** the existing `codex-codex-claude-flow-gpt55-dev` profile remains listed

#### Scenario: Install the GPT-5.6 Sol profile through V2 setup

- **GIVEN** V2 global configuration is installed
- **WHEN** the user runs `v2/setup-project.sh --mode=codex-codex-claude-flow-gpt56-sol-dev`
- **THEN** the project receives the target root `AGENTS.md` and profile-specific `.codex` assets
- **AND** shared Codex hooks, tools, and workflow skills are installed before profile overrides
- **AND** the project V2 manifest records `mode` as `codex-codex-claude-flow-gpt56-sol-dev`
- **AND** `.codex/session-state.md` identifies `codex-codex-claude-flow-gpt56-sol-dev`

#### Scenario: Apply the approved model routing

- **GIVEN** `codex-codex-claude-flow-gpt56-sol-dev` is installed
- **WHEN** the installed TOML configuration is parsed
- **THEN** `.codex/config.toml` selects `gpt-5.6-sol` from the `openai` provider with `xhigh` reasoning
- **AND** `.codex/agents/worker-codex.toml` selects `gpt-5.5` from the `openai` provider with `xhigh` reasoning and `workspace-write` sandboxing
- **AND** `.codex/agents/review-codex.toml` selects `gpt-5.5` from the `openai` provider with `xhigh` reasoning and `read-only` sandboxing

#### Scenario: Switch from GPT-5.5 to GPT-5.6 Sol through V2

- **GIVEN** a project has a V2 manifest with `mode` set to `codex-codex-claude-flow-gpt55-dev`
- **WHEN** the user runs `v2/scripts/switch-plugin.sh codex-codex-claude-flow-gpt56-sol-dev`
- **THEN** the target profile assets replace the managed GPT-5.5 profile assets
- **AND** the project manifest `mode` is updated to `codex-codex-claude-flow-gpt56-sol-dev`
- **AND** incompatible GPT-5.5 session state is reinitialized from the GPT-5.6 Sol template

#### Scenario: Preserve the existing GPT-5.5 profile

- **GIVEN** both GPT-5.5 and GPT-5.6 Sol profile templates exist
- **WHEN** their source TOML files are parsed
- **THEN** the GPT-5.5 profile continues to route Architecture Codex to `gpt-5.5`
- **AND** its worker and review agents continue to route to `gpt-5.4`
- **AND** all three GPT-5.5 profile roles retain `xhigh` reasoning

#### Scenario: Document both switching paths

- **GIVEN** a user reads `README.md` for Codex profile commands
- **WHEN** they look for GPT-5.6 Sol
- **THEN** the documentation includes the V2 setup and switch commands for `codex-codex-claude-flow-gpt56-sol-dev`
- **AND** the documentation includes the V1 compatibility switch command
- **AND** the existing GPT-5.5 recommendation remains available
