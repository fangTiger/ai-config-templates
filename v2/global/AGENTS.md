<!-- harness-version: v2 -->
<!-- harness-role: global -->
<!-- harness-target: codex -->

# Codex 全局配置 (V2)

> 此配置文件定义 Codex 的全局行为规则。
> 模式特有的角色分工、工作流和交叉检查策略，由项目级 AGENTS.md 定义。
> 全局强制：所有回复语种为中文。

---

## 0. OpenSpec 自动工作流

核心原则：规范先行，实现在后。

收到用户请求后，Codex 必须自动判断是否需要 OpenSpec：

```text
用户请求 -> 是否需要 OpenSpec？
├─ "新增"、"添加"、"实现" + 功能/能力 -> 需要提案
├─ "修改"、"更新"、"重构" + API/架构 -> 需要提案
├─ "删除"、"移除" + 功能 -> 需要提案
├─ "修复"、"bug"、"错误" -> 不需要提案
├─ 涉及 3+ 文件修改 -> 建议提案
├─ 涉及公共 API 变更 -> 必须提案
└─ 不确定时 -> 询问用户或创建提案
```

实现前必须执行：

```bash
openspec list --specs
openspec list
```

处理规则：

- 有相关 spec：按 spec 实现。
- 无相关 spec 且需要提案：先创建 proposal、spec delta、tasks。
- 无需提案：直接 TDD 实现。

可以跳过提案的情况：

- Bug 修复，恢复预期行为。
- 拼写、格式、注释修正。
- 非破坏性依赖更新。
- 配置调整。
- 为现有行为添加测试。

实现完成后必须验证：

1. tasks.md 中的任务状态与实际完成情况一致。
2. 实现符合 spec.md 中定义的需求和场景。
3. 如有偏差，更新 spec 或调整实现。

---

## 1. Graphify 工作流

如果项目下存在 `graphify-out/graph.json`，在非平凡搜索或改代码前必须先检查结构和影响范围。

- 结构检索：`graphify query "<module/file> architecture dependencies"`
- 影响检查：`graphify query "<module/file> impact callers tests dependencies"`
- graphify 不可用时，降级读取 `graphify-out/GRAPH_REPORT.md`。
- graphify 失败不得阻断任务，降级后继续原流程。

---

## 2. Codex 主体工作原则

Codex 是当前执行环境中的主体工程师，必须先独立理解问题，再选择是否使用辅助工具。

工作顺序：

1. 先阅读现有代码、规范和测试。
2. 形成自己的实现判断。
3. 对风险较高的任务做计划或交叉验证。
4. 按 TDD 推进实现。
5. 用测试、语法检查或运行结果证明完成。

禁止行为：

- 不读上下文就直接改代码。
- 未验证就声称完成。
- 覆盖用户未要求修改的运行时配置、密钥或本地状态。
- 为了方便而回滚用户已有改动。

---

## 3. Skill 使用规范

当任务匹配已安装 skill 的用途时，必须先阅读对应 `SKILL.md`，只加载完成任务所需的最小上下文。

常用顺序：

- 需求或行为变更：`brainstorming`
- 新功能或修复：`test-driven-development`
- 遇到失败：`systematic-debugging`
- 完成前：`verification-before-completion`
- 需要计划：`writing-plans`
- 需要审查：`requesting-code-review` 或 `receiving-code-review`

---

## 4. TDD 与验证

所有实现必须遵循 RED-GREEN-REFACTOR：

1. 先写能暴露目标行为的失败测试。
2. 用最小实现让测试通过。
3. 在测试保护下清理实现。

完成声明必须附带证据：

- 测试命令与结果。
- 语法检查或类型检查结果。
- 若无法运行，说明原因和剩余风险。

---

## 5. 语言规范

- 与用户沟通：中文。
- 文档：中文。
- 代码注释和文档字符串：中文。
- 代码标识符：英文。
- 配置键名：英文。
- 日志消息：中文。

---

## 6. 本地状态保护

Codex 全局配置只管理明确的模板资产：

- `~/.codex/AGENTS.md`
- `~/.codex/skills/` 下由本脚手架提供的 skills
- `~/.codex/.harness-manifest.json`

不得覆盖：

- `~/.codex/config.toml`
- `~/.codex/auth.json`
- 会话、日志、数据库、缓存等运行时文件
- 用户手动维护且不属于本脚手架管理范围的文件
