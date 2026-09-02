# Change: 为所有 AI 配置模板添加提交归因

## Why

当前仓库的 Claude 与 Codex 配置模板没有统一要求在 Git commit message 中记录协作 AI，导致无法可靠统计代码由哪个 AI 生成或协作完成。该规则需要覆盖 V1、V2、全局、项目级及全部 profile 模板，避免切换或安装配置后丢失归因信息。

## What Changes

- 所有受版本控制的 `CLAUDE.md` 模板强制要求追加 `Co-Authored-By: Claude Code <claude-code@anthropic.com>`，不得省略。
- 所有受版本控制的 `AGENTS.md` 模板强制要求追加 `Co-Authored-By: Codex <codex@openai.com>`，不得省略。
- 每个模板中的对应 trailer 只能出现一次，且不得包含另一种 AI 的错误归因。
- 添加自动化测试，持续检查当前及未来新增模板的覆盖率和唯一性。

## Impact

- Affected specs: `plugin-profiles`
- Affected code: 仓库内全部 13 个 `CLAUDE.md`、13 个 `AGENTS.md` 模板，以及归因覆盖测试
- Breaking changes: 无

## Acceptance Criteria

- 仓库内所有受版本控制且文件名为 `CLAUDE.md` 的模板都包含且仅包含一次 Claude Code trailer。
- 仓库内所有受版本控制且文件名为 `AGENTS.md` 的模板都包含且仅包含一次 Codex trailer。
- 所有目标模板均以“Git Commit 规范（强制）”标识该规则，并明确使用“必须”和“不得省略”。
- Claude 模板不包含 Codex trailer，Codex 模板不包含 Claude Code trailer。
- 自动化测试和 `git diff --check` 均通过。

## Out of Scope

- 不修改 Git Author 身份。
- 不自动提交、推送或重写历史 commit。
- 不为 Gemini 或其他 AI 定义新的 trailer。
