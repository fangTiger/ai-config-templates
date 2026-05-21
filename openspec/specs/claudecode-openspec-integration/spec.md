# claudecode-openspec-integration 规范

## 目的
定义 Claude Code 如何自动集成 OpenSpec 规范驱动开发工作流，确保开发过程遵循 spec-first 原则。

## 需求

### 需求：实现前规范检查
Claude Code 必须在开始任何非平凡实现任务之前检查现有的 OpenSpec 规范。

#### 场景：功能请求匹配现有规范
- **当** 用户请求的功能在 `openspec/specs/` 中有现有规范时
- **则** Claude Code 在实现前先阅读相关规范
- **并且** 确保实现符合文档化的需求

#### 场景：功能请求无匹配规范
- **当** 用户请求的新功能没有现有规范时
- **则** Claude Code 提示是否先创建提案
- **并且** 解释规范驱动开发的好处

### 需求：自动提案触发检测
Claude Code 必须根据定义的触发器检测何时需要创建 OpenSpec 提案。

#### 场景：检测到破坏性变更
- **当** 实现会改变现有 API、数据模型或行为时
- **则** Claude Code 建议创建 OpenSpec 提案
- **并且** 推荐使用 `/openspec:proposal` 命令

#### 场景：检测到新能力
- **当** 实现引入新功能或能力时
- **则** Claude Code 检查 `openspec list --specs` 查找相关规范
- **并且** 如果能力未被文档化则推荐创建提案

### 需求：OpenSpec 命令集成
Claude Code 必须能够访问 OpenSpec 斜杠命令进行工作流管理。

#### 场景：用户调用提案命令
- **当** 用户输入 `/openspec:proposal` 或要求创建提案时
- **则** Claude Code 搭建提案结构
- **并且** 引导用户完成 proposal.md、tasks.md 和规范增量的创建

#### 场景：用户调用应用命令
- **当** 用户在提案批准后输入 `/openspec:apply` 时
- **则** Claude Code 按照 tasks.md 开始实现
- **并且** 完成任务后标记为已完成

### 需求：规范-实现一致性检查
Claude Code 必须验证实现是否与对应的规范匹配。

#### 场景：实现完成
- **当** tasks.md 中的所有任务都标记为完成时
- **则** Claude Code 对照规范需求审查代码
- **并且** 报告规范与实现之间的任何差异
