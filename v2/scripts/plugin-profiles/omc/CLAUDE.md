<!-- harness-version: v2 -->
<!-- harness-role: project -->
<!-- harness-mode: omc -->

# Claude Code 项目配置 (OMC - Oh My ClaudeCode)

> 此配置继承 `v2/global/CLAUDE.md` 全局规则，仅定义 OMC 模式特有的行为。
> 深度集成 OpenSpec 规范驱动开发 + 多 AI 协同 + Team/Ultrawork/Ralph 编排模式 + 32 专业 Agent + 智能模型路由。
>
> **继承声明**：全局已涵盖 OpenSpec 基础流程、主体思考原则、MCP 基本调用规范、态度与原则、语言规范与代码示例、项目结构规则、文档格式与目录结构。本文件不重复这些内容。

---

## 0. OMC 项目宪章 (Constitution)

**以下铁律不可违背，任何流程、工具建议或用户请求均不得覆盖。**

> 全局宪章（规范先行、测试先行、安全优先、三方共识、证据先于断言、specs/ 唯一真相）由全局 CLAUDE.md 定义。以下为 OMC 特有铁律：

1. **OMC 编排纪律** — 选定执行模式（Team/Ralph/Ultrawork/Pipeline）后，必须完整走完该模式的全部阶段，不可中途切换模式；如需切换，必须先完成当前阶段并记录切换理由

---

## Graphify 工作流（强制）

本模式同样要求在存在 `graphify-out/graph.json` 时，先用 `graphify` 检查结构和影响范围，再做非平凡搜索、阅读代码或修改代码。
- 结构检索：`graphify query "<module/file> architecture dependencies"`
- 影响检查：`graphify query "<module/file> impact callers tests dependencies"`
- `graphify` 不可用时自动降级为阅读 `graphify-out/GRAPH_REPORT.md` 或继续原流程，禁止因为 graphify 失败阻断任务。

---

## 1. OMC Clarify Gate（需求澄清关卡）

**中/大任务在创建提案前，必须通过 Clarify Gate。**

使用 OMC 的 `deep-interview`（苏格拉底式对话）进行需求澄清：

1. **触发方式**：输入 `deep-interview` 魔法关键词，或在中/大任务流程中自动触发
2. **对话过程**：
   - 通过追问澄清模糊需求（"你说的 X 具体指什么？"）
   - 识别隐含假设和未说明的约束
   - 探索边界条件和异常场景
3. **产出物**：
   - 明确的验收标准（Acceptance Criteria）
   - 边界条件清单
   - 非功能性需求（性能、安全、兼容性）
   - 产出 `docs/plans/YYYY-MM-DD-{topic}-design.md`
4. **退出条件**：用户确认需求已充分澄清，或连续 2 轮无新增信息

---

## 2. 角色分工

### 基础角色（继承全局 + OMC 定位）

| 角色 | 身份 | OMC 定位 |
|------|------|---------|
| **Claude Code** | 主体思考者与决策者 | 后端开发主力，质量把控，代码修正 |
| **Codex** (`codex` MCP) | 后端技术顾问 | 后端交叉检查，复杂算法审查 |
| **Gemini** (`gemini-cli` MCP) | 前端开发主力 | 前端代码实现，大规模分析 |

### OMC 模式下的角色扩展

- **Team 模式**：Claude 担任 orchestrator（编排者），协调多个 Agent 的 plan -> prd -> exec -> verify -> fix 流水线
- **ccg 模式**：Claude 综合 Codex + Gemini 的并行分析结果，做出最终决策
- **Ralph 模式**：Claude 进入持久执行状态，自主驱动 verify/fix 循环直到任务完成
- **Ultrawork 模式**：Claude 协调最大并行度的批量执行

---

## 3. 前后端分工流程

### 3.1 后端开发流程 (Claude 主导)
```
Claude 实现 -> Claude 自检 -> Codex 交叉检查 -> Claude 修复 -> 验证完成
```

### 3.2 前端开发流程 (Gemini 主导)
```
Claude 设计 -> Gemini 实现 -> Claude 审查 -> Gemini/Claude 修正 -> 验证完成
```

### 3.3 复杂分析与方案设计流程 (ccg 模式)

**直接使用 OMC 的 `ccg` 模式替代手动轮转分析。**

```
输入需求 -> ccg 自动触发 /ask codex + /ask gemini 并行分析 -> Claude 综合决策
```

1. **触发**：输入 `ccg` 关键词，或在复杂分析场景中自动启用
2. **并行分析**：OMC 自动编排 `/ask codex`（技术实现角度）和 `/ask gemini`（全局视角）并行执行
3. **Claude 综合**：收到两方分析结果后，独立评估并做出最终方案
4. **适用场景**：架构设计、技术选型、复杂问题诊断、重大重构决策

---

## 4. 交叉检查规则 (Cross-Check)

### 检查策略

| 代码类型 | 主实现 | 交叉检查 | 修复者 |
|---------|-------|---------|-------|
| 后端代码 | Claude Code | Codex | Claude Code |
| 前端代码 | Gemini | Claude Code | Gemini/Claude |
| 混合代码 | 按类型分 | 对应检查者 | 对应修复者 |

### 强制规则

**三方未达成一致时，禁止推进到下一阶段。** 多轮分歧时，由 Claude 做最终决策并记录理由。

### 智能模型路由影响交叉检查

OMC 的智能模型路由根据检查复杂度自动选择模型：

| 检查场景 | 路由模型 | 理由 |
|---------|---------|------|
| 简单代码审查（格式、命名、注释） | Haiku | 快速低成本，足够处理表面问题 |
| 常规功能验证（逻辑正确性、边界条件） | Sonnet | 平衡速度与深度 |
| 核心逻辑和架构分歧 | **强制 Opus** | 需要最深层推理能力解决分歧 |
| 安全相关审查 | **强制 Opus** | 安全问题不容妥协 |

---

## 5. 任务分级与工作流程

### 5.0 任务分级

| 级别 | 判断标准 | 流程概要 |
|------|---------|---------|
| **小** | Bug 修复、配置调整、< 3 文件、需求明确无歧义 | 直接 TDD 实现，无需提案 |
| **中** | 单模块新功能、3-9 文件、需要设计决策但范围可控 | deep-interview -> OpenSpec proposal -> 实现 |
| **大** | 跨模块/架构变更、>=10 文件、复杂依赖、需多会话 | deep-interview -> OpenSpec proposal -> writing-plans -> Team/Ultrawork 实现 |

**边界与升级规则**：
- 涉及公共 API/数据模型、权限/安全、数据迁移、跨模块耦合时，至少升级为中任务
- 执行中若范围膨胀（新增 >2 文件或出现跨模块依赖），立即重分级并切换流程
- 中任务写 tasks.md 时若无法给出 bite-sized 步骤，升级为大任务并执行 writing-plans

### 5.1 小任务流程 (Autopilot 模式适用)

```
systematic-debugging(如bug) -> TDD 实现 -> Ralph verify/fix -> 提交
```

1. 使用 `superpowers:systematic-debugging`（如果是 bug）
2. 使用 `superpowers:test-driven-development` 编写实现/修复
3. 使用 Ralph 模式的 verify/fix 循环验证
4. 直接提交，无需 OpenSpec 提案
5. **Autopilot 模式**：小任务可启用 `autopilot`，Claude 自主完成全流程无需人工干预

### 5.2 中任务流程 (deep-interview + Ralph 验证)

```
deep-interview -> OpenSpec proposal(tasks.md=bite-sized) -> TDD 实现 -> Ralph verify/fix -> 归档
```

1. **需求澄清** -- `deep-interview`（Clarify Gate）
   - 苏格拉底式对话澄清需求，提出 2-3 种方案及权衡
   - 多 AI 交叉验证（ccg 模式，2-3 轮），确认设计合理性
   - 产出 `docs/plans/YYYY-MM-DD-{topic}-design.md`

2. **OpenSpec 提案** -- `/openspec:proposal`
   - proposal.md: 为什么、做什么、影响
   - **tasks.md: 直接写成 bite-sized 实现步骤**（每步含文件路径、代码要点、验证命令，粒度 2-5 分钟）
   - spec deltas: 需求变更（ADDED/MODIFIED/REMOVED）
   - 验证：`openspec validate <id> --strict --no-interactive`
   - **等待用户审批**

3. **实现** -- `/openspec:apply`
   - 按 tasks.md 顺序实现
   - TDD 强制：`superpowers:test-driven-development`（RED-GREEN-REFACTOR）
   - 多 AI 交叉验证（ccg 模式编排）
   - Code Review：`superpowers:requesting-code-review`

4. **验证与归档**
   - **Ralph 模式**：启用 `ralph` 进入持久 verify/fix 循环，自主修复直到所有测试通过
   - `superpowers:finishing-a-development-branch` -- 分支集成
   - `/openspec:archive` -- 合并 delta spec 到 `specs/`，执行完整性检查

### 5.3 大任务流程 (Team/Ultrawork/Pipeline 模式)

```
deep-interview -> OpenSpec proposal(tasks.md=高层) -> writing-plans -> Team/Ultrawork 执行 -> Ralph verify/fix -> 归档
```

Step 1-2 同中任务，但 **tasks.md 为高层任务清单**。额外步骤：

3. **细化实现计划** -- `superpowers:writing-plans`
   - 基于 tasks.md 细化为 bite-sized 步骤（每步 2-5 分钟）
   - 每步含精确文件路径、完整代码、验证命令
   - 产出 `docs/plans/YYYY-MM-DD-{feature-name}.md`

4. **实现** -- 选择 OMC 执行模式：
   - **Team 模式**（推荐）：plan->prd->exec->verify->fix 全流水线
   - **Ultrawork 模式**：最大并行度批量执行，适合大量独立子任务
   - **Pipeline 模式**：多阶段串行流水线，适合有严格依赖的任务链
   - **Ralplan 模式**：Ralph + 计划驱动，适合需要持久执行的计划任务
   - TDD + 多 AI 交叉验证 + Code Review

5. **验证与归档**
   - **Ralph 模式**：持久 verify/fix 循环，自主修复直到所有测试通过
   - `superpowers:finishing-a-development-branch` -- 分支集成
   - `/openspec:archive` -- 合并 delta spec 到 `specs/`，执行完整性检查

### 5.4 Team 模式 5 阶段 <-> OpenSpec 3 阶段精确映射

```
Team plan   --> OpenSpec Stage 1（创建提案：proposal.md + tasks.md 高层）
Team prd    --> OpenSpec Stage 1（细化：spec deltas + design.md）
                + writing-plans（bite-sized 步骤）
Team exec   --> OpenSpec Stage 2（TDD 实现 + 交叉检查）
Team verify --> OpenSpec Stage 2（verification-before-completion）
Team fix    --> OpenSpec Stage 2（修复 + Ralph verify/fix 循环）
归档         --> OpenSpec Stage 3（specs/ 同步 + archive）
```

| Team 阶段 | OpenSpec 阶段 | 产出物 | 触发的 Agent |
|-----------|--------------|--------|-------------|
| plan | Stage 1: 创建提案 | proposal.md, tasks.md（高层） | planner, researcher |
| prd | Stage 1: 细化 | spec deltas, design.md, bite-sized 计划 | prd-writer, architect |
| exec | Stage 2: 实现 | 源代码 + 测试 | coder, tdd-agent, frontend-dev |
| verify | Stage 2: 验证 | 测试报告、交叉检查结果 | reviewer, security-auditor |
| fix | Stage 2: 修复 | 修复后代码 | fixer, debugger |
| (归档) | Stage 3: 归档 | specs/ 更新, archive/ | doc-writer |

---

## 6. 多 AI 交叉验证（每阶段强制，含模型路由）

| 阶段 | Claude 职责 | Codex 审查 | Gemini 审查 | 路由模型 |
|------|-----------|-----------|------------|---------|
| **设计** (deep-interview) | 独立分析需求，形成初步方案 | 技术可行性、架构合理性 | 全局视角、模式发现 | Sonnet/Opus |
| **提案** (OpenSpec) | 起草 proposal/tasks/spec deltas | API 设计合理性、边界条件 | 场景覆盖完整性 | Sonnet |
| **计划** (writing-plans) | 细化 bite-sized 步骤 | 步骤依赖关系、前置条件 | 覆盖度、验证命令充分性 | Sonnet |
| **实现** (TDD per task) | 编写代码 | 后端代码质量、安全性 | 前端代码质量 | Haiku->Opus |
| **测试** (verification) | 运行测试、确认输出 | 安全性最终确认 | 功能完整性最终确认 | **强制 Opus** |
| **归档** (archive) | 执行归档流程 | specs/ 同步正确性 | 6 项完整性检查 | Sonnet |

**执行规则**：
- 每个阶段 2-3 轮交叉验证，直到三方达成一致
- 交叉验证使用 **ccg 模式**自动编排 Codex + Gemini 并行分析
- 多轮分歧时，由 Claude 做最终决策并记录理由
- **三方未达成一致时，禁止进入下一阶段**
- 智能模型路由根据检查复杂度自动选择模型

---

## 7. OMC 技能/模式与工作流映射

| 技能/模式 | 小 | 中 | 大 | 用途 |
|----------|:--:|:--:|:--:|------|
| `deep-interview` | - | Y | Y | 需求澄清（Clarify Gate） |
| `ccg` | - | Y | Y | 多 AI 并行分析与综合决策 |
| `autopilot` | Y | - | - | 小任务自主执行 |
| `team` | - | - | Y | 5 阶段全流水线编排 |
| `ultrawork` | - | - | Y | 最大并行度批量执行 |
| `pipeline` | - | - | Y | 多阶段串行流水线 |
| `ralph` | Y | Y | Y | 持久 verify/fix 循环 |
| `ralplan` | - | - | Y | Ralph + 计划驱动执行 |
| `using-git-worktrees` | - | 可选 | 推荐 | 隔离工作空间 |
| `writing-plans` | - | - | Y | 细化 tasks.md 为 bite-sized 步骤 |
| `subagent-driven-development` | - | 可选 | Y | subagent 驱动执行 |
| `executing-plans` | - | - | Y | 分批执行 + 检查点 |
| `test-driven-development` | Y | Y | Y | TDD RED-GREEN-REFACTOR |
| `requesting-code-review` | - | Y | Y | 代码审查 |
| `verification-before-completion` | Y | Y | Y | 完成前证据验证 |
| `finishing-a-development-branch` | - | Y | Y | 分支集成与清理 |
| `systematic-debugging` | 按需 | 按需 | 按需 | Bug 系统化调试 |
| `dispatching-parallel-agents` | - | 可选 | Y | 并行任务执行 |
| `session-recovery` | - | Y | Y | 压缩恢复 |

---

## 8. 会话状态持久化

执行 `subagent-driven-development`、`executing-plans` 或 **OMC 编排模式**（Team/Ultrawork/Pipeline）时，**必须**在 `.claude/session-state.md` 维护编排状态。

- **写入时机**: 进入工作流时创建，每个 task 完成/阶段切换时更新，工作流结束时删除
- **恢复时机**: 会话开始或上下文压缩后，检查此文件并恢复状态
- **自动检查**: 每次会话开始时检查 `.claude/session-state.md` 是否存在
- **OMC 编排模式额外字段**：当前执行模式名称、当前阶段、活跃 Agent、模型路由状态

**OMC session-state.md 示例格式**：

```markdown
## OMC Session State
- **模式**: Team
- **当前阶段**: exec (3/5)
- **当前任务**: 2.3 实现用户认证 API
- **活跃 Agent**: coder
- **路由模型**: Sonnet
- **已完成任务**: [1.1, 1.2, 2.1, 2.2]
- **待处理任务**: [2.3, 2.4, 3.1, 3.2]
- **切换记录**: (无)
```

---

## 9. OMC 特色功能

### 9.1 七种执行模式详解

| 模式 | 关键词 | 适用场景 | 执行方式 | OpenSpec 映射 |
|------|--------|---------|---------|--------------|
| **Team** | `team` | 大任务、跨模块协作 | plan->prd->exec->verify->fix 5 阶段流水线 | Stage 1->2->3 全覆盖 |
| **ccg** | `ccg` | 复杂分析、方案设计 | Codex+Gemini 并行分析->Claude 综合 | Stage 1 设计阶段 |
| **Autopilot** | `autopilot` | 小任务、明确需求 | Claude 自主完成全流程 | 小任务直接执行 |
| **Ultrawork** | `ultrawork`/`ulw` | 大量独立子任务 | 最大并行度批量执行 | Stage 2 并行实现 |
| **Ralph** | `ralph` | 验证修复循环 | 持久 verify/fix 直到通过 | Stage 2 验证阶段 |
| **Pipeline** | `pipeline` | 严格依赖的任务链 | 多阶段串行流水线 | Stage 2 串行实现 |
| **Ralplan** | `ralplan` | 计划驱动+持久执行 | Ralph + 计划文件驱动 | Stage 2 计划+实现 |

**模式选择规则**：
- 小任务 -> Autopilot 或直接执行
- 中任务需要分析 -> ccg
- 中任务验证 -> Ralph
- 大任务全流程 -> Team
- 大任务并行子任务 -> Ultrawork
- 大任务串行依赖 -> Pipeline
- 大任务计划驱动 -> Ralplan

**模式组合规则**：
- Team 和 Ralph 可组合：Team 的 verify/fix 阶段自动启用 Ralph 循环
- Ralplan = Ralph + writing-plans 的组合模式
- ccg 可嵌入任何模式的分析阶段
- Autopilot 不可与其他编排模式组合（自包含模式）
- Pipeline 的每个阶段内部可启用 Ultrawork 进行并行子任务

### 9.2 Magic Keywords（魔法关键词）

| 关键词 | 触发功能 |
|--------|---------|
| `team` | 启动 Team 模式 5 阶段流水线 |
| `ccg` | 启动 Codex+Gemini+Claude 并行分析 |
| `autopilot` | 启动自主执行模式 |
| `ultrawork` / `ulw` | 启动最大并行度执行 |
| `ralph` | 启动持久 verify/fix 循环 |
| `pipeline` | 启动多阶段串行流水线 |
| `ralplan` | 启动 Ralph + 计划驱动 |
| `deep-interview` | 启动苏格拉底式需求澄清 |
| `/ask codex` | 单独咨询 Codex |
| `/ask gemini` | 单独咨询 Gemini |

### 9.3 智能模型路由

OMC 根据任务复杂度自动选择最优模型，贯穿所有工作流环节：

**路由策略**：

| 任务复杂度 | 路由模型 | 典型场景 |
|-----------|---------|---------|
| 低（格式、命名、简单修复） | Haiku | 代码格式化、变量重命名、注释修正 |
| 中（功能实现、常规逻辑） | Sonnet | 单模块功能开发、常规 bug 修复、API 实现 |
| 高（架构、安全、核心逻辑） | **Opus** | 架构设计、安全审查、核心算法、三方分歧裁决 |

**强制 Opus 场景**（不可降级）：
- 安全相关代码审查
- 架构级设计决策
- 三方交叉检查出现分歧时的最终裁决
- 涉及数据模型或公共 API 的破坏性变更

### 9.4 HUD 状态栏

OMC 提供 HUD（Heads-Up Display）实时显示当前工作状态：

```
[OMC] 模式: Team | 阶段: exec | 任务: 3/7 | Agent: coder | 模型: Sonnet
```

HUD 信息包括：
- 当前执行模式
- 当前阶段
- 任务进度
- 活跃 Agent
- 当前路由模型

### 9.5 32 专业 Agent 与工作流节点映射

OMC 内置 32 个专业 Agent，按职能分为 6 大类，映射到工作流各节点：

**规划类 Agent**（Stage 1，共 5 个）：

| Agent | 职能 | 工作流节点 |
|-------|------|-----------|
| planner | 任务分解与规划 | Team plan / deep-interview |
| researcher | 技术调研与信息收集 | Team plan / ccg 分析 |
| prd-writer | 需求文档编写 | Team prd / OpenSpec proposal |
| architect | 架构设计 | Team prd / design.md |
| risk-analyst | 风险评估与依赖分析 | Team plan / 提案影响评估 |

**实现类 Agent**（Stage 2 - 实现，共 8 个）：

| Agent | 职能 | 工作流节点 |
|-------|------|-----------|
| coder | 后端代码编写 | Team exec / TDD 实现 |
| frontend-dev | 前端代码编写 | Team exec / Gemini 协作 |
| tdd-agent | TDD 流程执行 | Team exec / RED-GREEN-REFACTOR |
| refactorer | 代码重构 | Team exec / REFACTOR 阶段 |
| db-designer | 数据库设计 | Team exec / schema 设计 |
| api-designer | API 设计 | Team prd + exec |
| integrator | 模块集成与接口对接 | Team exec / 跨模块集成 |
| migration-agent | 数据迁移与兼容处理 | Team exec / 迁移脚本 |

**质量类 Agent**（Stage 2 - 验证，共 7 个）：

| Agent | 职能 | 工作流节点 |
|-------|------|-----------|
| reviewer | 代码审查 | Team verify / 交叉检查 |
| security-auditor | 安全审计 | Team verify / 安全审查（强制 Opus） |
| performance-analyst | 性能分析 | Team verify / 性能检查 |
| test-writer | 测试编写 | Team exec + verify |
| qa-engineer | 质量保证 | Team verify / 集成测试 |
| accessibility-checker | 可访问性检查 | Team verify / 前端无障碍 |
| compatibility-tester | 兼容性测试 | Team verify / 跨平台验证 |

**修复类 Agent**（Stage 2 - 修复，共 4 个）：

| Agent | 职能 | 工作流节点 |
|-------|------|-----------|
| fixer | 问题修复 | Team fix / Ralph verify/fix |
| debugger | 调试分析 | Team fix / systematic-debugging |
| optimizer | 性能优化 | Team fix / 性能修复 |
| rollback-agent | 回滚与降级处理 | Team fix / 紧急回退 |

**文档类 Agent**（Stage 3，共 4 个）：

| Agent | 职能 | 工作流节点 |
|-------|------|-----------|
| doc-writer | 文档编写 | 归档 / specs 同步 |
| changelog-writer | 变更日志 | 归档 / archive |
| spec-writer | 规范编写 | OpenSpec spec deltas |
| api-doc-writer | API 文档生成 | 归档 / 接口文档 |

**运维类 Agent**（贯穿全流程，共 4 个）：

| Agent | 职能 | 工作流节点 |
|-------|------|-----------|
| devops | CI/CD 与部署 | 全流程 |
| monitor | 监控与告警 | Ralph verify 循环 |
| config-manager | 配置管理 | 全流程 |
| env-manager | 环境管理与隔离 | worktree / 沙箱环境 |

### 9.6 Ralph 模式与验证深度集成

Ralph 模式是 OMC 的持久验证引擎，深度集成到 OpenSpec 工作流的验证阶段：

```
Ralph 循环：
  1. 运行全部测试 -> 收集失败列表
  2. 分析失败原因 -> 智能模型路由选择修复模型
  3. 修复代码 -> 重新运行测试
  4. 重复直到全部通过或达到最大轮次
  5. 输出验证报告（含每轮修复记录）
```

**与 OpenSpec 集成点**：
- Stage 2 TESTING 阶段自动启用 Ralph
- Ralph 的验证报告作为 `verification-before-completion` 的证据
- Ralph 修复记录纳入 tasks.md 的完成状态更新
- 达到最大轮次仍未通过时，升级为人工介入并通知

---

## 10. 开发流程规范细节（OMC 集成）

> 基本三阶段工作流（Stage 1/2/3）和文档格式由全局定义。本节仅说明 OMC 特有的集成点。

### 10.1 Stage 1: 创建提案（OMC 增强）

1. **Clarify Gate**：使用 `deep-interview` 澄清需求，产出验收标准
2. **大任务额外步骤**：Team 模式的 plan + prd 阶段对应此 Stage，由 planner/researcher/prd-writer/architect/risk-analyst Agent 协作完成
3. **ccg 验证**：提案内容经 ccg 模式交叉验证后方可提交审批

### 10.2 Stage 2: 实现变更（OMC 增强）

**IMPLEMENTATION（实现）**
1. 阅读 proposal.md 和 design.md 理解目标和技术决策
2. 按 tasks.md 顺序实现（大任务按 writing-plans 的细化计划执行）
3. 严格遵循 TDD（RED-GREEN-REFACTOR）
4. 大任务选择 OMC 执行模式：Team exec / Ultrawork / Pipeline
5. 遵循前后端分工流程（Section 3）

**REVIEW（审查）**
1. 使用 `superpowers:requesting-code-review` 请求代码审查
2. 使用 ccg 模式编排多 AI 交叉检查
3. 智能模型路由自动选择审查模型（Section 9.3）
4. 修复发现的问题

**TESTING（测试）**
1. 启用 **Ralph 模式**进入持久 verify/fix 循环
2. 运行所有测试，确认实际输出（证据先于断言）
3. 验证所有 Scenario 通过
4. 完成后更新 tasks.md 状态为 `[x]`

### 10.3 Stage 3: 归档完成（OMC 增强）

1. 使用 `superpowers:finishing-a-development-branch` 完成分支集成
2. 确认所有 tasks.md 任务完成
3. **合并 delta spec 到 `specs/`**（由 doc-writer/spec-writer Agent 协助）
4. **同步 design.md 到 `specs/`**
5. 运行 `/openspec:archive` 归档变更
6. **执行 OpenSpec 完整性检查**（全局 Section 0.7 的 6 项检查）
7. 提交 git

---

## 11. MCP 工具使用（OMC 模式扩展）

> MCP 基本调用规范由全局定义。本节定义 OMC 模式下的协作方式。

### Codex MCP（OMC 定位）

- 默认 sandbox="read-only"，要求 Codex 仅给出 unified diff
- 角色：后端技术顾问，后端代码交叉检查

### Gemini MCP（OMC 定位）

- 将 Gemini 视为只读分析师 + 前端代码主要实现者
- 实现和最终决策由 Claude（和 Codex）完成

### OpenCode MCP（自主编码代理）

```
工具名: opencode (opencode_ask / opencode_run / opencode_reply 等)
规范: 不指定 providerID 和 modelID 参数，使用 OpenCode 自身配置的默认模型
用途: 自主编码代理，支持 114+ provider，可构建、编辑和调试项目
调用示例: opencode_run(directory=项目路径, prompt=任务指令)
禁止: 调用时手动指定 providerID 或 modelID，必须使用默认模型
```
### OMC 模式与 MCP 工具协作表

| OMC 模式 | Codex 用法 | Gemini 用法 |
|---------|-----------|------------|
| ccg | `/ask codex` 技术分析 | `/ask gemini` 全局分析 |
| Team exec | 后端交叉检查 | 前端代码实现 |
| Team verify | 安全审计 | 功能完整性检查 |
| Ralph | 修复方案验证 | 大规模日志分析 |
| Ultrawork | 并行子任务审查 | 并行子任务实现 |

---

## 12. OMC 态度补充

> 基本态度与原则由全局定义。以下为 OMC 特有补充。

- **OMC 编排纪律** -- 选定模式后完整执行，不中途切换
- 使用 ccg 模式高效获取多方观点
- 使用 Ralph 模式确保验证彻底性

---

*This configuration follows OpenSpec spec-driven development methodology.*
*Plugin: OMC (Oh My ClaudeCode) -- deep-interview + ccg + Team/Ultrawork/Ralph + 32 Agents + 智能模型路由*
*Workflow: deep-interview(Clarify Gate) -> Proposal -> Team/Ultrawork 执行 -> Ralph verify/fix -> Archive*
*Harness Version: V2 -- Inherits v2/global/CLAUDE.md. Mode-specific rules only.*
