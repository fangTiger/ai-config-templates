# codex-codex-python-dev tools

这些工具属于 `codex-codex-python-dev`，用于 Python 项目起步和执行约束。

## detect-python-project.sh

只读检测工具：

```bash
bash .codex/tools/detect-python-project.sh [project-dir]
```

输出 JSON 字段：

- `classification`: `empty-python-project` 或 `existing-python-project`
- `dependency_files`: 已发现的依赖 / 配置文件
- `virtualenv`: `.venv` / `venv` / `env` 或空字符串
- `layout`: 已发现的 `src`、`app`、`tests` 等布局
- `recommended_test_command`: 首选 pytest 命令
- `recommended_validation_commands`: 推荐验证命令列表
- `init_allowed`: 空项目为 `false`

## verify-python-project.sh

验证计划工具：

```bash
bash .codex/tools/verify-python-project.sh --print-plan
bash .codex/tools/verify-python-project.sh
```

`--print-plan` 只输出计划，不执行测试。默认模式会执行 `recommended_validation_commands`；空项目会拒绝执行并提示先走 `codex-python-bootstrap`。

## graphify-python-project.sh

Python 影响面辅助工具，优先读取 `graphify-out/graph.json`，不可用时提示读取 `graphify-out/GRAPH_REPORT.md`。
