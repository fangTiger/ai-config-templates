---
name: codex-orchestrate
description: Orchestrates codex-codex-dev workflow. Use when the Architecture Codex needs to analyze a coding request, decide whether OpenSpec is required, split tasks, prepare implementation handoff, and manage Implementation Codex execution boundaries.
---

# Codex Orchestrate — Architecture Codex 编排技能

## 概述

在 `codex-codex-dev` 模式下，Architecture Codex 使用本技能完成：
- 任务分级（小 / 中 / 大）
- 是否需要 OpenSpec 的判断
- Graphify 条件路由与影响面判断
- proposal/tasks 规划
- 是否需要拆分为多个 Implementation Codex
- 交付前的审查与推进决策

这是 **Architecture Codex** 的治理技能，不是直接实现技能。三角色入口口径见项目根 `AGENTS.md`；复杂阶段推进见 `.codex/workflow.md`。

## 触发条件

- 项目根 `AGENTS.md` 明确当前入口契约为 `codex-codex-dev`
- 用户提出中等及以上复杂度的开发需求
- 关键词：实现、设计、拆解、编排、开始开发、开始实现、handoff、交接、审查、Clarify Gate、Graphify、影响面

## 步骤 1：读取主控规则

开始前必须读取：
1. 项目根 `AGENTS.md`
2. 项目根 `openspec/config.yaml`、`openspec/changes/`、`openspec/specs/`（如任务涉及变更提案）
3. 按 `AGENTS.md` 上下文路由条件式读取 `CODE_WIKI.md`、`docs/guide/*`、`docs/domain/*`、`docs/reference/*`、`graphify-out/GRAPH_REPORT.md`、相关源码和测试；不存在时记录缺失与替代依据
4. 若存在 `graphify-out/graph.json` 且任务涉及架构、依赖、影响面、跨模块修改或非平凡搜索，优先获取图谱上下文；无法查询时降级读取 `graphify-out/GRAPH_REPORT.md`，仍不可用时记录降级原因并继续源码分析

## 步骤 1.5：Clarify Gate

进入 DESIGN 或 IMPLEMENT 前，Architecture Codex 必须确认：
- Acceptance criteria 是否明确
- Out-of-scope 是否明确
- 是否需要 OpenSpec；跳过时是否有理由
- 每个中 / 大任务的 Executor 是否明确到 Architecture Codex、Implementation Codex、Review Codex 或人工负责人
- Validation 和 stop conditions 是否可执行
- Review mode 是否明确：独立 Review Codex、替代 reviewer，或小任务轻量自审
- Graphify 条件路由是否已执行，或是否记录降级原因

缺失项会影响实现边界时，只问必要问题；未通过 Clarify Gate 不进入 DESIGN / HANDOFF / IMPLEMENT。

## 步骤 2：任务分级

### 小任务
满足任一特征：
- Bug 修复
- 修改文件 < 3
- 不涉及公共 API 或架构变化

动作：
- Architecture Codex 可直接实现
- 仍应执行验证与范围检查

### 中任务
满足任一特征：
- 单模块功能开发
- 修改 3-9 个文件
- 需要显式任务拆分

动作：
- 默认拆成 bite-sized tasks
- 若存在 2 个以上可独立验收、可独立验证、editable files 不重叠的任务包，默认使用多个 Implementation Codex
- 准备每个 slice 的 handoff 上下文

### 大任务
满足任一特征：
- 跨模块
- 修改 >= 10 文件
- 涉及新能力、架构演进、OpenSpec delta

动作：
- 先 OpenSpec proposal
- 默认按 slice 拆分，并优先使用多个 Implementation Codex
- 公共契约、schema、核心接口、迁移边界先由单一 owner 固化，再并行展开

## 步骤 3：OpenSpec 决策

OpenSpec 触发以变更性质优先，文件数只作为升级启发式，不能作为豁免条件。

### 必须创建提案
- 新功能
- API 契约变化或破坏性 API 变更
- 架构变化或 agent 执行契约变化
- 安全 / 权限 / 数据访问 / 部署行为变化
- profile、hook、skill、session-state、handoff/review gate 语义变化

### 可跳过提案
- Bug 修复
- 拼写 / 注释 / 文档修正
- 非破坏性配置调整
- 为现有功能补测试

## 步骤 4：形成实施包

Architecture Codex 需要输出 Gate 1: Handoff Task Package，作为 Implementation Codex 的唯一 handoff 输入：

```markdown
## Handoff Task Package

- ChangeId:
- TaskId:
- AgentId:
- SliceId:
- Executor:
- Editable files:
- Forbidden files:
- Acceptance criteria:
- Out-of-scope:
- Validation:
- Stop conditions:
- Graphify context:
- GitBaseline:
- SessionStatePath: .codex/session-state.md
- Patch artifact:
- Worktree path:
- TaskScopeFiles:
- PreExistingDirtyBaseline:
- GeneratedOrNoisyArtifacts:
- IntegrationOwner:
```

要求：
- `Executor` 必须明确到 Architecture Codex、Implementation Codex、Review Codex 或人工负责人。
- `Editable files` / `TaskScopeFiles` 和 `Forbidden files` 必须可执行，不能只写“相关文件”。
- `PreExistingDirtyBaseline` 和 `GeneratedOrNoisyArtifacts` 只能解释 status/diff，不得静默纳入 editable scope。
- `Validation` 必须包含可运行命令或明确无法运行的原因。
- `Stop conditions` 必须覆盖范围扩展、证据缺失、依赖未满足、安全边界变化。
- `Graphify context` 记录图谱查询、`GRAPH_REPORT.md` 降级依据或不适用理由。
- 并发任务必须明确 `AgentId` / `SliceId`，editable files 不重叠，并指定独立 worktree 或 patch artifact handback。
- 并发 Implementation Codex 默认使用独立 git worktree；无法使用独立 worktree 时，不得混写共享工作树，必须通过 patch artifact handback。
- 共享配置、公共 API 契约、数据模型、迁移/持久化结构、profile/workflow/skill/hook、session-state、构建配置、测试配置以及任何未列入 Editable files 的文件不得并发直写。
- 多 Implementation Codex 任务必须指定 IntegrationOwner，负责汇总 patch/worktree、检查冲突、更新 session-state，并在 Review Codex 前形成 integration evidence。
- 涉及认证、授权、密钥、数据权限、公共 API、部署或外部网关时，必须标记需要安全边界检查矩阵。

## 步骤 5：派工决策

### 直接执行
适用于：小任务、紧急修复、很容易判断的局部改动

### 委托 Implementation Codex
适用于：中 / 大任务，或需要稳定 TDD 节奏和边界约束的实现任务

动作：
- 中 / 大任务先按 task / slice 拆分；满足独立验收、独立验证、editable files 不重叠时启动多个 Implementation Codex
- 调用 `codex-worker-handoff`
- 记录项目根 `.codex/session-state.md`
- 多 Implementation Codex 完成后先执行 integration checkpoint，再通过独立 Review Codex / `codex-review` 驱动审查

### 暂停或降级
适用于：
- OpenSpec 依赖未接受或未归档且口径仍变化
- 当前 `.codex/session-state.md` 属于其他活跃任务
- `.codex/session-state.md` 缺失、为空或字段损坏，且无法确认没有活跃任务
- 需要编辑 allowlist 外文件但尚未获批
- profile 源位于当前仓库外且写权限未确认

动作：
- 停止派工
- 说明阻塞点、待确认信息和建议下一步
- 必要时将任务降级给 Architecture Codex 或人工负责人裁决
- 若确认无活跃任务，可从当前项目内 `.codex/session-state.template.md` 重建 `.codex/session-state.md`；若存在活跃任务证据，先根据任务包、git baseline 和 diff/status 重建状态并标记 `Recovered: true`
- 重建或推进状态时，同步 `CompletedTasks`、`PendingTasks` 和 `DegradationCount`，让恢复后的代理能判断剩余任务和是否需要降级

## 步骤 6：治理要求

Architecture Codex 必须：
1. 不能不经分析直接派工
2. 不能在大型任务中同时兼任主实现者
3. 不能跳过 file allowlist 检查
4. 不能不看验证结果就宣布完成
5. 发现范围漂移、反复失败、设计偏航时必须中止或降级
6. 不能把运行态 `.codex/session-state.md` 当作 profile 模板覆盖
7. 不能依赖或猜测 profile 源仓库路径恢复状态；恢复只使用当前项目内 `.codex/session-state.template.md`
8. 不能用清空 `.codex/session-state.md` 表示归档或重置；归档后必须从 `.codex/session-state.template.md` 生成新的初始状态
9. 不能丢失 `PendingTasks` 或 `DegradationCount`；它们是恢复、暂停和降级决策的一部分
10. 不能让多个 Implementation Codex 并发直写同一文件、共享运行态文件或未冻结的公共契约
11. 不能在多 Implementation Codex 完成后跳过 integration checkpoint
12. 不能在 Review Codex 未给出 `PASS` 时进入最终 VERIFY
13. 不能把专项 review skill 的 `Specialty Decision` / `Specialty Review Result` 当作最终 gate；最终 `PASS` / `FIX_REQUIRED` / `DOWNGRADE` 只能由 Review Codex 或小任务/降级接管时的 Architecture Codex 汇总产生

## 输出格式建议

在进入实现前，输出一份简明治理摘要：
- 任务级别
- 是否需要 OpenSpec
- 是否委托 Implementation Codex
- Implementation Codex 拆分策略：单 agent / 多 agent / contract-first then fan-out
- handoff 输入清单
- IntegrationOwner
- 验证命令
- 风险点
- dirty baseline 三分类
- 是否需要安全边界检查矩阵
