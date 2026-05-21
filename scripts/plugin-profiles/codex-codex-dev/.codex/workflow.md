# codex-codex-dev Workflow Guide

> 本文件是 `codex-codex-dev` 的阶段剧本。
> `AGENTS.md` 定义入口契约、优先级、上下文来源和 gate 通过标准；本文件只说明如何执行这些 gate。不要在这里重新定义入口优先级、OpenSpec 触发器或三角色章程。

---

## 1. 使用原则

- 先读 `AGENTS.md`，再按任务路径阅读本文件对应阶段。
- 小任务可以跳过 HANDOFF / 独立 REVIEW，但必须保留 intake、analyze、verify 证据。
- 中 / 大任务需要明确 task package；中 / 大、HANDOFF 和高风险任务默认进入 Review Codex gate，且在 subagent 可用时显式启动 `.codex/agents/review-codex.toml` 定义的 custom agent。
- 任何阶段发现范围漂移、验证缺失、dirty baseline 未分类或风险边界变化，都回到 DESIGN 或请求人工确认。
- 本文件承载可执行步骤；长期规则、上下文优先级和交付格式回到 `AGENTS.md`。

---

## 2. Session State 生命周期

`.codex/session-state.md` 是运行态文件，`.codex/session-state.template.md` 是项目级恢复模板。恢复时只使用当前项目内模板，不依赖 profile 源仓库路径。

- 初始化：新 worktree 或缺失状态时，从 `.codex/session-state.template.md` 生成 `.codex/session-state.md`，初始 `ActiveTaskStatus` 为 `NONE`。
- 激活：进入 handoff / implement / review 时，更新 `ActiveTaskStatus`、`Current Stage`、`ChangeId`、`CurrentTask`、`FileAllowlist`、`GitBaseline`、验证状态、`CompletedTasks`、`PendingTasks` 和 `DegradationCount`。
- 恢复：若 `.codex/session-state.md` 缺失或为空，且没有活跃任务证据，直接从模板重建；若 diff、任务包、线程记录或非模板字段显示存在活跃任务，暂停 handoff / review，按最近任务包、git baseline、已完成 / 待完成任务和降级计数重建状态，并标记 `Recovered: true`。
- 归档：完成任务后，将当前状态复制到 `.codex/session-state.archive/YYYYMMDDHHMMSS-<change-id>.md`，再从模板重置 `.codex/session-state.md`。不得用清空文件表示归档完成。
- 重置：只有用户明确要求、脚本显式 `--reset-session-state`，或确认无活跃任务时，才允许覆盖非空状态文件。

---

## 3. Stage 0: INTAKE

目标：锁定当前输入，防止旧上下文或用户已有改动混入。

动作：

1. 复述当前用户请求、明确排除项和预期交付物。
2. 运行或读取 `git status --porcelain`，分类 dirty baseline。
3. 确认目标文件是否在当前可写范围内。
4. 判断是否涉及 profile source 与 runtime 落盘同步。
5. 判断是否可能需要 OpenSpec、handoff、独立 review 或多 agent。

输出：

- Intake Summary。
- PreExistingDirtyBaseline。
- 初步 Editable files / Forbidden files。

Gate：dirty baseline 未分类、目标文件不可写或用户请求与现有状态冲突时，不进入 ANALYZE。

---

## 4. Stage 1: ANALYZE

目标：把请求变成可判断的任务边界。

动作：

1. 按 `AGENTS.md` 的上下文来源读取资料。
2. 执行 Graphify 条件路由：如果存在 `graphify-out/graph.json`，且任务涉及架构、依赖、影响面、跨模块修改或非平凡代码搜索，优先使用可用图谱查询目标模块的 `architecture dependencies`；修改代码前还要查询或梳理 `impact callers tests dependencies`。如果 graphify CLI/MCP 不可用、图谱过期或无匹配结果，降级读取 `graphify-out/GRAPH_REPORT.md`；仍不可用时记录原因并继续原流程。
3. 检查 OpenSpec：`openspec list --specs`、`openspec list`。
4. 对照现有 spec / change 判断是否复用、更新或新建提案。
5. 识别任务级别：小 / 中 / 大。
6. 识别风险边界：安全、权限、数据访问、公共契约、部署行为、profile/runtime sync。
7. 形成验收标准、out-of-scope、验证命令和 stop conditions。

Clarify Gate：

- 验收标准、out-of-scope、验证命令或 stop conditions 不清楚时，只问会影响实现边界的问题。
- 中 / 大任务必须明确每个 task 的执行责任：Architecture Codex、Implementation Codex、Review Codex 或人工负责人。
- 必须明确是否需要 OpenSpec；若跳过，记录理由。
- 必须明确 review mode：独立 Review Codex、替代 reviewer，或小任务轻量自审。
- 如果用户明确要求不使用 subagent，记录为约束，并在 review 阶段说明非独立上下文。

输出：

- Task level。
- OpenSpec 判断和依据。
- Acceptance criteria。
- Out-of-scope。
- Validation。
- Risk boundaries。
- Stop conditions。

Gate：Graphify 条件路由未执行且未记录降级原因、任务边界、OpenSpec 状态、验收标准、验证方式或风险影响不清楚时，不进入 DESIGN / IMPLEMENT。

---

## 5. Stage 2: DESIGN

目标：把分析结果转成可执行任务包。

动作：

1. 小任务：写轻量实现计划，列出文件、验证命令和回退点。
2. 中任务：拆成 bite-sized tasks；每个 task 必须能独立验收。
3. 需要 OpenSpec 时：准备或更新 proposal / design / tasks / spec delta，运行 `openspec validate <change-id> --strict --no-interactive`，记录审批状态；未批准不得进入 HANDOFF 或 IMPLEMENT。
4. 大任务：按 slice 推进；公共契约、schema、核心接口、迁移边界必须先由单一 owner 固化。
5. 若存在 Graphify impact 结果，将 callers、tests、依赖和受影响模块转成 editable / forbidden 边界或验证命令；若只做了降级分析，记录替代依据。
6. 若要并发，先确认 editable files 完全不重叠。
7. 定义 Integration Owner，负责 patch/worktree 汇总、冲突裁决和最终 verify。

Design 输出至少包含：

```markdown
- ChangeId or NO_OPENSPEC:
- OpenSpec validation:
- Approval status:
- TaskId / SliceId:
- Executor:
- Acceptance criteria:
- Editable files:
- Forbidden files:
- Validation:
- Stop conditions:
- Graphify context:
- GitBaseline:
- Split strategy:
- IntegrationOwner:
```

Gate：没有明确文件边界和验证命令，不启动 Implementation Codex；需要 OpenSpec 但未通过 strict validate 或未批准时，不进入 HANDOFF / IMPLEMENT；存在共享核心文件、契约未稳定、dirty baseline 未分类、session-state 冲突或安全/权限边界未说明时，不得并发。

---

## 6. Stage 3: HANDOFF

目标：把设计交给 Implementation Codex，同时保留治理边界。

Handoff Task Package 必须包含：

```markdown
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
- SessionStatePath:
- Patch artifact or Worktree path:
- PreExistingDirtyBaseline:
- GeneratedOrNoisyArtifacts:
- IntegrationOwner:
```

规则：

- `Editable files` 必须具体到路径或可执行 glob。
- `Forbidden files` 是硬禁止项。
- `PreExistingDirtyBaseline` 只能解释已有状态，不得自动纳入实现范围。
- 并发 Implementation Codex 默认使用独立 git worktree；无法使用独立 worktree 时，不得混写共享工作树，必须通过 patch artifact handback，由 Integration Owner 单点集成。
- 需要跨 sandbox 或写入非当前可写根时，先请求批准或改用 patch artifact。

Gate：任务包不完整、文件边界重叠、baseline 不一致或 session-state 冲突时，不启动 Implementation Codex。

---

## 7. Stage 4: IMPLEMENT

目标：按任务包实施，并收集足够进入 review 的证据。

Implementation Codex 每轮必须返回：

- TaskId / SliceId。
- changed files。
- RED command/result；无法 RED 时说明原因。
- GREEN command/result。
- Refactor note。
- Requirement coverage matrix。
- 未验证项和原因。
- 是否触发 stop conditions。
- 是否需要扩大范围。

Architecture Codex 每轮检查：

- `git diff --name-only` 是否落在 Editable files。
- `git status --porcelain` 是否出现未声明文件。
- 是否修改 Forbidden files。
- 是否混入 PreExistingDirtyBaseline 或 GeneratedOrNoisyArtifacts。
- 是否允许进入下一个 task。
- 多 Implementation Codex 场景下，是否需要先进入集成检查点。

TDD 口径：

- 新行为和 bugfix 默认先写测试或最小复现，再实现。
- 无法执行 RED-GREEN 时，必须说明原因，并提供等价验证证据。
- 每个 task 完成后记录验证命令、关键输出和未验证项。

Implementation Evidence 模板：

```markdown
## Implementation Evidence
- TaskId / SliceId:
- Changed files:
- RED command:
- RED result:
- GREEN command:
- GREEN result:
- Refactor note:
- Requirement coverage matrix:
- Unverified items:
- Risks / scope expansion:
```

混合前后端任务：

1. 后端或公共契约先由单一 owner 固化。
2. Sync Gate 检查端点、参数、返回值、错误语义和前端需要的状态。
3. 前端或 UI slice 基于已确认契约实施。
4. 如果前端发现契约不满足 UI 需求，回到 DESIGN 或后端 owner 修复。

集成检查点：

- 汇总每个 slice 的 changed files、GitBaseline、验证证据、未验证项和范围扩展记录。
- 检查 patch/worktree 基线是否一致，是否能干净合并。
- 检查 slice 间是否对同一契约、公共类型、配置或测试作出不一致实现。
- 运行与风险匹配的合并后验证命令，或说明无法运行的原因。
- 更新 `.codex/session-state.md`，记录 integration status 和剩余风险。

Gate：范围漂移、证据缺失、重复失败或风险边界变化时，停止并回到 DESIGN 或请求人工确认。

---

## 8. Stage 5: REVIEW

目标：产出 review decision，判断是否可进入最终 VERIFY。

Review 输入：

- Handoff Task Package。
- 每个 slice 的 Implementation Evidence。
- diff / status。
- OpenSpec、design、tasks 或 `NO_OPENSPEC` 理由。
- 验证命令输出。
- 安全边界和 profile/runtime sync 说明。

Review 执行模式：

1. `review-codex` custom agent / subagent：中 / 大任务、进入 HANDOFF 的任务和高风险任务在当前运行面支持 subagent 时必须显式启动。
2. 独立 session / fresh context / 人工 reviewer：仅在 `review-codex` custom agent / subagent 不可用或用户指定时作为替代 review decision 来源，并记录替代原因。
3. Architecture Codex 轻量自审：只用于小任务、降级接管或用户明确不启动 subagent 的场景；必须标注为非独立上下文。

Review 检查：

1. Scope：是否只改 Editable files，是否触碰 Forbidden files。
2. Alignment：是否符合 OpenSpec、design、tasks 和用户排除项。
3. Evidence：RED/GREEN、构建、脚本、静态检查或等价验证是否足够。
4. Safety：权限、数据访问、密钥、部署/runtime、profile sync 是否说明。
5. Regression：是否引入重复规则、双真相、兼容性风险或文档漂移。
6. Required fixes：必须修复项和复验命令。

Review 结论只能是：

- `PASS`：可进入 VERIFY。
- `FIX_REQUIRED`：退回 Implementation Codex 或 Architecture Codex 修复。
- `DOWNGRADE`：停止当前协作路径，由主线程或人工负责人重新裁决。

Gate：需要独立 review decision 的任务没有 `PASS` 时，不得进入最终 VERIFY。中 / 大、HANDOFF、高风险任务默认需要 Review Codex decision；当前运行面支持 subagent 时必须显式启动 `review-codex` custom agent。若用户明确要求不启动 subagent、custom agent 不可用或运行环境不支持，必须记录替代 review 来源或人工裁决。小任务、降级接管或用户明确要求不启动 subagent 的场景可以跳过 Stage 5，但最终 VERIFY 必须标注该 review 非独立上下文，并列出自审依据。

---

## 9. Stage 6: VERIFY + SYNC

目标：用 fresh evidence 证明交付状态。

动作：

1. 运行最终验证命令或说明无法运行原因。
2. 如涉及 OpenSpec，验证 change 或说明无需变更的依据。
3. 如涉及 profile 模板，检查 profile source 与目标 runtime 是否需要同步。
4. 如修改落盘模板，必要时运行 switch 脚本 dry-run 或等价布局检查。
5. 如归档 session-state，先写入 `.codex/session-state.archive/`，再从 `.codex/session-state.template.md` 重置运行态文件。
6. 汇总读取依据、修改文件、验证结果、未验证项和剩余风险。

Profile/runtime sync 检查：

- profile 源文件是否被修改。
- 目标项目运行态文件是否需要重新落盘。
- `.codex/workflow.md`、skills 是否与 `AGENTS.md` 分层一致。
- `.codex/session-state.template.md` 是否已落盘，`.codex/session-state.md` 是否非空且包含基础字段。
- 文档引用是否只指向目标项目可能存在或可降级的来源。
- 旧规则、旧路径和硬编码 runtime 策略是否残留。

---

## 10. 降级规则

触发以下条件时停止当前协作路径，由主线程或人工负责人重新裁决：

| 触发条件 | 动作 |
| --- | --- |
| 单 task 修复超过 3 次仍未通过验证 | 停止该 Implementation Codex，回到 DESIGN 或由 Architecture Codex 接管 |
| 自审或 review 连续 2 次 `FIX_REQUIRED` 且问题同源 | 停止扩大实现，重新评估任务包 |
| 修改超出 Editable files 且无法自动拆分 | 停止集成，请求人工确认 |
| 发现安全、权限、数据访问或公共契约风险未在设计中覆盖 | 回到 DESIGN，必要时更新 OpenSpec |
| session-state 疑似属于其他活跃任务 | 暂停 handoff / review，请求人工裁决 |

降级不等于丢弃已完成工作。先保留证据、diff 和验证输出，再决定修复、拆分、回滚或人工接管。

---

## 11. 附录：官方依据

以下链接仅作为 profile 维护、审计和交接锚点，不替代 `AGENTS.md` 的当前执行规则。维护或修改本 profile 时，应重新核验 OpenAI Codex 官方最新文档。

- OpenAI Codex `AGENTS.md` 项目指令机制：https://developers.openai.com/codex/guides/agents-md
- OpenAI Codex Workflows：https://developers.openai.com/codex/workflows
- OpenAI Codex Subagents：https://developers.openai.com/codex/subagents
- OpenAI Codex Skills：https://developers.openai.com/codex/skills
- OpenAI Codex 配置基础：https://developers.openai.com/codex/config-basic
- OpenAI Codex 沙箱机制：https://developers.openai.com/codex/concepts/sandboxing
