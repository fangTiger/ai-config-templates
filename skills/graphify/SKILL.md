---
name: graphify
description: 知识图谱工具 — 代码结构检索、依赖分析、影响范围检查。使用 graphify 生成项目知识图谱，通过查询获取模块架构、调用链、测试覆盖等上下文信息。
triggers:
  - keyword:
      - graphify
      - 图谱
      - 知识图谱
      - 知识图
      - knowledge graph
  - intent:
      - 检查代码结构
      - 分析依赖关系
      - 查看影响范围
      - 理解模块架构
      - 建图
      - 生成图谱
---

# Graphify — 代码知识图谱

## 概述

Graphify 是一个代码知识图谱工具，能够将代码库转换为结构化图谱，支持快速检索模块架构、依赖关系、调用链和测试覆盖。

在 OpenCode 环境中，Graphify 通过以下方式工作：
1. **MCP 工具**（首选）：`graphify_query`、`graphify_status`、`graphify_build`
2. **CLI 命令**：`graphify query`、`graphify build`
3. **降级策略**：阅读 `graphify-out/GRAPH_REPORT.md`

## 使用方式

### 1. 首次建图

在项目根目录执行建图：

```bash
# 使用斜杠命令
/graphify .

# 或使用 MCP 工具
graphify_build(path=".")
```

建图成功后会生成：
- `graphify-out/graph.json` — 图谱数据
- `graphify-out/GRAPH_REPORT.md` — 结构报告

### 2. 结构查询

在搜索代码前，先通过图谱了解模块结构：

```
# MCP 工具调用
graphify_query(query="<模块/文件> architecture dependencies")

# CLI 命令
graphify query "<模块/文件> architecture dependencies" --budget 1500
```

### 3. 影响分析

在修改代码前，先检查影响范围：

```
# MCP 工具调用
graphify_query(query="<目标文件> impact callers tests dependencies")

# CLI 命令
graphify query "<目标文件> impact callers tests dependencies" --budget 1500
```

### 4. 状态检查

```
# MCP 工具调用
graphify_status()
```

## 查询场景

| 场景 | 查询示例 |
|------|---------|
| 理解模块架构 | `graphify_query(query="src/api architecture")` |
| 查找依赖关系 | `graphify_query(query="auth module dependencies")` |
| 评估修改影响 | `graphify_query(query="UserService impact callers")` |
| 定位测试覆盖 | `graphify_query(query="PaymentService tests")` |
| 查找调用链 | `graphify_query(query="handleRequest callers dependencies")` |

## 降级策略

```
graphify_query MCP 可用？→ 直接使用获取上下文
  ↓ 否
graphify CLI 可用？→ 通过 Bash 调用 graphify query
  ↓ 否
graphify-out/GRAPH_REPORT.md 存在？→ 阅读报告
  ↓ 否
继续原流程，不阻断
```

## 注意事项

- Graphify 是**增强层**，不是硬依赖。不可用时不允许阻断正常流程
- 查询结果应作为**上下文补充**，不替代直接代码阅读
- 大型项目建图可能需要几分钟，建议在项目首次打开时执行
- 排除规则参见项目根目录的 `.graphifyignore` 文件
