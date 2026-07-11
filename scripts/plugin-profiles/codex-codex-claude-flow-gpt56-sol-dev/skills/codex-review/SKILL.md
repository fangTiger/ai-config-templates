---
name: codex-review
description: Reviews Implementation Codex implementation results in codex-codex-claude-flow-gpt56-sol-dev mode. Use when Review Codex needs to validate design alignment, file scope, test evidence, and decide whether to accept, request fixes, or downgrade.
---

# Codex Review — Review Codex 审查技能

## 概述

在 `codex-codex-claude-flow-gpt56-sol-dev` 模式下，本技能用于 Review Codex 对 Implementation Codex 的结果进行治理性审查。
重点不是“帮忙写一点代码”，而是判断：
- 实现是否符合 design / spec / tasks
- 是否超出文件白名单
- 是否有足够测试证据
- 是否可以推进到 VERIFY / ARCHIVE
- 多 Implementation Codex 输出是否逐 slice 合规，且合并后契约、基线和验证证据是否一致

这是 **Review Codex** 的审查技能。三角色入口、六阶段流水线和 gate 口径均以项目根 `AGENTS.md` 为准。

专项 review skills 只能输出 `Specialty Decision` 或 `Specialty Review Result`。最终允许进入 VERIFY 的 `Review Decision` 只能由本技能对应的 Review Codex，或小任务/降级接管时的 Architecture Codex 汇总输出。

## 触发条件

- Implementation Codex 声称某个 task 已完成
- 所有 tasks 已完成，需要进入自审 / 总审
- 关键词：review、复审、审查、验收、检查实现、范围检查、自审结果

## 审查清单

### 1. 范围合规
必须检查：
1. `git status --porcelain`
2. `git diff --name-only [baseline]`
3. 修改文件是否全部在 Editable files / `TaskScopeFiles` 中
4. 是否出现未声明的新增文件
5. 是否修改 Forbidden files
6. 是否区分 `TaskScopeFiles`、`PreExistingDirtyBaseline` 和 `GeneratedOrNoisyArtifacts`
7. 多 Implementation Codex 场景下，每个 slice 是否具备唯一 `AgentId` / `SliceId`，且 editable files 彼此不重叠

### 2. 设计一致性
检查实现是否与以下内容一致：
- proposal.md
- design.md
- tasks.md
- spec delta

重点关注：
- 是否擅自扩展需求
- 是否破坏既有接口契约
- 是否绕开约定实现方式

### 3. TDD / 验证证据
Implementation Codex 应提供：
- RED 证据
- GREEN 证据
- 关键测试命令
- 编译 / 构建 / 运行结果

如无证据，不得直接视为通过。

多 Implementation Codex 场景还必须提供：
- 每个 slice 的 Implementation Evidence
- IntegrationOwner 汇总的 Integration Evidence
- patch/worktree 基线一致性说明
- 合并后验证命令与关键输出，或无法运行的原因

### 4. 安全边界检查矩阵
Review Codex 必须输出安全边界检查矩阵。未命中也要写 `N/A`。

| 边界 | 是否命中 | 检查内容 |
| --- | --- | --- |
| 认证 |  | 登录态、token、会话校验是否变化 |
| 授权 |  | 角色、菜单、接口权限是否变化 |
| 密钥与敏感配置 |  | 密钥、连接串、环境变量是否新增或泄露 |
| 租户 / 用户上下文 |  | 租户、用户、组织或等价上下文是否正确传递 |
| 数据权限 |  | 查询范围、过滤条件、越权访问风险 |
| 公共 API 契约 |  | endpoint、参数、响应、错误码兼容性 |
| 部署或运行时行为 |  | 启动、配置、hook、profile、自动化行为变化 |
| 外部服务 / HTTP 调用 |  | 网关、第三方服务、超时、错误处理、日志 |

命中任一项时，必须列出已读规范/代码、影响面、验证命令和未验证原因。

专项审查建议：
- Review 启动前可先使用 `prepare-review` 整理 `TaskScopeFiles`、`PreExistingDirtyBaseline`、`GeneratedOrNoisyArtifacts`、证据缺口和风险边界。
- 命中技术栈专项边界时，调用目标项目可用的对应 review skill，或记录未调用原因。
- 命中数据访问边界时，调用目标项目可用的数据访问 / 查询风险 review skill，或记录未调用原因。
- 命中权限或安全边界时，调用目标项目可用的安全 review skill，或记录未调用原因。
- 任一专项 `Specialty Decision` 都不能单独替代最终 `Review Decision`。

### 5. 代码质量
检查：
- 注释与命名是否符合项目规范
- 是否引入不必要依赖
- 是否重复造轮子
- 是否存在明显风险点 / TODO 遗留

### 6. 多 Implementation Codex 两阶段审查

当任务由多个 Implementation Codex 或多个 slice 完成时，Review Codex 必须执行两阶段审查：

1. **Slice Review**：逐 slice 检查 scope、spec/design alignment、验证证据、安全矩阵、范围扩展审批和 Forbidden files。
2. **Integration Review**：检查合并 diff、patch/worktree 基线、文件冲突、公共契约一致性、重复实现、测试覆盖、回归风险和最终验证要求。

任一 slice 出现以下情况，整体不得 `PASS`：
- 超出 allowlist。
- 修改 Forbidden files。
- 缺少验证证据。
- 安全矩阵缺失。
- patch/worktree 基线不一致且无法干净合并。
- slice 间对同一契约、公共类型、配置或测试作出不一致实现。

### 7. 审查结论
审查结论只能是以下三种之一：
1. **PASS** — 可进入下一阶段
2. **FIX_REQUIRED** — 退回 Implementation Codex 修复
3. **DOWNGRADE** — 中止 Implementation Codex，由 Architecture Codex 接管或人工确认

只有 `PASS` 允许进入最终 VERIFY。证据缺失、范围漂移、安全矩阵缺失或 profile/runtime 同步无法证明时，必须返回 `FIX_REQUIRED` 或 `DOWNGRADE`。

## 退回修复的典型触发条件

- 修改超出 allowlist
- 测试不通过
- 无法给出验证证据
- 与 design/spec 明显不一致
- 同类问题反复出现
- 安全边界检查矩阵缺失
- profile/runtime 内容级同步证据缺失
- 多 Implementation Codex 的 Integration Evidence 缺失或无法证明可干净合并
- slice 间公共契约、数据模型、配置或测试行为不一致

## 降级触发条件

- 单 task 修复 > 3 次
- 自审连续 2 次失败
- 范围漂移无法收敛
- 任务理解明显失控

## 输出格式建议

### PASS
- 审查结论：PASS
- 通过原因
- 已验证命令
- 风险余项（如有）
- 安全边界检查矩阵

### FIX_REQUIRED
- 审查结论：FIX_REQUIRED
- 问题列表
- 需要修复的文件 / 任务编号
- 重新验证要求
- 阻止进入 VERIFY 的 gate

### DOWNGRADE
- 审查结论：DOWNGRADE
- 降级原因
- 建议接管方式
- 当前保留成果

## Review Decision 模板

```markdown
## Review Decision

- Decision: PASS | FIX_REQUIRED | DOWNGRADE
- Scope check:
- Spec/design alignment:
- Evidence check:
- Safety matrix:
- Specialty review inputs:
- Slice review:
- Integration review:
- Required fixes:
- Re-validation commands:
```
