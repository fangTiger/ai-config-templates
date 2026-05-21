---
name: sql-risk-review
description: Use when reviewing YMS JDBC/ORM data access, LambdaQueryCondition, SQLParameter raw SQL, DAO services, DbAdaptor/Cypher query filters, pagination, batch, transaction, tenant/data-scope changes in iuap-aip-data
---

# SQL / Data Access Risk Review

## 使用时机

当变更涉及 YMS JDBC/ORM 数据访问、`LambdaQueryCondition`、`SQLParameter` 自拼 SQL、`AbstractKgBaseService`/DAO service、`DbAdaptor` 查询、Cypher 查询条件、分页、排序、批量处理、事务边界、租户/组织/数据权限过滤或查询性能时使用本 skill。

本项目当前审查口径不以 mapper XML、MyBatis annotation SQL 或 PageHelper 为默认前提。若 diff 中真的出现这些路径，应先确认是否为新增未批准技术路线或历史兼容代码，而不是要求实现者补 MyBatis 形态证据。

## 输入材料

审查前读取本次 OpenSpec proposal/design/tasks、实现说明、`git diff`、相关 Controller/Service/DAO/Adaptor 调用链和测试输出。涉及表结构、字段、索引或数据权限判断时，优先查现有 model、`OrmRepository` 用法、数据库参考文档、同模块既有 SQL 或 `docs/reference/database/*`，不凭表名猜测。

重点定位这些入口：

- `IYmsJdbcApi` / `YmsJdbcUtil` / `YMSDataSourceHandle` / `CustomDsConfiguration`
- `LambdaQueryCondition`、`Condition`、`SQLParameter`
- `queryByClause`、`queryForDTOList`、`queryForObject`、`queryDtoPage`、`update`、`insert`
- `AbstractKgBaseService`、`DebugBaseDaoService` 及各模块 `dao/service/impl`
- `DbAdaptorFactory`、`IDbQueryAdaptor`、`IDbStoreAdaptor`
- 图谱/Cypher 条件构造、算法网关查询请求

## Specialty Decision 规则

审查结果必须只输出一个 `Specialty Decision: PASS | FIX_REQUIRED | DOWNGRADE`。该结论只作为 Review Agent 的专项输入，不是最终 VERIFY gate。

- `PASS`：数据访问安全、数据隔离、分页/count、批量/事务、性能和证据都满足要求。
- `FIX_REQUIRED`：存在当前任务内可修复的 SQL、数据过滤、性能、事务或证据问题。
- `DOWNGRADE`：数据范围规则不清、事务/权限设计需要重新确认、实现引入未批准数据访问技术路线，或修改超出任务边界。

如果多个结论同时存在，按 `DOWNGRADE > FIX_REQUIRED > PASS` 取最严格结论。最终 `Review Decision` 仍由 Review Agent 或 Outer Codex 汇总输出。

## 审查口径

### Scope check

- 只审查本次任务允许修改的 DAO service、Service、Adaptor、model、数据访问工具和测试文件。
- 列出新增或改动的数据访问入口：YMS ORM 条件查询、自拼 SQL、分页查询、批量写入/更新/删除、Cypher/图查询、外部数据源 Adaptor。
- 发现权限、租户、事务、数据范围或底层数据访问技术路线变化但任务未覆盖时，给 `DOWNGRADE`。

### Spec/design alignment

- 对照 proposal/design/tasks，确认查询目标、返回字段、排序、分页、更新范围和数据源路由没有自行扩大。
- 数据权限过滤必须与业务语义一致，不能只依赖前端传参或调用方口头保证。
- 读写事务边界应在 Service 或既有事务层表达，不把事务语义藏在 DAO helper 或 SQL 片段里。
- 图谱/Cypher 查询必须保留租户、catalog、节点/边范围语义，不把任意用户输入拼成结构性查询。

### Evidence check

- 必须看到相关单测、集成测试、最小 SQL/条件构造验证、执行计划说明或明确无法验证说明。
- 新查询或变更查询优先要求覆盖有数据、无数据、跨租户/跨组织、空集合、分页边界、批量边界和异常路径。
- 文档类 skill 无法真实观察 baseline RED 时，RED 替代证据是 pressure scenarios 覆盖：必须证明 skill 明确约束模型不再按 MyBatis/mapper 假设审查，并能抓住 YMS JDBC 参数绑定、租户过滤、分页/count 和性能证据缺口。
- 缺少执行计划、索引依据或数据量上限时，性能敏感查询至少给 `FIX_REQUIRED`。

## Findings 检查点

- 参数绑定：自拼 SQL 默认使用 `?` + `SQLParameter`；外部输入不得直接 append 到 SQL。动态表名、列名、排序字段、Cypher label/type 等结构标识必须来自白名单或枚举映射。
- `LambdaQueryCondition`：空集合 `in`、空租户、空关键条件必须有保护；`dr`、`ytenant_id`、组织/用户过滤应与业务语义一致。
- 租户/组织/数据权限：列表、count、导出、详情、批量更新和删除都要包含一致过滤；禁止只在列表查询加过滤。
- 分页/count：`queryDtoPage`、`PageRequest` 或自定义 count 条件必须与主查询一致；排序字段白名单且排序稳定。
- YMS ORM 元数据：`OrmRepository` 推导的表名、主键、字段名不得受未校验用户输入控制；`metaUri` 变化要说明来源和边界。
- 索引友好：避免在索引列上包函数、前置通配 `LIKE`、无选择性宽 `OR`、隐式类型转换、无界 `ORDER BY`。
- 全表扫描：没有明确业务上限、索引或过滤条件的查询必须标风险；宽字段查询或 `select *` 应替换为必要字段。
- N+1：Service 循环内按行查询、逐条外部数据源查询或逐条 count 需要改为批量查询、缓存，或解释数据量上限。
- 批量更新/删除：空集合保护、批量大小、影响行数校验、幂等性和失败回滚策略必须清楚。
- 事务边界：批量写入、先查后改、状态流转和多表写入需明确事务；避免长事务包外部 IO、算法网关调用或大批量查询。
- 图谱/Cypher/Adaptor：用户输入只能作为值条件，不应直接成为 Cypher/SQL 结构；跨数据源查询需要说明租户、catalog、数据源隔离和超时/分页策略。

## Pressure scenarios

- “这里用了 `SQLParameter`，但排序字段来自请求参数直接 append”：必须 `FIX_REQUIRED`，要求白名单或固定映射。
- “`tenantIds` 为空时跳过 `in` 条件，结果变成全租户查询”：数据隔离风险，`FIX_REQUIRED`；若需求语义不清，`DOWNGRADE`。
- “列表查询有租户过滤，count/export/detail 没有”：数据隔离不一致，`FIX_REQUIRED`。
- “for 循环里每条调用 `getYmsJdbc().queryForDTOList` 或 `queryByClause`”：默认判为 N+1，除非有明确小数据上限和证据。
- “新增批量更新但没有空集合保护、批量大小或影响行数校验”：`FIX_REQUIRED`。
- “Cypher 条件或 label/type 由用户输入直接拼接”：结构注入风险，至少 `FIX_REQUIRED`；若数据范围语义未定义，`DOWNGRADE`。
- “评审要求补 mapper XML 或 `@Select` 证据”：这是错栈审查，应改查 YMS JDBC/ORM、自拼 SQL、Adaptor 或图查询证据。
- “数据权限规则没有写进 spec/design，只在实现里猜”：`DOWNGRADE`。

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
- `rg -n 'IYmsJdbcApi|YmsJdbcUtil|LambdaQueryCondition|SQLParameter|queryDtoPage|queryForDTOList|queryForObject|queryByClause|getYmsJdbc\\(\\)|DbAdaptor|Cypher|@Transactional|select \\*|order by|limit| in \\(' src/main src/test`
```
