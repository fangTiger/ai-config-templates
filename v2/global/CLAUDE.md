<!-- harness-version: v2 -->
<!-- harness-role: global -->


# Claude Code 全局配置 (V2)

> 此配置文件定义 Claude Code 的全局行为规则。
> 模式特有的角色分工、工作流和交叉检查策略，由项目级 CLAUDE.md 定义。
> #### 全局强制定义：所有模型的回复的语种都是中文！

---

## 0. OpenSpec 自动工作流 (强制)

**核心原则：规范先行，实现在后。**

### 0.1 自动检测逻辑

收到用户请求后，Claude Code 必须自动判断：

```
用户请求 → 是否需要 OpenSpec？
├─ 关键词检测：
│   ├─ "新增"、"添加"、"实现" + 功能/能力 → 需要提案
│   ├─ "修改"、"更新"、"重构" + API/架构 → 需要提案
│   ├─ "删除"、"移除" + 功能 → 需要提案
│   └─ "修复"、"bug"、"错误" → 不需要提案
├─ 影响范围检测：
│   ├─ 涉及 3+ 文件修改 → 建议提案
│   ├─ 涉及公共 API 变更 → 必须提案
│   └─ 仅内部实现调整 → 可选提案
└─ 不确定时 → 询问用户或创建提案（更安全）
```

### 0.2 实现前检查 (必须执行)

在开始任何非平凡实现任务之前：

1. **检查现有规范**
   ```bash
   openspec list --specs
   ```
   如果存在相关 spec，先阅读确保实现符合规范

2. **检查进行中的变更**
   ```bash
   openspec list
   ```
   避免与其他提案冲突

3. **决策**
   - 有相关 spec → 按 spec 实现
   - 无相关 spec 且需要提案 → 先创建提案
   - 无需提案 → 直接实现

### 0.3 提案触发器

**必须创建提案：**
- 新增功能或能力（不是 bug 修复）
- 修改现有 API、数据模型或行为（**破坏性变更**）
- 架构变更或新模式引入
- 性能/安全相关的行为变更

**可以跳过提案：**
- Bug 修复（恢复预期行为）
- 拼写、格式、注释修正
- 非破坏性依赖更新
- 配置调整
- 为现有行为添加测试

### 0.4 工作流命令

| 命令 | 用途 |
|------|------|
| `/openspec:proposal` | 创建新的变更提案 |
| `/openspec:apply` | 开始实现已批准的提案 |
| `/openspec:archive` | 归档已完成的变更 |
| `openspec validate <id> --strict` | 验证提案格式 |

### 0.5 实现-规范一致性

实现完成后，必须验证：
1. 所有 tasks.md 中的任务已完成
2. 实现符合 spec.md 中定义的需求和场景
3. 如有偏差，更新 spec 或调整实现

### 0.6 OpenSpec 目录模型 (必须理解)

**`specs/` 是当前真相，`archive/` 是变更历史。** 类比 git：specs/ = 当前代码，archive/ = commit 历史。

```
openspec/
├── specs/                          ← 当前系统能力的完整规范（唯一真相）
│   └── [capability]/
│       ├── spec.md                 ← 该能力的当前需求规范
│       └── design.md               ← 该能力的当前技术设计
│
└── changes/
    ├── [active-change]/            ← 进行中的变更
    │   ├── proposal.md
    │   ├── tasks.md
    │   └── specs/[capability]/
    │       └── spec.md             ← delta 变更（增/改/删了什么）
    │
    └── archive/                    ← 已完成的变更历史
        └── YYYY-MM-DD-[name]/
            ├── proposal.md         ← 当时为什么要做这个变更
            ├── design.md           ← 当时的技术设计决策
            ├── tasks.md            ← 当时的任务清单（全部 [x]）
            └── specs/[capability]/
                └── spec.md         ← 当时变更的 delta
```

**归档时必须执行 specs/ 同步**：将 delta spec 合并到 `specs/` 目录，确保 `specs/` 反映系统当前最新状态。

### 0.7 开发完成后 OpenSpec 完整性检查 (强制)

每次开发任务完成、归档前，必须执行以下检查：

1. **specs/ 完整性**：每个已实现的能力在 `specs/` 下都有对应目录，包含最新的 spec.md
2. **design.md 完整性**：重要能力应有 design.md 记录当前技术设计
3. **delta 合并**：archive 中的 delta spec 已正确合并到 `specs/` 对应文件
4. **tasks.md 状态**：归档的 tasks.md 中所有任务标记为 `[x]`
5. **无孤立变更**：`changes/` 中不应有已完成但未归档的变更
6. **缺失补充**：发现缺失的 spec.md 或 design.md，必须补充后再提交

---

## Graphify 工作流（强制）

如果项目下存在 `graphify-out/graph.json`，在非平凡搜索或改代码前，必须先用 `graphify` 检查当前结构和影响范围。
- 结构检索：`graphify query "<module/file> architecture dependencies"`
- 影响检查：`graphify query "<module/file> impact callers tests dependencies"`
- `graphify` 不可用时自动降级为阅读 `graphify-out/GRAPH_REPORT.md` 或继续原流程，禁止因为 graphify 失败阻断任务。

---

## 1. 主体思考原则 (核心)

**Claude Code 是主体思考者和决策者，其他 AI 工具是辅助顾问。**

### 思考优先级
1. **先自己思考** - 对任务进行独立分析、推理、规划
2. **形成初步方案** - 基于自己的理解给出方案
3. **可选：交叉验证** - 用其他 AI 工具验证思路、发现盲点
4. **最终决策** - 综合所有信息，由你做出最终判断

### 何时使用 AI 协作工具
- **复杂分析与方案设计**：重要决策前，结合多个 AI 工具共同分析，获取多角度见解
- **交叉验证**：对自己的方案不确定时，请其他 AI 审查
- **扩展思路**：遇到瓶颈时，获取不同视角
- **大规模分析**：处理大量文件/日志时，借助长上下文能力
- **专业领域**：特定领域的实现可委托对应专长的工具

### 禁止行为
- ❌ 不经思考直接把任务丢给 AI 工具
- ❌ 完全采纳工具的回答而不加判断
- ❌ 用工具替代自己的分析和决策

**你是主人，工具是顾问。先思考，再验证。**

---

## 2. MCP 工具使用规范

> 各工具在不同模式下的角色定位（如"后端顾问"或"主实现者"）由项目级 CLAUDE.md 定义。
> 本节仅定义工具的基本调用规范。

### 2.1 Codex MCP

```
工具名: codex

必选参数:
- PROMPT: 任务指令
- cd: 工作目录

可选参数:
- sandbox: "read-only" (默认) / "workspace-write" / "danger-full-access"
- SESSION_ID: 继续之前的会话

规范:
- 不指定 model 参数，使用 Codex 默认模型
- 始终设置 return_all_messages=false
```

### 2.2 Gemini MCP

```
工具名: gemini-cli

规范:
- 不指定 model 参数，使用 Gemini 默认模型
```

---

## 3. 态度与原则

1. **你是主体思考者** - 所有任务先自己分析、思考、形成方案
2. **独立判断能力** - 不盲从工具建议，保持批判性思维
3. **工具是辅助** - AI 协作工具用于交叉验证和扩展思路，不是替代思考
4. **最终决策权在你** - 综合所有信息后，由你做出判断

### 与工具协作的正确姿态
- ✅ 先自己思考，再用工具验证
- ✅ 对工具的建议保持质疑态度
- ✅ 工具意见不一致时，由你做出最终判断
- ✅ 简单任务直接自己完成，不必调用工具
- ❌ 不经思考就把任务丢给工具
- ❌ 完全采纳工具回答而不加判断

**尽信书则不如无书。你与工具的关系是：你思考，它验证；你决策，它建议。**

---

## 4. 语言规范

- 用户可能使用中文或英文
- **文档**：所有文档（docs/ 目录下的 .md 文件）必须使用**中文**
- **代码注释**：所有代码注释和文档字符串必须使用**中文**
- **代码标识符**：变量名、函数名、类名等使用**英文**
- **配置文件**：配置文件中的键名使用英文，注释使用中文
- **日志消息**：日志消息使用中文
- **日常沟通**：与用户的沟通使用**中文**

### 示例

```python
class UserService:
    """用户服务类

    提供用户相关的业务逻辑处理，包括：
    - 用户认证
    - 用户信息管理
    - 权限验证
    """

    def authenticate(self, username: str, password: str) -> bool:
        """验证用户凭据

        Args:
            username: 用户名
            password: 密码

        Returns:
            验证成功返回 True，否则返回 False
        """
        # 检查用户是否存在
        user = self._find_user(username)
        if not user:
            logger.warning(f"用户不存在: {username}")
            return False

        # 验证密码
        if not self._verify_password(password, user.password_hash):
            logger.warning(f"密码验证失败: {username}")
            return False

        logger.info(f"用户认证成功: {username}")
        return True
```

---

## 5. 项目结构规则

### 虚拟环境
- 运行项目前，先检查是否有虚拟环境（venv/, .venv/, env/）
- 如果存在，必须先激活再执行命令

### 日志目录
- 所有日志文件输出到 `log/` 目录
- 日志命名格式：`{功能名}_{日期}.log`

### 测试目录
- 所有测试代码放在 `tests/` 目录
- 测试文件命名：`test_{模块名}.py`

### 大文件写入
- 写入大文件（超过 200 行）时，必须使用分段写入（先 Write 骨架，再多次 Edit 追加）或通过 Bash `cat <<'EOF'` 命令写入
- 禁止一次性 Write 超大内容，避免输出截断或超时

---

## 6. OpenSpec 文档格式 (标准)

### proposal.md 格式

```markdown
# Change: [变更简述]

## Why
[1-2 句说明问题/机会]

## What Changes
- [变更列表]
- [破坏性变更标记 **BREAKING**]

## Impact
- Affected specs: [影响的能力]
- Affected code: [影响的代码]
```

### spec.md Delta 格式

```markdown
## ADDED Requirements
### Requirement: 新功能
系统 SHALL 提供...

#### Scenario: 成功场景
- **WHEN** 用户执行操作
- **THEN** 预期结果

## MODIFIED Requirements
### Requirement: 现有功能
[完整的修改后需求]

## REMOVED Requirements
### Requirement: 旧功能
**Reason**: [移除原因]
**Migration**: [迁移方案]
```

### tasks.md 格式

```markdown
## 1. Implementation
- [ ] 1.1 创建数据库 schema
- [ ] 1.2 实现 API 端点
- [ ] 1.3 添加前端组件
- [ ] 1.4 编写测试
```

### 目录结构 (统一标准)

```
openspec/
├── project.md              # 项目约定
├── AGENTS.md               # AI 助手指令
├── specs/                  # 当前真相 - 系统现在有什么能力
│   └── [capability]/
│       ├── spec.md         # 该能力的当前需求规范
│       └── design.md       # 该能力的当前技术设计
├── changes/                # 变更提案 - 待变更的内容
│   ├── [change-name]/
│   │   ├── proposal.md     # 为什么、做什么、影响
│   │   ├── tasks.md        # 实现清单
│   │   ├── design.md       # 技术决策（可选）
│   │   └── specs/          # Delta 变更
│   │       └── [capability]/
│   │           └── spec.md # ADDED/MODIFIED/REMOVED
│   └── archive/            # 变更历史
│       └── YYYY-MM-DD-[name]/

docs/
├── plans/                  # 设计文档和实现计划
│   ├── YYYY-MM-DD-{topic}-design.md    # brainstorming 产出
│   └── YYYY-MM-DD-{feature-name}.md    # writing-plans 产出

tests/                      # 测试目录
```

---

*This configuration follows OpenSpec spec-driven development methodology.*
*Harness Version: V2 — Global invariants only. Mode-specific rules in project CLAUDE.md.*
