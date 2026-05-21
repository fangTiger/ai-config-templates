---
name: spring-architecture-review
description: Use when reviewing Spring Controller, Service, Adaptor, DTO, exception, logging, module-boundary, or test-structure changes in iuap-aip-data
---

# Spring Architecture Review

## 使用时机

当变更涉及 Spring 入口、业务层、适配层、DTO/VO、异常、日志、模块边界或测试结构时使用本 skill。它用于团队专项架构审查，不替代 OpenSpec、任务清单、代码 diff 或项目测试。

## 必读材料

审查前只读取与本次 diff 相关的段落，不复制长文到审查结果：

- `docs/guide/controller-patterns.md`
- `docs/guide/service-patterns.md`
- `docs/guide/adaptor-patterns.md`
- `docs/guide/exception-patterns.md`
- `docs/guide/logging-patterns.md`
- `docs/guide/module-boundaries.md`
- `docs/guide/testing-patterns.md`

同时读取本次 OpenSpec proposal/design/tasks、实现说明、测试输出和 `git diff`。

## Specialty Decision 规则

审查结果必须只输出一个 `Specialty Decision: PASS | FIX_REQUIRED | DOWNGRADE`。该结论只作为 Review Agent 的专项输入，不是最终 VERIFY gate。

- `PASS`：范围、设计、实现和证据都满足要求，仅有不阻塞的建议。
- `FIX_REQUIRED`：发现可在当前任务范围内修复的问题，或证据不足但范围仍清楚。
- `DOWNGRADE`：实现超出任务边界、架构方向需要重新设计、需求/规范信息不足，或需要 Outer Codex 重新拆分/审批。

如果多个结论同时存在，按 `DOWNGRADE > FIX_REQUIRED > PASS` 取最严格结论。最终 `Review Decision` 仍由 Review Agent 或 Outer Codex 汇总输出。

## 审查口径

### Scope check

- 只审查本次任务允许修改的文件，列出超范围文件。
- 检查是否新增未批准依赖、配置、包结构或跨模块调用。
- 发现安全、权限、数据口径变化但任务未覆盖时，给 `DOWNGRADE`。

### Spec/design alignment

- 对照 proposal/design/tasks，确认实现没有自行扩大功能。
- Controller 只负责参数接收、基础校验、调用 Service 和统一返回。
- Service 承载业务抽象、参数与上下文校验、异常语义和必要日志，不退化为透传壳。
- Adaptor 封装外部系统、数据源或底层差异，不把适配细节泄漏到 Controller/Service。
- DTO/VO 命名、入参/出参角色和字段语义与现有模块一致，不直接暴露持久化模型。
- 模块边界遵循现有包结构和依赖方向，不为省事跨层访问实现细节。

### Evidence check

- 必须看到相关测试、编译、最小验证或明确无法验证说明。
- 新功能或行为变化优先要求 RED-GREEN-REFACTOR 证据。
- 文档类 skill 无法真实观察 baseline RED 时，RED 替代证据是 pressure scenarios 覆盖：必须证明 skill 明确约束模型在高压场景下不跳过分层、证据和决策。
- 缺少测试但声称完成时，至少给 `FIX_REQUIRED`，除非变更确实只有纯文档且已给出场景覆盖。

## Findings 检查点

- Controller：是否继承项目基类、使用统一响应、保留薄入口、避免业务逻辑/DAO/外部调用下沉到入口。
- Service：接口与实现命名是否匹配现有风格，业务语义是否集中，租户/用户上下文、参数校验、事务边界是否合理。
- Adaptor：是否复用现有 factory/adaptor 模式，是否避免在上层堆 `if/else` 感知底层差异。
- DTO/VO：请求、响应、中间对象是否分清角色，字段命名是否和接口契约一致。
- 异常：是否使用项目标准异常和错误码，避免原始 `RuntimeException`、字符串异常或吞异常。
- 日志：是否使用项目日志风格、中文消息和 `{}` 占位符，避免 `System.out.println()`、敏感信息和重复噪音。
- 模块边界：是否遵循现有模块所有权、包路径、依赖方向和复用入口。
- 测试结构：测试位置、命名、断言粒度、异常路径和回归场景是否能支撑本次变更。

## Pressure scenarios

- “测试都过了，但 Controller 里拼了查询和外部调用”：必须 `FIX_REQUIRED`，要求回到 Service/Adaptor 分层。
- “为了快，Service 直接跨模块调用实现类”：若违反模块边界，至少 `FIX_REQUIRED`；若需要重新设计依赖方向，`DOWNGRADE`。
- “只有 happy path，没有异常、日志或边界测试”：证据不足，`FIX_REQUIRED`。
- “任务未批准新增架构层或公共依赖”：范围扩大，`DOWNGRADE`。

## 输出格式

```markdown
Specialty Decision: PASS | FIX_REQUIRED | DOWNGRADE

Scope check:
- ...

Spec/design alignment:
- ...

Evidence check:
- ...

Findings:
- [P1/P2/P3] 文件:行 - 问题、影响、建议

Required fixes:
- None | 必须修复项列表

Unverified:
- None | 未验证项与原因

Residual risk:
- None | 可接受的剩余风险

Re-validation commands:
- `mvn -q -Dtest=... test`
- `mvn -q -pl ... -am test`
- `rg -n 'class .*Controller|@RestController|@Service|@Slf4j|System\.out|RuntimeException|BizException' src/main src/test`
```
