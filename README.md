# AI Config Templates

> 一套可切换的 AI 编码工作流脚手架：OpenSpec 规范驱动 + Claude/Codex/Gemini 协作。

把一套经过打磨的 AI 编码规则，一条命令装进任何项目；再用一条命令在不同「协作模式」之间切换。

- **规范驱动**：所有非平凡变更先写 OpenSpec 提案，`openspec/specs/` 是系统能力的唯一真相
- **模式可切换**：Claude 全包、Claude 设计+Codex 实现、Codex 全包……换模式只换项目级配置

---

## 安装

分两层，**顺序不能反**：全局装一次，然后每个项目各装一次。

### 第 1 步：克隆仓库（每台机器一次）

```bash
# 放进独立工具目录，不要放进 ~/.claude 这类运行态目录
mkdir -p ~/aicoding
git clone <repo-url> ~/aicoding/ai-config-templates
```

> 下文所有命令里的 `~/aicoding/ai-config-templates` 都是这里克隆的路径，按你的实际位置替换。
> **务必用完整路径**——脚本靠自身位置定位模板，路径写错会装到错误的副本上。

### 第 2 步：装全局配置（每台机器一次）

```bash
~/aicoding/ai-config-templates/v2/setup-global.sh
```

写入 `~/.claude/CLAUDE.md`、`~/.codex/AGENTS.md`，以及全局标记
`~/.claude/.harness-manifest.json`。**后面每一步都要读这个标记文件**，所以这步不能跳。

### 第 3 步：初始化项目（每个项目一次）

```bash
cd /path/to/your-project      # 必须在项目根目录
~/aicoding/ai-config-templates/v2/setup-project.sh
```

写入项目的 `.claude/`、`.codex/`、`CLAUDE.md` 和项目标记
`.claude/.harness-manifest.json`。**没做这步就不能切换模式。**

默认装 `superpowers`。想一步到位装成别的模式，加 `--mode=`：

```bash
# mattpocock 工作流（推荐）
~/aicoding/ai-config-templates/v2/setup-project.sh --mode=mps
~/aicoding/ai-config-templates/v2/setup-project.sh --mode=codex-mps-dev
~/aicoding/ai-config-templates/v2/setup-project.sh --mode=codex-codex-mps-dev

# Codex 主工作台，按模型路由选（详见下方「模式一览」）
~/aicoding/ai-config-templates/v2/setup-project.sh --mode=codex-codex-claude-flow-gpt55-dev
~/aicoding/ai-config-templates/v2/setup-project.sh --mode=codex-codex-claude-flow-gpt56-sol-dev
```

带了 `--mode=` 就不用再单独执行切换命令。全部可选模式见下方[模式一览](#模式一览)。

### 第 4 步：装模式对应的插件

看下方[插件对照表](#每个模式需要装什么插件)——**只装你实际会用的那个**，不用全装。

### 装完检查

```bash
ls ~/.claude/.harness-manifest.json          # 第 2 步的产物
ls /path/to/your-project/.claude/.harness-manifest.json   # 第 3 步的产物
```

两个都在，就可以切换模式了。

---

## 模式一览

### 先选：你想让谁写代码

| 你的场景 | 用这个 | 切换命令 |
|---|---|---|
| Claude 全程干活 | `mps` | `switch-plugin.sh mps` |
| Claude 出方案、**Codex 写代码** | `codex-mps-dev` | `switch-plugin.sh codex-mps-dev` |
| **全程在 Codex CLI 里干**，不开 Claude | `codex-codex-mps-dev` | `switch-plugin.sh codex-codex-mps-dev` |

以上是 mattpocock 工作流（本仓库当前推荐）。如果你更习惯 Superpowers，把上面三个换成
`superpowers`、`codex-dev`、`codex-codex-dev`，角色分工完全一样，只是工作流技能不同。

> **`codex-dev` 和 `codex-mps-dev` 容易混。** 两个都是「Claude 设计 + Codex 实现」，
> 唯一区别是工作流技能：前者用 `superpowers:brainstorming` → `writing-plans`，
> 后者用 `/grill-with-docs` → `/to-spec` → `/to-tickets`。`codex-codex-dev` 与
> `codex-codex-mps-dev` 同理。

### 全部模式

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

### 每个模式需要装什么插件

**插件不是必须全装**——只装你实际会用的模式所需的那个。切换 profile 时会自动开关
`enabledPlugins`，但**插件本身得先装到 Claude Code 里**，否则切过去是空的。

| 你要用的模式 | 需要预先安装 | 安装命令 |
|---|---|---|
| `superpowers`、`teams`、`codex-dev` | Superpowers | `claude plugin marketplace add obra/superpowers-marketplace` |
| `mps`、`codex-mps-dev`、`codex-codex-mps-dev` | mattpocock-skills | `claude plugin marketplace add mattpocock/skills` |
| `ecc` | Everything Claude Code | 见该插件仓库 |
| `omc` | Oh My ClaudeCode | 见该插件仓库 |
| `codex-codex-*`（非 mps） | **无需任何 Claude 插件** | — |

两条要点：

- **只用 mps 系列的话，Superpowers 完全不用装。** mps 模式会主动关闭 superpowers——两者的
  `tdd`/`code-review`/`diagnosing-bugs`/`domain-modeling` 与 superpowers 的四个同职责技能
  会互相争抢触发。
- **`codex-codex-*` 模式下 Claude 不参与**（入口是 `AGENTS.md`），所以任何 Claude 插件在那里
  都不生效。这些 profile 的 `settings.json` 里仍保留着插件开关，纯属历史遗留，不影响使用。

---

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

**切换前必读：**

1. **切换只对下一次会话生效**——切完要退出重开对应的 CLI
2. 切到 `codex-codex-*` 会**删除项目根 `CLAUDE.md`**（改用 `AGENTS.md`），
   `/switch-profile` 会强制二次确认。之后要在 Codex CLI 里工作，Claude 会话不再加载项目配置
3. **不能在模板仓库自己身上执行切换**——会覆盖仓库自带的模板文件，脚本直接拒绝
4. **⚠️ 在两个 `codex-codex-*` 模式之间切换会重置 `.codex/session-state.md`**

关于第 4 条：session-state 里记录着进行中任务的 ChangeId、当前阶段、文件白名单等。
切换器会校验文件里的 `## Mode:` 是否匹配目标模式，不匹配就按新模板重新初始化——
**你手工加的内容会丢**。有进行中的任务就先备份：

```bash
cp .codex/session-state.md /tmp/session-state.bak
```

同模式内重复切换（例如 `--reset-session-state` 之外的场景）会保留原内容，只有跨模式才重置。

### 找不到 `switch-plugin.sh` 或报「未知 profile」

如果机器上有**多个模板仓库副本**（例如一个早期部署的 + 一个最新的），旧副本可能没有你要的模式。
`/switch-profile` 会自动在候选副本中挑有该模式的那个；用命令行时则要确保路径指向正确的副本：

```bash
# 确认某个副本有没有你要的模式
ls <模板仓库路径>/v2/scripts/plugin-profiles/
```

切换成功后，模板路径会写回项目的 `.claude/.harness-manifest.json`，之后 `/switch-profile`
直接命中，不用再指定。

---

## mps 模式（mattpocock-skills）

以「密集访谈 → 规范合成」为核心的工作流，来自
[mattpocock/skills](https://github.com/mattpocock/skills)。三个变体的区别只在**谁写代码**：
`mps`（Claude）、`codex-mps-dev`（Codex 后端 + Gemini 前端）、`codex-codex-mps-dev`（Codex 全包）。

首次使用要注册 marketplace（见上方插件对照表）：

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


---

## MCP

`.mcp.json` 预置两个 server：

| 名称 | 命令 |
|---|---|
| `codex` | `codex mcp-server` |
| `gemini-cli` | `npx -y gemini-mcp-tool` |

项目初始化时会把 `.mcp.json` 和 `AGENTS.md` 一并复制到目标项目。

---

## 常见问题

### 报错：`错误: 全局 manifest 不存在`

第 2 步没做，或者跑错了脚本。**装全局只有这一条命令**：

```bash
~/aicoding/ai-config-templates/v2/setup-global.sh
```

注意路径里的 `v2/`。仓库根目录下另有一个同名的 `setup-global.sh`，那是早期版本的遗留文件，
**它不写 manifest**，跑了等于没跑。

如果确认跑过了还报这个错，检查 `$HOME` 是不是被改了——比如用了 `sudo`，那样脚本会去
`/var/root/.claude/` 找，当然找不到。**不要用 sudo 跑这些脚本。**

```bash
ls ~/.claude/.harness-manifest.json     # 确认全局标记存在
```

### 报错：`错误: 项目 manifest 不存在（未初始化 V2）`

第 3 步没做。切换模式之前必须先初始化项目：

```bash
cd /path/to/your-project      # 必须在项目根，不能在子目录
~/aicoding/ai-config-templates/v2/setup-project.sh
```

切换器是按**当前工作目录**判断项目的。在子目录里跑，它会去子目录找 `.claude/`，
找不到就报这个错——即使项目根其实已经初始化过了。

```bash
ls /path/to/your-project/.claude/.harness-manifest.json   # 确认项目标记存在
```

### ⚠️ 在两个 `codex-codex-*` 模式之间切换会重置 `.codex/session-state.md`

`session-state.md` 记录着进行中任务的 ChangeId、当前阶段、文件白名单等。切换器会校验文件里的
`## Mode:` 是否匹配目标模式，**不匹配就按新模板重新初始化——你手工加的内容会丢**。

手上有进行中的任务，切换前先备份：

```bash
cp .codex/session-state.md /tmp/session-state.bak
```

同一模式内重复切换会保留原内容，只有跨模式才重置。

### 切换报「检测到漂移，但当前不是交互终端」（退出码 2）
入口文件被手工改过。跑 `/setup-matt-pocock-skills` 会追加 `## Agent skills` 块，必然触发。
先看清改了什么——确认可以丢弃就加 `--force-overwrite`，想保留就先提交或备份。

### 切换报「当前目录是模板仓库本身」

你在模板仓库里执行了切换。到目标项目目录再跑。

### `/switch-profile` 找不到 `switch-plugin.sh`

项目配置里没记录模板路径（早期版本装的）。命令会自动回退：环境变量
`AI_CONFIG_TEMPLATES_ROOT` → 已知候选路径；机器上有多个模板副本时会挑有该模式的那个。
**成功切换一次后路径会写回配置，之后不用再猜。**

### mattpocock skill 没出现在 `/plugin` 里

marketplace 没注册，或者切换后没重启会话。

### 切换后感觉配置没生效

切换只对下一次会话生效。退出，重开。

---

## 目录结构

```text
ai-config-templates/
├── v2/
│   ├── setup-global.sh              # 全局配置初始化
│   ├── setup-project.sh             # 项目配置初始化
│   ├── global/                      # 全局 CLAUDE.md / AGENTS.md
│   └── scripts/
│       ├── switch-plugin.sh         # 模式切换器
│       └── plugin-profiles/
│           ├── shared/              # 所有模式共享的 hooks / skills / commands
│           ├── mps/                 # 各模式的差异化配置
│           ├── codex-mps-dev/
│           └── ...
├── openspec/                        # 本仓库自身的 OpenSpec 规范与变更历史
├── tests/                           # 切换器与模板的回归测试
├── CONTEXT.md                       # 本仓库的领域术语表
├── settings.json                    # Claude Code settings 模板
└── .mcp.json                        # MCP server 模板
```

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
