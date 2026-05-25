# .codex/tools

本目录只放 AI / Codex / 上下文工程辅助工具，不放业务脚本。

- 业务脚本、数据库脚本、部署脚本继续放项目既有业务目录。
- Codex hook、graphify、上下文生成、agent 运行辅助脚本放 `.codex/tools/` 或 `.codex/hooks/`。
- 不要把 AI 辅助工具放到 `scripts/`，避免和业务交付物混淆。
- 上下文工程完整维护口径见 `docs/guide/codex-context-engineering.md`。
- `.graphifyignore` 避免使用可能误伤源码包路径的裸目录名。需要忽略仓库根数据目录时，优先使用带锚点或显式范围的模式，例如 `data/**`。

## Graphify

```bash
bash .codex/tools/graphify-java-project.sh
bash .codex/tools/graphify-java-project.sh --incremental
```

全量图谱输出：

- `graphify-out/graph.json`
- `graphify-out/GRAPH_REPORT.md`
- `graphify-out/graph.html`
- `graphify-out/graph-preview-top500.html`
- `graphify-out/extract.json`
- `graphify-out/manifest.json`

脚本只允许把图谱产物写入仓库根目录 `graphify-out/`。如果发现 `src/graphify-out` 或 `src/**/graphify-out`，说明曾在错误工作目录下执行过 graphify，需要清理越界产物并重新从仓库根目录运行。

## 运行时验证摘要

`runtime-verification-summary.sh` 读取 PostToolUse tracker 写入的运行时缓存，汇总本轮编辑文件和建议验证命令。它只输出摘要，不执行 Maven、测试、构建、git 或删除操作。

```bash
bash .codex/tools/runtime-verification-summary.sh
bash .codex/tools/runtime-verification-summary.sh <session-id>
```

默认读取 `/tmp/<project-name>/<project-name>-codex-runtime-cache` 中最近更新的 session。需要指定缓存根目录时，设置 `CODEX_RUNTIME_CACHE_DIR`。
