# AI Config Templates

> OpenSpec + Graphify + Claude/Codex/Gemini/OpenCode 的统一 AI 开发脚手架。

这个仓库用来在新机器或新项目中快速落地一套 AI 编码工作流。它包含：

- **V2 分层配置**：全局不变量 + 项目模式差异，推荐优先使用
- ~~**V1 兼容配置**~~：**已停止维护**，仅为旧项目保留，不再接收新 profile 和修复
- **插件模式切换**：Superpowers / mps / ECC / OMC / Teams / codex-dev 等，支持会话内 `/switch-profile`
- **Codex 专用模式**：`codex-codex-dev` 与 claude-flow 系列 profile
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

# 2. 初始化全局配置（会安装 ~/.claude/CLAUDE.md 与 ~/.codex/AGENTS.md）
./v2/setup-global.sh

# 3. 在目标项目安装项目级配置（文档下方【Profile 切换】后续还会新增各种模型组合模式，待接入，如 dp-v4pro、glm，如果我充钱的话）
# claude 设计模式，如使用 codex 则需要切换下面命令
cd /path/to/your-project
~/aicoding/ai-config-templates/v2/setup-project.sh

# Codex 主用推荐：安装完整 Codex-native GPT-5.5 profile
~/aicoding/ai-config-templates/v2/setup-project.sh --mode=codex-codex-claude-flow-gpt55-dev

# 新增独立 GPT-5.6 Sol profile：主 agent 5.6-sol-xhigh，worker、review-5.5-xhigh
~/aicoding/ai-config-templates/v2/setup-project.sh --mode=codex-codex-claude-flow-gpt56-sol-dev

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

### 兼容路径：V1（已停止维护）

> **V1 已停止维护。** 新项目一律用 V2；`mps` 等新增 profile 只在 V2 提供。
> 下列脚本仅为尚未迁移的旧项目保留，不再接收新功能和缺陷修复。
> 迁移方式：在项目目录执行 `v2/setup-project.sh --migrate`。

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
├── setup-global.sh                 # V1 全局初始化（已停止维护）
├── setup-claude-config.sh          # V1 项目初始化（已停止维护）
├── scripts/                        # V1 profile 切换脚本和模板（已停止维护）
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
├── CLAUDE.md                       # V1 项目级规则模板（已停止维护）
├── AGENTS.md                       # OpenCode/Codex 项目指令模板
├── settings.json                   # Claude Code settings 模板
├── .mcp.json                       # Codex/Gemini/OpenCode MCP 模板
└── graphifyignore.template         # Graphify 排除模板
```

## Profile 切换

### 会话内切换（推荐）

在 Claude Code 会话里直接用 slash 命令，无需退出：

```
/switch-profile mps
/switch-profile --status
/switch-profile --list
/switch-profile mps --dry-run
```

该命令是 `switch-plugin.sh` 的封装，靠 manifest 的 `templateRoot` 字段定位脚本。
若项目是用旧版 `setup-project.sh` 初始化的（`manifestSchemaVersion: 1`，无该字段），
命令会回退到环境变量 `AI_CONFIG_TEMPLATES_ROOT` 与候选路径；都失败时会给出修复指引。
重跑 `v2/setup-project.sh` 即可补上该字段。

> 切换目标为 `codex-*` 时命令会强制二次确认——这类切换会删除项目根 `CLAUDE.md`。

### 外部脚本切换

在已经初始化过的目标项目目录执行（下面为 claude 专用）：

```bash
# Claude Code profile
~/aicoding/ai-config-templates/scripts/switch-plugin.sh superpowers
~/aicoding/ai-config-templates/scripts/switch-plugin.sh ecc
~/aicoding/ai-config-templates/scripts/switch-plugin.sh omc
~/aicoding/ai-config-templates/scripts/switch-plugin.sh teams
~/aicoding/ai-config-templates/scripts/switch-plugin.sh codex-dev

# mps（V2）
~/aicoding/ai-config-templates/v2/scripts/switch-plugin.sh mps

# 状态和预览
~/aicoding/ai-config-templates/scripts/switch-plugin.sh --status
~/aicoding/ai-config-templates/scripts/switch-plugin.sh ecc --dry-run
```

### mps 模式（mattpocock-skills）

以访谈驱动的规范合成为核心，链路为
`/grill-with-docs → /to-spec → /to-tickets → /implement(tdd + code-review)`。

首次使用需要注册 marketplace：

```bash
claude plugin marketplace add mattpocock/skills
```

要点：

- 依赖 `mattpocock-skills@mattpocock`，**pin 版本 1.2.3**；上游升级后需重跑 mps 的验收流程
- 本模式**关闭 superpowers 插件**——两者的 `tdd`/`code-review`/`diagnosing-bugs`/`domain-modeling`
  与 superpowers 的四个同职责 skill 会互相争抢触发
- skill 产出一律落到 `openspec/`（proposal / spec delta / tasks.md），**不使用 issue tracker**。
  落点的权威定义在 `docs/agents/issue-tracker.md`——这是上游 `/setup-matt-pocock-skills`
  Section A **Other** 选项设计的扩展点，切换到 mps 时自动安装；`mps/CLAUDE.md` Section 1 只是速查摘要
- **默认无需运行 `/setup-matt-pocock-skills`**（profile 已预置其产物）。必须运行时 Section A 选 `Other`，
  **不要选「本地文件」**——该模式路径写死 `.scratch/`，没有指向 `openspec/` 的选项
- profile 已配置 `deny` 规则，拦截 `gh issue`/`gh secret`/`git push` 等外部写操作
- 领域术语表维护在项目根 `CONTEXT.md`

mps 有三个变体，按「谁写代码」区分：

| profile | 入口 | Claude | Codex | Gemini |
|---|---|---|---|---|
| `mps` | `CLAUDE.md` | 设计 + **实现** | 交叉审查 | 前端 |
| `codex-mps-dev` | `CLAUDE.md` | 设计 + 编排 + 审查 | **后端实现** | **前端实现** |
| `codex-codex-mps-dev` | `AGENTS.md` | 不参与 | **全包** | 不参与 |

```bash
~/aicoding/ai-config-templates/v2/scripts/switch-plugin.sh mps
~/aicoding/ai-config-templates/v2/scripts/switch-plugin.sh codex-mps-dev
~/aicoding/ai-config-templates/v2/scripts/switch-plugin.sh codex-codex-mps-dev
```

**三者共用同一份 `docs/agents/issue-tracker.md`**，规范落点语义完全一致，互相切换不会产生分叉。

`codex-mps-dev`（Claude 设计 + Codex 实现）：

- 6 阶段流水线 `ANALYZE → DESIGN → HANDOFF → IMPLEMENT → REVIEW → VERIFY`
- 各阶段技能换成 mattpocock 链路：`/grill-with-docs` → `/to-spec` → `/to-tickets` → 交接 → `code-review`
- 交接靠 `codex-handoff` skill，含 FileAllowlist 护栏和 git 基线
- `tasks.md` 每个 task 标注 `Executor: Codex|Gemini|Claude`
- Codex 侧另装 `.codex/skills/openspec-*` 四个技能

`codex-codex-mps-dev`（Codex 主工作台）：


- 入口为 `AGENTS.md`（切换时会**删除** `CLAUDE.md`），Claude 不参与
- `.codex/skills/` 是 25 个 mattpocock skill 的**英文原样文件副本**（与插件发布清单一致，pin 1.2.3），
  另加 shared 的 9 个，共 34 个
- 与 Claude 侧共用同一份 `docs/agents/issue-tracker.md`，落点语义完全一致

#### 日常使用：从零到归档

装好之后一次完整的中等任务长这样（以 `mps` 为例，另外两个变体只是实现环节换人）：

```bash
# 一次性准备
claude plugin marketplace add mattpocock/skills      # 注册 marketplace
cd /path/to/your-project
~/aicoding/ai-config-templates/v2/setup-project.sh   # 首次装 harness
~/aicoding/ai-config-templates/v2/scripts/switch-plugin.sh mps
# 重启会话（切换只对下一次会话生效）
```

会话内：

```
/grill-with-docs          # ① 密集访谈澄清需求，产出 docs/plans/YYYY-MM-DD-*-design.md
                          #    术语增量自动进 CONTEXT.md
/to-spec                  # ② 合成规范 → openspec/changes/<id>/proposal.md + spec deltas
                          #    ⚠️ 到此停下，等你审批。发布 ≠ 批准
/to-tickets               # ③ 拆成 bite-sized 任务 → tasks.md（编号条目，非 issues/ 目录）
/implement                # ④ 按 tasks.md 逐条实现，强制 TDD；code-review 自动触发
                          # ⑤ 粘贴真实测试输出后才能声称完成
/openspec:archive         # ⑥ 合并 delta 到 openspec/specs/，归档变更
```

大任务在 ② 和 ③ 之间插一步 `/wayfinder` 建决策地图（落 `design.md`），逐个决策解决后再拆解。
小任务（bug 修复、< 3 文件）不走这条链，直接 `diagnosing-bugs` → `tdd` → 验证。

日常还会用到：

```
/switch-profile --status              # 看当前模式
/switch-profile mps --dry-run         # 预览切换影响，不落盘
/switch-profile codex-mps-dev         # 换成 Codex 实现
/ask-matt                             # 不确定该用哪个 skill 时问它
```

#### 常见问题

**切换报「检测到漂移，但当前不是交互终端」（退出码 2）**
说明入口文件被手工改过（`/setup-matt-pocock-skills` 会追加 `## Agent skills` 块，必然触发）。
先看清改了什么，确认可以丢弃后加 `--force-overwrite`；想保留就先提交或备份。

**切换报「当前目录是模板仓库本身」**
你在模板仓库里执行了切换。到目标项目目录再跑。

**`/switch-profile` 找不到 `switch-plugin.sh`**
项目 manifest 是旧的 schema v1（无 `templateRoot`）。命令会依次回退到环境变量
`AI_CONFIG_TEMPLATES_ROOT` 和候选路径；机器上有多个模板副本时，它会自动挑有该 profile 的那个。
**成功切换一次后会把路径写回 manifest，之后不再需要猜。**

**mattpocock skill 没出现在 `/plugin` 里**
marketplace 没注册，或切换后没重启会话。

> **注意**：切换脚本禁止在模板仓库自身执行——那会用 profile 文件覆盖仓库根的 `CLAUDE.md` /
> `AGENTS.md` 模板（它们是纳入版本管理的交付物）。请到目标项目目录执行。

Codex 专用 profile：

```bash
# V2 推荐：Codex 主工作台（完整 agents/hooks/tools/session-state）
~/aicoding/ai-config-templates/v2/scripts/switch-plugin.sh codex-codex-claude-flow-gpt55-dev

# V2 独立 GPT-5.6 Sol：主 agent 5.6-sol-xhigh，worker、review-5.5-xhigh
~/aicoding/ai-config-templates/v2/scripts/switch-plugin.sh codex-codex-claude-flow-gpt56-sol-dev

# V1 兼容路径：仅在旧项目或尚未迁移 V2 时使用
# 测试验证版，可忽略
~/aicoding/ai-config-templates/scripts/switch-plugin_codex.sh codex-codex-dev
# 测试验证版，可忽略
~/aicoding/ai-config-templates/scripts/switch-plugin_codex.sh codex-codex-claude-flow-dev
# 主 agent 5.5-xhigh，worker、review-5.4-xhigh
~/aicoding/ai-config-templates/scripts/switch-plugin_codex.sh codex-codex-claude-flow-gpt55-dev
# 主 agent 5.6-sol-xhigh，worker、review-5.5-xhigh
~/aicoding/ai-config-templates/scripts/switch-plugin_codex.sh codex-codex-claude-flow-gpt56-sol-dev
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

脚手架会把 Graphify hook 安装到 Claude/Codex 侧；图谱可用时优先提供结构和影响面上下文，不可用时记录降级原因并继续原流程。

更多维护细节见 `docs/graphify-integration.md`。

## MCP 与 OpenCode

`.mcp.json` 预置：

- `codex`：`codex mcp-server`
- `gemini-cli`：`npx -y gemini-mcp-tool`
- `opencode`：`npx -y opencode-mcp`

项目初始化脚本可把 `.mcp.json`、`opencode.json`、`AGENTS.md` 和 OpenCode graphify 插件模板复制到目标项目。

## 维护建议

- **V1 已停止维护**：新能力一律只加到 `v2/`，不要同步回 `scripts/`。
- 新能力优先加到 `v2/scripts/plugin-profiles/shared/`，再按 profile 做差异化覆盖。
- 只属于某个模式的规则放到对应 profile 目录。
- 修改 hooks 或 settings 后，至少运行 JSON 校验和 shell 语法检查。
- 修改脚手架行为前，优先在 `openspec/changes/` 下写 proposal 和 tasks。

## License

MIT
