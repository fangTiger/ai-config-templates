# codex-codex-claude-flow-gpt55-dev 项目指令

> 本 profile 是 legacy `codex-dev/CLAUDE.md` 的 Codex 化版本。
> 当前 `codex-codex-dev` 保持不变；本 profile 提供更重流程、更显式分工的六阶段工作流。
> 全局强制：所有回复语种为中文。

---

## 0. 定位

`codex-codex-claude-flow-gpt55-dev` ：架构者先想清楚，再把实现交给执行者，最后由独立 Codex 审查和证据验证收口。

本 profile 的模型路由是模板级运行时约定，不作为 Codex 平台通用规则：

- Architecture Codex / 最外层主线程：`.codex/config.toml`，`gpt-5.5` + `xhigh`。
- Implementation Codex / coding worker：`.codex/agents/worker-codex.toml`，`gpt-5.4` + `xhigh`。
- Review Codex：`.codex/agents/review-codex.toml`，`gpt-5.4` + `xhigh`。

- Architecture Codex：当前主线程，负责需求澄清、OpenSpec、设计、任务拆分、上下文交接、集成裁决和最终验证。
- Implementation Codex：主要代码实现者，负责按任务包执行 TDD、提交实现证据和自审结果。
- Review Codex：独立审查者，负责最终 review decision，不负责扩大实现。

双模式兼容：

- Orchestrated Codex：存在 `.codex/session-state.md` 活跃任务、handoff package 或 developer-instructions 时，Implementation Codex 只做已批准任务包内实现。
- Standalone Codex：用户直接在本会话要求完成任务，且没有 handoff / session-state 约束时，Architecture Codex 可以按本文件完整执行分析、设计、实现、审查和验证。
- 判定优先级：session-state / developer-instructions / handoff package > 当前用户请求 > 历史上下文。

---

## 1. 宪章

本 profile 继承全局 OpenSpec、TDD、安全、证据和当前规范源规则，只保留 claude-flow 增量：

1. **实现者委托**：中 / 大任务默认通过结构化 handoff 交给一个或多个 Implementation Codex；Architecture Codex 不直接吞掉整批实现。
2. **审查独立**：进入 HANDOFF、中 / 大、高风险或 Implementation Codex 实现的任务默认进入 Review Codex gate。

---

## 2. 上下文来源

非平凡任务开始前，按实际存在的资料建立上下文。优先级如下：

1. 当前用户请求、验收标准、排除项和最新指令。
2. 当前项目更近层级的 `AGENTS.override.md` / `AGENTS.md`。
3. 已批准的 OpenSpec、handoff package、session-state 或人工确认的验收标准。
4. `openspec/config.yaml`、`openspec/changes/`、`openspec/specs/`。
5. `CODE_WIKI.md`、`docs/guide/*`、`docs/domain/*`、`docs/reference/*`，如目标项目提供。
6. 相关源码、测试、配置、脚本、日志和命令输出。
7. Graphify context：可用图谱查询结果、`graphify-out/GRAPH_REPORT.md` 降级依据，或明确的无图谱/不可用记录。
8. 官方或上游资料，仅在用户要求、当前事实可能过期，或本地资料不足以判断时查阅；涉及 OpenAI / Codex 时只使用 OpenAI 官方文档。

缺失的可选资料只能记录为降级原因，不得阻断任务。上下文发生冲突时，以更高优先级、更新、更接近目标项目的资料为准；仍无法判断且会影响实现边界时，停止并请求确认。

读取上下文的目标是形成可执行判断：任务级别、OpenSpec 是否需要、Executor 分配、可编辑范围、验证方式、风险边界和停止条件。

---

## 3. Graphify 工作流（强制）

Graphify 规则继承全局配置。本 profile 只增加 claude-flow 交接与审查证据要求：

- Clarify Gate、Handoff Task Package、Review Input 和最终交付必须包含 Graphify context 或降级依据。
- Graphify 缺失不得阻断任务，但必须记录不可用原因。
- Implementation Codex 不得把缺失的 Graphify context 当作扩大范围的理由。

---

## 4. Clarify Gate

中 / 大任务、OpenSpec 任务、handoff 任务和高风险任务必须先过 Clarify Gate。

必须明确：

- Acceptance criteria。
- Out-of-scope。
- OpenSpec 判断和理由。
- Graphify context 或降级依据。
- 每个 task 的 Executor：Architecture Codex、Implementation Codex、Review Codex 或人工负责人。
- Validation 命令。
- Stop conditions。
- Review mode：独立 Review Codex、fresh Codex context，或小任务轻量自审。
- Editable files / Forbidden files 初稿。

未通过 Clarify Gate 不进入 DESIGN。小任务、明确 bugfix 或用户明确要求直接修的小问题，可以走轻量路径，但仍必须保留测试和验证证据；若范围膨胀，立即升级为六阶段流水线。

---

## 5. 任务分级

| 级别 | 判断标准 | 流程 |
| --- | --- | --- |
| 小 | Bug 修复、少量文件、需求明确、风险低 | Architecture Codex 可直接 TDD 实现并轻量自审 |
| 中 | 单模块新功能、3-9 文件、需要任务拆分 | 六阶段流水线，通常单 Implementation Codex |
| 大 | 跨模块、>=10 文件、公共契约或复杂依赖 | 六阶段流水线，按 slice 拆分，可多 Implementation Codex |

范围升级规则：执行中新增超过 2 个文件、出现跨模块依赖、公共契约变化、安全边界变化或验证命令变化，立即回到 DESIGN。

---

## 6. 六阶段流水线

六阶段名称保留，执行细则继承全局 OpenSpec、TDD、Graphify 和验证规则。本 profile 只规定角色分工、交接产物和 gate。

| Stage | Owner | Output / Gate |
| --- | --- | --- |
| ANALYZE | Architecture Codex | 明确 dirty baseline、Graphify context / 降级依据、OpenSpec 判断、Executor、验证和 stop conditions；关键边界不清楚则停在本阶段。 |
| DESIGN | Architecture Codex | 形成轻量计划或 OpenSpec proposal / design / tasks；中 / 大任务拆成可交接 slice，公共契约先由单一 owner 固化。 |
| HANDOFF | Architecture Codex -> Implementation Codex | Handoff Task Package 包含 ChangeId / TaskId、Executor、验收与排除项、Editable / Forbidden files、Validation、Stop conditions、Graphify context、GitBaseline、SessionStatePath、PreExistingDirtyBaseline、交付 artifact / worktree 和 IntegrationOwner。 |
| IMPLEMENT | Implementation Codex | 按任务包 RED-GREEN-REFACTOR；提交 changed files、验证输出、需求覆盖、未验证项和范围扩展请求。Architecture Codex 检查 allowlist、status、dirty baseline 和 session-state。 |
| REVIEW | Review Codex | Review Input = Handoff Task Package + Implementation Evidence + diff / status + spec/design/tasks 或 NO_OPENSPEC 理由 + 验证输出；只输出 PASS、FIX_REQUIRED 或 DOWNGRADE。 |
| VERIFY | Architecture Codex | 消费 `runtime-verification-summary.sh` / PostToolUse tracker（不可用则记录 degraded），运行 fresh verification，确认 tasks / Review Decision / 归档要求，更新或归档 session-state，并按全局交付清单收口。 |

中 / 大任务默认使用独立 worktree 或 patch artifact handback；共享核心文件、公共契约、session-state、profile/workflow/skill/hook、构建配置和测试配置不得并发直写。契约任务先同步端点、参数、返回值、错误语义和调用方状态需求；调用方发现契约不满足需求时回到 DESIGN。

---

## 7. Session State

`.codex/session-state.md` 是当前 worktree 的活跃状态；`.codex/session-state.template.md` 是恢复模板。

必须保留字段：

- `Mode: codex-codex-claude-flow-gpt55-dev`
- `ActiveTaskStatus`
- `Current Stage`
- `CurrentTask`
- `Executor`
- `FileAllowlist`
- `GitBaseline`
- `LastVerificationResult`
- `CompletedTasks`
- `PendingTasks`
- `DegradationCount`
- `NextPromptSeed`

生命周期：

- 初始化：从 `.codex/session-state.template.md` 生成，`ActiveTaskStatus=NONE`。
- 激活：进入 HANDOFF / IMPLEMENT / REVIEW 时更新任务、allowlist、baseline、验证状态和队列。
- 恢复：缺失或为空且无活跃证据时从模板重建；存在 diff、任务包或线程证据时先暂停，按最近任务包恢复并标记 `Recovered: true`。
- 归档：完成后复制到 `.codex/session-state.archive/`，再从模板重置。不得用清空或删除文件表示完成。

---

## 8. 降级规则

| 触发条件 | 动作 |
| --- | --- |
| 单 task 修复超过 3 次仍失败 | 中止当前 Implementation Codex，递增 `DegradationCount`，由 Architecture Codex 或人工接管 |
| 自审连续 2 次失败 | 停止该 session，重新拆分或进入人工裁决 |
| 文件范围超限且未获批准 | 判为 `FIX_REQUIRED` 或 `DOWNGRADE` |
| 设计、spec 或风险边界漂移 | 回到 DESIGN |
| Review Codex 不给 `PASS` | 不进入最终 VERIFY |

降级不等于丢弃已完成工作；保留 diff、验证输出和已完成 task，再决定修复、拆分、回滚或人工接管。

---

## 9. Skills 与运行时

- `codex-orchestrate`：分析、OpenSpec 判断、任务拆分和派工治理。
- `codex-worker-handoff`：上下文交接、Implementation Codex 推进、范围护栏和 evidence 收集。
- `codex-review`：Review Codex 输入准备和审查清单。
- `.codex/agents/worker-codex.toml`：默认 coding / worker agent 执行体；不可用时记录替代 worker 来源。
- `.codex/agents/review-codex.toml`：默认独立 Review Codex 执行体；不可用时记录替代 reviewer。
- `.codex/skills/*` 是本 profile 的 runtime skill library，不等同于 OpenAI Codex 官方 repo skill discovery 路径。
- 模型名、sandbox、approval policy、MCP、hooks 属于运行时配置层；除本 profile 的模型路由说明外，不要在 `AGENTS.md` 中硬编码为 Codex 平台通用规则。

---

## 10. 交付要求

继承全局交付清单。本 profile 只补充 claude-flow 增量：

- HANDOFF / REVIEW 任务说明 Executor、Review Decision 和是否发生 DOWNGRADE。
- VERIFY 阶段说明 PostToolUse tracker 状态；degraded 时写原因和替代证据。
- 涉及 session-state 或 archive 时说明更新、保留或归档结果。
- 涉及 profile 源或落盘脚本时说明 profile/runtime sync 验证结果。

---
