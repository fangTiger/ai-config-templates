# Design: mps profile 与 /switch-profile 命令

## 上下文

`mattpocock/skills`（`mattpocock-skills` v1.2.3，MIT，自带 `.claude-plugin/marketplace.json`）提供 21 个 skill，分两类：

- **user-invoked**（`disable-model-invocation: true`）：`ask-matt`、`grill-with-docs`、`to-spec`、`to-tickets`、`implement`、`wayfinder`、`triage`、`improve-codebase-architecture`、`setup-matt-pocock-skills`
- **model-invoked**：`tdd`、`code-review`、`codebase-design`、`diagnosing-bugs`、`domain-modeling`、`research`、`prototype`、`resolving-merge-conflicts`、`wizard`

主链路：`ask-matt → grill-with-docs/domain-modeling → to-spec → to-tickets → implement(tdd + code-review) → wayfinder`

---

## 决策 1：规范真相源保留 OpenSpec，mattpocock 作为交互层

### 冲突

`to-spec` 的默认行为是把规范发布到 issue tracker 并打 `ready-for-agent` 标签，`CONTEXT.md` + ADR + issue 历史构成其真相源。这与项目宪章第 1 条（规范先行走 OpenSpec）和第 6 条（`openspec/specs/` 是唯一真相）直接冲突——两套真相源并存必然漂移。

### 决策

保留 OpenSpec 为唯一真相源，在 `mps/CLAUDE.md` 中以**产出落点映射表**约束每个 skill 的写入位置：

| mattpocock skill | 触发 | 产出落点 |
|---|---|---|
| `/grill-with-docs` | 用户 | `docs/plans/YYYY-MM-DD-{topic}-design.md` |
| `/to-spec` | 用户 | `openspec/changes/<id>/proposal.md` + `specs/<cap>/spec.md` delta，**禁止发 issue tracker** |
| `/to-tickets` | 用户 | `openspec/changes/<id>/tasks.md` 的编号条目（不建 `issues/`、不建 `.scratch/`） |
| `/implement` | 用户 | 等价 `/openspec:apply`，按 tasks.md 顺序执行 |
| `/wayfinder` | 用户 | 大任务决策票落 `openspec/changes/<id>/design.md` |
| `/improve-codebase-architecture` | 用户 | 报告落 `docs/plans/` |
| `tdd` | 模型 | 直接使用（等价 RED-GREEN-REFACTOR） |
| `code-review` | 模型 | 直接使用（双轴：标准符合 + spec 保真） |
| `diagnosing-bugs` | 模型 | 直接使用（替代 `systematic-debugging`） |
| `domain-modeling` | 模型 | 维护项目根 `CONTEXT.md` |
| `codebase-design` / `research` / `prototype` / `resolving-merge-conflicts` / `wizard` | 模型 | 直接使用，无落点约束 |

### 落点的**实现方式**：走 skill 原生扩展点，而非 prompt 声明（Codex 交叉验证后修正）

初版实现是在 `mps/CLAUDE.md` 写一句「本表优先级高于 skill 正文」。**该做法被否决**，因为交叉验证
阶段实读上游 skill 原文后发现三条硬事实：

1. `to-tickets/SKILL.md` 对本地模式写死 `.scratch/<f>/issues/NN-<slug>.md`，并明确
   **"one file per ticket, never a single combined file"**。一句 prompt 层的优先级声明
   压不住这种显式禁令。
2. `setup-matt-pocock-skills/issue-tracker-local.md` 的路径写死 `.scratch/`，
   **不存在**「文档位置指向 openspec/」这个配置项——初版 CLAUDE.md 和 README 的指引是错的。
3. `setup-matt-pocock-skills/SKILL.md` Section A 有 **Other** 选项：
   "ask the user to describe the workflow in one paragraph; the skill will record it as
   freeform prose"，产物落在 `docs/agents/issue-tracker.md`。而各 skill 在需要读写 tracker 时
   **显式去读该文件**。

因此正确做法是**填充 skill 自己设计的扩展点**：mps profile 预置一份 OpenSpec 版
`docs/agents/issue-tracker.md`，逐项应答 skill 正文的三个查询锚点
（"publish to the issue tracker" / "fetch the relevant ticket" / "apply the ready-for-agent label"），
并正面化解「一票一文件」冲突——说明 OpenSpec 下稳定标识由任务编号承载、独立状态由行内 checkbox
承载，两个约束目的均已满足，故不拆文件。

`CLAUDE.md` 的映射表降级为速查摘要，并声明冲突时以 `docs/agents/issue-tracker.md` 为准。

### 决策 1b：新增通用 `project-files/` 安装机制

`docs/agents/issue-tracker.md` 落在项目根，不在 `.claude/` 下，现有 `SWITCHABLE_DIRS` 机制覆盖不到。
新增通用约定：**profile 目录下的 `project-files/**` 按相对路径复制到项目根**。

- 做成通用机制而非 mps 专属分支，避免在 `switch-plugin.sh` 里堆 profile 特判
- 切换离开时**不清理**：这些是普通项目文档，误删比留下危险得多
- 代价：切到别的 profile 后文件仍在。可接受——彼时 mattpocock skill 已禁用，文件无效但无害

### 备选与否决理由

- **原生 mattpocock 流程**（spec 发 issue tracker）：放弃宪章 1/6 条，且 `openspec/specs/` 下已有 3 个 capability、22 条需求会失去维护入口。否决。
- **双载体并存**（OpenSpec 归档 + issue 看板）：信息最全但需手工双写，漂移不可避免。否决。

---

## 决策 2：mps 模式下关闭 superpowers 插件

### 问题

`tdd` vs `test-driven-development`、`code-review` vs `requesting-code-review`、`diagnosing-bugs` vs `systematic-debugging`、`domain-modeling` vs `brainstorming` 是四组同职责 skill。两个插件同时启用时，model-invoked 触发会在同职责 skill 间随机命中，行为不可预测。

### 决策

`mps/settings.json` 中 `superpowers@superpowers-marketplace: false`。

### 能力缺口与补齐

mattpocock 没有对应物的两项能力，改为 `mps/CLAUDE.md` **内联规则**，不新建 skill（避免 skill 数量膨胀）：

| 缺失能力 | 补齐方式 |
|---|---|
| `verification-before-completion` | CLAUDE.md 保留宪章第 5 条「证据先于断言」，并在 Stage 2 TESTING 显式要求粘贴测试输出 |
| `finishing-a-development-branch` | CLAUDE.md Stage 3 内联分支集成检查清单 |
| `session-recovery` | 已在 `shared/skills/session-recovery/`，切换时自动复制，不受影响 |
| 多 AI 交叉验证（Codex/Gemini） | CLAUDE.md 原样保留 superpowers profile 的 Section 4，与插件无关 |

---

## 决策 3：/switch-profile 的模板路径解析

### 问题（阻塞点）

`switch-plugin.sh` 位于模板仓库（README 用 `~/aicoding/ai-config-templates/`，脚本自身注释用 `~/.claude/config-templates/`），但**目标项目没有任何地方记录该路径**——现有 `.claude/.harness-manifest.json` 只有 `manifestSchemaVersion / harnessVersion / role / mode / globalVersionRequired / sourceRevision / templateHash / managedAssets / installedAt / switchedAt`。

### 决策：manifest 新增字段 + 候选路径回退

1. `v2/setup-project.sh` 写入 `templateRoot`（`$V2_DIR/..` 的绝对路径），`manifestSchemaVersion` 升至 `2`
2. `/switch-profile` 解析顺序：
   1. `.claude/.harness-manifest.json` 的 `templateRoot`
   2. 环境变量 `AI_CONFIG_TEMPLATES_ROOT`
   3. 候选路径探测：`~/aicoding/ai-config-templates`、`~/.claude/config-templates`
   4. 全部失败 → 输出修复指引（重跑 `setup-project.sh` 或显式设置环境变量），**不静默失败**
3. 解析到的路径必须校验 `<root>/v2/scripts/switch-plugin.sh` 存在且可执行

### 兼容性

`manifestSchemaVersion: 1` 的既有项目不会被破坏——命令走第 2/3 步回退。`switch-plugin.sh` 的 `update_manifest` 只改 `mode`/`templateHash`/`switchedAt`，不会擦除 `templateRoot`。

---

## 决策 4：/switch-profile 的会话内执行风险

`switch-plugin.sh` 在会话运行中执行会产生三个真实副作用：

| 风险 | 表现 | 处置 |
|---|---|---|
| R1 hooks 目录被重建 | `clean_switchable` 对 `.claude/hooks` 做 `find -exec rm -rf`（`switch-plugin.sh:356-361`），当前会话已注册的 hook 命令在重建窗口内可能执行失败 | 命令正文明确提示「切换期间勿并发操作」，切换后必须重启会话 |
| R2 切到 codex-native 会删除 CLAUDE.md | `switch-plugin.sh:567` 执行 `rm -f "$PROJECT_DIR/CLAUDE.md"`，等于在 Claude 会话内自毁项目配置 | 目标匹配 `codex-*` 时**强制二次确认**，并说明后续需改用 Codex CLI |
| R3 漂移检测需要交互输入 | 漂移分支执行裸 `read confirm`；`set -e` 下无 stdin 时**静默退出** | 已在脚本层修复（决策 7）：非 TTY 时以退出码 2 明确失败 + 新增 `--force-overwrite` |

命令定位为**外部脚本的会话内封装**，不重新实现切换逻辑——避免出现第二套需要同步维护的切换代码。

---

## 决策 5：skill-rules.json 是全量覆盖而非增量

`switch-plugin.sh:574-586` 先复制 `shared/`，再复制 `profile/`，同名文件后者覆盖前者。因此 `mps/skills/skill-rules.json` 必须是**完整文件**（包含 shared 里 `dev-workflow`/`git-workflow`/`openspec-workflow` 等条目 + mattpocock 新增触发词），不能只写增量条目，否则 shared 的触发规则会全部丢失。

`superpowers/skills/skill-rules.json` 已是同样模式，实现时以其为基线修改。

---

## 决策 6：CONTEXT.md 与 openspec/project.md 的分工

| 文件 | 职责 | 维护者 |
|---|---|---|
| `openspec/project.md` | 项目约定：技术栈、目录结构、构建/测试命令 | 人工 |
| `CONTEXT.md`（项目根） | 领域术语表：业务概念、缩写、状态机命名 | `domain-modeling` skill 自动维护 |

两者不重叠。`CONTEXT.md` 放项目根而非 `openspec/` 内，因为 mattpocock skill 默认在仓库根查找该文件。

---

## 风险登记

| ID | 风险 | 影响 | 缓解 |
|---|---|---|---|
| R4 | **插件键名未经实机验证** | `settings.json` 写错 key 会导致插件静默不加载 | 实现时先执行 `claude plugin marketplace add mattpocock/skills`，用 `/plugin` 界面确认真实 key 后再写入；tasks.md 已列为独立前置任务 |
| R5 | `setup-matt-pocock-skills` 会配置 issue tracker，并向 `CLAUDE.md` 追加 `## Agent skills` 块 | 覆盖落点配置 + 制造 manifest 漂移 | **默认不跑它**（profile 已预置其 Section A/C 产物）。必须跑时选 **Other**（不是「本地文件」——该模式路径写死 `.scratch/`，无 openspec 选项，见决策 1），跑完重跑 `switch-plugin.sh mps` 恢复 |
| R6 | `.codex/skills/` 下为英文原样副本，正文含 "publish to issue tracker" 字样，与 `AGENTS.md` 冲突 | Codex 可能按 skill 正文行事 | `AGENTS.md` 顶部以「铁律」形式声明落点映射覆盖 skill 正文；阶段 B 验证时重点观察 |
| R7 | 上游 skill 升级后落点约束失效 | 静默漂移 | `README.md` 记录 pin 的版本（当前 1.2.3）；升级需重跑阶段 A 验收 |
| R8 | ~~v1 与 v2 profile 集合不一致~~ | **已作废** | 用户确认 V1 不再维护，该风险不成立 |
| R9 | **多模板副本**（实现期实测发现）：机器上同时存在 `~/aicoding/ai-config-templates`（已部署，rev 9181228，无 mps）与开发副本（rev a849604，有 mps）。候选路径回退会静默命中前者 | `/switch-profile mps` 报「未知 profile」，且用户不知道原因 | 命令增加步骤 1b：执行前校验 `<root>/v2/scripts/plugin-profiles/<profile>/` 存在，缺失时中止并列出该副本可用 profile。**根治需用户决定以哪个副本为准并同步** |

| R10 | **cwd 误报**（实现期实测发现）：`switch-plugin.sh` 用 `PROJECT_DIR="$(pwd)"` 判定目标项目，在子目录执行时静默输出「项目版本: 未初始化」而非报错 | 用户以为项目没装 harness，做出错误处置 | 命令增加步骤 1c：向上查找含 `.claude/.harness-manifest.json` 的最近目录作为项目根，所有调用显式 `cd` 到该目录，不依赖 shell cwd |

### R9 补充说明

本项目 manifest 的 `sourceRevision: 9181228` 指向 `~/aicoding` 副本，说明项目是从该副本初始化的。
mps 要在其他项目可用，必须把本次变更同步到 `~/aicoding/ai-config-templates`（或改以开发副本为准）。
两副本的 profile 集合已有分歧：`~/aicoding` 副本仍保留已被移除的 `codex-codex-python-dev`。
该同步动作超出本变更范围，需用户决策。

---

## 决策 7：非交互环境下的漂移处置（Codex 交叉验证后新增）

### 问题（真 bug，非理论风险）

`switch-plugin.sh` 顶部是 `set -euo pipefail`，漂移分支执行裸 `read confirm`。在无 stdin 的
非交互环境（正是 `/switch-profile` 的运行场景）下 `read` 返回 1，`set -e` 令脚本**立即静默退出**，
连「已取消切换」都不打印。用户只看到命令莫名失败。

初版测试没能发现该缺陷，因为测试辅助函数 `run_cmd` 给每个子进程注入了 `"n\nn\nn\n"`，
恰好喂饱了 `read`——**测试掩盖了 bug**。

而且该路径几乎必然被触发：`/setup-matt-pocock-skills` 会向 `CLAUDE.md` 追加 `## Agent skills` 块，
直接改变入口文件 hash。

### 决策

1. 漂移分支先判 `[[ -t 0 ]]`；非 TTY 时以**退出码 2** 明确失败，并打印两条可执行出路
2. 新增 `--force-overwrite` 显式跳过确认，供人工确认后使用
3. `/switch-profile` 命令负责把漂移内容呈现给用户，**禁止自作主张加 `--force-overwrite`**
4. 新增两个**不注入 stdin** 的行为测试，覆盖失败路径与 `--force-overwrite` 路径

实测输出（退出码 2）：

```
⚠ 检测到 profile 入口文件已被手动修改
✗ 检测到漂移，但当前不是交互终端，无法确认
请任选其一：
  1. 在外部终端执行: cd <项目> && <switcher> mps
  2. 确认要丢弃本地修改后重跑: <switcher> mps --force-overwrite
```

---

## 决策 8：mps 的 deny 规则

第三方插件扩大了攻击面，且这些不是理论风险，是 skill 正文里写明的行为：

| skill | 行为 | 出处 |
|---|---|---|
| `to-spec` / `to-tickets` / `triage` | 创建、评论、改标签、关闭外部 issue | SKILL.md 正文 |
| `triage` | 读取外部 issue、评论、PR diff → **prompt injection 入口** | triage/SKILL.md |
| `implement` | 自动 commit 当前分支 | implement/SKILL.md |
| `wizard` | 触碰 `.env`、GitHub secrets / variables | wizard/SKILL.md |

而 mps 沿用了 `Bash:*` + `acceptEdits`。补 deny：

```
Bash(gh issue:*)  Bash(gh api:*)  Bash(gh secret:*)  Bash(gh variable:*)
Bash(glab issue:*)  Bash(glab api:*)  Bash(glab mr:*)
Bash(git push:*)  Bash(git push --force:*)  Bash(rm -rf /:*)
```

**已知局限（诚实记录）**：字符串 deny 可被 `git -C … push`、Python HTTP 请求等绕过。
彻底修复需要移除 `Bash:*` 白名单并改回逐次确认，但那会改变全部 profile 的既有交互习惯，
**超出本变更范围，需用户单独决策**（见下方「待用户决策」）。

---

## 待用户决策（本变更范围外）

Codex 交叉验证提出、我判断**不应在本变更内擅自执行**的三项：

| 项 | 内容 | 为什么不在本变更做 |
|---|---|---|
| D1 | 移除 `Bash:*`、改 `defaultMode` 为需确认 | 会改变全部 profile 的既有交互习惯，是产品级决策 |
| D2 | 切换流程事务化（staging 目录 + 原子 rename + 失败回滚） | 重写 `switch-plugin.sh` 核心，风险高于本变更收益；且是既有设计问题，非 mps 引入 |
| D3 | fork mattpocock skill 正文改写为 OpenSpec 原生 | 维护成本高；先用扩展点方案跑一轮验证是否够用 |

另外两项**既有缺陷**（非本变更引入，已记录待办）：

- `update_manifest` 在无 python3/jq 时静默不执行，调用方仍报成功
- 切换非事务：清理后复制失败会留下半切换状态；`ok=false` 不影响退出码，仍打印「切换完成」
