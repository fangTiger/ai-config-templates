## Context

仓库通过 V1、V2、全局配置、项目配置和多个 profile 分发 `CLAUDE.md` 与 `AGENTS.md`。只修改根目录文件不能覆盖安装脚本和 profile 切换实际使用的全部模板，因此归因规则必须在所有模板副本中保持一致。

## Goals / Non-Goals

- Goals:
  - 为 Claude Code 与 Codex 提供稳定、可机器解析的 Git trailer。
  - 覆盖当前所有受版本控制的 `CLAUDE.md` 与 `AGENTS.md` 模板。
  - 用测试防止未来新增模板遗漏或重复归因。
- Non-Goals:
  - 不改变实际提交人的 Git Author。
  - 不引入 Git hooks 或自动改写 commit message 的脚本。
  - 不定义 Claude Code、Codex 以外的 AI 身份。

## Decisions

- Decision: 使用 Git 标准 `Co-Authored-By` trailer，而不是自定义字段，便于 GitHub 等工具识别并支持脚本统计。
- Decision: Claude Code 固定使用 `Claude Code <claude-code@anthropic.com>`，Codex 固定使用 `Codex <codex@openai.com>`。
- Decision: 所有模板使用“Git Commit 规范（强制）”标题，并明确声明 trailer “必须”添加且“不得省略”，避免被解释为建议性规则。
- Decision: 以受版本控制且 basename 精确为 `CLAUDE.md` 或 `AGENTS.md` 的文件作为覆盖集合；当前集合为 13 + 13 个文件。
- Decision: 每个文件只允许一个对应 trailer，并禁止交叉写入另一 AI 的 trailer。
- Alternatives considered:
  - 只修改根目录模板：无法覆盖全局配置与 profile 分发路径，已排除。
  - 只修改全局模板：未执行全局安装或使用 V1/profile 切换时可能缺失，已排除。
  - 使用自定义 `AI-Generated-By`：生态兼容性和识别能力弱于标准 trailer，已排除。

## Risks / Trade-offs

- 多层指令可能同时被模型读取，但唯一性要求可防止在同一 commit message 中重复追加相同 trailer。
- 批量修改文件较多，使用自动化覆盖测试和精确 trailer 计数降低遗漏风险。

## Migration Plan

1. 先添加覆盖测试并确认当前模板集合不满足要求。
2. 为全部 Claude 与 Codex 模板分别追加统一规则。
3. 运行覆盖测试、现有相关测试和补丁格式检查。

## Open Questions

- 无。
