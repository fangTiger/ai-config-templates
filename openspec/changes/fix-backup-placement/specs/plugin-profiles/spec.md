## ADDED Requirements

### Requirement: 备份按 agent 归位

切换器与项目初始化 SHALL 按 agent 分别备份配置：Claude 资产写入 `.claude/.harness-backups/`，
Codex 资产写入 `.codex/.harness-backups/`，两侧互不混装。

#### Scenario: Claude 侧备份不含 Codex 资产
- **GIVEN** 项目处于任一 Claude 侧模式
- **WHEN** 用户切换到另一个模式
- **THEN** `.claude/.harness-backups/<时间戳>-<原模式>/` 包含 `CLAUDE.md` 与 `settings.json`
- **AND** 该目录不包含 `.codex` 或任何 Codex 运行资产

#### Scenario: Codex-native 切换时资产落在 Codex 侧
- **GIVEN** 项目处于 `codex-codex-dev`，项目根没有 `CLAUDE.md`
- **WHEN** 用户切换到 `codex-codex-mps-dev`
- **THEN** `.codex/.harness-backups/<时间戳>-<原模式>/` 包含 `AGENTS.md`
- **AND** 包含 `config.toml`、`hooks.json`、`session-state.md` 等 Codex 运行资产

#### Scenario: 不再产生混装的旧式备份目录
- **GIVEN** 用户执行任意切换
- **WHEN** 备份完成
- **THEN** `.claude/` 下不存在 `.backup-*` 形式的目录

#### Scenario: 备份目录命名统一
- **GIVEN** 用户从 `superpowers` 切换到其他模式
- **WHEN** 备份完成
- **THEN** 备份目录名形如 `20260905104801-superpowers`

#### Scenario: 无内容时不创建空目录
- **GIVEN** 某一侧没有任何可备份的内容
- **WHEN** 备份完成
- **THEN** 该侧不留下空的备份目录

#### Scenario: migrate 接管时同样归位
- **GIVEN** 项目已有 `.claude/` 配置但不受本脚手架管理
- **WHEN** 用户执行 `v2/setup-project.sh --migrate`
- **THEN** 现有配置按 agent 分别备份到两侧的 `.harness-backups/`
- **AND** 目录名以 `-premigrate` 结尾
