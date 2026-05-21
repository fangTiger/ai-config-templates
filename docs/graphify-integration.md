# Graphify 集成说明

> 说明 ai-config-templates 脚手架中 `graphify` 的集成范围、默认行为、降级策略与维护入口。

---

## 1. 目标

`graphify` 在这个脚手架里不是单独的功能插件，而是代码结构检索和影响分析的增强层。

目标有两点：
- 在非平凡搜索、阅读代码、修改代码前，优先利用代码图谱理解当前结构
- 在 `graphify` 不可用时自动降级，不影响 Claude/Codex 正常流程

这套策略统一覆盖：
- V1 安装链路
- V2 安装链路
- 所有 profile：`superpowers`、`ecc`、`omc`、`teams`、`codex-dev`
- Claude 和 Codex 两侧

---

## 2. 生效入口

### 2.1 安装脚本

- V1 项目安装：`setup-claude-config.sh`
- V2 项目安装：`v2/setup-project.sh`

### 2.2 模式切换脚本

- V1 模式切换：`scripts/switch-plugin.sh`
- V2 模式切换：`v2/scripts/switch-plugin.sh`

### 2.3 Hook 模板

- Root Hook：`hooks/graphify-query-hook.sh`
- V1 Shared Hook：`scripts/plugin-profiles/shared/hooks/graphify-query-hook.sh`
- V2 Shared Hook：`v2/scripts/plugin-profiles/shared/hooks/graphify-query-hook.sh`

### 2.4 配置模板

Claude 侧：
- `settings.json`
- `scripts/plugin-profiles/*/settings.json`
- `v2/scripts/plugin-profiles/*/settings.json`

Codex 侧：
- 安装脚本与切换脚本动态生成 `.codex/hooks.json`

---

## 3. 默认触发范围

脚手架会把 `graphify` Hook 挂到以下工具：

```text
Bash|Read|Grep|Glob|Edit|MultiEdit|Write|NotebookEdit
```

含义如下：
- `Grep`、`Glob`、部分搜索型 `Bash`：在广泛搜索前优先提示使用图谱检索
- `Read`：在阅读关键文件前提示先看结构关系
- `Edit`、`MultiEdit`、`Write`、`NotebookEdit`：在改代码前提示先做影响分析

---

## 4. 标准使用方式

### 4.1 本机安装

```bash
pip install graphifyy && graphify install
```

### 4.2 项目首次建图

在 Claude Code / Codex 项目会话中执行：

```bash
/graphify .
```

建图成功后，项目内通常会出现：

```text
graphify-out/graph.json
graphify-out/GRAPH_REPORT.md
```

### 4.3 推荐查询方式

结构检索：

```bash
graphify query "<module/file> architecture dependencies"
```

影响检查：

```bash
graphify query "<module/file> impact callers tests dependencies"
```

建议在做以下操作前优先使用：
- 跨模块修改
- 公共接口调整
- 重构调用链
- 找测试影响范围
- 定位依赖关系或边界责任

---

## 5. 自动降级策略

`graphify` 在脚手架中按 `fail-open` 设计实现。

这意味着：
- 没有 `graphify-out/graph.json`：Hook 直接退出，不影响原流程
- 本机没装 `graphify` CLI：Hook 回退为提示阅读 `graphify-out/GRAPH_REPORT.md`
- `graphify query` 查询失败：Hook 不阻断工具，只返回通用提示或空结果提示
- 没有匹配到相关节点：Hook 不报错，只提示当前查询无结果

**规则要求：**
- `graphify` 是增强层，不是硬依赖
- 不允许因为 `graphify` 不可用而阻断 Claude/Codex 的正常使用

---

## 6. 文档规则

脚手架模板已在以下文档中写入统一规则：
- `README.md`
- `CLAUDE.md`
- `global/CLAUDE.md`
- `v2/global/CLAUDE.md`
- 各 profile 自己的 `CLAUDE.md`

统一要求为：
- 如果项目存在 `graphify-out/graph.json`，在非平凡搜索/读代码/改代码前优先使用 `graphify`
- 如果 `graphify` 不可用，自动降级，不阻断流程

---

## 7. 维护建议

后续维护 `graphify` 集成时，优先检查这几类文件是否同步：

1. Hook 实现是否一致
2. V1/V2 安装脚本是否同步
3. 模式切换脚本是否同步
4. 各 profile 的 `settings.json` matcher 是否同步
5. 全局文档与 profile 文档是否同步
6. 测试是否覆盖：
   - 安装链路
   - matcher 范围
   - Hook 的 `Edit/Write` 提示
   - 自动降级行为

当前相关测试：
- `tests/test_legacy_setup_graphify.py`
- `tests/test_v2_setup_project_graphify.py`
- `tests/test_graphify_query_hook.py`

---

## 8. 快速排查

如果发现 `graphify` 没生效，可以按这个顺序检查：

1. 是否已建图：项目下是否存在 `graphify-out/graph.json`
2. 是否已安装 CLI：`graphify --help`
3. Claude 侧是否有 Hook：
   - `.claude/hooks/graphify-query-hook.sh`
   - `.claude/settings.json`
4. Codex 侧是否有 Hook：
   - `.codex/hooks/graphify-query-hook.sh`
   - `.codex/hooks.json`
5. 当前 profile 的模板 `settings.json` 是否仍带有完整 matcher

如果 CLI 不存在但项目已有 `graphify-out/GRAPH_REPORT.md`，属于预期降级行为，不是故障。
