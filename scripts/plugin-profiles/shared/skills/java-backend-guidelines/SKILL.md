---
name: java-backend-guidelines
description: Use when working on Java/Spring/Maven backend code in iuap-aip-data, especially Controller, Service, DAO, DTO, response, exception, or tests
---

# Java Backend Guidelines

## 必读上下文

1. `AGENTS.md`
2. `CODE_WIKI.md`
3. `docs/guide/task-doc-mapping.md`
4. 按任务类型补读 `docs/guide/api-patterns.md`、`docs/guide/resp.md`、`docs/reference/enums.md`、`docs/reference/utils.md`

## 项目约束

- Java 8 + Spring Boot + Maven WAR。
- Controller 继承 `ApiBaseController`，用 `success()` 返回。
- 业务异常优先 `BizException + RespErrorEnum`。
- HTTP/YMS 调用优先复用 `ItdYmsHttpUtil` 和既有工具。
- DTO/VO/枚举/Service 命名沿用项目约定。
- 日志、注释、文档使用中文；代码标识符使用英文。

## 实施原则

- 先确认是否需要 OpenSpec。
- 优先复用现有 Service、utils、enums、响应模式。
- 不在 Controller 写业务逻辑。
- 不引入新依赖，除非任务明确要求并有理由。
- 改公共 API、权限、数据访问时扩大影响面检查。

## 验证

- 改生产 Java：优先运行相关测试类。
- 改测试 Java：运行对应测试类。
- 改 `pom.xml`：至少运行 Maven 构建或说明未运行原因。
- 提交前使用 `maven-verification` 选择验证命令。
