---
name: codex-python-testing
description: Run Python RED-GREEN-REFACTOR in codex-codex-python-dev using detector-provided validation commands. Use before implementing Python behavior changes or bug fixes.
---

# Codex Python Testing

## 开始前

运行：

```bash
bash .codex/tools/detect-python-project.sh
bash .codex/tools/verify-python-project.sh --print-plan
```

读取 `recommended_validation_commands`。这组命令是本轮 Python TDD 的默认验证边界。

## RED

先写一个最小失败测试。运行检测结果中的 `recommended_test_command`，确认失败原因来自缺失行为，而不是导入错误、环境错误或测试拼写错误。

## GREEN

只写让测试通过的最小实现。继续使用同一个命令验证。

## REFACTOR

只有 GREEN 后才能重构。重构后再次运行 `recommended_validation_commands`。

## 空项目

若检测结果为 `empty-python-project`，不要写测试或代码。先转入 `codex-python-bootstrap` 创建 OpenSpec 初始化提案。
