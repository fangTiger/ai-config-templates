# Change: 接入 mattpocock/skills 并新增 mps 模式与 /switch-profile 命令

## Why

现有 profile 体系（superpowers / ecc / omc / teams / codex-*）缺少一套以「访谈驱动需求澄清 + 规范合成」为核心的工作流。`mattpocock/skills` 提供了 21 个小而可组合的 skill，其 `grill-with-docs → to-spec → to-tickets → implement` 主链路在需求澄清和规范合成两个环节明显强于当前 `brainstorming` 单点方案。

同时，profile 切换目前只能退出会话、在项目外执行 shell 脚本，且脚本路径未被任何配置记录，切换成本高、易出错。

## What Changes

### 1. 新增 `mps` profile（Claude 侧）
- 新增 `v2/scripts/plugin-profiles/mps/`，包含 `CLAUDE.md` / `settings.json` / `skills/skill-rules.json`
- `settings.json` 启用 `mattpocock-skills` 插件，**关闭** `superpowers` 插件（避免 `tdd` 与 `test-driven-development`、`code-review` 与 `requesting-code-review` 两套同职责 skill 同时可触发）
- `CLAUDE.md` 定义**产出落点映射**：mattpocock skill 的产出一律落到 OpenSpec 目录，而非其默认的 issue tracker

### 2. 新增 `/switch-profile` slash 命令
- 新增 `v2/scripts/plugin-profiles/shared/commands/switch-profile.md`，所有 profile（含 codex-native）自动获得
- 会话内执行 `/switch-profile <profile>`、`/switch-profile --status`、`/switch-profile --list`、`/switch-profile <profile> --dry-run`
- **BREAKING**（对 manifest schema）：`.claude/.harness-manifest.json` 新增 `templateRoot` 字段记录模板仓库路径，`manifestSchemaVersion` 由 `1` 升至 `2`；旧 manifest 无该字段时命令回退到候选路径探测

### 3. 新增 `codex-codex-mps-dev` profile（Codex 侧）
- 新增 `v2/scripts/plugin-profiles/codex-codex-mps-dev/`，为 codex-native 结构（`AGENTS.md` + `.codex/`）
- mattpocock skill 经 `npx skills@latest add mattpocock/skills` 复制为文件副本落到 `.codex/skills/`
- `AGENTS.md` 承载与 Claude 侧一致的落点映射

### 4. 配套
- 新增 `tests/test_v2_mps_profile.py`
- 更新 `README.md` 的「Profile 切换」章节
- 项目根新增 `CONTEXT.md`（领域术语表），与 `openspec/project.md` 分工明确

## Acceptance Criteria

1. `switch-plugin.sh --list` 输出包含 `mps` 与 `codex-codex-mps-dev`
2. 切到 `mps` 后：`CLAUDE.md` 含 `<!-- harness-mode: mps -->`；`.claude/settings.json` 中 `superpowers@superpowers-marketplace` 为 `false` 且 mattpocock 插件键为 `true`；`.claude/commands/switch-profile.md` 存在
3. 切到 `codex-codex-mps-dev` 后：项目根为 `AGENTS.md`（`CLAUDE.md` 被移除）；`.codex/config.toml`、`.codex/hooks.json`、`.codex/session-state.md`、`.codex/skills/` 齐备
4. `/switch-profile --status` 在模板路径缺失时给出可执行的修复指引，不静默失败
5. `/switch-profile` 目标为 `codex-*` 时必须二次确认（该切换会删除当前会话依赖的 `CLAUDE.md`）
6. `tests/test_v2_mps_profile.py` 全绿
7. `openspec validate add-mattpocock-skills-profile --strict` 通过

## Out of Scope

- **v1（`scripts/plugin-profiles/`）不做**：本次仅覆盖 v2 主线，v1 保持现状
- **不改写 mattpocock skill 正文**：`.codex/skills/` 下为原样副本，落点差异由 `AGENTS.md` 覆盖（见 design.md 风险 R3）
- 不引入 issue tracker（GitHub/Linear）集成
- 不调整 `openspec/specs/` 中既有 codex-dev / codex-codex-* 相关需求

## Impact

- Affected specs: `plugin-profiles`
- Affected code:
  - 新增 `v2/scripts/plugin-profiles/mps/**`
  - 新增 `v2/scripts/plugin-profiles/codex-codex-mps-dev/**`
  - 新增 `v2/scripts/plugin-profiles/shared/commands/switch-profile.md`
  - 修改 `v2/scripts/switch-plugin.sh`（usage、收尾提示分支）
  - 修改 `v2/setup-project.sh`（写入 `templateRoot`、`manifestSchemaVersion: 2`）
  - 新增 `tests/test_v2_mps_profile.py`
  - 修改 `README.md`
  - 新增 `CONTEXT.md`

## 分批交付建议

第 3 项（`codex-codex-mps-dev`）成本显著高于前两项，且依赖 Claude 侧验证结论。建议按 `阶段 A（1+2+配套）→ 验证 → 阶段 B（3）` 交付，tasks.md 已按此分段。
