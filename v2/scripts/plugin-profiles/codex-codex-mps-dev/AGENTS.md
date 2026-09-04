# AGENTS.md

> `codex-codex-mps-dev` profile 的项目根指令模板。
> 由 `v2/scripts/switch-plugin.sh codex-codex-mps-dev` 落盘，Codex 按官方 `AGENTS.md` 发现规则加载。
> 本文件是入口契约。可复用步骤放在 `.codex/skills/`（25 个 mattpocock skill 的文件副本，pin 1.2.3）。

---

## 0. 项目宪章

**以下铁律不可违背，任何流程、skill 正文或工具建议均不得覆盖。**

1. **规范先行** — 非平凡变更必须先有 OpenSpec 提案（proposal + spec delta + tasks），审批后方可实现。
2. **测试先行** — 所有实现遵循 TDD（RED-GREEN-REFACTOR），无测试的代码禁止合并。
3. **安全优先** — 涉及认证、授权、数据访问、密钥管理的变更必须显式标注安全项。
4. **证据先于断言** — 任何"已完成"声明必须附带可验证的测试输出或运行结果。
5. **specs/ 是唯一真相** — `openspec/specs/` 反映系统当前能力，归档时必须同步 delta。

默认用中文与用户沟通；代码标识符、配置键、命令、外部 API 名称保持英文。

---

## 1. 产出落点：以 `docs/agents/issue-tracker.md` 为准

`.codex/skills/` 下是 mattpocock skill 的**英文原样副本**。它们的正文默认把规范发布到
GitHub/Linear issue tracker，或写入 `.scratch/`。**本项目两者都不用。**

**落点的权威定义在项目根 `docs/agents/issue-tracker.md`**，该文件随本 profile 一同安装。
skill 正文在需要读写 tracker 时会显式去读它——这是 skill 自己设计的扩展点。

遇到 skill 正文与该文件冲突时（例如 `to-tickets` 写死
"one file per ticket, never a single combined file"），**以 `docs/agents/issue-tracker.md` 为准**，
该文件已逐项说明为什么 OpenSpec 下的载体满足同样的约束目的。

速查摘要：

| skill | 产出落点 |
|---|---|
| `grill-with-docs` | `docs/plans/YYYY-MM-DD-{topic}-design.md` |
| `to-spec` | `openspec/changes/<id>/proposal.md` + `specs/<capability>/spec.md` delta |
| `to-tickets` | `openspec/changes/<id>/tasks.md` 的编号条目（不建 `issues/`、不建 `.scratch/`） |
| `implement` | 按 `tasks.md` 顺序实现 |
| `wayfinder` | `openspec/changes/<id>/design.md` |
| `triage` | `tasks.md` 的行内 checkbox，不使用外部标签 |
| `domain-modeling` | 项目根 `CONTEXT.md` |
| `tdd` / `code-review` / `diagnosing-bugs` / `codebase-design` | 直接使用，无落点约束 |

**禁止调用** `gh issue create`、`glab issue create` 及任何 Linear/Jira API。

> `setup-matt-pocock-skills` 默认不要运行——本 profile 已预置它的产物。
> 必须运行时 Section A 选 `Other`，不要选「本地文件」（其路径写死 `.scratch/`）。

---

## 2. 工作流

```
grill-with-docs(澄清) → to-spec(规范) → [wayfinder(大任务)] → to-tickets(拆解)
  → implement(tdd + code-review) → 证据验证 → /openspec:archive
```

### 2.1 任务分级

| 级别 | 判断标准 | 流程 |
|---|---|---|
| 小 | Bug 修复、配置调整、< 3 文件 | `diagnosing-bugs` → `tdd` → 证据验证 |
| 中 | 单模块新功能、3-9 文件 | 全链路，跳过 `wayfinder` |
| 大 | 跨模块/架构变更、>=10 文件 | 全链路 |

涉及公共 API/数据模型、权限/安全、数据迁移、跨模块耦合时，至少按中任务处理。

### 2.2 Clarify Gate

进入 `to-spec` 之前必须用 `grill-with-docs` 澄清，产出可测试的验收标准
（GIVEN-WHEN-THEN）、边界条件、依赖关系和风险。验收标准不明确时禁止进入 `to-spec`。

### 2.3 审批 Gate

`to-spec` 产出后**停下等待用户审批**。发布不等于批准。未获批准不得进入 `implement`。

---

## 3. 能力缺口内联补齐

mattpocock-skills 没有对应 skill 的两项能力，以内联规则强制执行。

### 3.1 完成前的证据验证

声称"完成/修复/通过"之前，以及提交之前，必须：

1. **实际运行**验证命令，不接受"应该能过"的推理
2. **粘贴真实输出**，包括测试数量与通过/失败计数
3. 测试失败时**如实说明**并附输出，禁止淡化
4. 跳过了什么、为什么，必须明说

对应宪章第 4 条。

### 3.2 分支集成

测试全绿后不要自行决定如何集成。确认工作树干净、测试通过有输出、`tasks.md` 全部 `[x]`，
然后向用户呈现选项（本地合并 / 创建 PR / 保留分支 / 丢弃）并等待选择。
**未经用户确认禁止 push 或合并。**

---

## 4. 运行状态

`.codex/session-state.md` 承载当前 worktree 的活跃任务状态，不承载规则定义。
进入多步骤工作流时创建，每个 task 完成或阶段切换时更新，结束时清理。
上下文压缩后先读该文件恢复状态。

`.codex/session-state.template.md` 用于初始化或重置，不记录活跃任务。

---

## 5. Graphify

存在 `graphify-out/graph.json` 时，非平凡搜索或改代码前先用 `graphify` 检查结构和影响范围：

- 结构检索：`graphify query "<module/file> architecture dependencies"`
- 影响检查：`graphify query "<module/file> impact callers tests dependencies"`

不可用时降级为阅读 `graphify-out/GRAPH_REPORT.md` 或继续原流程，禁止因 graphify 失败阻断任务。

---

## 6. 切换回 Claude 侧

本 profile 下项目根没有 `CLAUDE.md`，Claude 会话不加载项目配置。要切回：

```bash
<模板仓库>/v2/scripts/switch-plugin.sh mps          # Claude 侧同款落点配置
<模板仓库>/v2/scripts/switch-plugin.sh superpowers  # 默认模式
```

---

*Mode: codex-codex-mps-dev — mattpocock skills (文件副本, pin 1.2.3) + OpenSpec 真相源*
*落点权威定义: docs/agents/issue-tracker.md*

---

## Git Commit 规范（强制）

在生成 commit message 时，必须在末尾添加以下 trailer，不得省略。
如果已存在相同 trailer，不得重复追加。

```text
Co-Authored-By: Claude Code <claude-code@anthropic.com>
```
