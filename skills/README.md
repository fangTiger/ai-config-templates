# Skills

项目级技能模板，配合 Superpowers 插件和 OpenSpec 工作流使用。

---

## 技能体系说明

本项目的技能分为两层：

- **Superpowers 插件技能**（全局）：通过 `superpowers@superpowers-marketplace` 插件安装，提供通用开发方法论（brainstorming、TDD、plan 等）
- **项目级技能**（本目录）：针对项目特定的领域规范和工作流

两层技能通过 CLAUDE.md Section 4（全局工作流程）统一协调。

---

## 项目级技能列表

### openspec-workflow
OpenSpec 规范驱动开发工作流。

- 创建变更提案、检查现有规范、实现已批准的变更、归档
- 与 Superpowers 的 brainstorming/writing-plans 配合使用

### git-workflow
Git 工作流规范。

- 分支命名（feature/、bugfix/、hotfix/）
- Conventional Commits 提交规范
- Pre-commit 检查、合并流程

### python-backend-guidelines
Python/Django/FastAPI 后端开发规范。

- 分层架构（Routes → Views → Services → Repositories）
- Pydantic 验证、SQLAlchemy/Django ORM
- 异步模式、依赖注入

### python-error-tracking
Sentry 错误追踪规范。

- FastAPI/Django 集成
- 异常捕获、性能监控
- 后台任务监控

### skill-developer
创建和管理 Claude Code 技能的指南。

- 技能结构、YAML frontmatter
- 触发器类型（关键词、意图模式、文件路径）
- Hook 机制、500 行规则

### ppt-generator
生成符合用友设计规范的PPT素材。

- 输出 SVG 矢量图 + 配套演讲文案
- 遵循用友红(#e60012)点缀配色、大圆角容器
- 支持封面、时间线、架构、数据、总结等页面类型
- 输出到 `ppt_assets/` 目录

### document-reader
读取 Word 和 Excel 文档内容。

- 支持 `.docx`、`.xlsx`、`.xls` 格式
- 输出为 Markdown、JSON 或纯文本
- 提取文档结构、表格、元数据
- 命令行工具和 Python API

### design-doc-generator
将 Markdown 设计文档转换为企业标准格式。

- 支持 Markdown 转 Word (.docx) 和 XML
- 自动创建归档目录结构
- 生成封面、修订记录、目录
- 基于 design-template 模板规范

### e2e-testing
端到端测试规范与脚手架。

- 覆盖 API E2E、前端 UI、后端集成、AI/模型评测四大场景
- 多框架支持（pytest + Playwright + httpx）
- 多格式报告（Markdown + JSON + JUnit XML + 终端实时输出）
- 标准化目录结构 `tests/e2e/` 和命名规范
- 提供模板文件：conftest 骨架、报告生成器、pytest 配置
- 可选与 OpenSpec/TDD/Verification 工作流集成

### session-recovery
会话状态持久化与恢复。

- 解决长会话上下文压缩后 subagent 工作流状态丢失的问题
- 定义 `.claude/session-state.md` 文件格式和写入规范
- 提供自动恢复流程：读取 state → TaskList → plan → 继续执行
- 与 subagent-driven-development 和 executing-plans 配合使用

---

## 配置文件

- `skill-rules.json` — 技能激活触发规则，定义关键词、意图模式、文件路径匹配

---

## 与 Superpowers 的关系

| 阶段 | Superpowers 技能 | 项目级技能 |
|------|-----------------|-----------|
| 需求设计 | `brainstorming` | `openspec-workflow` |
| 计划编写 | `writing-plans` | — |
| 实现 | `test-driven-development` | `python-backend-guidelines` |
| 端到端测试 | — | `e2e-testing` |
| 错误处理 | — | `python-error-tracking` |
| 文档生成 | — | `ppt-generator`, `design-doc-generator` |
| 文档读取 | — | `document-reader` |
| 会话恢复 | — | `session-recovery` |
| 代码审查 | `requesting-code-review` | — |
| Git 操作 | `finishing-a-development-branch` | `git-workflow` |
| 验证 | `verification-before-completion` | — |
