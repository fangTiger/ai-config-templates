---
name: codex-python-bootstrap
description: Empty Python project startup for codex-codex-python-dev. Use when the target directory is empty or lacks Python project structure and the user wants to create a Python project. Always detect first and create/update an OpenSpec 初始化提案 before scaffolding.
---

# Codex Python Bootstrap

## 目的

在 `codex-codex-python-dev` 中处理空 Python 项目起步。该技能帮助项目从“空目录”进入“有规范的 Python 项目”，但不得跳过 OpenSpec Gate。

## 必须先做

```bash
bash .codex/tools/detect-python-project.sh
```

如果输出 `classification=empty-python-project` 且 `init_allowed=false`：

1. 创建或更新 OpenSpec 初始化提案。
2. 提案必须说明包名、布局、依赖管理、测试入口和非目标。
3. 提案批准前不得创建 `pyproject.toml`、`src/`、`app/`、包目录或 `tests/`。

## 默认约束

- 不默认 FastAPI。
- 不默认 Django。
- 不默认 Poetry。
- 不默认 uv。
- 不默认 Ruff、MyPy、Sentry、数据库、Docker 或 CI。

这些选择只能来自用户明确要求、现有项目事实或已批准提案。

## 初始化提案最小内容

OpenSpec 初始化提案应回答：

- 项目类型：library / CLI / service / script / other。
- 包名与目录布局。
- Python 版本策略。
- 依赖文件：如 `pyproject.toml` 或 `requirements.txt`。
- 测试入口：通常是 `python -m pytest`，如存在虚拟环境则使用检测结果。
- 明确 non-goals：框架、数据库、CI、部署等未选择项。

## 提案批准后

按提案执行 TDD：

1. 写最小 RED 测试。
2. 创建最小项目骨架。
3. 运行 GREEN。
4. 使用 `bash .codex/tools/verify-python-project.sh --print-plan` 和实际验证命令收集证据。
