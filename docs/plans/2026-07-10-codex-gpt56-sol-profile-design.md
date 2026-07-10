# Codex GPT-5.6 Sol 独立 Profile 设计

## 背景

当前 `codex-codex-claude-flow-gpt55-dev` 将 Architecture Codex 路由到 `gpt-5.5` + `xhigh`，将 worker/review 路由到 `gpt-5.4` + `xhigh`。本次新增独立 profile，而不是原地升级旧 profile，确保已有项目仍能复现原有模型组合。

OpenAI 当前 Codex 模型文档给出的 Sol 标识为 `gpt-5.6-sol`。虽然模型选择界面已提供 Max，配置参考中的 `model_reasoning_effort` 严格枚举仍只明确到 `xhigh`，因此主线程也采用 `xhigh`，避免模板在 strict config 下出现兼容性风险。

## 已选方案

新 profile 名称为 `codex-codex-claude-flow-gpt56-sol-dev`，模型矩阵如下：

| 执行体 | 模型 | 推理档位 | 沙箱 |
| --- | --- | --- | --- |
| Architecture Codex | `gpt-5.6-sol` | `xhigh` | 继承主配置 |
| Worker Codex | `gpt-5.5` | `xhigh` | `workspace-write` |
| Review Codex | `gpt-5.5` | `xhigh` | `read-only` |

同时支持两条路径：

- V2：只保存 8 个 profile 专属文件，公共 hooks、tools 和 workflow skills 继续从 `shared/codex` 注入。
- V1：复制完整 profile 运行时树，并在 `scripts/switch-plugin_codex.sh` 中增加 allowlist 与 layout validation。

根 `.gitignore` 增加 V2 profile-local `.codex` 的通用反忽略规则，避免新 profile 的隐藏配置无法进入普通 Git diff。

## 备选方案

原地升级 GPT-5.5 profile 的改动更少，但会让 profile 名称与真实模型不一致，并破坏旧路由的可复现性。只做 V2 可减少 V1 复制，但会让 README 仍声明的兼容入口缺少同级 profile。两者均不采用。

## 数据流

V2 setup/switch 通过目录自动发现新 profile，先安装共享 Codex 资产，再覆盖 profile 专属 `.codex` 文件，最后写入 manifest 与 session state。V1 switcher 先校验 allowlist，再复制完整模板、生成 session state，并执行 profile-specific layout validation。

## 错误处理与回滚

未知或非 Codex profile 继续由 V1/V2 入口以非零状态拒绝。跨 GPT-5.5 到 GPT-5.6 Sol 切换时，旧 session-state 的 Mode 不匹配，V2 应从新模板初始化，避免跨 profile 复用错误状态。

回滚只需移除新 profile、V1 注册项、README 命令和对应测试；旧 GPT-5.5 profile 从始至终不改路由。

## 测试策略

测试必须解析真实 TOML，而不能只断言 `AGENTS.md` 文案：

- V2：覆盖 list、setup、switch、manifest、session state、共享资产与 Git ignore。
- V1：在临时项目执行真实切换脚本并检查落盘布局。
- 回归：明确断言旧 GPT-5.5 profile 仍为主 5.5、worker/review 5.4，全部为 `xhigh`。
- 完整验证：Python 测试、shell syntax、JSON/TOML 解析、OpenSpec strict validation、Git diff check 与 Graphify rebuild/degraded evidence。

当前 PATH 上 Codex CLI 为 0.142.3，低于 GPT-5.6 所需运行时；因此仓库验证可覆盖模板与切换行为，真实模型 smoke test 需在升级且有权限的 Codex 环境完成。
