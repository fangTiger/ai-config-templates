---
name: codex-handoff
description: Orchestrates context handoff from Claude to Codex for code implementation. Use when an approved OpenSpec proposal needs implementation in codex-dev mode. Handles context package construction, Codex session management, programmatic guardrails, evidence collection, and Sync Gate for mixed frontend/backend tasks.
---

# Codex Handoff — 上下文交接编排

## 概述

在 codex-dev 模式下，Claude 完成设计和提案后，通过此技能将实现工作委托给 Codex。
此技能编排整个 Stage 3 (HANDOFF) -> Stage 4 (IMPLEMENT) -> Stage 5 前半段 (SELF-REVIEW) 的流程。

## 触发条件

- codex-dev 配置已激活（优先检查 `.claude/.harness-manifest.json` 中 `mode = codex-dev`；旧安装兼容 `.claude/.active-plugin` = `codex-dev`）
- 已有通过审批的 OpenSpec 提案
- tasks.md 中包含 `Executor: Codex` 的任务
- 当前请求不是“用户明确指定 Claude 直接修改小问题”
- 关键词：handoff、交接、开始实现、codex 实现

## 前置检查

执行交接前，必须确认：
1. 若用户明确要求 Claude 直接处理且任务符合小任务标准：**停止交接，回退到 Claude 直接实现**
2. `openspec list` — 确认提案存在且已审批
3. 读取 proposal.md、design.md、tasks.md、spec deltas
4. 确认 tasks.md 中标注了每个 task 的 Executor
5. 确认至少存在一个 `Executor: Codex` 的未完成 task
6. 确认虚拟环境已激活（如存在）
7. 记录 git 基线：`git rev-parse HEAD`

## 步骤 1: 构建上下文包

### 1.1 收集上下文

从 OpenSpec 提案目录收集以下内容：

- proposal_summary: proposal.md 全文
- design_summary: design.md 全文（如存在）
- tasks: tasks.md 全文
- spec_deltas: specs/*/spec.md 全文
- acceptance_criteria: 从 proposal.md 的 Acceptance Criteria 节提取
- out_of_scope: 从 proposal.md 的 Out of Scope 节提取

### 1.2 构建文件白名单

从 tasks.md 提取所有涉及的文件路径，形成 file_allowlist。

### 1.3 构建 developer-instructions

注入以下内容：

```
你是代码实现者。按照任务清单逐一实现所有任务。

## 强制规则
1. 先遵循技能检查规则；实现/修复类 task 必须使用 `test-driven-development`
2. 遇到测试失败、行为异常或定位不清，先使用 `systematic-debugging` 再继续修复
3. 声称完成、通过、已修复前，必须使用 `verification-before-completion`
4. 只实现 `Executor: Codex` 的 task；若当前 task 属于 `Executor: Claude` / `Executor: Gemini`，停止并交回 Claude
5. 若请求被 Claude 标记为“Claude 直接修改小问题”，停止实现并交回 Claude
6. TDD 先行：每个 task 先写测试（RED），运行确认失败，再写实现（GREEN），最后重构
7. 范围约束：优先读取 `.claude/session-state.md`，只修改 `FileAllowlist` 中指定的文件路径
8. Atomic Commits：每完成一个 task 执行 git commit
9. 代码注释使用中文，标识符使用英文
10. 遵循 design.md 中的技术决策，不添加任务清单未要求的功能
11. 不引入新的外部依赖（除非任务明确要求），不修改测试配置文件
12. 每完成一个 task 输出：task 编号、RED 命令+结果、GREEN 命令+结果、修改文件列表、需求覆盖要点、下一步建议
```

附加负面约束（从 design.md 或 proposal.md 中提取的禁止项）和环境信息。

## 步骤 2: 启动 Codex Session

### 2.1 初始 Prompt

调用 codex MCP:
- cwd: 项目根目录
- sandbox: "workspace-write"
- developer-instructions: 步骤 1.3 的内容
- prompt: 完整上下文包 + "请先实现 task [第一个 Codex task]: [描述]"

### 2.2 记录 Session 状态

立即写入 `.claude/session-state.md`：

```
# codex-dev Workflow State
## Mode: codex-dev
## ChangeId: [change-id]
## Current Stage: 4 (IMPLEMENT)
## CodexThreadId: [threadId]
## CurrentTask: [task number]
## FileAllowlist: [paths]
## GitBaseline: [commit hash]
## LastVerificationResult: PENDING
## CompletedTasks: []
## PendingTasks: [remaining task numbers]
## DegradationCount: 0
## NextPromptSeed: [next prompt]
```

## 步骤 3: 逐 Task 推进

### 3.1 每个 Task 完成后

1. 范围检查: `git diff --name-only [baseline]` 比对 file_allowlist
2. 中间验证（必须）: 运行当前 task 对应的测试/验证命令
3. 推进: `codex-reply` 传入下一个 task
4. 更新 session-state.md

### 3.2 降级检查

- 同一 task 修复 > 3 次 -> 中止 session，Claude 手动实现
- 记录降级事件到 session-state.md

## 步骤 4: Sync Gate（混合任务时）

仅在 tasks.md 同时包含 Codex 和 Gemini 任务时执行。

### 4.1 后端接口验证

Codex 完成后端后，Claude 对照 design.md 验证 API 契约一致性。

### 4.2 前端上下文交接

调用 gemini-cli MCP，传入以下 prompt 模板：

```
你是前端实现者。请根据以下 API 契约和任务清单实现功能。

## API 契约
[从 Codex 后端提取的接口文档：端点、参数、返回值、错误码]

## 前端任务清单
[tasks.md 中 Executor: Gemini 的 tasks]

## 技术栈约束
- 前端框架: [项目使用的框架]
- 组件库: [项目使用的组件库]
- 状态管理: [项目使用的方案]
- 路由: [相关路由路径]

## UI/UX 规范
[如有]

## 强制规则
1. 遵循项目现有的前端架构和组件库，不引入新依赖
2. 必须实现 Loading 状态、Error 状态捕获和空数据兜底
3. 代码注释使用中文，标识符使用英文
4. 只修改任务清单中指定的前端文件
5. 每个 task 需有对应的单元测试
6. 完成后输出：修改文件列表、场景覆盖自测报告

## Mock 策略
如后端接口尚未就绪，先基于 API 契约创建 mock 数据进行开发。
```

### 4.3 前端审查与反向反馈

Claude 审查 Gemini 实现：
- 小问题直接修正
- 大问题让 Gemini 重做
- **契约反向反馈**：如果 Gemini 发现 API 契约无法满足 UI 场景（缺少字段、分页元数据等），
  Claude 审核后可退回 Phase A 要求 Codex 调整后端接口，然后重新触发 Sync Gate

## 步骤 5: 触发 Codex 自审

所有 tasks 完成后，通过 codex-reply 触发自审：

自审清单：
1. TDD 合规性
2. 设计一致性
3. 需求覆盖
4. 代码质量
5. 范围合规

要求输出：
- 每项状态 (PASS/FAIL)
- 证据（命令和输出）
- 需求覆盖矩阵

自审失败 -> 同一 session 修复 -> 再次自审
连续 2 次失败 -> 降级到 superpowers

## 步骤 6: 交回 Claude

自审通过后：
1. 更新 session-state.md: Stage 5 (REVIEW)
2. Claude 执行三方审核
3. 审核通过 -> Stage 6 (VERIFY + ARCHIVE)
4. 完成 -> 删除 session-state.md

## 快速参考

```
纯后端:  HANDOFF -> Codex TDD -> 自审 -> 三方审核
混合:    HANDOFF -> Codex 后端 -> Sync Gate -> Gemini 前端 -> 自审 -> 三方审核
纯前端:  跳过 Codex，直接 Gemini（退化为 superpowers 前端流程）
```
