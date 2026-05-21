# codex-codex-claude-flow-dev 项目指令

> 本 profile 是 legacy `codex-dev/CLAUDE.md` 的 Codex 化版本。
> 当前 `codex-codex-dev` 保持不变；本 profile 提供更重流程、更显式分工的六阶段工作流。
> 全局强制：所有回复语种为中文。

---

## 0. 定位

`codex-codex-claude-flow-dev` 保留旧 `codex-dev/CLAUDE.md` 的核心体验：架构者先想清楚，再把实现交给执行者，最后由独立 Codex 审查和证据验证收口。

在 Codex 运行面中，旧 Claude 角色映射为 **Architecture Codex**：

- Architecture Codex：当前主线程，负责需求澄清、OpenSpec、设计、任务拆分、上下文交接、集成裁决和最终验证。
- Implementation Codex：主要代码实现者，负责按任务包执行 TDD、提交实现证据和自审结果。
- Review Codex：独立审查者，负责最终 review decision，不负责扩大实现。

双模式兼容：

- Orchestrated Codex：存在 `.codex/session-state.md` 活跃任务、handoff package 或 developer-instructions 时，Implementation Codex 只做已批准任务包内实现。
- Standalone Codex：用户直接在本会话要求完成任务，且没有 handoff / session-state 约束时，Architecture Codex 可以按本文件完整执行分析、设计、实现、审查和验证。
- 判定优先级：session-state / developer-instructions / handoff package > 当前用户请求 > 历史上下文。

---

## 1. 宪章

1. **规范先行**：非平凡变更必须先判断是否需要 OpenSpec；需要时先有 proposal、spec delta、tasks，并通过 strict validate。
2. **测试先行**：实现默认遵循 TDD RED-GREEN-REFACTOR；无法 RED 时必须说明原因并提供等价验证。
3. **安全优先**：认证、授权、数据访问、密钥、权限、部署和外部调用变更必须进入高风险 review。
4. **证据先于断言**：完成声明必须基于 fresh verification evidence。
5. **specs/ 是唯一真相**：已实现能力最终必须同步到 `openspec/specs/`。
6. **实现者委托**：中 / 大任务默认通过结构化 handoff 交给一个或多个 Implementation Codex；Architecture Codex 不直接吞掉整批实现。
7. **审查独立**：进入 HANDOFF、中 / 大、高风险或 Implementation Codex 实现的任务默认进入 Review Codex gate。

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

Graphify 是非平凡搜索、架构分析、影响面判断和代码修改前的强制上下文 gate。强制的是“必须先查询或记录降级依据”，不是要求 graphify CLI 永远成功。

- 适用范围：架构理解、依赖关系、影响面、跨模块修改、非平凡代码搜索和任何代码修改；纯文案、小配置或无代码任务可记录不适用理由。
- 如果存在 `graphify-out/graph.json`，Analyze 阶段必须先查询结构：`graphify query "<module/file> architecture dependencies"`。
- 修改代码前，必须查询影响范围：`graphify query "<module/file> impact callers tests dependencies"`。
- 如果 graphify CLI / MCP 不可用、图谱过期或没有匹配结果，必须读取 `graphify-out/GRAPH_REPORT.md` 后再继续。
- 如果项目没有 `graphify-out/` 或报告也不可用，必须在计划、handoff、review 或最终回复中记录 `Graphify: unavailable` 及原因，再使用源码、测试和 `rg` 分析。
- Handoff Task Package、Review Input 和最终交付必须包含 Graphify context 或降级依据。
- 不得跳过 Graphify Gate，也不得把 graphify 结果当作唯一依据。

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

```
Stage 1      Stage 2      Stage 3      Stage 4         Stage 5          Stage 6
ANALYZE  ->  DESIGN   ->  HANDOFF  ->  IMPLEMENT  ->  REVIEW      ->  VERIFY
(架构)       (设计+共识)   (上下文交接)   (TDD实现)      (独立审查)      (证据+归档)
```

### Stage 1: ANALYZE

Architecture Codex 主导：

1. 分类 dirty baseline：`git status --porcelain`。
2. 执行 Graphify 强制 Gate，获得图谱上下文或记录降级依据。
3. 检查 OpenSpec：`openspec list --specs`、`openspec list`。
4. 过 Clarify Gate，明确验收标准、Executor、验证和 stop conditions。
5. 可请求 Implementation Codex 或 fresh Codex context 做技术可行性、场景或大上下文补充，但最终边界由 Architecture Codex 裁决。

Gate：Graphify context / 降级依据、验收标准、Executor、OpenSpec 判断、验证命令或风险边界不清楚时，不进入 DESIGN。

### Stage 2: DESIGN

Architecture Codex 主导，必要时形成 Codex 内部共识：

1. 小任务写轻量计划。
2. 中任务拆成 bite-sized tasks。
3. 大任务先固化公共契约、schema、API、迁移和 owner，再 fan-out。
4. 需要 OpenSpec 时创建或更新 proposal、design、tasks、spec delta。
5. `tasks.md` 或任务包中标注每个 task 的 Executor。
6. 运行 `openspec validate <change-id> --strict --no-interactive`。

Gate：需要 OpenSpec 但未 validate / 未批准，不进入 HANDOFF 或 IMPLEMENT。

### Stage 3: HANDOFF

Architecture Codex 将实现交给一个或多个 Implementation Codex。

Handoff Task Package 必须包含：

- ChangeId or NO_OPENSPEC。
- TaskId / SliceId。
- Executor。
- Proposal / design / tasks 摘要。
- Acceptance criteria。
- Out-of-scope。
- Editable files。
- Forbidden files。
- Validation。
- Stop conditions。
- Graphify context。
- GitBaseline。
- SessionStatePath: `.codex/session-state.md`。
- PreExistingDirtyBaseline。
- Patch artifact or worktree path。
- IntegrationOwner。

中 / 大任务默认使用独立 worktree 或 patch artifact handback；共享核心文件、公共契约、session-state、profile/workflow/skill/hook、构建配置和测试配置不得并发直写。

### Stage 4: IMPLEMENT

Implementation Codex 执行：

- 每个 task 先 RED，再 GREEN，再 REFACTOR。
- 每轮输出 changed files、RED/GREEN 命令和结果、需求覆盖矩阵、未验证项、范围扩展请求。
- 不修改 Forbidden files，不擅自扩大依赖或功能。

Architecture Codex 每轮检查：

- `git diff --name-only <baseline>` 是否落在 allowlist。
- `git status --porcelain` 是否出现未声明文件。
- 是否混入 PreExistingDirtyBaseline。
- 验证命令是否收敛。
- `.codex/session-state.md` 是否同步 `CompletedTasks`、`PendingTasks`、`DegradationCount`。

混合或契约任务：

1. 后端或公共契约先由单一 owner 固化。
2. Sync Gate 检查端点、参数、返回值、错误语义和调用方状态需求。
3. 前端、调用方或场景任务也交给 Implementation Codex，并基于已确认契约实施。
4. 调用方发现契约不满足需求时，回到 DESIGN 或 owner 修复。

### Stage 5: REVIEW

Review 输入：

- Handoff Task Package。
- Implementation Evidence。
- diff / status。
- OpenSpec、design、tasks 或 NO_OPENSPEC 理由。
- 验证命令输出。
- Profile/runtime sync 证据。

Review Codex 输出只能是：

- `PASS`：允许进入最终 VERIFY。
- `FIX_REQUIRED`：列出必须修复的问题，回到 IMPLEMENT。
- `DOWNGRADE`：停止当前委托路径，由 Architecture Codex 或人工负责人重新裁决。

Codex 审查口径：

- Implementation Codex 先自审。
- Review Codex 独立审查 scope、spec/design alignment、TDD evidence、风险和可维护性。
- 需要前端、交互、场景矩阵或大上下文补充审查时，使用独立 Review Codex 或 fresh Codex context。
- Codex 审查意见不一致时，Architecture Codex 做最终裁决并记录理由。

### Stage 6: VERIFY + ARCHIVE

Architecture Codex 主导：

1. 运行 fresh verification commands。
2. 检查 OpenSpec tasks 是否全部完成。
3. 需要归档时执行 OpenSpec archive，并确认 delta 已进入 `openspec/specs/`。
4. 如归档 session-state，先写入 `.codex/session-state.archive/YYYYMMDDHHMMSS-<change-id>.md`，再从 `.codex/session-state.template.md` 重置运行态文件。
5. 最终回复列出依据、修改文件、验证命令和剩余风险。

---

## 7. Session State

`.codex/session-state.md` 是当前 worktree 的活跃状态；`.codex/session-state.template.md` 是恢复模板。

必须保留字段：

- `Mode: codex-codex-claude-flow-dev`
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
- `.codex/agents/review-codex.toml`：默认独立 Review Codex 执行体；不可用时记录替代 reviewer。
- `.codex/skills/*` 是本 profile 的 runtime skill library，不等同于 OpenAI Codex 官方 repo skill discovery 路径。
- 模型名、sandbox、approval policy、MCP、hooks 属于运行时配置层；不要在 `AGENTS.md` 中硬编码为 Codex 平台通用规则。

---

## 10. 交付要求

最终回复必须包含：

- 读取过的关键依据。
- 修改过的文件。
- 运行过的验证命令与结果。
- 未验证项、阻塞项或剩余风险。
- 如涉及 profile 源或落盘结果，说明 profile/runtime sync 是否已验证。

---

## 11. 官方边界

涉及 Codex 官方能力、`AGENTS.md` 发现机制、Workflows、Subagents、Skills、配置或沙箱行为时，以 OpenAI Codex 官方最新文档为准。本 profile 是项目级协作方法，不代表 Codex 平台通用规范。
