# Tasks: mps profile 与 /switch-profile 命令

> 阶段 A = Claude 侧 + 命令 + 配套；阶段 B = Codex 侧。A 验收通过后再进入 B。

## 0. 前置确认（阻塞后续所有任务）

- [x] 0.1 注册 marketplace 并确认插件真实键名
  - 执行 `claude plugin marketplace add mattpocock/skills`
  - 查看 marketplace 缓存的 `.claude-plugin/marketplace.json` 与 `known_marketplaces.json`，记录 `enabledPlugins` 的真实 key
  - **实测结果：`mattpocock-skills@mattpocock`**（提案原推断 `mattpocock-skills@mattpocock-skills` 有误，见 design R4）
  - 验证：把实测 key 记录到本文件下方「实测记录」节
- [x] 0.2 确认 `npx skills@latest add mattpocock/skills` 可用且能选择 Codex 目标（阶段 B 依赖）
  - 验证：`npx skills@latest --help` 有输出

## 阶段 A-1. manifest 与模板路径

- [x] A1.1 `v2/setup-project.sh`：写 manifest 处新增 `templateRoot` 字段（值为模板仓库绝对路径），`manifestSchemaVersion` 由 `1` 改为 `2`
  - 验证：`bash -n v2/setup-project.sh`
- [x] A1.2 在临时目录跑一次 `v2/setup-project.sh`，确认生成的 `.claude/.harness-manifest.json` 含 `templateRoot` 且路径下 `v2/scripts/switch-plugin.sh` 存在
  - 验证：`python3 -c "import json;d=json.load(open('<tmp>/.claude/.harness-manifest.json'));print(d['manifestSchemaVersion'],d['templateRoot'])"`
- [x] A1.3 确认 `switch-plugin.sh` 的 `update_manifest`（`v2/scripts/switch-plugin.sh:250-270`）不会擦除 `templateRoot`
  - 验证：切换一次后重新读取 manifest，`templateRoot` 仍在

## 阶段 A-2. /switch-profile slash 命令

- [x] A2.1 新建 `v2/scripts/plugin-profiles/shared/commands/switch-profile.md`
  - frontmatter 含 `description` 与 `argument-hint`
  - 正文写明路径解析四步顺序（manifest → `AI_CONFIG_TEMPLATES_ROOT` → 候选路径 → 报错指引，见 design 决策 3）
  - 正文写明目标匹配 `codex-*` 时**强制二次确认**（design R2）
  - 正文写明切换后必须重启会话
- [x] A2.2 同步到 `.claude/commands/switch-profile.md`（本仓库自身也要能用）
  - 验证：`ls .claude/commands/switch-profile.md`
- [x] A2.3 手工验证 `/switch-profile --status` 与 `/switch-profile --list` 能正确输出
  - 验证：粘贴实际输出到本文件「实测记录」节

## 阶段 A-3. mps profile 文件

- [x] A3.1 `v2/scripts/plugin-profiles/mps/settings.json`
  - 以 `superpowers/settings.json` 为基线
  - `superpowers@superpowers-marketplace: false`；加入 0.1 实测得到的 mattpocock key 为 `true`
  - hooks 三段（UserPromptSubmit / PreToolUse / PostToolUse）原样保留
  - 验证：`python3 -m json.tool v2/scripts/plugin-profiles/mps/settings.json`
- [x] A3.2 `v2/scripts/plugin-profiles/mps/CLAUDE.md` — 骨架与头部
  - 三行 harness 注释，`<!-- harness-mode: mps -->`
  - Section 0 宪章：6 条原样保留
  - Graphify 章节原样保留
  - 验证：`grep -c "harness-mode: mps" v2/scripts/plugin-profiles/mps/CLAUDE.md` 输出 1
- [x] A3.3 `mps/CLAUDE.md` — 新增「产出落点映射」节；**权威定义指向 `docs/agents/issue-tracker.md`**
  （初版写成「本表优先级高于 skill 正文」，经 Codex 交叉验证证伪后改为走 skill 原生扩展点，见 design 决策 1）
- [x] A3.4 `mps/CLAUDE.md` — 工作流章节：把 superpowers 的 5.1/5.2/5.3 流程中的 skill 名替换为 mattpocock 对应物
  - 小任务：`diagnosing-bugs → tdd → 证据验证`
  - 中任务：`grill-with-docs → to-spec → to-tickets → implement`
  - 大任务：中任务链路 + `wayfinder`
- [x] A3.5 `mps/CLAUDE.md` — 内联补齐 `verification-before-completion` 与 `finishing-a-development-branch`（design 决策 2）
- [x] A3.6 `mps/CLAUDE.md` — 保留 Section 4 多 AI 交叉验证表、Section 8 MCP 规范、Git Commit trailer 章节
  - 验证：`grep -c "Co-Authored-By: Claude Code" v2/scripts/plugin-profiles/mps/CLAUDE.md` 输出 1
- [x] A3.7 `v2/scripts/plugin-profiles/mps/skills/skill-rules.json`
  - 以 `superpowers/skills/skill-rules.json` 为基线**全量复制**（design 决策 5：覆盖而非增量）
  - 追加 mattpocock skill 的触发词条目
  - 验证：`python3 -m json.tool v2/scripts/plugin-profiles/mps/skills/skill-rules.json`

## 阶段 A-4. switch-plugin.sh 接入

- [x] A4.1 `v2/scripts/switch-plugin.sh` usage 函数（约 `:220-226`）新增 `mps` 一行说明
- [x] A4.2 收尾提示分支（约 `:666-677`）新增 `mps` 分支
  - 提示首次使用需 `claude plugin marketplace add mattpocock/skills`
  - 提示 `/setup-matt-pocock-skills` 默认无需运行；必须运行时 Section A 选 `Other`（**不是**「本地文件」，其路径写死 `.scratch/`）
  - 验证：`bash -n v2/scripts/switch-plugin.sh && v2/scripts/switch-plugin.sh --list | grep mps`

## 阶段 A-5. CONTEXT.md 与文档

- [x] A5.1 项目根新建 `CONTEXT.md`，写入初始术语表骨架 + 与 `openspec/project.md` 的分工说明（design 决策 6）
- [x] A5.2 `README.md`「Profile 切换」章节（约 `:94-131`）加入 `mps`、`/switch-profile` 用法、以及「mps 仅 v2 可用」标注（design R8）
- [x] A5.3 `README.md` 记录 pin 的 mattpocock-skills 版本 1.2.3（design R7）

## 阶段 A-6. 测试

- [x] A6.1 新建 `tests/test_v2_mps_profile.py`，以 `tests/test_v2_codex_profiles.py` 为骨架（复用 `run_cmd` / `make_env`）
- [x] A6.2 用例：`switch-plugin.sh --list` 输出含 `mps`
- [x] A6.3 用例：切到 mps 后 `CLAUDE.md` 含 `harness-mode: mps`
- [x] A6.4 用例：切到 mps 后 `settings.json` 中 superpowers key 为 `false`、mattpocock key 为 `true`
- [x] A6.5 用例：切到 mps 后 `.claude/commands/switch-profile.md` 存在
- [x] A6.6 用例：`mps/skills/skill-rules.json` 包含 shared 基线条目（防止退化为增量文件）
- [x] A6.7 用例：`setup-project.sh` 生成的 manifest 含 `templateRoot` 且 `manifestSchemaVersion == 2`
  - 验证：`python3 -m unittest tests.test_v2_mps_profile -v`

## 阶段 A-7. 阶段 A 验收

- [x] A7.1 全量测试：`python3 -m unittest discover -s tests -v`，粘贴输出
- [ ] A7.2 实机切换到 mps，重启会话，确认 mattpocock skill 在 `/plugin` 与 Skill 列表中可见
- [ ] A7.3 跑通一次最小链路：`/grill-with-docs` → `/to-spec`，确认 spec 落到 `openspec/changes/` 而非 issue tracker（验证 design 决策 1 生效）
- [x] A7.4 切回 superpowers，确认可逆、无残留
- [x] A7.5 交叉验证：**Codex 已做**（发现 6 项实质问题，触发一轮返工）；**Gemini 未做**（Codex 的发现已足以推翻并重建核心设计，Gemini 的场景覆盖审查留待实机验证后补）

---

## 阶段 B（A 验收通过后启动）

- [x] B1.1 `npx skills@latest add mattpocock/skills`，目标选 Codex，产物落到临时目录
- [x] B1.2 新建 `v2/scripts/plugin-profiles/codex-codex-mps-dev/`，把 skill 副本放入 `.codex/skills/`
- [x] B1.3 `codex-codex-mps-dev/AGENTS.md`：以 `codex-codex-dev/AGENTS.md` 为基线，**指向 `docs/agents/issue-tracker.md`**
  （不重复 Claude 侧被证伪的「声明压制」做法；两侧共用同一份落点配置，R6 因此消解）
- [x] B1.4 `codex-codex-mps-dev/.codex/config.toml`、`hooks.json`、`session-state.template.md`、`agents/*.toml`
  - session-state 模板必须满足 `validate_session_state_file`（`switch-plugin.sh:120-129`）：含 `# codex-codex-mps-dev Workflow State`、`## Mode: codex-codex-mps-dev`、`## ChangeId:`、`## Current Stage:`
- [x] B1.5 `codex-codex-mps-dev/settings.json`
- [x] B1.6 `switch-plugin.sh` 收尾提示加 codex-native 分支说明
- [x] B1.7 测试用例：`is_codex_native_profile` 识别正确；切换后 `AGENTS.md` 存在、`CLAUDE.md` 被移除、`.codex/` 五件套齐备
- [x] B1.8 `README.md` 补充 codex 侧用法
- [ ] B1.9 阶段 B 验收：实机在 Codex CLI 跑通一次 `to-spec` 落点验证（重点观察 R6）

---

## 实测记录

### 0.1 插件键名（实测）

- marketplace 名：`mattpocock`（**不是** `mattpocock-skills`）
- 插件名：`mattpocock-skills`
- **enabledPlugins 真实 key：`mattpocock-skills@mattpocock`**
- 版本：1.2.3；实际发布 25 个 skill（engineering 18 + productivity 7）；`misc`/`in-progress` 目录不随插件发布
- 提案中原推断的 `mattpocock-skills@mattpocock-skills` **是错的**，已按实测值修正

### 0.2 npx skills CLI（实测）

`npx skills@latest --help` 正常输出，含 `add <package>` 子命令，阶段 B 可行。

### A2.3 `/switch-profile --status` 端到端实测

路径解析：本仓库 manifest 为 `manifestSchemaVersion: 1`、无 `templateRoot` → 回退到候选路径，
命中 `/Users/captain/aicoding/ai-config-templates`。

暴露两个提案阶段未预见的问题，均已修复并补测试：

1. **R10 cwd 误报**：从子目录调用时输出「项目版本: 未初始化」（脚本用 `pwd` 判定项目）。
   已加步骤 1c 要求显式定位项目根。
2. **R9 过期副本实锤**：命中的 `~/aicoding` 副本（rev 9181228）列出的 profile **无 `mps`**，
   却含已被移除的 `codex-codex-python-dev`。已加步骤 1b 做 profile 存在性校验。

在项目根执行的正确输出：

```
V2 Harness 状态
全局版本: v2
项目版本: v2
当前模式: superpowers
```

### A4.2 mps 收尾提示（实测 `--dry-run`）

```
V2 切换完成！当前模式: mps
注意事项：
  1. 需要重启 Claude Code 会话才能生效
  2. 退出当前会话，重新运行 claude 即可
  3. 首次使用请注册 marketplace: claude plugin marketplace add mattpocock/skills
  4. 运行 /setup-matt-pocock-skills 时请选择「本地文件」模式
     （本 harness 以 openspec/ 为规范真相源，不使用 issue tracker）
  5. 本模式已关闭 superpowers 插件，避免同职责 skill 争抢触发
```

### A7.5 Codex 交叉验证结论（触发返工）

Codex 实读上游 skill 原文，推翻了初版核心设计。三条硬事实：

1. `to-tickets/SKILL.md` 本地模式写死 `.scratch/<f>/issues/NN-<slug>.md`，
   并明确 **"one file per ticket, never a single combined file"**
2. `setup-matt-pocock-skills/issue-tracker-local.md` 路径写死 `.scratch/`，
   **没有**「文档位置指向 openspec/」这个配置项
3. `setup-matt-pocock-skills/SKILL.md` Section A 有 **Other** 选项，产物落
   `docs/agents/issue-tracker.md`，而各 skill 读写 tracker 时显式读该文件

→ 落点实现从「CLAUDE.md 声明压制」改为「填充 skill 原生扩展点」，并新增通用 `project-files/` 机制。

另外发现并修复：

- **非 TTY 漂移静默退出**（真 bug）：`set -e` + 裸 `read`，会话内调用时静默失败。
  且初版测试因 `run_cmd` 注入 `"n\n"` 而**掩盖了它**。已加 `[[ -t 0 ]]` 检测 + `--force-overwrite`
  + 两个不注入 stdin 的行为测试
- **权限缺 deny**：`triage` 读外部 issue/PR（injection 入口）、`implement` 自动 commit、
  `wizard` 碰 secrets，而 profile 是 `Bash:*` + `acceptEdits`。已补 10 条 deny
- **manifest JSON 未转义**：heredoc 直插 `templateRoot`，路径含引号会生成非法 JSON。已修
- **`update_manifest` 静默失败**：无 python3/jq 时不执行却报成功。已改为显式告警

### 实现期自行发现的问题

- **R9 多模板副本**（实测）：`~/aicoding/ai-config-templates`（rev 9181228，无 mps，remote 为内网 GitLab）
  与开发副本（rev a849604，remote 为 github）是**两个分叉的 fork**，且前者有 9 个未提交改动。
  → 未单方面合并；改为让切换**自愈**：`update_manifest` 写回自身仓库路径，命令端在多副本中择优
- **R10 cwd 误报**（实测）：脚本用 `pwd` 判定项目，子目录执行时误报「未初始化」
- **R11 模板仓库自切换**（实测）：在本仓库执行切换会用 profile 文件**覆盖 git 追踪的 V1 `CLAUDE.md` 模板**
  （650 行交付物 vs 403 行 profile 文件）。已加前置护栏直接拒绝

### 全链路往返实测

```
初始 (setup)             mode=superpowers          入口=CLAUDE.md  tracker=✗  .codex/skills=0
→ mps                    mode=mps                  入口=CLAUDE.md  tracker=✓  .codex/skills=0
→ codex-codex-mps-dev    mode=codex-codex-mps-dev  入口=AGENTS.md  tracker=✓  .codex/skills=34
→ mps                    mode=mps                  入口=CLAUDE.md  tracker=✓  .codex/skills=0
→ superpowers            mode=superpowers          入口=CLAUDE.md  tracker=✓  .codex/skills=0

mps 下 mattpocock 插件: True / superpowers 插件: False / deny 规则 10 条
.codex/skills 34 = mattpocock 25 + shared 6 + shared/codex 3（无冗余无缺失）
```

### 非 TTY 漂移实测

```
⚠ 检测到 profile 入口文件已被手动修改
✗ 检测到漂移，但当前不是交互终端，无法确认
请任选其一：
  1. 在外部终端执行: cd <项目> && <switcher> mps
  2. 确认要丢弃本地修改后重跑: <switcher> mps --force-overwrite
EXIT = 2
```

### 模板仓库护栏实测

```
错误: 当前目录是模板仓库本身，禁止在此执行切换
  切换会用 profile 文件覆盖仓库根的 CLAUDE.md / AGENTS.md 模板。
```

