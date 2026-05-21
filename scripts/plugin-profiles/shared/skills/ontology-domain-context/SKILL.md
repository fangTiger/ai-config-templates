---
name: ontology-domain-context
description: Use when working on ontology, graph query, TTL import, Agent query, OML conversion, metadata APIs, or data permission behavior in iuap-aip-data
---

# Ontology Domain Context

## 先读哪些

- 通用：`AGENTS.md`、`CODE_WIKI.md`、`docs/guide/task-doc-mapping.md`
- 模块概览：`docs/domain/ontology-overview.md`
- API 模式：`docs/guide/api-patterns.md`、`docs/guide/resp.md`
- 相关规范：`openspec/specs/ontology-*`、`openspec/specs/ttl-import`、`openspec/specs/agent-graph-query`、`openspec/specs/data-permission-query`

## 领域边界

- `ontology/controller`：REST API 入口。
- `ontology/service/api/impl`：本体 API、TTL、Agent 查询、图查询核心服务。
- `ontology/dao`：图谱任务、归档同步等持久化模型与服务。
- `ontology/pojo/api`：外部 API DTO / 返回对象。
- `common/resp`：统一响应与错误码。

## 常见高风险点

- Agent 查询返回 OML / 原始三元组格式时，不要破坏既有字段契约。
- TTL/Jena 改动需要覆盖解析边界和文件导入边界。
- 权限、租户、数据访问行为必须检查 `UserUtils`、tenantId、权限过滤默认语义。
- `getTableMeta` / `getSampleData` 涉及任务模式时，要检查分页、任务状态、错误码和重试语义。

## 验证建议

- 优先定位相关 `src/test/java/com/yonyou/iuap/aip/data/ontology/**` 测试。
- API 契约改动需同时检查文档、OpenSpec 和 DTO。
- 任务型 API 设计可补读 `docs/guide/ai-task-api-review-checklist.md`。
