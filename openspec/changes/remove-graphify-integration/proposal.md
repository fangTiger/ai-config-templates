# Change: 移除 Graphify 集成

## Why

Graphify 代码图谱在实际使用中未产生预期价值：hook 在每次 Edit/Write 前注入查询提示，
但图谱数据往往过期或缺失，降级路径被频繁触发，净效果是增加噪声而非提供上下文。
维护成本（每个 profile 的 hook 配置、`.graphifyignore`、Java/Python 建图工具、
两套 hook 副本）与收益不匹配。

## What Changes

**BREAKING**：移除 Graphify 全部集成。已安装该配置的项目在下次切换/初始化后不再获得
Graphify hook，`graphify` 命令与图谱数据不再被引用。

删除范围：

- hook 脚本：`v2/scripts/plugin-profiles/shared/hooks/graphify-query-hook.sh`、
  `shared/codex/hooks/graphify-query-hook.sh`、`hooks/graphify-query-hook.sh`
- 建图工具：`shared/codex/java/tools/graphify-java-project.sh` 及其 README
- 技能与命令：`skills/graphify/`
- OpenCode 插件模板：`templates/.opencode/plugins/graphify.js`
- 忽略模板：`graphifyignore.template`、`v2/graphifyignore.template`
- 文档：`docs/graphify-integration.md`
- 各 profile `settings.json` 中的 `PreToolUse` graphify hook 注册（12 处）
- 各 profile `CLAUDE.md` / `AGENTS.md` 中的「Graphify 工作流（强制）」章节
- 全局 `v2/global/CLAUDE.md`、`v2/global/AGENTS.md` 中的同名章节
- `v2/scripts/switch-plugin.sh` 的 `ensure_graphify_assets` 与 `.graphifyignore` 落盘逻辑
- `v2/setup-project.sh` 的 Graphify 安装逻辑
- `README.md` 的 Graphify 章节
- 相关测试断言

## Out of Scope

- **不改 `openspec/changes/archive/**` 与已完成变更目录**：那是历史记录，改动等同篡改历史
- **不改 `docs/plans/**`**：同上，历史设计文档
- ~~不改 V1~~ **（实施中修正）**：原计划保留 V1 的 Graphify 引用，但删除根级
  `graphifyignore.template` 与 `hooks/graphify-query-hook.sh` 后，V1 的
  `switch-plugin_codex.sh` 因硬校验 `.codex/hooks/graphify-query-hook.sh` 而落盘失败。
  要么恢复根级文件（与"整体移除"矛盾），要么一并清理 V1。选择后者——V1 已停维，
  留一半 Graphify 反而制造不一致。
- 不删除用户项目中已生成的 `graphify-out/`、`.graphifyignore`（属用户数据）

## Acceptance Criteria

1. `v2/` 下无任何 graphify 相关文件
2. 12 个 profile 的 `settings.json` 中不再注册 graphify hook
3. 所有 v2 profile 与全局模板中不再出现「Graphify 工作流」章节
4. `switch-plugin.sh` 与 `setup-project.sh` 不再引用 graphify
5. 切换与初始化流程在无 graphify 的情况下正常完成
6. 全量测试通过

## Impact

- Affected specs: `plugin-profiles`
- Affected code: `v2/**`、`scripts/**`（V1）、`hooks/`、`skills/graphify/`、`templates/`、
  `setup-claude-config.sh`、根 `CLAUDE.md`/`AGENTS.md`/`settings.json`、`README.md`、`tests/**`

## 实施记录

- 删除专属文件 21 个（hook 脚本、建图工具、skill、OpenCode 插件、忽略模板、集成文档）
- 12 个 profile 的 `settings.json` 移除 `PreToolUse` graphify hook（该事件下无其他 hook，整段移除）
- 5 个 `.codex/hooks.json` 同步清理
- 模板中区分两种形态处理：整节删除（`## Graphify 工作流`）vs 行内短语摘除（表格行、清单项）
- **过程中两次因行级过滤造成损伤并回滚重做**：删除含 graphify 的整行会连带删掉
  shell 函数定义行、跨行 `assertEqual` 参数、以及只是顺带提及 graphify 的表格行
  （含 `ANALYZE`/`HANDOFF` 等无关内容）。最终改用函数级/块级/短语级三类精准删除。
- 测试：删除 2 个纯 graphify 测试函数，摘除 14 行断言，更新 hooks 断言
- 残留核对：除 `openspec/changes/**`（变更历史）与 `docs/plans/**`（历史设计文档）外，
  全仓库 graphify 零残留
