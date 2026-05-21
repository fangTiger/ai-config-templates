---
name: team-workflow
description: Use when starting any medium or large task that benefits from structured multi-agent collaboration. Orchestrates a 5-stage pipeline (analyze → design → implement → review → verify) with specialized agents, integrated with OpenSpec workflow, TDD, and multi-model cross-validation.
---

# Team Workflow — 原生 Agent Teams 编排

## 概述

Claude 作为 orchestrator，按 5 阶段流水线派发专业 Agent 协作完成任务。
每个阶段有明确的 Agent 角色、产出物、质量关口和多模型交叉验证。

**与 OpenSpec 的映射：**
- Teams Stage 1-2 (ANALYZE + DESIGN) = OpenSpec Stage 1 (创建提案)
- Teams Stage 3-4 (IMPLEMENT + REVIEW) = OpenSpec Stage 2 (实现变更)
- Teams Stage 5 (VERIFY) = OpenSpec Stage 2→3 (测试 + 归档)

## 触发条件

- 中/大任务（3+ 文件变更）
- 用户明确要求 team 模式
- 关键词：team、团队、协作、多 agent

## 流程

```
┌─────────────────────────────────────────────────────┐
│  Claude (Orchestrator) — 全程协调、最终决策          │
├─────────┬──────────┬───────────┬─────────┬──────────┤
│ Stage 1 │ Stage 2  │  Stage 3  │ Stage 4 │ Stage 5  │
│ ANALYZE │ DESIGN   │ IMPLEMENT │ REVIEW  │ VERIFY   │
│         │          │           │         │          │
│ requirement │ solution  │ subagent  │ code-arch │ test     │
│ -analyst    │ -architect│ -driven   │ -reviewer │ -architect│
│         │ +plan    │ -dev      │         │          │
│         │ -reviewer│ (TDD)     │         │          │
│         │          │           │         │          │
│ +Codex  │ +Codex   │ +Codex    │ +Codex  │ +verify  │
│ +Gemini │ +Gemini  │  审查     │ +Gemini │  skill   │
├─────────┴──────────┴───────────┴─────────┴──────────┤
│ 质量关口：每阶段三方共识 → 未一致禁止推进            │
└─────────────────────────────────────────────────────┘
```

## Stage 1: ANALYZE（需求分析）

**Agent:** `requirement-analyst`
**对应 OpenSpec:** Stage 1 前半段
**产出:** 需求分析报告（功能点、验收标准、边界条件、风险）

**Orchestrator 操作：**
1. 派发 `requirement-analyst` agent，传入用户需求 + 现有 specs/
2. 收到报告后，请 Codex 审查技术可行性
3. 请 Gemini 补充场景覆盖
4. **质量关口：** 三方对验收标准达成一致
5. 产出 `docs/plans/YYYY-MM-DD-{topic}-design.md` 的需求部分

**失败处理：** 三方不一致 → 记录分歧 → Claude 最终裁决并记录理由

## Stage 2: DESIGN（技术设计）

**Agent:** `solution-architect` + `plan-reviewer`（复用）
**对应 OpenSpec:** Stage 1 后半段
**产出:** proposal.md + design.md + tasks.md + spec deltas

**Orchestrator 操作：**
1. 派发 `solution-architect` agent，传入需求分析报告
2. 收到设计后，派发 `plan-reviewer` agent 审查
3. 请 Codex 审查架构合理性和 API 设计
4. 请 Gemini 审查场景覆盖完整性
5. **质量关口：** 三方对技术方案达成一致
6. 整理为 OpenSpec 提案：proposal.md + tasks.md + spec deltas
7. `openspec validate <id> --strict --no-interactive`
8. **等待用户审批**

**tasks.md 要求：**
- 中任务：直接 bite-sized（每步含文件路径、验证命令）
- 大任务：高层任务，后续由 subagent-driven-development 细化

## Stage 3: IMPLEMENT（实现）

**Skill:** `superpowers:subagent-driven-development`（复用）
**对应 OpenSpec:** Stage 2 IMPLEMENTATION
**强制：** TDD (RED-GREEN-REFACTOR)

**Orchestrator 操作：**
1. 使用 `superpowers:subagent-driven-development` 按 tasks.md 派发
   - 每个 task 派发 implementer subagent
   - 内置 spec-reviewer + code-quality-reviewer 两阶段审查
2. 每个 task 完成后，请 Codex 交叉检查后端代码
3. 前端代码由 Gemini 实现（通过 orchestrator 协调）
4. **TDD 强制：** 每个 task 必须先写测试再写实现
5. 更新 tasks.md 状态

**并行策略：**
- 独立 task → `dispatching-parallel-agents` 并行派发
- 有依赖的 task → 顺序执行

## Stage 4: REVIEW（审查）

**Agent:** `code-architecture-reviewer`（复用增强）
**Skill:** `superpowers:requesting-code-review`
**对应 OpenSpec:** Stage 2 REVIEW

**Orchestrator 操作：**
1. 使用 `superpowers:requesting-code-review` 发起审查
2. 派发 `code-architecture-reviewer` agent 做架构级审查
3. 请 Codex 做安全性和后端质量审查
4. 请 Gemini 做功能完整性审查
5. **质量关口：** 三方对代码质量达成一致
6. 发现问题 → 回到 Stage 3 修复 → 重新审查

**审查清单：**
- [ ] 实现符合 design.md
- [ ] 所有 tasks.md 任务完成
- [ ] TDD 覆盖率充分
- [ ] 无安全隐患
- [ ] 代码质量达标
- [ ] 向后兼容

## Stage 5: VERIFY（验证）

**Agent:** `test-architect`
**Skill:** `superpowers:verification-before-completion`
**对应 OpenSpec:** Stage 2 TESTING → Stage 3 归档

**Orchestrator 操作：**
1. 派发 `test-architect` agent，传入验收标准 + 实现代码
2. test-architect 运行所有测试，收集实际输出（证据先于断言）
3. 使用 `superpowers:verification-before-completion` 最终验证
4. **质量关口：** 所有验收标准有对应测试证据
5. 通过后执行归档：
   - 合并 delta spec 到 specs/
   - `/openspec:archive`
   - 执行 OpenSpec 完整性检查
6. 使用 `superpowers:finishing-a-development-branch` 完成分支集成

## 模型选择策略

| 角色 | 推荐模型 | 理由 |
|------|---------|------|
| requirement-analyst | Opus | 需要深度理解和推理 |
| solution-architect | Opus | 架构决策需要最强推理 |
| plan-reviewer | Opus | 审查需要全局视角 |
| implementer (简单 task) | Sonnet | 机械实现，spec 明确 |
| implementer (复杂 task) | Opus | 多文件集成，需要判断 |
| spec-reviewer | Sonnet | 对照检查，规则明确 |
| code-quality-reviewer | Sonnet | 模式匹配，规则明确 |
| code-architecture-reviewer | Opus | 架构级审查 |
| test-architect | Opus | 测试策略需要全局视角 |
| Codex 交叉检查 | 默认 | 不指定 model |
| Gemini 交叉检查 | 默认 | 不指定 model |

## 会话状态持久化

在 `.claude/session-state.md` 维护编排状态：

```markdown
# Team Workflow State
## Current Stage: [1-5]
## Task: [任务描述]
## Completed Stages: [列表]
## Current Agent: [agent 名称]
## Pending Reviews: [待审查项]
## Cross-Validation Status: [三方共识状态]
```

每个 Stage 完成时更新，防止上下文压缩丢失进度。

## 快速参考

```
team 小任务 → 不用 team，直接 TDD
team 中任务 → 5 阶段完整流程
team 大任务 → 5 阶段 + Stage 3 并行派发
```
