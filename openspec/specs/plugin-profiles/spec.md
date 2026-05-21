## Purpose

Plugin profiles 提供多种 AI 协同工作模式的配置切换能力。每个 profile 定义了 Claude、Codex、Gemini 的角色分工、工作流程和交叉检查规则，通过 `switch-plugin.sh` 脚本一键切换。
## Requirements
### Requirement: codex-dev 插件配置

系统 SHALL 提供 `codex-dev` 插件配置，将 Claude 定位为架构师/审查者，Codex 定位为主代码实现者。

#### Scenario: 切换到 codex-dev 配置
- **GIVEN** 用户在一个包含 `.claude/` 目录的项目中
- **WHEN** 用户执行 `switch-plugin.sh codex-dev`
- **THEN** 项目的 CLAUDE.md 被替换为 codex-dev 配置
- **AND** settings.json 更新为 codex-dev 权限配置（包含 deny 规则）
- **AND** codex-handoff 技能在 `.claude/skills/` 中可用
- **AND** `.active-plugin` 被设置为 `codex-dev`

#### Scenario: 查看 codex-dev 配置状态
- **GIVEN** codex-dev 配置已激活
- **WHEN** 用户执行 `switch-plugin.sh --status`
- **THEN** 输出显示 `codex-dev` 为当前激活的配置

#### Scenario: 从 codex-dev 切换回其他配置
- **GIVEN** codex-dev 配置已激活
- **WHEN** 用户执行 `switch-plugin.sh superpowers`
- **THEN** 项目恢复为 superpowers 配置
- **AND** codex-dev 特有文件被清理

### Requirement: codex-dev 角色定义

codex-dev 的 CLAUDE.md SHALL 为实现工作流中的每个 AI 定义不同角色。

#### Scenario: Claude 作为架构师
- **GIVEN** codex-dev 配置已激活
- **WHEN** 一个中/大任务需要实现
- **THEN** Claude 执行分析、设计、提案和审查阶段
- **AND** Claude 通过上下文交接将实现工作委托给 Codex
- **AND** Codex 自审完成后，Claude 主导三方审核

#### Scenario: Codex 作为实现者
- **GIVEN** codex-dev 配置已激活且提案已通过
- **WHEN** Claude 发起上下文交接
- **THEN** Codex 收到结构化上下文包（proposal、design、tasks、spec deltas）
- **AND** Codex 在 workspace-write 沙箱模式下实现任务
- **AND** Codex 遵循 developer-instructions 中的 TDD 规则（RED-GREEN-REFACTOR）

#### Scenario: Gemini 作为前端开发者
- **GIVEN** codex-dev 配置已激活且任务包含前端工作
- **WHEN** Codex 完成后端实现且 Sync Gate 通过
- **THEN** Gemini 收到前端任务及来自 Codex 后端的 API 契约
- **AND** Gemini 按照项目规范实现前端组件

### Requirement: 上下文交接技能

系统 SHALL 提供 `codex-handoff` 技能，编排从 Claude 到 Codex 的上下文交接。

#### Scenario: 为后端任务发起上下文交接
- **GIVEN** 一个已批准的 OpenSpec 提案包含后端任务
- **WHEN** Claude 调用 codex-handoff 技能
- **THEN** 从 proposal.md、design.md、tasks.md 和 spec deltas 构建结构化上下文包
- **AND** developer-instructions 包含 TDD 规则、编码规范、文件白名单和负面约束
- **AND** 以 sandbox="workspace-write" 启动 Codex session

#### Scenario: 程序化文件范围护栏
- **GIVEN** Codex 在 workspace-write 模式下实现任务
- **WHEN** 一轮 Codex 实现完成
- **THEN** Claude 通过 `git diff --name-only` 校验文件白名单
- **AND** 超范围的修改触发自动中止和人工确认

#### Scenario: 证据驱动的自审
- **GIVEN** Codex 完成所有分配的任务
- **WHEN** Claude 通过 codex-reply 触发自审
- **THEN** Codex 输出 RED/GREEN 证据、变更文件清单、需求覆盖矩阵
- **AND** 发现的问题在同一 session 中修复后，才进入三方审核

### Requirement: codex-dev 安全配置

codex-dev 的 settings.json SHALL 执行比 superpowers 更严格的安全策略。

#### Scenario: 继承 teams 配置的 deny 规则
- **GIVEN** codex-dev 配置已激活
- **WHEN** 检查 `.claude/settings.json`
- **THEN** deny 规则至少包含 `git push --force` 和 `rm -rf /`
- **AND** superpowers 的所有 allow 规则保持不变

### Requirement: codex-dev 降级规则

系统 SHALL 定义明确的降级触发条件，回退到 superpowers 模式。

#### Scenario: 实现反复失败时降级
- **GIVEN** Codex 在 codex-dev 模式下实现某个任务
- **WHEN** 单个任务修复超过 3 次仍未通过测试
- **THEN** Claude 中止 Codex 实现，切换到 superpowers 模式由 Claude 手动实现

#### Scenario: 自审连续失败时降级
- **GIVEN** Codex 自审连续失败
- **WHEN** 自审连续失败 2 次
- **THEN** Claude 中止并切换到 superpowers 模式

### Requirement: codex-codex-dev 专用切换入口

系统 SHALL 提供 `scripts/switch-plugin_codex.sh` 作为 `codex-codex-dev` 的专用切换入口，且该入口不承担 Claude profile 的切换职责。

#### Scenario: 切换到 codex-codex-dev 配置

- **GIVEN** 用户在一个包含 `.claude/` 目录的项目中
- **WHEN** 用户执行 `switch-plugin_codex.sh codex-codex-dev`
- **THEN** 项目的 `AGENTS.md`、`.codex/instructions.md`、`.codex/workflow.md`、`.codex/config.toml` 与 `.codex/session-state.md` 被正确落盘
- **AND** `.codex/hooks`、`.codex/commands/openspec` 与 `.codex/skills` 被正确落盘
- **AND** `.claude/settings.json` 中的 Codex hooks 路径指向 `.codex/hooks/...`
- **AND** `.active-plugin` 被设置为 `codex-codex-dev`

#### Scenario: 拒绝非 Codex profile

- **GIVEN** 用户在项目目录中执行 Codex 专用切换脚本
- **WHEN** 用户执行 `switch-plugin_codex.sh superpowers`
- **THEN** 脚本以非零状态退出
- **AND** 提示该入口仅支持 `codex-codex-dev`
- **AND** 提示 Claude profile 应使用 `switch-plugin_claude.sh`
