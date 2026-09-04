# CONTEXT — 领域术语表

> 本文件是本仓库的**领域术语表**，由 `domain-modeling` skill 在 mps 模式下维护。
> 与 `openspec/project.md` 分工：project.md 记录项目约定（技术栈、目录、命令），
> 本文件只记录**业务概念与叫法**。两者不重叠。

---

## 核心概念

### harness
本仓库分发的整套 AI 编码配置，包含全局层与项目层。用 `harnessVersion` 标记版本（当前 `v2`）。
不要叫它"脚手架"或"框架"——harness 特指"约束 AI 行为的配置外壳"。

### profile（模式）
一组可整体切换的项目级配置，决定 Claude/Codex/Gemini 的角色分工与工作流。
当前有 `superpowers`、`mps`、`ecc`、`omc`、`teams`、`codex-dev`、`codex-codex-*` 系列。

### Claude 侧 profile vs Codex-native profile
- **Claude 侧**：以项目根 `CLAUDE.md` 为入口，Claude 是主脑。如 `superpowers`、`mps`、`ecc`、`omc`、`teams`、`codex-dev`。
- **Codex-native**：以项目根 `AGENTS.md` + `.codex/` 为入口，切换时**删除 `CLAUDE.md`**，Claude 不参与。
  判定条件：profile 目录同时含 `AGENTS.md` 与 `.codex/`。命名前缀统一为 `codex-codex-`。

注意 `codex-dev` 是 **Claude 侧** profile，不是 Codex-native——它表示"Claude 设计 + Codex 实现"，
容易和 `codex-codex-dev` 混淆，讨论时务必带完整名字。

### shared（共享层）
`plugin-profiles/shared/` 下的资源，切换到任意 profile 时都会先复制。
包含 hooks、commands、通用 skills，以及 `codex/` 子树（供 Codex-native profile 使用）。

### 覆盖语义（shared → profile）
切换时先复制 `shared/`，再复制 profile 自身目录，**同名文件后者覆盖前者**。
因此 profile 下的 `skill-rules.json` 必须是**全量文件**，不能只写增量条目，否则 shared 的规则会全部丢失。

### manifest
`.claude/.harness-manifest.json`（项目层）与 `~/.claude/.harness-manifest.json`（全局层），
记录 harness 版本、当前 `mode`、受管资产清单、模板仓库路径 `templateRoot`。
用 `manifestSchemaVersion` 标记结构版本（当前 `2`）。

### 漂移检测（drift detection）
切换 profile 前，比对 manifest 记录的 `templateHash` 与 profile 入口文件（`CLAUDE.md` 或 `AGENTS.md`）
的实际 hash。不一致说明用户手工改过配置，脚本会**交互式询问**是否覆盖。
这个交互会阻塞非 TTY 环境，会话内调用切换时需先跑 `--dry-run` 规避。

### templateRoot
manifest 中记录的模板仓库根路径（本仓库的绝对路径）。
`/switch-profile` 命令靠它定位 `switch-plugin.sh`。schema v1 的旧项目没有该字段，需走回退解析。

---

## mps 模式专有术语

### 落点映射（output mapping）
`mps/CLAUDE.md` Section 1 定义的表格，规定每个 mattpocock skill 的产出写到哪里。
存在的原因：mattpocock skill 默认把规范发到 issue tracker，与本项目"`openspec/specs/` 是唯一真相"冲突。
**落点映射的优先级高于 skill 正文自带的指令。**

### 真相源（source of truth）
`openspec/specs/` 目录。specs/ 是"当前系统有什么能力"，`changes/archive/` 是"变更历史"。
类比 git：specs/ = 当前代码，archive/ = commit 历史。

### user-invoked vs model-invoked skill
mattpocock-skills 的两类 skill：
- **user-invoked**：带 `disable-model-invocation: true`，只能用户显式 `/xxx` 调用（如 `/to-spec`）
- **model-invoked**：靠 description 自动触发（如 `tdd`、`code-review`）

### 同职责争抢
两个插件同时提供职责重叠的 model-invoked skill 时，触发会在它们之间随机命中，行为不可预测。
`mps` 关闭 `superpowers` 的直接原因（`tdd` vs `test-driven-development` 等四组）。

---

## 版本 pin

| 依赖 | 版本 | 记录位置 |
|---|---|---|
| mattpocock-skills | 1.2.3 | `mps/CLAUDE.md` 页脚、README |
