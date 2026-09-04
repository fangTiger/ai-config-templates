# AI Config Templates

> 一套可切换的 AI 编码工作流脚手架：OpenSpec 规范驱动 + Graphify 代码图谱 + Claude/Codex/Gemini 协作。

把一套经过打磨的 AI 编码规则，一条命令装进任何项目；再用一条命令在不同「协作模式」之间切换。

- **规范驱动**：所有非平凡变更先写 OpenSpec 提案，`openspec/specs/` 是系统能力的唯一真相
- **模式可切换**：Claude 全包、Claude 设计+Codex 实现、Codex 全包……换模式只换项目级配置
- **代码图谱**：Graphify hook 在改代码前自动提供结构和影响面

---

## 安装

```bash
# 1. 克隆到独立工具目录（不要放进 ~/.claude 这类运行态目录）
mkdir -p ~/aicoding
git clone <repo-url> ~/aicoding/ai-config-templates

# 2. 装全局配置（写入 ~/.claude/CLAUDE.md 和 ~/.codex/AGENTS.md）
~/aicoding/ai-config-templates/v2/setup-global.sh

# 3. 进目标项目，装项目级配置
cd /path/to/your-project
~/aicoding/ai-config-templates/v2/setup-project.sh

# 4. 可选：装 Graphify 并首次建图
pip install graphifyy && graphify install
```

第 3 步默认装 `superpowers` 模式。想直接装成别的模式，加 `--mode=`：

```bash
# Claude 侧
~/aicoding/ai-config-templates/v2/setup-project.sh --mode=mps

# Codex 主用
~/aicoding/ai-config-templates/v2/setup-project.sh --mode=codex-codex-claude-flow-gpt55-dev
~/aicoding/ai-config-templates/v2/setup-project.sh --mode=codex-codex-claude-flow-gpt56-sol-dev
```

> 下文所有命令里的 `~/aicoding/ai-config-templates` 都是你第 1 步克隆的路径，按实际情况替换。

---

## 模式一览

模式决定**谁来写代码**、**用哪套工作流技能**。按「入口文件」分两类：入口是 `CLAUDE.md` 的由
Claude 主导；入口是 `AGENTS.md` 的是 Codex 主工作台，切过去会**删掉 `CLAUDE.md`**，Claude 不再参与。

| 模式 | 入口 | 谁写代码 | 工作流技能 |
|---|---|---|---|
| `superpowers` | `CLAUDE.md` | Claude | Superpowers（默认模式） |
| `mps` | `CLAUDE.md` | Claude | mattpocock-skills |
| `codex-dev` | `CLAUDE.md` | Codex 后端 / Gemini 前端 | Superpowers |
| `codex-mps-dev` | `CLAUDE.md` | Codex 后端 / Gemini 前端 | mattpocock-skills |
| `codex-codex-dev` | `AGENTS.md` | Codex 全包 | Codex 原生 |
| `codex-codex-mps-dev` | `AGENTS.md` | Codex 全包 | mattpocock-skills |
| `ecc` | `CLAUDE.md` | Claude | Everything Claude Code |
| `omc` | `CLAUDE.md` | Claude | Oh My ClaudeCode |
| `teams` | `CLAUDE.md` | Claude | Superpowers Teams |

Codex 主工作台还有几个按模型路由区分的变体：

| 模式 | 主 agent | worker / review |
|---|---|---|
| `codex-codex-claude-flow-gpt55-dev` | 5.5-xhigh | 5.4-xhigh |
| `codex-codex-claude-flow-gpt56-sol-dev` | 5.6-sol-xhigh | 5.5-xhigh |
| `codex-codex-claude-flow-dev` | — | 测试验证版，可忽略 |

```bash
~/aicoding/ai-config-templates/v2/scripts/switch-plugin.sh codex-codex-claude-flow-gpt55-dev
~/aicoding/ai-config-templates/v2/scripts/switch-plugin.sh codex-codex-claude-flow-gpt56-sol-dev
```

> 后续计划接入更多模型组合（dp-v4pro、glm 等）。

---

## 切换模式

### 会话内（推荐）

Claude Code 会话里直接用 slash 命令，不用退出：

```
/switch-profile mps
/switch-profile --status          # 看当前模式
/switch-profile --list            # 列出全部模式
/switch-profile mps --dry-run     # 预览影响，不落盘
```

### 命令行

```bash
cd /path/to/your-project
~/aicoding/ai-config-templates/v2/scripts/switch-plugin.sh mps
~/aicoding/ai-config-templates/v2/scripts/switch-plugin.sh --status
~/aicoding/ai-config-templates/v2/scripts/switch-plugin.sh mps --dry-run
```

**三条通用规则：**

1. **切换只对下一次会话生效**——切完要退出重开
2. 切到 `codex-*` 会**删除项目根 `CLAUDE.md`**，`/switch-profile` 会强制二次确认
3. **不能在模板仓库自己身上执行切换**（会覆盖仓库自带的模板文件），脚本会直接拒绝

---

## mps 模式（mattpocock-skills）

以「密集访谈 → 规范合成」为核心的工作流，来自
[mattpocock/skills](https://github.com/mattpocock/skills)。三个变体的区别只在**谁写代码**：
`mps`（Claude）、`codex-mps-dev`（Codex 后端 + Gemini 前端）、`codex-codex-mps-dev`（Codex 全包）。

首次使用要注册 marketplace：

```bash
claude plugin marketplace add mattpocock/skills
```

### 关键约定

**规范一律落到 `openspec/`，不发外部 issue tracker。**

上游 skill 默认把规范发到 GitHub/Linear，或写进 `.scratch/`。本脚手架通过
`docs/agents/issue-tracker.md` 改写了这个行为——该文件是上游 `/setup-matt-pocock-skills`
的 `Other` 选项设计的扩展点，skill 在读写 tracker 时会显式去读它。切到任一 mps 变体时自动安装，
三个变体共用同一份，落点语义不会分叉。

其余要点：

- 本模式**关闭 superpowers 插件**——`tdd`/`code-review`/`diagnosing-bugs`/`domain-modeling`
  和 superpowers 的四个同职责技能会互相争抢触发
- 依赖 `mattpocock-skills@mattpocock`，**pin 1.2.3**；上游升级后需重跑验收
- 已配 `deny` 规则拦截 `gh issue`/`gh secret`/`git push` 等外部写操作
- 领域术语表维护在项目根 `CONTEXT.md`
- **默认不用跑 `/setup-matt-pocock-skills`**（配置已预置）。真要跑，Section A 必须选 `Other`，
  **别选「本地文件」**——那个选项路径写死 `.scratch/`，没有指向 `openspec/` 的配置项

### `codex-mps-dev` 的交接流水线

Claude 不写代码，改为设计 + 编排 + 审查，走 6 阶段：

```
ANALYZE → DESIGN → HANDOFF → IMPLEMENT → REVIEW → VERIFY
```

交接由 `codex-handoff` 技能完成，包含可编辑文件白名单（FileAllowlist）和 git 基线；
`tasks.md` 里每个任务标注 `Executor: Codex|Gemini|Claude`。

---

## 日常使用

一个中等任务从头到尾（以 `mps` 为例）：

```
/grill-with-docs     ① 密集访谈澄清需求 → docs/plans/YYYY-MM-DD-*-design.md
                        术语增量自动进 CONTEXT.md
/to-spec             ② 合成规范 → openspec/changes/<id>/proposal.md + spec deltas
                        ⚠️ 到此停下等审批。发布 ≠ 批准
/to-tickets          ③ 拆成小任务 → tasks.md 的编号条目
/implement           ④ 按 tasks.md 逐条实现，强制 TDD，code-review 自动触发
                     ⑤ 粘贴真实测试输出后才能声称完成
/openspec:archive    ⑥ 合并 delta 到 openspec/specs/，归档
```

- **大任务**在 ② 和 ③ 之间插一步 `/wayfinder` 建决策地图，逐个决策解决后再拆解
- **小任务**（bug 修复、改动 < 3 文件）不走这条链，直接 `diagnosing-bugs` → `tdd` → 验证
- 不确定该用哪个技能时，问 `/ask-matt`

其他模式的链路不同（`superpowers` 用 `brainstorming` → `/openspec:proposal` → `writing-plans`），
但**都以 OpenSpec 提案为准入、以归档为终点**。具体见切换后项目根 `CLAUDE.md` 的工作流章节。

OpenSpec 命令在所有模式下通用：

- `/openspec:proposal` 创建提案
- `/openspec:apply` 实现已批准的变更
- `/openspec:archive` 归档

---

## Graphify

代码图谱。可用时在改代码前自动提供结构和影响面上下文，不可用时记录降级原因并继续，不阻断任务。

```bash
pip install graphifyy && graphify install
/graphify .                      # 项目首次建图
```

安装脚本会把 hook 装到 Claude 和 Codex 两侧。维护细节见 `docs/graphify-integration.md`。

---

## MCP

`.mcp.json` 预置三个 server：

| 名称 | 命令 |
|---|---|
| `codex` | `codex mcp-server` |
| `gemini-cli` | `npx -y gemini-mcp-tool` |
| `opencode` | `npx -y opencode-mcp` |

项目初始化时会把 `.mcp.json`、`opencode.json`、`AGENTS.md` 和 OpenCode graphify 插件模板一并复制过去。

---

## 常见问题

**切换报「检测到漂移，但当前不是交互终端」（退出码 2）**
入口文件被手工改过。跑 `/setup-matt-pocock-skills` 会追加 `## Agent skills` 块，必然触发。
先看清改了什么——确认可以丢弃就加 `--force-overwrite`，想保留就先提交或备份。

**切换报「当前目录是模板仓库本身」**
你在模板仓库里执行了切换。到目标项目目录再跑。

**`/switch-profile` 找不到 `switch-plugin.sh`**
项目配置是旧版初始化的，没记录模板路径。命令会自动回退：环境变量
`AI_CONFIG_TEMPLATES_ROOT` → 已知候选路径；机器上有多个模板副本时会挑有该模式的那个。
**成功切换一次后路径会写回配置，之后不用再猜。**

**mattpocock skill 没出现在 `/plugin` 里**
marketplace 没注册，或者切换后没重启会话。

**切换后感觉配置没生效**
切换只对下一次会话生效。退出，重开。

---

## 目录结构

```text
ai-config-templates/
├── v2/
│   ├── setup-global.sh              # 全局配置初始化
│   ├── setup-project.sh             # 项目配置初始化
│   ├── global/                      # 全局 CLAUDE.md / AGENTS.md
│   ├── graphifyignore.template
│   └── scripts/
│       ├── switch-plugin.sh         # 模式切换器
│       └── plugin-profiles/
│           ├── shared/              # 所有模式共享的 hooks / skills / commands
│           ├── mps/                 # 各模式的差异化配置
│           ├── codex-mps-dev/
│           └── ...
├── openspec/                        # 本仓库自身的 OpenSpec 规范与变更历史
├── tests/                           # 切换器与模板的回归测试
├── docs/graphify-integration.md
├── CONTEXT.md                       # 本仓库的领域术语表
├── AGENTS.md                        # OpenCode/Codex 项目指令模板
├── settings.json                    # Claude Code settings 模板
└── .mcp.json                        # MCP server 模板
```

> `scripts/`、`setup-global.sh`、`setup-claude-config.sh` 与根 `CLAUDE.md` 是旧版遗留，
> **已停止维护**，不再接收新模式和修复。新项目不要用。

---

## 维护

- 新能力优先加到 `v2/scripts/plugin-profiles/shared/`，再按模式做差异化覆盖
- 只属于某个模式的规则，放进对应的 profile 目录
- 改 hooks 或 settings 后，至少跑一遍 JSON 校验和 `bash -n`
- 新增模式模板后**先 `git add` 再跑测试**——`tests/test_ai_commit_attribution.py` 用
  `git ls-files` 枚举模板，未追踪的文件会被静默跳过
- 改脚手架行为前，先在 `openspec/changes/` 下写 proposal 和 tasks

```bash
python3 -m unittest discover -s tests
```

---

## License

MIT
