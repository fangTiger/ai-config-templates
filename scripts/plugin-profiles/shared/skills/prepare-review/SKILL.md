---
name: prepare-review
description: Use when a Review Agent needs review input for an implementation before deciding whether specialty review is required
---

# Prepare Review

## 核心原则

`prepare-review` 只整理审查输入，不给 `PASS`、`FIX_REQUIRED` 或 `DOWNGRADE` 终判。最终结论仍由 Review Agent 汇总后输出。

执行前先读取：

- `docs/guide/agent-team-operating-model.md`
- `docs/guide/codex-context-engineering.md`
- 当前 OpenSpec change 的 `proposal.md`、`design.md`、`tasks.md` 与相关 spec delta

## 适用场景

- Review Agent 启动前，需要把实现证据整理为可审查材料。
- Coding Agent 提交了修改文件、验证命令、未验证项或风险说明。
- 变更可能命中 Spring 架构、SQL、权限安全等专项边界，但尚未决定调用哪个专项 review。

不适用：

- 不替代专项 review skill。
- 不直接判断实现是否可以交付。
- 不补写缺失实现、测试或 OpenSpec 文档。

## 输入检查

至少收集：

| 输入 | 检查口径 |
| --- | --- |
| `git status --porcelain` | 是否存在未跟踪文件、他人并行修改或异常产物 |
| `git diff --name-only` | 是否超出 Handoff Task Package 的 Editable files |
| `TaskScopeFiles` | 本 task 批准修改并需要 review 的文件 |
| `PreExistingDirtyBaseline` | handoff 前已经 dirty 或 untracked 的文件，只作背景，不自动纳入本 task |
| `GeneratedOrNoisyArtifacts` | `target/`、IDE 文件、运行态缓存、生成产物等噪声，只分类说明或建议 ignore |
| OpenSpec/task | task 编号、验收标准、out-of-scope、验证命令是否对应 |
| 实现证据 | RED/GREEN 证据；文档类无法 RED 时说明替代证据 |
| 验证输出 | 命令、关键结果、失败或未执行原因 |
| 风险边界 | 安全矩阵、Spring 架构、SQL/数据访问、部署运行时、外部调用 |

## 输出模板

```markdown
## Review Input

- ChangeId:
- TaskId:
- Read documents:
- Changed files:
- TaskScopeFiles:
- PreExistingDirtyBaseline:
- GeneratedOrNoisyArtifacts:
- Scope check:
- OpenSpec/task alignment:
- Validation evidence:
- Missing evidence:
- Risk-boundary hits:
- Suggested specialty reviews:
- Stop conditions:
- Notes for Review Agent:
```

## 风险边界命中表

未命中写 `N/A`，不省略。

| 边界 | 是否命中 | 建议专项 review | 依据 |
| --- | --- | --- | --- |
| Spring 架构 |  | `spring-architecture-review` | Controller、Service、Adaptor、DTO/VO、异常、日志、模块边界、测试结构 |
| SQL/数据访问 |  | `sql-risk-review` | YMS JDBC/ORM、`LambdaQueryCondition`、`SQLParameter` 自拼 SQL、DAO service、DbAdaptor/Cypher、分页、排序、批量、事务、查询过滤 |
| 权限安全 |  | `permission-security-review` | 认证、授权、租户上下文、数据权限、密钥、公共 API、部署行为、外部 HTTP/网关调用 |

## Pressure Scenarios

文档类 skill 无法像代码一样先写自动化 RED 测试；本 skill 的 RED 替代证据是场景覆盖。Review 前逐项核对：

- 时间压力：用户催促“直接给 PASS”。仍只能输出 `Review Input`，不得给终判。
- 证据缺口：Coding Agent 未给 RED/GREEN 或验证输出。必须列入 `Missing evidence`，不得用“看起来合理”补足。
- 范围漂移：`git diff --name-only` 出现 allowlist 外文件。必须写入 `Stop conditions`，交给 Review Agent 或 Outer Codex 裁决。
- 风险误判：变更只改文档但涉及 agent 执行契约。仍需检查 OpenSpec/task 对齐与运行态 skill 扁平路径。
- 并行协作：工作树存在他人未提交文件。必须区分 `TaskScopeFiles`、`PreExistingDirtyBaseline` 与 `GeneratedOrNoisyArtifacts`，不要求回退他人文件，也不得把噪声纳入 editable scope。

## 常见错误

| 错误 | 正确做法 |
| --- | --- |
| 输出 `PASS` 或 `FIX_REQUIRED` | 改为列出证据、缺口和建议专项 review |
| 只看 diff，不看 OpenSpec task | 明确写出 task 对齐或偏离点 |
| 缺少验证仍继续审查 | 把缺口写入 `Missing evidence` 和 `Stop conditions` |
| 复制大段 guide | 只引用应读取的 guide 和关键检查口径 |

## 可运行验证

```bash
rg -n "prepare-review|Review Input|TaskScopeFiles|PreExistingDirtyBaseline|GeneratedOrNoisyArtifacts|PASS|FIX_REQUIRED|DOWNGRADE|Risk-boundary|Pressure Scenarios|OpenSpec|Missing evidence|Suggested specialty reviews" .codex/skills/prepare-review/SKILL.md
```
