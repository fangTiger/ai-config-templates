---
name: codex-python-project
description: Inspect Python project structure, dependencies, virtualenvs, and validation commands for codex-codex-python-dev. Use before modifying Python source, dependencies, tests, or project startup files.
---

# Codex Python Project

## 核心规则

先运行：

```bash
bash .codex/tools/detect-python-project.sh
```

把输出作为本轮事实来源，尤其是：

- `classification`
- `dependency_files`
- `virtualenv`
- `layout`
- `recommended_test_command`
- `recommended_validation_commands`

## 空项目

如果是 `empty-python-project`，转入 `codex-python-bootstrap`。不要自己决定 FastAPI、Django、Poetry、uv、Ruff、MyPy 或 Sentry。

## 现有项目

如果是 `existing-python-project`：

1. 读取检测出的依赖文件。
2. 沿用现有虚拟环境和测试目录。
3. 使用 `recommended_validation_commands` 约束实现和验证。
4. 修改依赖、包管理器、框架或测试入口前必须有 OpenSpec 或用户明确确认。

## 输出要求

交接或最终回复中包含 Python 检测摘要和推荐验证命令。
