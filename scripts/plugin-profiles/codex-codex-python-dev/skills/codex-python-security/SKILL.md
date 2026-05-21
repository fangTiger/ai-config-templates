---
name: codex-python-security
description: Python backend/security review boundaries for codex-codex-python-dev. Use when Python changes touch auth, permissions, secrets, data access, APIs, external calls, or error tracking.
---

# Codex Python Security

## 先决条件

先运行：

```bash
bash .codex/tools/detect-python-project.sh
```

安全审查必须基于现有项目事实；不默认 FastAPI、不默认 Django、不默认 Sentry，也不假设项目已有数据库或外部服务。

## 检查矩阵

| 边界 | 检查内容 |
| --- | --- |
| 认证 | 登录态、token、session、请求上下文 |
| 授权 | 角色、权限、资源归属 |
| 密钥 | 环境变量、连接串、日志泄露 |
| 数据权限 | 查询范围、租户 / 用户过滤 |
| API 契约 | 参数、响应、错误语义、兼容性 |
| 外部调用 | 超时、重试、错误处理、敏感日志 |
| 错误追踪 | 仅在项目已有或用户选择时接入 |

## 输出要求

审查结论必须写明命中边界、验证命令和剩余风险。未命中也写 `N/A`。
