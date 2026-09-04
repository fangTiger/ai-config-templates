# .codex/tools

本目录只放 AI / Codex / 上下文工程辅助工具，不放业务脚本。

- 业务脚本、数据库脚本、部署脚本继续放项目既有业务目录。
- 不要把 AI 辅助工具放到 `scripts/`，避免和业务交付物混淆。
- 上下文工程完整维护口径见 `docs/guide/codex-context-engineering.md`。


## 运行时验证摘要

`runtime-verification-summary.sh` 读取 PostToolUse tracker 写入的运行时缓存，汇总本轮编辑文件和建议验证命令。它只输出摘要，不执行 Maven、测试、构建、git 或删除操作。

```bash
bash .codex/tools/runtime-verification-summary.sh
bash .codex/tools/runtime-verification-summary.sh <session-id>
```

默认读取 `/tmp/<project-name>/<project-name>-codex-runtime-cache` 中最近更新的 session。需要指定缓存根目录时，设置 `CODEX_RUNTIME_CACHE_DIR`。
