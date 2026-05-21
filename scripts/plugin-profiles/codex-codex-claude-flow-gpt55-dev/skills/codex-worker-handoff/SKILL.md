---
name: codex-worker-handoff
description: Orchestrates structured context handoff from Architecture Codex to Implementation Codex for implementation. Use when an approved OpenSpec proposal or approved task package needs implementation in codex-codex-claude-flow-gpt55-dev mode. Handles context packaging, Implementation Codex session startup, file-scope guardrails, progress checkpoints, evidence collection, optional Codex review sync, and review handback.
---

# Codex Worker Handoff — Architecture Codex 向 Implementation Codex 的上下文交接

## 概述

在 `codex-codex-claude-flow-gpt55-dev` 模式下，Architecture Codex 完成分析、设计与任务拆解后，通过本技能把实现工作交给 Implementation Codex。

本技能覆盖以下流程阶段：
- Stage 3: HANDOFF
- Stage 4: IMPLEMENT
- Stage 5 前半段: SELF-REVIEW

核心原则：
- Architecture Codex 负责治理、分解、边界控制、质量把关
- Implementation Codex 负责按 task / slice 清单实施代码、测试和自审
- 中 / 大任务默认拆分为可独立审查的 task / slice；满足独立验收、独立验证、editable files 不重叠时默认使用多个 Implementation Codex
- 额外的前端、专项审查或全局一致性工作也必须通过 Implementation Codex、Review Codex 或 fresh Codex context 承接
- 三角色入口、六阶段流水线和 gate 口径均以项目根 `AGENTS.md` 为准

## 触发条件

满足以下任一情况时使用本技能：
- 项目根 `AGENTS.md` 明确当前入口契约为 `codex-codex-claude-flow-gpt55-dev`
- 已有通过审批的 OpenSpec proposal
- 已有明确批准的任务包（即使未正式走 OpenSpec）
- tasks.md 中存在 `Executor: Implementation Codex` 的任务
- 用户或主控流程明确进入“开始实现 / handoff / 交接 / 派工”阶段

## 前置检查

执行交接前，Architecture Codex 必须确认：
1. `openspec list` — 提案存在且状态允许推进（如该任务使用 OpenSpec）
2. 已读取 proposal.md、design.md、tasks.md、spec deltas（如存在）
3. 每个 task 的 Executor 已标注清楚
4. 项目运行环境可用（虚拟环境、依赖、构建工具按需检查）
5. 已记录 git 基线：`git rev-parse HEAD`
6. 已明确本轮允许修改的文件范围
7. 已记录 `SessionStatePath`，canonical 为 `.codex/session-state.md`
8. 若 handoff 前工作树已 dirty，已分类 `TaskScopeFiles`、`PreExistingDirtyBaseline`、`GeneratedOrNoisyArtifacts`
9. 若并发执行，已分配唯一 `AgentId` / `SliceId`，并准备独立 worktree 或 Patch artifact 交回协议
10. `.codex/session-state.md` 非空且字段可读；若缺失或为空，先从当前项目内 `.codex/session-state.template.md` 恢复；若疑似属于其他活跃任务，停止 handoff 并请求人工裁决
11. 多 Implementation Codex 场景已指定 `IntegrationOwner`，并明确集成检查点与最终 Review Codex 输入

## 步骤 1：构建上下文包

### 1.1 收集上下文

从提案目录或任务包中收集以下内容：
- `AgentId`: 当前 Implementation Codex 标识
- `SliceId`: 当前任务 slice 标识
- `proposal_summary`: proposal.md 摘要或全文
- `design_summary`: design.md 摘要或全文（如存在）
- `tasks`: tasks.md 全文
- `spec_deltas`: `specs/*/spec.md` 相关变更（如存在）
- `acceptance_criteria`: 验收标准
- `out_of_scope`: 明确不在本轮处理范围内的内容
- `risk_notes`: 已知风险、兼容性注意点、禁止动作
- `Graphify context`: 图谱查询结果、`GRAPH_REPORT.md` 降级依据或不适用理由
- `GitBaseline`: handoff 基线 commit
- `SessionStatePath`: `.codex/session-state.md`
- `Patch artifact`: 共享 worktree 时的补丁交回路径；若使用隔离工作区，则记录 worktree path
- `TaskScopeFiles`: 本 task 批准修改的文件
- `PreExistingDirtyBaseline`: handoff 前已经 dirty 或 untracked 的文件
- `GeneratedOrNoisyArtifacts`: 构建产物、IDE 文件、运行态缓存等噪声
- `IntegrationOwner`: 负责汇总 patch/worktree、检查冲突、更新 session-state 并形成 integration evidence 的负责人

### 1.2 校验 Handoff Task Package

Architecture Codex 必须确认每个 task 都具备 Gate 1 字段：

- ChangeId
- TaskId
- AgentId
- SliceId
- Executor
- Editable files
- Forbidden files
- Acceptance criteria
- Out-of-scope
- Validation
- Stop conditions
- Graphify context
- GitBaseline
- SessionStatePath
- Patch artifact 或 worktree path
- TaskScopeFiles
- PreExistingDirtyBaseline
- GeneratedOrNoisyArtifacts
- IntegrationOwner

`Editable files` / `TaskScopeFiles` 用于约束 Implementation Codex 的编辑范围；`Forbidden files` 是硬禁止项。若无法给出明确边界，不应直接启动 Implementation Codex。
`PreExistingDirtyBaseline` 和 `GeneratedOrNoisyArtifacts` 只能解释 `git status`，不得静默加入 `TaskScopeFiles`。
并发 Implementation Codex 必须满足：
- 每个 slice 使用唯一 `AgentId` / `SliceId`
- editable files 不重叠
- 默认使用独立 git worktree
- 无法使用独立 worktree 时，不得混写共享工作树，必须回传 Patch artifact、changed files、GitBaseline、验证输出、未验证项和范围扩展记录
- 不得并发直写共享配置、公共 API 契约、数据模型、迁移/持久化结构、profile/workflow/skill/hook、session-state、构建配置、测试配置，以及任何未列入 Editable files 的文件

### 1.3 构建 developer-instructions

交给 Implementation Codex 的 developer-instructions 至少应包含以下内容：

```text
你是 Implementation Codex，负责根据批准的 Handoff Task Package 逐一实现。

## 强制规则
1. TDD 先行：每个 task 先写测试（RED），运行确认失败，再写实现（GREEN），最后重构
2. 范围约束：只修改 Editable files / TaskScopeFiles，绝不修改 Forbidden files
3. Atomic Commits：每完成一个 task 建议形成原子提交（如当前运行模式允许）
4. 代码注释使用中文，标识符使用英文
5. 遵循 design.md 中的技术决策
6. 每完成一个 task 输出：task 编号、修改文件列表、测试结果
7. 不添加任务清单未要求的功能
8. 不引入新的外部依赖（除非任务明确要求）
9. 不修改测试配置文件
10. 如发现任务信息不足、需要范围扩展或触发 Stop conditions，先报告缺口，不擅自补需求
```

此外应补充：
- 项目技术栈约束
- 本轮禁止修改项
- `AgentId` / `SliceId`
- `SessionStatePath`
- `TaskScopeFiles` / `PreExistingDirtyBaseline` / `GeneratedOrNoisyArtifacts`
- Graphify context
- Patch artifact 或 worktree path
- 验证命令
- IntegrationOwner 和 handback 格式
- 必要的环境信息

## 步骤 2：启动 Implementation Codex Session

### 2.1 初始 Prompt

Architecture Codex 启动 Implementation Codex 时，应传入：
- 当前工作目录（项目根）
- 当前 config / session / custom agent 层批准的运行权限
- 上述 developer-instructions
- 完整上下文包
- 第一个待实现 task 的明确描述

推荐首轮 prompt 结构：
1. 任务背景
2. proposal/design 摘要
3. tasks 清单
4. AgentId / SliceId
5. SessionStatePath
6. TaskScopeFiles / PreExistingDirtyBaseline / GeneratedOrNoisyArtifacts
7. Patch artifact 或 worktree path
8. 文件白名单
9. 验证命令
10. IntegrationOwner 和交回要求
11. `请先实现 task X` 的直接指令

### 2.2 记录 Session 状态

启动后，Architecture Codex 必须立即维护项目根 `.codex/session-state.md`，建议结构如下：

```markdown
# codex-codex-claude-flow-gpt55-dev Workflow State
## Mode: codex-codex-claude-flow-gpt55-dev
## ActiveTaskStatus: ACTIVE
## ChangeId: [change-id]
## AgentId: [agent-id]
## SliceId: [slice-id]
## SessionStatePath: .codex/session-state.md
## Current Stage: 4 (IMPLEMENT)
## OuterRole: orchestrator/reviewer
## InnerCodexThreadId: [threadId]
## CurrentTask: [task number]
## FileAllowlist: [paths]
## TaskScopeFiles: [approved editable paths]
## PreExistingDirtyBaseline: [dirty/untracked paths present before handoff]
## GeneratedOrNoisyArtifacts: [build outputs, IDE files, runtime cache]
## GitBaseline: [commit hash]
## PatchArtifactOrWorktree: [patch artifact path or isolated worktree path]
## IntegrationOwner: [orchestration/integration owner]
## LastVerificationResult: PENDING
## Recovered: false
## ArchivedFrom: NONE
## CompletedTasks: []
## PendingTasks: []
## DegradationCount: 0
## NextPromptSeed: [next prompt]
```

状态维护规则：
- 不得把 `.codex/session-state.md` 清空作为“清理”或“归档”。
- 缺失或空状态且无活跃任务证据时，从当前项目内 `.codex/session-state.template.md` 重建初始状态后再写入当前任务信息。
- 若状态文件损坏但存在活跃任务证据，根据最近任务包、GitBaseline、diff/status 重建状态，并将 `Recovered` 标记为 `true`。
- 若状态属于其他活跃任务，不启动 Implementation Codex，先由 Architecture Codex 或人工负责人裁决。
- `CompletedTasks` / `PendingTasks` 必须随 task 推进更新；`DegradationCount` 记录当前 task 或 slice 的连续修复 / 降级尝试次数。
- 不得依赖或猜测 profile 源仓库路径恢复状态。

## 步骤 3：逐 Task 推进

### 3.1 每个 Task 完成后

Architecture Codex 每轮都应执行以下检查：
1. 范围检查：`git diff --name-only [baseline]`
2. 未跟踪文件检查：`git status --porcelain`
3. dirty baseline 分类：确认变更只落在 `TaskScopeFiles`，将既有脏文件归入 `PreExistingDirtyBaseline`，将构建产物/IDE/缓存归入 `GeneratedOrNoisyArtifacts`
4. 中间验证：按需运行测试、编译、lint
5. 判定是否允许进入下一个 task
6. 更新项目根 `.codex/session-state.md`
7. 确认未修改 Forbidden files
8. 同步 `CompletedTasks`、`PendingTasks` 和当前 `DegradationCount`

### 3.2 推进规则

当当前 task 通过后，Architecture Codex 才能向 Implementation Codex 推送下一个 task。
禁止一次性无边界放出整批高风险任务而不设检查点。
多 Implementation Codex 并发时，每个 slice 独立推进；Architecture Codex 不得把一个 slice 的通过状态外推为其他 slice 通过。

### 3.3 范围扩展

Implementation Codex 需要修改 Editable files 之外的文件时：

1. 先停止，不编辑该文件
2. 说明需要扩展的文件、原因、风险和验证命令
3. 等 Architecture Codex 或人类负责人批准更新后的 allowlist
4. 批准后才能继续

未经批准的范围扩展必须在 review 中判为 `FIX_REQUIRED` 或 `DOWNGRADE`。

### 3.4 降级检查

出现以下情况时，Architecture Codex 应考虑中止或降级：
- 同一 task 修复超过 3 次仍失败
- 修改范围持续超出 allowlist
- 实现结果与 design/spec 明显漂移
- 无法提供必要验证证据
- profile/runtime 同步验证无法收敛

降级后：
- 记录事件到项目根 `.codex/session-state.md`
- 递增 `DegradationCount`，并在重新拆分或人工接管后明确是否重置计数
- 由 Architecture Codex 接管，或等待人工确认

## 步骤 4：Sync Gate（混合任务时）

多 Implementation Codex 完成后，必须先执行 integration checkpoint：
- 汇总每个 slice 的 changed files、GitBaseline、验证证据、未验证项和范围扩展记录
- 检查 patch/worktree 基线是否一致，是否能干净合并
- 检查 slice 间是否对同一契约、公共类型、配置或测试作出不一致实现
- 运行与风险匹配的合并后验证命令，或说明无法运行原因
- 形成 Integration Evidence，作为 Review Codex 输入

额外的前端、专项审查或全局一致性检查仅在任务包明确批准时执行，且只能通过 Implementation Codex、Review Codex 或 fresh Codex context 承接；这不影响默认 Review Codex gate。

### 4.1 后端接口验证

Implementation Codex 完成相关实现后，Architecture Codex 对照 design/spec 验证契约，包括：
- 端点
- 参数
- 返回结构
- 错误码
- 边界行为

### 4.2 调用方任务上下文交接（可选）

如需由额外的 Implementation Codex 承接前端、调用方或场景任务，Architecture Codex 应交付：
- API 契约摘要
- 调用方任务清单
- 技术栈约束
- UI/UX 约束
- Mock 策略（如后端尚未完全就绪）

### 4.3 反向反馈

如果额外的 Implementation Codex 或 Review Codex 发现契约无法满足场景需求，Architecture Codex 必须做裁决：
- 小改动：退回 Implementation Codex 调整
- 大改动：返回 DESIGN / proposal 层重新确认

## 步骤 5：触发 Implementation Codex 自审

所有 tasks 完成后，Architecture Codex 应触发 Implementation Codex 自审。

自审清单应包括：
1. TDD 合规性
2. 设计一致性
3. 需求覆盖
4. 代码质量
5. 范围合规
6. 安全边界检查矩阵是否需要 Review Codex 复核
7. profile/runtime 同步证据（如涉及 `.codex`、skills、hooks、profile）

Implementation Codex 应输出：
- 每项状态（PASS / FAIL）
- 证据（命令与关键结果）
- 需求覆盖矩阵
- 剩余风险点
- Gate 2: Implementation Evidence

Gate 2 输出至少包含：
- 修改文件列表
- RED 证据或无法 RED 的说明
- GREEN 证据
- 验证命令与关键输出
- 未验证项及原因
- 范围扩展审批记录（如有）

若自审失败：
- 可在同一 session 修复后再审
- 连续失败 2 次，建议降级处理

## 步骤 6：交回 Review Codex

自审通过后：
1. 更新项目根 `.codex/session-state.md`，将流程推进到 Stage 5 (REVIEW)
2. 多 Implementation Codex 场景先确认 Integration Evidence 已形成
3. 使用 `codex-review` 整理 Review Input 和审查清单，然后显式启动 `.codex/agents/review-codex.toml` 定义的 `review-codex` custom agent；若 review-codex custom agent 不可用，记录替代 Codex review 来源
4. 审查通过后进入 Stage 6 (VERIFY + ARCHIVE)
5. 完成后将 session-state 归档到 `.codex/session-state.archive/YYYYMMDDHHMMSS-<change-id>.md`，再从 `.codex/session-state.template.md` 重置 `.codex/session-state.md`

## 快速参考

```text
纯后端:
ANALYZE → DESIGN → slice HANDOFF → one/many Implementation Codex TDD → Integration Evidence → Review Codex → VERIFY

混合任务:
ANALYZE → DESIGN → 契约 owner → one/many Implementation Codex 实现 → Integration/Sync Gate → Review Codex

纯前端:
按已批准任务包交给 Implementation Codex 实现，仍需 Review Codex 汇总
```
