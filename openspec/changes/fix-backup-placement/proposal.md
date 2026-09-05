# Change: 备份按 agent 归位

## Why

项目层的备份全部写进 `.claude/`，包括整个 `.codex/` 目录树。在 Codex-native 模式下
（`codex-codex-*`）项目根本没有 `CLAUDE.md`、Claude 完全不参与，41 项 Codex 资产却
备份到 Claude 的目录下——位置说不通，用户也找不到。

全局层（`v2/setup-global.sh`）本来就是分开的（`~/.claude/CLAUDE.md.backup.*` 与
`~/.codex/AGENTS.md.backup.*`、`~/.codex/.harness-backups/`），项目层与之不一致。

## What Changes

**BREAKING**（对备份路径）：备份位置改变，旧备份不迁移。

- 备份按 agent 归位：
  - `.claude/.harness-backups/<时间戳>-<原模式>/` — `CLAUDE.md`、`settings.json`、
    `skills/`、`agents/`、`commands/`、`rules/`、`hooks/`
  - `.codex/.harness-backups/<时间戳>-<原模式>/` — `AGENTS.md`、`config.toml`、
    `hooks.json`、`session-state.md`、`skills/`、`agents/`、`tools/`
- 命名统一为 `<时间戳>-<原模式>`，采用全局层已有的 `.harness-backups/` 约定
- 哪一侧无内容就不创建目录，不留空目录
- `setup-project.sh --migrate` 采用同一方案，后缀 `-premigrate`
- `--migrate` 的提示措辞去掉 V1 概念：「项目已有 .claude/ 配置，但不是本脚手架管理的」

## Out of Scope

- **不迁移已有的旧备份**（`.claude/.backup-*`、`.claude/.v1-backup-*`）：属用户数据，
  由用户自行处理
- 不引入自动清理/保留策略——备份仍需手工删除，README 已说明

## Acceptance Criteria

1. Claude 侧备份不含 `.codex` 内容
2. Codex-native 切换时 `AGENTS.md` 与 `.codex/` 资产落在 `.codex/.harness-backups/`
3. 不再产生 `.claude/.backup-*` 目录
4. 备份目录名匹配 `^\d{14}-<模式>$`
5. 不产生空备份目录
6. 全量测试通过

## Impact

- Affected specs: `plugin-profiles`
- Affected code: `v2/scripts/switch-plugin.sh`、`v2/setup-project.sh`、`README.md`、`tests/`
