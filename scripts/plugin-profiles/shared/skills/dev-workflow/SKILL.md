---
name: dev-workflow
description: Development workflow management for iuap-aip-data. Use when creating requirements, writing design notes, conducting reviews, choosing verification, or tracking implementation progress in this Java/Maven ontology project.
---

# 开发流程技能

## 目的

为 iuap-aip-data 的开发任务提供轻量流程约束，确保需求、设计、实现、复审和验证之间有清晰证据链。

## 适用场景

- 创建或复核需求、设计、实现计划
- 执行 OpenSpec 提案中的任务清单
- 对 Java/Spring/Maven 或 ontology 相关改动做代码复审
- 选择验证命令并整理交付证据
- 跟踪中大型任务进度

## 基本流程

### 1. 判断任务类型

- 非平凡能力、API、数据模型、权限、架构或 `.codex` 执行契约变更：先走 OpenSpec。
- 明确 bug、文档、测试补充或局部小改：可走小任务最小交付。
- 无法判断影响面时，默认先提案。

### 2. 建立上下文

按 `AGENTS.md` 阅读顺序建立上下文：

1. `AGENTS.md`
2. `CODE_WIKI.md`
3. `docs/guide/task-doc-mapping.md`
4. 必要时补读 `.codex/workflow.md`
5. 涉及上下文工程时补读 `docs/guide/codex-context-engineering.md`
6. 相关 OpenSpec、guide、domain、reference 文档
7. 相关模块现有实现和测试

### 3. 编写或复核方案

中大型任务至少明确：

- 目标和非目标
- 影响范围
- 涉及文件或模块
- 验证方式
- 风险和回滚思路

OpenSpec 任务使用 `openspec/changes/<change-id>/proposal.md`、`design.md`、`tasks.md` 和 `specs/*/spec.md` 作为主记录。

轻量任务可使用 `docs/plans/` 或任务对应文档记录设计取舍，不新增重复目录体系。

### 4. 实现与复审

- 保持改动范围贴合任务，不做无关重构。
- Java 代码遵循 Controller / Service / DAO / DTO / VO 分层。
- 优先复用既有 utils、enums、Service、异常和响应封装。
- 安全、权限、数据访问相关改动必须做额外审查。
- Java 分层、SQL / 数据访问、权限安全边界命中时，优先调用对应专项 review skill，或在交付说明中记录未调用原因。
- 多代理或 handoff 任务以 `.codex/workflow.md` 和相关 codex skill 为准。

### 5. 验证与交付

按改动类型选择验证：

| 改动类型 | 最小验证 |
|----------|----------|
| Markdown / 说明 | 空白检查、结构检查或 OpenSpec validate |
| Java 生产代码 | 定向 Maven 测试，必要时扩大到模块或全量测试 |
| 公共 API / 权限 / 数据访问 | 定向测试 + 影响面说明 + 扩大验证 |
| OpenSpec | `openspec validate <change-id> --strict`，必要时 `openspec validate --all` |
| `.codex` / hooks / skills / tools | JSON、shell、Node 语法校验，说明 profile 是否同步 |
| graphify | `bash .codex/tools/graphify-java-project.sh --incremental` |

交付说明至少包含：

- 读取的关键文档
- 修改的文件
- 验证命令和结果
- 未验证项及原因

## 复审清单

- [ ] 是否符合 `AGENTS.md` 与相关 OpenSpec
- [ ] 是否未扩大到无关文件
- [ ] 是否遵守 Java/Maven/ontology 项目约定
- [ ] 是否保留安全、权限、数据访问边界
- [ ] 是否有足够验证证据
- [ ] 是否同步了运行态与 profile 持久源
