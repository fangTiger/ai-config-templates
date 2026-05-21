---
name: graphify
description: 代码知识图谱工具 — 建图、查询结构、分析依赖和影响范围
arguments:
  - name: action
    description: "操作类型：build(建图)、query(查询)、status(状态)"
    required: false
    default: "status"
  - name: target
    description: "查询目标（文件/模块名）或建图路径"
    required: false
    default: "."
---

请执行以下 graphify 操作：

**如果参数 action 为 "build" 或目标为 "."：**

1. 检查 `graphify` CLI 是否已安装（`which graphify`）
2. 如果未安装，提示用户：`pip install graphifyy && graphify install`
3. 如果已安装，执行建图：`graphify build {{target}}`
4. 等待建图完成，报告结果

**如果参数 action 为 "status"：**

1. 检查 `graphify` CLI 是否可用
2. 检查 `graphify-out/graph.json` 是否存在
3. 如果图谱存在，报告图谱状态和节点数量
4. 如果不存在，提示用户执行 `/graphify build` 建图

**如果参数 action 为 "query"：**

1. 确认图谱文件存在（`graphify-out/graph.json`）
2. 执行查询：`graphify query "{{target}}" --budget 1500`
3. 报告查询结果
4. 如果无结果，提示可能的替代搜索方式
