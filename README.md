# AI Config Templates

> OpenSpec + Graphify + Claude/Codex/Gemini/OpenCode 的统一 AI 开发脚手架。

这个仓库用来在新机器或新项目中快速落地一套 AI 编码工作流。它包含：

- **V2 分层配置**：全局不变量 + 项目模式差异，推荐优先使用
- **V1 兼容配置**：保留旧版 `setup-global.sh` 和 `setup-claude-config.sh`
- **插件模式切换**：Superpowers / ECC / OMC / Teams / codex-dev 等
- **Codex 专用模式**：`codex-codex-dev`、`codex-codex-python-dev`、claude-flow 系列 profile
- **OpenSpec 工作流**：proposal / apply / archive 命令与规范骨架
- **Graphify 增强**：Claude/Codex hooks、`.graphifyignore`、知识图谱降级策略
- **MCP / OpenCode 模板**：Codex、Gemini、OpenCode 项目配置

## 快速开始

### 推荐路径：V2

```bash
# 1. 克隆到用户目录下的独立工具目录（不要放到 ~/.claude 这类运行态目录）
mkdir -p ~/aicoding
git clone <repo-url> ~/aicoding/ai-config-templates
cd ~/aicoding/ai-config-templates

# 2. 初始化全局配置
./v2/setup-global.sh

# 3. 在目标项目安装项目级配置
cd /path/to/your-project
~/aicoding/ai-config-templates/v2/setup-project.sh

# Codex 主用推荐：安装完整 Codex-native GPT-5.5 profile
~/ai-config-templates/v2/setup-project.sh --mode=codex-codex-claude-flow-gpt55-dev

# Python 项目推荐：安装 Python-first Codex-native profile
~/ai-config-templates/v2/setup-project.sh --mode=codex-codex-python-dev

# 4. 可选：安装 graphify 并首次建图
pip install graphifyy
graphify install
/graphify .
```

V2 的好处：

- 全局规则和项目模式差异分层，重复内容更少
- 切换 profile 时只替换项目级资源，风险更低
- 自动写入 `.harness-manifest.json`，便于识别配置版本
- 同步生成 Claude/Codex hooks 和 `.graphifyignore`

### 兼容路径：V1

```bash
# 全局初始化
./setup-global.sh

# 部署到具体项目
./setup-claude-config.sh /path/to/your-project
```

`setup-claude-config.sh` 已改为从脚本所在仓库读取模板，所以这个脚手架不要求固定放在 `~/.claude/config-templates`；`.claude/` 只作为工具运行态和最终落盘配置目录。

## 目录结构

```text
ai-config-templates/
├── setup-global.sh                 # V1 全局初始化
├── setup-claude-config.sh          # V1 项目初始化
├── scripts/                        # Profile 切换脚本和 profile 模板
│   ├── switch-plugin.sh
│   ├── switch-plugin_codex.sh
│   └── plugin-profiles/
├── v2/                             # V2 分层配置
│   ├── setup-global.sh
│   ├── setup-project.sh
│   ├── graphifyignore.template
│   └── scripts/plugin-profiles/
├── global/                         # 全局规则和 Codex skills
├── hooks/                          # Claude/Graphify hooks
├── skills/                         # 项目级 skills 模板
├── agents/                         # Agent 模板
├── commands/openspec/              # OpenSpec 命令
├── openspec/                       # OpenSpec 项目骨架与现有 specs
├── templates/                      # OpenCode / AGENTS 模板
├── docs/graphify-integration.md    # Graphify 维护说明
├── CLAUDE.md                       # V1 项目级规则模板
├── AGENTS.md                       # OpenCode/Codex 项目指令模板
├── settings.json                   # Claude Code settings 模板
├── .mcp.json                       # Codex/Gemini/OpenCode MCP 模板
└── graphifyignore.template         # Graphify 排除模板
```

## Profile 切换

在已经初始化过的目标项目目录执行（下面为 claude 专用）：

```bash
# Claude Code profile
~/aicoding/ai-config-templates/scripts/switch-plugin.sh superpowers
~/aicoding/ai-config-templates/scripts/switch-plugin.sh ecc
~/aicoding/ai-config-templates/scripts/switch-plugin.sh omc
~/aicoding/ai-config-templates/scripts/switch-plugin.sh teams
~/aicoding/ai-config-templates/scripts/switch-plugin.sh codex-dev

# 状态和预览
~/aicoding/ai-config-templates/scripts/switch-plugin.sh --status
~/aicoding/ai-config-templates/scripts/switch-plugin.sh ecc --dry-run
```

Codex 专用 profile：

```bash
# V2 推荐：Codex 主工作台（完整 agents/hooks/tools/session-state）
~/ai-config-templates/v2/scripts/switch-plugin.sh codex-codex-claude-flow-gpt55-dev

# V2 推荐：Python-first Codex 主工作台
~/ai-config-templates/v2/scripts/switch-plugin.sh codex-codex-python-dev

# V1 兼容路径：仅在旧项目或尚未迁移 V2 时使用
# 测试验证版，可忽略
~/aicoding/ai-config-templates/scripts/switch-plugin_codex.sh codex-codex-dev
# 测试验证版，可忽略
~/aicoding/ai-config-templates/scripts/switch-plugin_codex.sh codex-codex-claude-flow-dev
# 主 agent 5.5-xhigh woker、review-5.4-xhigh
~/aicoding/ai-config-templates/scripts/switch-plugin_codex.sh codex-codex-claude-flow-gpt55-dev
# 测试验证python版，可忽略
~/aicoding/ai-config-templates/scripts/switch-plugin_codex.sh codex-codex-python-dev
```

切换后重启对应 AI CLI 会话，让新的项目级配置生效。

## 工作流

```text
需求澄清
  -> brainstorming / 需求设计
  -> OpenSpec proposal
  -> writing-plans / 任务拆分
  -> TDD 实现
  -> review
  -> verification-before-completion
  -> archive / merge
```

OpenSpec 命令：

- `/openspec:proposal`：创建变更提案
- `/openspec:apply`：实现已批准的变更
- `/openspec:archive`：归档已完成的变更

Superpowers / Codex skills 会把需求探索、计划、TDD、审查和完成验证串成一致流程。

## Graphify

推荐安装：

```bash
pip install graphifyy
graphify install
```

项目首次建图：

```bash
/graphify .
```

脚手架会把 Graphify hook 安装到 Claude/Codex 侧：

- 搜索前优先做结构查询：`graphify query "<module/file> architecture dependencies"`
- 改代码前优先做影响检查：`graphify query "<module/file> impact callers tests dependencies"`
- 如果 `graphify` CLI 不可用，会降级读取 `graphify-out/GRAPH_REPORT.md` 或继续原流程

更多维护细节见 `docs/graphify-integration.md`。

## MCP 与 OpenCode

`.mcp.json` 预置：

- `codex`：`codex mcp-server`
- `gemini-cli`：`npx -y gemini-mcp-tool`
- `opencode`：`npx -y opencode-mcp`

项目初始化脚本可把 `.mcp.json`、`opencode.json`、`AGENTS.md` 和 OpenCode graphify 插件模板复制到目标项目。

## 维护建议

- 新能力优先加到 `v2/scripts/plugin-profiles/shared/`，再按 profile 做差异化覆盖。
- 只属于某个模式的规则放到对应 profile 目录。
- 修改 hooks 或 settings 后，至少运行 JSON 校验和 shell 语法检查。
- 修改脚手架行为前，优先在 `openspec/changes/` 下写 proposal 和 tasks。

## License

MIT
