# 项目指令 (AGENTS.md)

> 此文件为读取 `AGENTS.md` 的 agent（Codex CLI 等）提供项目级指令。
> 全局强制：所有回复语种为中文。

---

## 0. 项目宪章 (Constitution)

以下铁律不可违背：

1. **规范先行** — 非平凡变更必须先有 OpenSpec 提案（proposal + spec delta + tasks），审批后方可实现。
2. **测试先行** — 所有实现必须遵循 TDD（RED-GREEN-REFACTOR），无测试的代码禁止合并。
3. **安全优先** — 涉及认证、授权、数据访问、密钥管理的变更，必须经过安全审查。
4. **证据先于断言** — 任何"已完成"的声明必须附带可验证的测试输出或运行结果，禁止仅凭推理声称通过。
5. **specs/ 是唯一真相** — `openspec/specs/` 目录反映系统当前能力的完整规范，归档时必须同步 delta 到 specs/。

---


### 1.1 核心原则


### 1.3 降级策略（强制）

```
  ↓ 否
GRAPH_REPORT.md 存在？→ 阅读报告获取结构概览
  ↓ 否
继续原流程，不阻断
```

### 1.4 MCP 工具清单

| 工具 | 用途 | 参数 |
|------|------|------|

---

## 2. OpenSpec 自动工作流 (强制)

核心原则：规范先行，实现在后。

### 2.1 自动检测逻辑

```
用户请求 → 是否需要 OpenSpec？
├─ "新增"、"添加"、"实现" + 功能/能力 → 需要提案
├─ "修改"、"更新"、"重构" + API/架构 → 需要提案
├─ "删除"、"移除" + 功能 → 需要提案
├─ "修复"、"bug"、"错误" → 不需要提案
├─ 涉及 3+ 文件修改 → 建议提案
├─ 涉及公共 API 变更 → 必须提案
└─ 不确定时 → 询问用户
```

### 2.2 实现前检查 (必须执行)

1. 检查现有规范：`openspec list --specs`
2. 检查进行中变更：`openspec list`
3. 有相关 spec → 按 spec 实现；无 spec 且需要 → 先创建提案

### 2.3 提案触发器

必须创建提案：新增功能、修改 API/数据模型/行为（破坏性变更）、架构变更、性能/安全行为变更。
可以跳过：Bug 修复、拼写/格式修正、非破坏性依赖更新、配置调整、为现有行为添加测试。

### 2.4 三阶段工作流

```
Stage 1: 创建提案 → Stage 2: 实现变更 → Stage 3: 归档完成
```

详细流程参见 `openspec/AGENTS.md`。

### 2.5 归档后完整性检查 (强制)

1. specs/ 完整性：每个已实现能力有最新 spec.md
2. design.md 完整性：重要能力有 design.md
3. delta 已合并到 specs/
4. tasks.md 所有任务标记 `[x]`
5. changes/ 中无已完成但未归档的变更

---

## 3. 任务分级

| 级别 | 判断标准 | 流程 |
|------|---------|------|
| 小 | Bug 修复、< 3 文件、需求明确 | 直接 TDD 实现 |
| 中 | 单模块新功能、3-9 文件 | 需求分析 → OpenSpec 提案 → 实现 |
| 大 | 跨模块/架构变更、>=10 文件 | 需求分析 → OpenSpec 提案 → 细化计划 → 实现 |

执行中若范围膨胀（新增 >2 文件或出现跨模块依赖），立即重分级。

---

## 4. 语言规范

- **文档**（docs/ 下 .md 文件）：中文
- **代码注释和文档字符串**：中文
- **代码标识符**（变量名、函数名、类名）：英文
- **配置文件**：键名英文，注释中文
- **日志消息**：中文
- **与用户沟通**：中文

---

## 5. 项目结构规则

- 运行项目前检查虚拟环境（venv/, .venv/, env/），存在则先激活
- 日志输出到 `log/` 目录，命名 `{功能名}_{日期}.log`
- 测试代码放 `tests/` 目录，命名 `test_{模块名}.py`

### 目录结构

```
openspec/
├── project.md
├── AGENTS.md
├── specs/                  # 当前真相
│   └── [capability]/
│       ├── spec.md
│       └── design.md
├── changes/
│   ├── [change-name]/      # 进行中的变更
│   │   ├── proposal.md
│   │   ├── tasks.md
│   │   ├── design.md
│   │   └── specs/
│   └── archive/            # 变更历史

docs/plans/                 # 设计文档和实现计划
tests/                      # 测试目录
```

---

## 6. 文档格式 (OpenSpec 标准)

**proposal.md：**
```markdown
# Change: [变更简述]
## Why
[1-2 句说明问题/机会]
## What Changes
- [变更列表]
## Impact
- Affected specs: [影响的能力]
- Affected code: [影响的代码]
```

**spec.md Delta：** 使用 `## ADDED|MODIFIED|REMOVED Requirements`，每个 Requirement 至少一个 `#### Scenario:`。

**tasks.md：** 使用 `- [ ]` 清单格式，实现完成后标记 `- [x]`。


Rules:

---

## Git Commit 规范（强制）

在生成 commit message 时，必须在末尾添加以下 trailer，不得省略：

如果已存在相同 trailer，不得重复追加。

```text
Co-Authored-By: Codex <codex@openai.com>
```
