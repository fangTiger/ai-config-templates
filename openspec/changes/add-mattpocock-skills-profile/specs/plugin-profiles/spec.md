## ADDED Requirements

### Requirement: mps 插件配置

系统 SHALL 提供 `mps` profile，启用 `mattpocock-skills` 插件并关闭 `superpowers` 插件，使 mattpocock 的访谈驱动链路成为该模式下唯一的工作流 skill 来源。

#### Scenario: 列出 mps profile
- **GIVEN** 用户在一个已初始化 V2 的项目中
- **WHEN** 用户执行 `v2/scripts/switch-plugin.sh --list`
- **THEN** 输出包含 `mps`
- **AND** 显示其具备 `CLAUDE.md` 与 `settings.json`

#### Scenario: 切换到 mps profile
- **GIVEN** 用户在一个已初始化 V2 的项目中
- **WHEN** 用户执行 `v2/scripts/switch-plugin.sh mps`
- **THEN** 项目根 `CLAUDE.md` 被替换为含 `<!-- harness-mode: mps -->` 的配置
- **AND** `.claude/settings.json` 中 `superpowers@superpowers-marketplace` 为 `false`
- **AND** `.claude/settings.json` 中 mattpocock 插件键为 `true`
- **AND** `.claude/skills/skill-rules.json` 同时包含 shared 基线条目与 mattpocock skill 触发词
- **AND** 项目 manifest 的 `mode` 被更新为 `mps`

#### Scenario: 首次切换到 mps 时给出前置指引
- **GIVEN** 用户首次切换到 `mps`
- **WHEN** 切换流程结束并输出注意事项
- **THEN** 提示需执行 `claude plugin marketplace add mattpocock/skills`
- **AND** 提示 `/setup-matt-pocock-skills` 默认无需运行，必须运行时应选择 `Other` 选项

#### Scenario: 从 mps 切回其他 profile
- **GIVEN** `mps` profile 已激活
- **WHEN** 用户执行 `v2/scripts/switch-plugin.sh superpowers`
- **THEN** 项目恢复为 superpowers 配置
- **AND** mps 特有的 skill-rules 条目被清除

### Requirement: mps 产出落点映射

`mps` SHALL 通过 skill 原生扩展点 `docs/agents/issue-tracker.md` 定义 mattpocock skill 的产出落点，`CLAUDE.md` 提供速查摘要并声明冲突时以该扩展点为准，以保证 `openspec/specs/` 仍是唯一规范真相源。

#### Scenario: to-spec 产出落到 OpenSpec
- **GIVEN** `mps` profile 已激活
- **WHEN** 用户执行 `/to-spec`
- **THEN** 规范被写入 `openspec/changes/<change-id>/proposal.md` 及对应的 spec delta
- **AND** 不向任何 issue tracker 发布

#### Scenario: to-tickets 产出落到 tasks.md
- **GIVEN** `mps` profile 已激活且存在一个变更提案
- **WHEN** 用户执行 `/to-tickets`
- **THEN** 任务清单被写入 `openspec/changes/<change-id>/tasks.md`

#### Scenario: grill-with-docs 产出落到 docs/plans
- **GIVEN** `mps` profile 已激活
- **WHEN** 用户执行 `/grill-with-docs`
- **THEN** 访谈结论被写入 `docs/plans/YYYY-MM-DD-{topic}-design.md`

#### Scenario: domain-modeling 维护 CONTEXT.md
- **GIVEN** `mps` profile 已激活
- **WHEN** `domain-modeling` skill 被触发
- **THEN** 领域术语被写入项目根 `CONTEXT.md`
- **AND** `openspec/project.md` 的项目约定内容不被改写

#### Scenario: 落点配置走 skill 原生扩展点安装
- **GIVEN** 用户切换到 `mps`
- **WHEN** 切换器安装 profile 的 `project-files/**`
- **THEN** 项目根获得 `docs/agents/issue-tracker.md`
- **AND** 该文件应答 skill 正文的查询锚点「publish to the issue tracker」与「fetch the relevant ticket」
- **AND** 该文件显式禁止调用 `gh issue create` 等外部 tracker 命令
- **AND** `CLAUDE.md` 声明冲突时以该文件为准

#### Scenario: 化解一票一文件冲突
- **GIVEN** 上游 `to-tickets` 正文要求「one file per ticket, never a single combined file」
- **WHEN** 在 mps 模式下执行 `/to-tickets`
- **THEN** `docs/agents/issue-tracker.md` 说明 OpenSpec 下稳定标识由任务编号承载、独立状态由行内 checkbox 承载
- **AND** 任务写入单一 `tasks.md` 的编号条目
- **AND** 不创建 `openspec/changes/<id>/issues/`，不创建 `.scratch/`

#### Scenario: 第三方插件的外部写操作被 deny 兜底
- **GIVEN** `mps` profile 已激活
- **WHEN** 加载 `.claude/settings.json`
- **THEN** `permissions.deny` 包含 `Bash(gh issue:*)`、`Bash(gh secret:*)`、`Bash(git push:*)`、`Bash(rm -rf /:*)`

#### Scenario: 补齐 superpowers 关闭后的能力缺口
- **GIVEN** `mps` profile 已激活
- **WHEN** 任务进入完成前的验证阶段
- **THEN** `CLAUDE.md` 的内联规则要求粘贴可验证的测试输出
- **AND** 分支集成检查清单以内联形式提供

### Requirement: 会话内 Profile 切换命令

系统 SHALL 提供 `/switch-profile` slash 命令，作为 `switch-plugin.sh` 的会话内封装，使用户无需退出会话即可切换 profile。该命令 SHALL NOT 重新实现切换逻辑。

#### Scenario: 所有 profile 均可获得该命令
- **GIVEN** 命令模板位于 `shared/commands/switch-profile.md`
- **WHEN** 用户切换到任意 profile
- **THEN** Claude 侧 profile 在 `.claude/commands/switch-profile.md` 获得该命令
- **AND** Codex-native profile 在 `.codex/commands/switch-profile.md` 获得该命令

#### Scenario: 查询当前状态
- **GIVEN** 项目已初始化 V2
- **WHEN** 用户执行 `/switch-profile --status`
- **THEN** 输出当前激活的 profile 与可用 profile 列表

#### Scenario: 切换到目标 profile
- **GIVEN** 项目已初始化 V2
- **WHEN** 用户执行 `/switch-profile mps`
- **THEN** 底层调用模板仓库的 `v2/scripts/switch-plugin.sh mps`
- **AND** 输出提示需重启会话才能生效

#### Scenario: 切换到 Codex-native profile 需二次确认
- **GIVEN** 用户在 Claude 会话中
- **WHEN** 用户执行 `/switch-profile` 且目标 profile 名以 `codex-` 开头
- **THEN** 命令先说明该切换会删除项目根 `CLAUDE.md`
- **AND** 在用户明确确认前不执行切换

#### Scenario: 预览切换影响
- **GIVEN** 项目已初始化 V2
- **WHEN** 用户执行 `/switch-profile mps --dry-run`
- **THEN** 输出将要执行的操作而不产生文件变更

### Requirement: 非交互环境下的漂移处置

切换器 SHALL 在检测到漂移且当前不是交互终端时明确失败，而非静默退出。

#### Scenario: 无 stdin 时漂移确认明确失败
- **GIVEN** profile 入口文件已被手动修改，且当前不是交互终端
- **WHEN** 用户执行 `switch-plugin.sh <profile>`
- **THEN** 切换器以退出码 `2` 终止
- **AND** 输出说明检测到漂移但无法确认
- **AND** 给出在外部终端执行与使用 `--force-overwrite` 两条出路
- **AND** 不静默退出、不阻塞等待输入

#### Scenario: force-overwrite 跳过漂移确认
- **GIVEN** profile 入口文件已被手动修改，且当前不是交互终端
- **WHEN** 用户执行 `switch-plugin.sh <profile> --force-overwrite`
- **THEN** 切换器覆盖本地修改并完成切换
- **AND** 退出码为 `0`

#### Scenario: 命令不得自行决定覆盖
- **GIVEN** `/switch-profile` 检测到目标切换存在漂移
- **WHEN** 命令准备执行切换
- **THEN** 先向用户呈现漂移的具体内容
- **AND** 在用户明确确认前不附加 `--force-overwrite`

### Requirement: Profile 项目级文件安装

切换器 SHALL 支持把 profile 的 `project-files/**` 按相对路径安装到项目根，用于 `.claude/` 之外的受管配置。

#### Scenario: 安装 project-files
- **GIVEN** profile 目录下存在 `project-files/docs/agents/issue-tracker.md`
- **WHEN** 用户切换到该 profile
- **THEN** 项目根出现 `docs/agents/issue-tracker.md`
- **AND** 缺失的中间目录被自动创建

#### Scenario: 切换离开时保留 project-files
- **GIVEN** `mps` 已安装 `docs/agents/issue-tracker.md`
- **WHEN** 用户切换到其他 profile
- **THEN** 该文件保留在项目中
- **AND** 不因切换被删除

### Requirement: 模板仓库路径记录

项目 manifest SHALL 记录模板仓库根路径，使会话内命令能够定位 `switch-plugin.sh`。

#### Scenario: 初始化时写入模板路径
- **GIVEN** 用户执行 `v2/setup-project.sh`
- **WHEN** 项目 manifest 被创建
- **THEN** manifest 包含 `templateRoot` 字段，值为模板仓库绝对路径
- **AND** `manifestSchemaVersion` 为 `2`

#### Scenario: 切换 profile 不擦除模板路径
- **GIVEN** manifest 中已有 `templateRoot`
- **WHEN** 用户执行任意 profile 切换
- **THEN** `templateRoot` 字段保持不变

#### Scenario: 旧 manifest 回退解析
- **GIVEN** 项目 manifest 的 `manifestSchemaVersion` 为 `1` 且无 `templateRoot`
- **WHEN** 用户执行 `/switch-profile --status`
- **THEN** 命令依次尝试环境变量 `AI_CONFIG_TEMPLATES_ROOT` 与已知候选路径
- **AND** 解析成功时正常执行

#### Scenario: 在项目子目录调用时仍定位到项目根
- **GIVEN** 当前 shell 工作目录位于项目的某个子目录
- **WHEN** 用户执行 `/switch-profile --status`
- **THEN** 命令向上查找含 `.claude/.harness-manifest.json` 的最近目录作为项目根
- **AND** 显式在项目根执行 `switch-plugin.sh`
- **AND** 不出现「项目版本: 未初始化」的误报

#### Scenario: 命中缺少目标 profile 的过期模板副本
- **GIVEN** 机器上存在多个模板仓库副本，回退解析命中的副本中没有目标 profile
- **WHEN** 用户执行 `/switch-profile <profile>`
- **THEN** 命令在执行切换前校验 `<root>/v2/scripts/plugin-profiles/<profile>/` 是否存在
- **AND** 目录不存在时中止切换并报告该副本可能过期
- **AND** 列出该副本实际可用的 profile 供用户判断

#### Scenario: 模板路径无法解析时给出修复指引
- **GIVEN** manifest、环境变量与候选路径均无法定位模板仓库
- **WHEN** 用户执行 `/switch-profile`
- **THEN** 命令报告无法定位 `switch-plugin.sh`
- **AND** 给出重跑 `setup-project.sh` 或设置 `AI_CONFIG_TEMPLATES_ROOT` 的具体指引
- **AND** 不静默失败

### Requirement: codex-mps-dev 插件配置

系统 SHALL 提供 `codex-mps-dev` profile，以 mattpocock 链路驱动「Claude 设计 + Codex 实现」的 6 阶段交接流水线。

#### Scenario: 识别为 Claude 侧 profile
- **GIVEN** profile 目录含 `CLAUDE.md` 且不含 `.codex/`
- **WHEN** 切换器判断 profile 类型
- **THEN** `codex-mps-dev` 不被识别为 Codex-native
- **AND** 切换后项目根保留 `CLAUDE.md` 作为入口

#### Scenario: 切换到 codex-mps-dev
- **GIVEN** 用户在一个已初始化 V2 的项目中
- **WHEN** 用户执行 `v2/scripts/switch-plugin.sh codex-mps-dev`
- **THEN** 项目根 `CLAUDE.md` 含 `<!-- harness-mode: codex-mps-dev -->`
- **AND** `.claude/skills/codex-handoff/SKILL.md` 被安装
- **AND** `.codex/skills/openspec-propose`、`openspec-apply-change`、`openspec-archive-change`、`openspec-explore` 被安装
- **AND** 项目根获得 `docs/agents/issue-tracker.md`
- **AND** `.claude/settings.json` 启用 mattpocock 插件、关闭 superpowers、含 deny 规则

#### Scenario: 流水线使用 mattpocock 链路
- **GIVEN** `codex-mps-dev` 已激活
- **WHEN** 阅读其 `CLAUDE.md` 的 6 阶段流水线
- **THEN** Stage 1 使用 `/grill-with-docs`，Stage 2 使用 `/to-spec` 与 `/to-tickets`
- **AND** Stage 5 使用 `code-review`
- **AND** 不再引用 `superpowers:brainstorming`、`superpowers:writing-plans`、`superpowers:verification-before-completion`

#### Scenario: 保留交接护栏
- **GIVEN** `codex-mps-dev` 已激活且提案已批准
- **WHEN** Claude 进入 HANDOFF 阶段
- **THEN** 上下文包含 FileAllowlist、git 基线与验证命令
- **AND** 上下文包显式注入 `docs/agents/issue-tracker.md` 的落点约束
- **AND** `tasks.md` 中每个 task 标注 `Executor`

### Requirement: mps 系列落点配置一致性

三个 mps profile SHALL 共用同一份 `docs/agents/issue-tracker.md`，避免规范落点语义分叉。

#### Scenario: 三个 profile 的落点配置完全一致
- **GIVEN** `mps`、`codex-mps-dev`、`codex-codex-mps-dev` 三个 profile
- **WHEN** 比对各自 `project-files/docs/agents/issue-tracker.md`
- **THEN** 三份文件内容完全相同

#### Scenario: 在三个 mps profile 间切换不产生落点分叉
- **GIVEN** 项目已安装任一 mps profile
- **WHEN** 用户切换到另一个 mps profile
- **THEN** `docs/agents/issue-tracker.md` 内容保持一致
- **AND** 规范仍落到 `openspec/changes/`

### Requirement: codex-codex-mps-dev 插件配置

系统 SHALL 提供 Codex-native 的 `codex-codex-mps-dev` profile，将 mattpocock skill 以文件副本形式提供给 Codex 主工作台。

#### Scenario: 识别为 Codex-native profile
- **GIVEN** profile 目录同时包含 `AGENTS.md` 与 `.codex/`
- **WHEN** 切换器判断 profile 类型
- **THEN** `codex-codex-mps-dev` 被识别为 Codex-native

#### Scenario: 切换到 codex-codex-mps-dev
- **GIVEN** 用户在一个已初始化 V2 的项目中
- **WHEN** 用户执行 `v2/scripts/switch-plugin.sh codex-codex-mps-dev`
- **THEN** 项目根安装 `AGENTS.md`
- **AND** 项目根 `CLAUDE.md` 被移除
- **AND** `.codex/config.toml`、`.codex/hooks.json`、`.codex/session-state.md`、`.codex/session-state.template.md` 被安装
- **AND** mattpocock skill 文件副本被安装到 `.codex/skills/`
- **AND** 项目 manifest 的 `mode` 被更新为 `codex-codex-mps-dev`

#### Scenario: AGENTS.md 落点映射覆盖 skill 正文
- **GIVEN** `.codex/skills/` 下的 skill 副本正文包含发布到 issue tracker 的指令
- **WHEN** Codex 读取项目根 `AGENTS.md`
- **THEN** `AGENTS.md` 以铁律形式声明产出落点映射优先于 skill 正文
- **AND** 规范产出落到 `openspec/changes/`

#### Scenario: session-state 模板校验通过
- **GIVEN** 用户切换到 `codex-codex-mps-dev`
- **WHEN** 切换器安装 `.codex/session-state.md`
- **THEN** 文件包含 `# codex-codex-mps-dev Workflow State` 标题
- **AND** 包含 `## Mode: codex-codex-mps-dev`、`## ChangeId:`、`## Current Stage:` 字段
