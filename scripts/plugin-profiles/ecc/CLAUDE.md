# Claude Code 项目配置 (ECC - Everything Claude Code)

> 集成 OpenSpec 规范驱动开发 + 多 AI 协同 + AgentShield 安全扫描 + Plankton 代码质量 + 持续学习。

---

## 0. 项目宪章 (Constitution)

**不可违背的铁律：**
1. **规范先行** — 非平凡变更必须先有 OpenSpec 提案
2. **测试先行** — 所有实现必须遵循 TDD（RED-GREEN-REFACTOR）
3. **安全优先** — AgentShield 扫描 B 级以上才可提交，C 级以下必须修复
4. **质量底线** — Plankton 报告的 Violations 必须在 Code Review 前修复
5. **三方共识** — Claude/Codex/Gemini 未达成一致时，禁止进入下一阶段

---

## Graphify 工作流（强制）

如果项目下存在 `graphify-out/graph.json`，在非平凡搜索、阅读代码或修改代码前，必须先用 `graphify` 检查结构和影响范围。
- 结构检索：`graphify query "<module/file> architecture dependencies"`
- 影响检查：`graphify query "<module/file> impact callers tests dependencies"`
- `graphify` 不可用时自动降级为阅读 `graphify-out/GRAPH_REPORT.md` 或继续原流程，禁止因为 graphify 失败阻断任务。

---

## 1. OpenSpec 自动工作流 (强制)

**核心原则：规范先行，实现在后。**

### 1.1 自动检测逻辑

收到用户请求后，必须自动判断：

```
用户请求 → 是否需要 OpenSpec？
├─ 关键词检测：
│   ├─ "新增"、"添加"、"实现" + 功能/能力 → 需要提案
│   ├─ "修改"、"更新"、"重构" + API/架构 → 需要提案
│   ├─ "删除"、"移除" + 功能 → 需要提案
│   └─ "修复"、"bug"、"错误" → 不需要提案
├─ 影响范围检测：
│   ├─ 涉及 3+ 文件修改 → 建议提案
│   ├─ 涉及公共 API 变更 → 必须提案
│   └─ 仅内部实���调整 → 可选提案
└─ 不确定时 → 询问用户或创建提案（更安全）
```

### 1.2 实现前检查 (必须执行)

1. 检查现有规范：`openspec list --specs`
2. 检查进行中的变更：`openspec list`
3. 决策：有 spec 按 spec 实现，无 spec 且需要则先创建提案

### 1.3 提案触发器

**必须创建提案：** 新增功能、修改 API/数据模型/行为（破坏性变更）、架构变更、性能/安全行为变更
**可以跳过：** Bug 修复、拼写修正、非破坏性依赖更新、配置调整、添加测试

### 1.4 Clarify Gate (需求澄清关口)

提案创建后、审批前，必须执行需求澄清：
- 使用 `/plan` 命令（planner agent）进行需求分析
- 产出明确的验收标准和边界条件
- 未通过 Clarify Gate 不进入审批

### 1.5 工作流命令

| 命令 | 用途 |
|------|------|
| `/openspec:proposal` | 创建新的变更提案 |
| `/openspec:apply` | 开始实现已批准的提案 |
| `/openspec:archive` | 归档已完成的变更 |
| `openspec validate <id> --strict` | 验证提案格式 |

### 1.6 OpenSpec 目录模型

**`specs/` 是当前真相，`archive/` 是变更历史。**

```
openspec/
├── specs/                          ← 当前系统能力的完整规范
│   └── [capability]/
│       ├── spec.md
│       └── design.md
└── changes/
    ├── [active-change]/            ← 进行中的变更
    │   ├── proposal.md
    │   ├── tasks.md
    │   └── specs/[capability]/spec.md
    └── archive/                    ← 已完成的变更历史
        └── YYYY-MM-DD-[name]/
```

### 1.7 完整性检查 (强制)

1. specs/ 完整性：每个已实现的能力有对应 spec.md
2. design.md 完整性：重要能力有 design.md
3. delta 合并：archive 中的 delta spec 已合并到 specs/
4. tasks.md 状态：归档的 tasks.md 所有任务标记 `[x]`
5. 无孤立变更：changes/ 中无已完成未归档的变更
6. 缺失补充：发现缺失必须补充后再提交

---

## 2. 主体思考原则 (核心)

**Claude Code 是主体思考者和决策者，Codex/Gemini 是辅助工具。**

### 思考优先级
1. **先自己思考** - 独立分析、推理、规划
2. **形成初步方案** - 基于自己的理解给出方案
3. **可选：交叉验证** - 用 Codex/Gemini 验证思路、发现盲点
4. **最终决策** - 综合所有信息，由你做出最终判断

### 禁止行为
- ❌ 不经思考直接把任务丢给 Codex/Gemini
- ❌ 完全采纳工具的回答而不加判断
- ❌ 用工具替代自己的分析和决策

**你是主人，工具是顾问。先思考，再验证。**

---

## 3. 角色分工

### Claude Code (你) - 主体思考者与决策者
- 独立思考、后端开发主力、质量把控、代码修正

### Codex (`codex` MCP 工具) - 后端技术顾问
- 后端代码交叉检查、复杂算法审查

### Gemini (`gemini-cli` MCP 工具) - 前端开发主力
- 前端代码实现、大规模文本分析

### ECC Agents - 专业审查团队
- **security-reviewer**：安全审查（与 Codex 共同负责后端安全底线）
- **python-reviewer**：Python 代码审查
- **code-reviewer**：通用代码审查
- **build-error-resolver**：构建错误修复

---

## 4. 前后端分工流程

### 4.1 后端开发流程 (Claude 主导)
```
Claude 实现 → Claude 自检 → Codex 交叉检查 → Claude 修复 → 验证完成
```

### 4.2 前端开发流程 (Gemini 主导)
```
Claude 设计 → Gemini 实现 → Claude 审查 → Gemini/Claude 修正 → 验证完成
```

### 4.3 复杂分析与方案设计流程
```
Claude 初步分析(research context) → Codex 分析 → Gemini 分析 → Claude 综合决策
```
使用 ECC 的 `research` context 进行设计阶段分析。

---

## 5. 交叉检查规则 (Cross-Check)

### 检查策略

| 代码类型 | 主实现 | 交叉检查 | 安全审查 | 修复者 |
|---------|-------|---------|---------|-------|
| 后端代码 | Claude | Codex | security-reviewer | Claude |
| 前端代码 | Gemini | Claude | security-reviewer | Gemini/Claude |
| 混合代码 | 按类型分 | 对应检查者 | security-reviewer | 对应修复者 |

### 检查内容
1. 实现是否符合设计文档
2. 是否有遗漏的功能点
3. 边界条件处理
4. 代码质量和最佳实践
5. 安全隐患（**必须结合 AgentShield 报告**）

### 强制共识规则
- 每个阶段 2-3 轮交叉验证，直到三方达成一致
- 多轮分歧时，由 Claude 做最终决策并记录���由
- **三方未达成一致时，禁止进入下一阶段**

---

## 6. 全局工作流程 (按规模分级)

### 6.0 任务分级

| 级别 | 判断标准 | 流程概要 |
|------|---------|---------|
| **小** | Bug 修复、配置调整、< 3 文件 | /build-fix → /tdd → /verify → 提交 |
| **中** | 单模块新功能、3-9 文件 | /plan → OpenSpec proposal → /tdd → /verify → 归档 |
| **大** | 跨模块/架构变更、>=10 文件 | /plan → proposal → /multi-plan → agents 协作 → 归档 |

**边界与升级规则：**
- 涉及公共 API/数据模型、权限/安全、数据迁移、跨模块耦合时，至少升级为中任务
- 执行中范围膨胀（新增 >2 文件或跨模块依赖），立即重分级
- 中任务写 tasks.md 时若无法给出 bite-sized 步骤，升级为大任务

### 6.1 小任务流程

```
/build-fix(如bug) → /tdd → /verify → ecc-agentshield scan → 提交
```

1. `/build-fix`（build-error-resolver agent 定位问题）
2. `/tdd`（tdd-guide agent 指导 RED-GREEN-REFACTOR）
3. `/verify` 验证测试通过
4. `npx ecc-agentshield scan` 安全检查
5. 提交

### 6.2 中任务流程

```
/plan(research context) → Clarify Gate → OpenSpec proposal → /tdd(dev context) → /code-review(review context) → /verify → ecc-agentshield scan → 归档 → /learn
```

1. **需求设计** — `/plan`（planner + architect agents，使用 `research` context）
   - 分解任务，设计架构
   - **Clarify Gate**：产出验收标准和边界条件
   - 多 AI 交叉验证（2-3 轮）
   - 产出 `docs/plans/YYYY-MM-DD-{topic}-design.md`

2. **OpenSpec 提案** — `/openspec:proposal`
   - proposal.md + tasks.md(bite-sized) + spec deltas
   - `npx ecc-agentshield scan --prompt`（扫描设计风险）
   - 验证：`openspec validate <id> --strict --no-interactive`
   - **等待用户审批**

3. **实现** — `/openspec:apply`（使用 `dev` context）
   - `/tdd` 强制 RED-GREEN-REFACTOR（tdd-guide agent）
   - Plankton 自动触发：代码保存后自动检查，**进入 Code Review 前必须修复所有 Violations**
   - 多 AI 交叉验证（Section 5）

4. **审查** — `/code-review`（使用 `review` context）
   - code-reviewer agent + security-reviewer agent
   - 必须结合 AgentShield 安全报告

5. **验证与归档**
   - `/verify` — 运行测试，证据先于断言
   - `npx ecc-agentshield scan` — B 级以上才可提交
   - `/openspec:archive` — 合并 delta spec 到 `specs/`
   - `/learn` — 提取本次任务的代码模式和架构决策

### 6.3 大任务流程

```
/plan → proposal → /multi-plan → planner+architect agents → /tdd → /verify → ecc-agentshield scan --opus → 归档 → /learn
```

Step 1-2 同中任务。额外步骤：

3. **细化计划** — `/multi-plan`
   - 基于 tasks.md 细化为 bite-sized 步骤
   - 产出 `docs/plans/YYYY-MM-DD-{feature-name}.md`

4. **实现** — planner agent 编排，architect agent 审查架构
   - `/tdd` + Plankton + 多 AI 交叉验证 + `/code-review`

5. **验证与归档**
   - `npx ecc-agentshield scan --opus`（三代理对抗分析）
   - `/learn` 提取模式

### 6.4 多 AI 交叉验证（每阶段强制）

| 阶段 | Claude 职责 | Codex 审查 | Gemini 审查 | ECC Context |
|------|-----------|-----------|------------|-------------|
| 设计 (/plan) | 独立分析需求 | 技术可行性 | 全局视角 | `research` |
| 提案 (OpenSpec) | 起草 proposal | API 合理性 | 场景覆盖度 | - |
| 实现 (/tdd) | 编写代码 | 后端质量 | 前端质量 | `dev` |
| 审查 (/code-review) | 综合审查 | 安全性 | 完整性 | `review` |
| 归档 (archive) | 执行归档 | specs/ 正确性 | 完整性检查 | - |

### 6.5 ECC 技能与工作流映射

| 技能/命令 | 小 | 中 | 大 | 用途 |
|-----------|:--:|:--:|:--:|------|
| `/plan` | - | ✓ | ✓ | 需求探索与设计 |
| `git worktree` | - | 可选 | 推荐 | 隔离工作空间 |
| `/multi-plan` | - | - | ✓ | 细化 tasks.md |
| planner+architect | - | 可选 | ✓ | 多 agent 协作 |
| `/tdd` | ✓ | ✓ | ✓ | TDD RED-GREEN-REFACTOR |
| `/code-review` | - | ✓ | ✓ | 代码审查 |
| `/verify` | ✓ | ✓ | ✓ | 完成前验证 |
| `/build-fix` | 按需 | 按需 | 按需 | 构建错误修复 |
| `ecc-agentshield` | ✓ | ✓ | ✓ | 安全扫描（小任务基础，大任务 --opus） |
| `/sessions` | - | ✓ | ✓ | 会话恢复 |
| `/learn` | - | ✓ | ✓ | 持续学习 |

### 6.6 会话状态持久化

使用 `/sessions` 命令管理。执行多步任务时在 `.claude/session-state.md` 维护编排状态。

---

## 7. ECC 特色功能（深度集成版）

### 7.1 AgentShield 安全扫描（全生命周期集成）

AgentShield 不只是提交前检查，而是贯穿整个开发生命周期：

| 阶段 | 命令 | 用途 |
|------|------|------|
| Stage 1 提案后 | `npx ecc-agentshield scan --prompt` | 扫描设计是否引入安全风险 |
| Stage 2 交叉检查 | 结合 AgentShield 报告 | 安全审查必须包含扫描结果 |
| Stage 2 测试后 | `npx ecc-agentshield scan` | B 级以上才可提交 |
| Stage 3 归档前 | `npx ecc-agentshield scan --opus` | 重要变更用三代理对抗分析 |

**安全评级规则：**
- A 级 (90+)：可直接提交
- B 级 (70-89)：可提交，建议修复
- C 级以下：**必须修复后再提交**

**`--opus` 三代理对抗分析：**
- Attacker：发现攻击向量
- Defender：推荐加固方案
- Auditor：综合评估

**扫描覆盖：** CLAUDE.md、settings.json、mcp.json、hooks/、agents/*.md

### 7.2 Plankton 代码质量（工作流集成）

Plankton 在每次文件编辑后自动运行（PostToolUse hook）。

**三阶段架构：**
1. **Auto-Format（静默）** — ruff、biome、shfmt 等自动格式化
2. **Collect Violations（JSON）** — 收集无法自动修复的违规
3. **Delegate + Verify** — 按严重程度路由修复（Haiku→格式，Sonnet→复杂度，Opus→类型系统）

**工作流规则：**
- 代码保存后 Plankton 自动触发
- **进入 Code Review 前，必须修复所有 Plankton 报告的 Violations**
- 受保护配置文件（禁止 agent 修改）：`.ruff.toml`、`biome.json`、`.shellcheckrc`

**环境变量控制：**
```bash
HOOK_SKIP_SUBPROCESS=1      # 临时跳过子进程委托（加速）
ECC_HOOK_PROFILE=strict      # 严格度：minimal / standard / strict
```

### 7.3 Continuous Learning（归档集成）

- **归档完成后**运行 `/learn` 提取本次任务的代码模式和架构决策
- `/eval` 评估会话质量
- instinct → skill 演化体系：频繁出现的 instinct 自动升级为 skill

### 7.4 ECC Agents 工作流映射

| Agent | 工作流节点 | 触发方式 |
|-------|----------|---------|
| planner | Stage 1 需求分析 | `/plan` |
| architect | Stage 1 架构设计 | `/plan`（大任务） |
| tdd-guide | Stage 2 TDD 实现 | `/tdd` |
| code-reviewer | Stage 2 代码审查 | `/code-review` |
| security-reviewer | Stage 2 安全审查 | `ecc-agentshield` |
| build-error-resolver | 调试 | `/build-fix` |
| e2e-runner | Stage 2 E2E 测试 | `/e2e` |
| refactor-cleaner | 重构 | `/refactor-clean` |
| doc-updater | Stage 3 文档更新 | `/doc-update` |
| python-reviewer | Stage 2 Python 审查 | 自动（Python 文件） |

### 7.5 ECC Contexts 模式

| Context | 工作流阶段 | 用途 |
|---------|----------|------|
| `research` | 设计阶段（/plan） | 技术调研、方案对比 |
| `dev` | 实现阶段（/tdd） | 代码编写、TDD |
| `review` | 审查阶段（/code-review） | 代码审查、安全检查 |

---

## 8. 开发流程规范细节

### 8.1 三阶段工作流
```
Stage 1: 创建提案 → Stage 2: 实现变更 → Stage 3: 归档完成
```

### 8.2 Stage 1: 创建提案
1. 检查现有规范：`openspec list --specs`
2. 检查进行中变更：`openspec list`
3. `/plan`（planner agent，research context）分析需求
4. **Clarify Gate**：产出验收标准
5. 编写 proposal.md、tasks.md、spec deltas
6. `npx ecc-agentshield scan --prompt`（设计风险扫描）
7. 验证：`openspec validate [change-id] --strict --no-interactive`
8. **等待审批**

### 8.3 Stage 2: 实现变更
**IMPLEMENTATION**（dev context）
1. 按 tasks.md 顺序实现
2. `/tdd` 强制 RED-GREEN-REFACTOR
3. Plankton 自动检查，修复所有 Violations

**REVIEW**（review context）
1. `/code-review`（code-reviewer + security-reviewer agents）
2. 多 AI 交叉检查（Section 5）
3. 结合 AgentShield 安全报告

**TESTING**
1. `/verify` 验证
2. `npx ecc-agentshield scan`（B 级以上）
3. 更新 tasks.md 状态为 `[x]`

### 8.4 Stage 3: 归档完成
1. 确认所有 tasks.md 任务完成
2. 合并 delta spec 到 `specs/`
3. 同步 design.md 到 `specs/`
4. `npx ecc-agentshield scan --opus`（重要变更）
5. `/openspec:archive` 归档
6. 执行完整性检查（Section 1.7）
7. `/learn` 提取模式
8. 提交 git

### 8.5 目录结构 (统一标准)

```
openspec/
├── project.md
├── AGENTS.md
├── specs/
│   └── [capability]/
│       ├── spec.md
│       └── design.md
├── changes/
│   ├── [change-name]/
│   │   ├── proposal.md
│   │   ├── tasks.md
│   │   ├── design.md
│   │   └── specs/[capability]/spec.md
│   └── archive/
│       └── YYYY-MM-DD-[name]/

docs/plans/
tests/
```

### 8.6 文档格式 (OpenSpec 标准)

**proposal.md：**
```markdown
# Change: [变更简述]
## Why
[1-2 句说明]
## What Changes
- [变更列表，破坏性标记 **BREAKING**]
## Impact
- Affected specs: [影响的能力]
- Affected code: [影响的代码]
```

**spec.md Delta：**
```markdown
## ADDED Requirements
### Requirement: 新功能
系统 SHALL 提供...
#### Scenario: 成功场景
- **WHEN** 用户执行操作
- **THEN** 预期结果

## MODIFIED Requirements
## REMOVED Requirements
```

**tasks.md：**
```markdown
## 1. Implementation
- [ ] 1.1 创建数据库 schema
- [ ] 1.2 实现 API 端点
- [ ] 1.3 编写测试
```

---

## 9. MCP 工具使用规范

### 9.1 Codex MCP
```
工具名: codex
默认 sandbox="read-only"，不指定 model 参数
```

### 9.2 Gemini MCP
```
工具名: gemini-cli
将 Gemini 视为只读分析师，前端代码优先使用 Gemini
```

### 9.3 OpenCode MCP

```
工具名: opencode (opencode_ask / opencode_run / opencode_reply 等)
规范: 不指定 providerID 和 modelID 参数，使用 OpenCode 自身配置的默认模型
用途: 自主编码代理，支持 114+ provider，可构建、编辑和调试项目
调用示例: opencode_run(directory=项目路径, prompt=任务指令)
禁止: 调用时手动指定 providerID 或 modelID，必须使用默认模型
```
---

## 10. 态度与原则

1. **你是主体思考者** - 所有任务先自己分析、思考、形成方案
2. **独立判断能力** - 不盲从工具建议，保持批判性思维
3. **工具是辅助** - Codex/Gemini/ECC Agents 用于交叉验证，不是替代思考
4. **最终决策权在你** - 综合所有信息后，由你做出判断

### 与工具协作的正确姿态
- ✅ 先自己思考，再用工具验证
- ✅ 对工具的建议保持质疑态度
- ✅ 工具意见不一致时，由你做出最终判断
- ✅ 简单任务直接自己完成，不必调用工具
- ❌ 不经思考就把任务丢给工具
- ❌ 完全采纳工具回答而不加判断

**尽信书则不如无书。你与工具的关系是：你思考，它验证；你决策，它建议。**

---

## 11. 语言规范

- **文档**：所有文档使用**中文**
- **代码注释**：所有代码注释和文档字符串使用**中文**
- **代码标识符**：变量名、函数名、类名使用**英文**
- **配置文件**：键名英文，注释中文
- **日志消息**：中文
- **日常沟通**：中文

### 示例

```python
class UserService:
    """用户服务类

    提供用户相关的业务逻辑处理，包括：
    - 用户认证
    - 用户信息管理
    - 权限验证
    """

    def authenticate(self, username: str, password: str) -> bool:
        """验证用户凭据"""
        # 检查用户是否存在
        user = self._find_user(username)
        if not user:
            logger.warning(f"用户不存在: {username}")
            return False

        # 验证密码
        if not self._verify_password(password, user.password_hash):
            logger.warning(f"密码验证失败: {username}")
            return False

        logger.info(f"用户认证成功: {username}")
        return True
```

---

## 12. 项目结构规则

### 虚拟环境
- 运行项目前，先检查虚拟环境（venv/, .venv/, env/）
- 如果存在，必须先激活再执行命令

### 日志目录
- 所有日志文件输出到 `log/` 目录
- 日志命名格式：`{功能名}_{日期}.log`

### 测试目录
- 所有测试代码放在 `tests/` 目录
- 测试文件命名：`test_{模块名}.py`

### 大文件写入
- 写入大文件（超过 200 行）时，使用分段写入或 Bash `cat <<'EOF'`
- 禁止一次性 Write 超大内容

---

*This configuration follows OpenSpec spec-driven development methodology.*
*Plugin: Everything Claude Code (ECC) — AgentShield + Plankton + Continuous Learning*
*Workflow: /plan(Clarify Gate) → Proposal(AgentShield) → /tdd(Plankton) → /code-review → /verify(AgentShield) → Archive(/learn)*
