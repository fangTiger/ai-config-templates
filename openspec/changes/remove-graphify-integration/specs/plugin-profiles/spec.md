## REMOVED Requirements

### Requirement: Graphify 资产安装

**Reason**: Graphify 图谱数据在实际使用中频繁过期或缺失，降级路径被频繁触发，
hook 注入的提示成为噪声而非上下文；维护成本与收益不匹配。

**Migration**: 无需迁移。已安装项目在下次切换或初始化后自动不再获得 Graphify hook。
项目中已生成的 `graphify-out/` 与 `.graphifyignore` 属用户数据，不会被删除，可自行清理。

## MODIFIED Requirements

### Requirement: V2 Codex-Native Profile Support

The system SHALL provide V2 first-class support for Codex-native `codex-codex-*` profiles while preserving the behavior of the existing V1 Codex profile templates.

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
- **AND** `.codex/hooks.json`, `.codex/hooks/post-tool-use-tracker.sh`, `.codex/hooks/skill-activation-prompt.sh`, and `.codex/hooks/skill-activation-prompt.cjs` are installed
- **AND** `.codex/tools/runtime-verification-summary.sh` is installed
- **AND** `.codex/session-state.md` and `.codex/session-state.template.md` are installed
- **AND** the project V2 manifest records `mode` as `codex-codex-claude-flow-gpt55-dev`

#### Scenario: Reject removed Python Codex-native profile through V2 setup
- **GIVEN** V2 global configuration is installed
- **WHEN** the user runs `v2/setup-project.sh --mode=codex-codex-python-dev`
- **THEN** the setup exits with a non-zero status
- **AND** the output reports the mode does not exist
