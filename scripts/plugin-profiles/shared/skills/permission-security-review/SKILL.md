---
name: permission-security-review
description: Use when reviewing changes that touch authentication, authorization, tenant context, data permissions, secrets, public APIs, runtime behavior, or external HTTP calls
---

# Permission Security Review

## 核心原则

`permission-security-review` 是权限与安全专项审查。它必须输出唯一 `Specialty Decision: PASS | FIX_REQUIRED | DOWNGRADE`，并用 safety matrix 说明认证、授权、密钥、租户上下文、数据权限、公共 API、部署/运行时、外部 HTTP/网关调用的检查结果。该结论只是 Review Agent 的输入，不是进入最终 VERIFY 的 gate。

执行前先读取：

- `docs/guide/agent-team-operating-model.md`
- `docs/guide/codex-context-engineering.md`
- 当前 OpenSpec change、Handoff Task Package、实现 diff 和验证证据

## 适用场景

- 登录态、token、session、鉴权拦截器、权限注解、菜单/接口权限发生变化。
- 租户、组织、用户上下文或 `UserUtils` 传递链路发生变化。
- 查询范围、数据权限过滤、跨租户访问、公共 API 契约发生变化。
- 密钥、连接串、环境变量、日志脱敏、部署 profile、启动行为发生变化。
- 新增或修改外部 HTTP、YMS、算法网关、第三方网关调用。

不适用：

- 不修复代码；只给审查结论、证据和必须修复项。
- 不在缺少关键证据时给 `PASS`。
- 不放宽 OpenSpec、任务包或文件 allowlist。

## Specialty Decision 规则

| Specialty Decision | 条件 |
| --- | --- |
| `PASS` | 范围合规，安全矩阵已覆盖，命中边界均有验证证据，未发现必须修复风险 |
| `FIX_REQUIRED` | 发现可局部修复的问题，或关键验证缺失但仍可在当前任务范围内补齐 |
| `DOWNGRADE` | 范围越界、设计/规范冲突、疑似越权/泄密风险无法局部确认，或需要 Outer Codex/人类重新裁决 |

## Safety Matrix

未命中写 `N/A`，命中但未验证写清原因。任何命中项缺少证据时，不能给 `PASS`。

| 边界 | 是否命中 | 必查内容 | 证据 |
| --- | --- | --- | --- |
| 认证 |  | 登录态、token、session、鉴权拦截器、匿名访问默认值 | 代码位置、测试或人工验证 |
| 授权 |  | 角色、菜单、接口权限、权限注解、越权访问路径 | 权限配置、调用链、负向用例 |
| 密钥与敏感配置 |  | 密钥、连接串、环境变量、日志脱敏、配置默认值 | diff、配置来源、日志样例 |
| 租户上下文 |  | tenant、org、user、`UserUtils` 是否正确传递与隔离 | 上下文来源、跨层传递、异常路径 |
| 数据权限 |  | 查询范围、过滤条件、组织隔离、跨租户/跨组织访问 | SQL/DAO/service 证据、负向用例 |
| 公共 API |  | endpoint、参数、响应、错误码、兼容性、鉴权语义 | API diff、契约测试或调用样例 |
| 部署/运行时 |  | profile、启动参数、hook、定时任务、自动化行为、降级策略 | 配置 diff、启动/运行验证 |
| 外部 HTTP/网关调用 |  | URL、鉴权、超时、重试、错误处理、日志、敏感字段 | 调用封装、异常路径、验证输出 |

## 输出模板

```markdown
## Permission Security Review

- Specialty Decision: PASS | FIX_REQUIRED | DOWNGRADE
- Scope check:
- OpenSpec/task alignment:
- Evidence check:
- Safety matrix:
- Required fixes:
- Re-validation commands:
- Unverified:
- Residual risk:
```

`Specialty Decision` 只能出现一个，且不得写成最终 `Review Decision`。`Required fixes` 为空时写 `None`；`Unverified` 为空时写 `None`。

## Pressure Scenarios

文档类 skill 无法先跑自动化 RED；本 skill 的 RED 替代证据是场景覆盖。审查时逐项压测自己的结论：

- 权威压力：实现者声称“只是小改”。只要命中认证、授权、租户、数据权限或外部调用，就必须填 safety matrix。
- 时间压力：用户要求快速通过。缺少负向用例、调用链证据或配置验证时，不能给 `PASS`。
- 表面安全：只改 public API 参数名。仍需检查鉴权语义、兼容性、错误码和调用方影响。
- 间接越权：Service/DAO 改查询过滤但 Controller 未变。仍需检查租户上下文和数据权限。
- 敏感信息：日志、异常、配置示例包含 token、secret、连接串或用户隐私。至少 `FIX_REQUIRED`。
- 外部依赖：新增网关/HTTP 调用但缺少超时、错误处理或脱敏日志。至少 `FIX_REQUIRED`；若影响范围不明则 `DOWNGRADE`。
- 范围越界：diff 超出任务包或安全设计与 OpenSpec 冲突。输出 `DOWNGRADE`，交回 Outer Codex。

## 常见错误

| 错误 | 正确做法 |
| --- | --- |
| 只看认证和授权 | 同时覆盖租户、数据权限、公共 API、运行时和外部调用 |
| 未命中项留空 | 写 `N/A` 并说明依据 |
| 证据缺失仍给 `PASS` | 给 `FIX_REQUIRED` 或 `DOWNGRADE` |
| 把 review 写成实现建议大纲 | 聚焦必须修复项、复验命令和残余风险 |
| 复制大段项目文档 | 引用 guide，正文保留可执行检查口径 |

## 可运行验证

```bash
rg -n "permission-security-review|Specialty Decision: PASS \\| FIX_REQUIRED \\| DOWNGRADE|Safety Matrix|认证|授权|密钥|租户|数据权限|公共 API|部署/运行时|外部 HTTP|Pressure Scenarios" .codex/skills/permission-security-review/SKILL.md
```
