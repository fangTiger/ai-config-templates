---
name: git-workflow
description: Git workflow management for iuap-aip-data. Use when creating branches, checking diffs, staging, committing, pushing, or preparing PRs for this Java/Maven project.
---

# Git 工作流技能

## 目的

在 iuap-aip-data 中进行 Git 操作时，保持分支、范围检查、提交和 PR 证据清晰，避免误提交其他任务或生成产物。

## 适用场景

- 创建或切换任务分支
- 检查当前改动范围
- 暂存、提交、推送代码
- 准备 PR 描述或复核合并前状态
- 处理脏工作区中的多任务改动

## 分支口径

- 默认使用 `codex/<short-task>` 分支前缀。
- 若仓库已有团队分支规范，以团队规范优先。
- 当前工作区存在其他活跃任务时，优先使用独立 worktree。

## 操作前检查

执行 Git 写操作前先确认：

```bash
git status --short
git diff --check
```

如存在非本任务改动：

- 不回滚、不覆盖、不自动格式化无关文件。
- 只暂存本任务文件。
- 与当前任务冲突时，先说明冲突点再处理。

## 运行态文件边界

`AGENTS.md` 与 `.codex/` 是本项目由 profile 生成的本地运行态文件，默认不进入 iuap-aip-data 业务提交；项目自有且需要团队审查的 `.codex/skills/<skill-name>/SKILL.md` 可通过精确 `.gitignore` 例外纳入提交。提交前必须检查：

```bash
git ls-files AGENTS.md .codex
git check-ignore -v AGENTS.md .codex/workflow.md
git status --short -- AGENTS.md .codex
```

期望结果：

- `git ls-files AGENTS.md .codex` 默认无输出；若出现明确纳入版本控制的项目自有 review skill，必须能解释其 `.gitignore` 精确例外和 profile 同步来源。
- `AGENTS.md` 与 `.codex/` 中的运行配置不出现在 staged tracked 变更中。
- 如运行配置已被跟踪，使用 `git rm --cached -r -- AGENTS.md .codex` 只移出索引，保留本地文件；不要移除已明确批准跟踪的项目自有 skill。

## 提交前验证

根据改动类型选择验证：

| 改动类型 | 建议命令 |
|----------|----------|
| Java 测试类 | `mvn -q -Dtest=<TestClass> test` |
| Java 生产代码且有相关测试 | `mvn -q -Dtest=<RelatedTest> test` |
| Java 生产代码但无定向测试 | `mvn -q test` 或说明无法全量执行的原因 |
| OpenSpec 变更 | `openspec validate <change-id> --strict` |
| `.codex` / hooks / skills | JSON、shell、Node 语法校验 |
| Markdown | `rg -n '[ \t]+$' <changed-markdown-files>` |

## 暂存与提交

- 优先精确暂存文件：

```bash
git add <file1> <file2>
```

- 不使用 `git add -A` 暂存混杂工作区，除非已确认所有改动都属于当前任务。
- 在 iuap-aip-data 中，即使使用 `git add -A` 前已确认范围，也要先完成“运行态文件边界”检查。
- 提交信息建议采用简洁 conventional commit：

```bash
git commit -m "docs(codex): add context governance proposal"
git commit -m "chore(codex): align hooks and skills"
```

## PR 描述

PR 描述至少包含：

- Summary：改了什么
- Test Plan：运行了哪些验证
- Scope：是否涉及 Java 业务代码、API、权限、数据访问
- Notes：未验证项、profile 同步情况或已知风险

## 禁止事项

- 不执行 `git reset --hard`、`git checkout -- <file>` 等破坏性命令，除非用户明确要求。
- 不提交 `AGENTS.md`、`.codex/` 等本地运行态文件；项目自有 review skill 这类明确纳入版本控制的 `.codex/skills/<skill-name>/SKILL.md` 例外。需要持久化时同步到本脚手架仓库的 `scripts/plugin-profiles/` 模板源。
- 不把 `target/`、`graphify-out/`、`.codex/runtime-cache`、`.codex/.backup-*` 等生成产物作为业务改动提交。
- 不因提交方便而合并其他任务的未跟踪文件。
