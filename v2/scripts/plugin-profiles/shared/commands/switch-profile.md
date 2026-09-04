---
name: Switch Profile
description: 在会话内切换 harness profile（superpowers / mps / ecc / omc / teams / codex-*）。
category: Harness
tags: [harness, profile, switch]
argument-hint: "[profile] | --status | --list | [profile] --dry-run"
---

**职责边界**

本命令是 `switch-plugin.sh` 的会话内封装。**禁止自行实现切换逻辑**——所有文件操作一律委托给脚本，
避免出现第二套需要同步维护的切换代码。你的工作只有三件：解析模板路径、做安全确认、转述脚本输出。

---

**步骤 1：解析模板仓库路径**

按以下顺序解析，取第一个命中的：

1. 读取 `.claude/.harness-manifest.json` 的 `templateRoot` 字段
   （`manifestSchemaVersion >= 2` 才有；用 Read 工具读取，不要用 shell 拼 JSON 解析）
2. 环境变量 `AI_CONFIG_TEMPLATES_ROOT`
3. 候选路径依次探测：`~/aicoding/ai-config-templates`、`~/.claude/config-templates`

解析到候选路径后**必须校验** `<root>/v2/scripts/switch-plugin.sh` 存在，否则继续尝试下一个。

全部失败时，停止执行并输出以下指引，**不要静默失败、不要猜测路径**：

```
无法定位 switch-plugin.sh。请任选其一修复：
  1. 重跑 <模板仓库>/v2/setup-project.sh（会写入 templateRoot）
  2. export AI_CONFIG_TEMPLATES_ROOT=<模板仓库绝对路径>
```

记 `SWITCHER="<root>/v2/scripts/switch-plugin.sh"`。

---

**步骤 1b：在多副本中挑出真正支持目标 profile 的那个**

机器上可能同时存在**多个模板仓库副本**（例如一个已部署副本 + 一个开发副本），
它们的 profile 集合可能不同。指定 profile 时（`--status`/`--list` 跳过本步）：

1. 先看步骤 1 选中的 root 是否有 `<root>/v2/scripts/plugin-profiles/<profile>/`。有 → 直接用。
2. 没有 → **依次检查其余候选**（manifest 值、`AI_CONFIG_TEMPLATES_ROOT`、
   `~/aicoding/ai-config-templates`、`~/.claude/config-templates`），
   挑第一个含该 profile 的副本，并**告知用户你换用了哪个副本、为什么**。
3. 全都没有 → 中止，输出：

```
所有已知模板副本中都没有 profile「<profile>」：
  <root1>: <该副本可用的 profile 列表>
  <root2>: <...>
请确认该 profile 所在的模板仓库，然后：
  export AI_CONFIG_TEMPLATES_ROOT=<正确的模板仓库绝对路径>
```

> 切换成功后 `switch-plugin.sh` 会把它自己的仓库路径写回 manifest 的 `templateRoot`，
> 所以**同一项目的后续切换会直接命中正确副本**，无需再走候选扫描。

---

**步骤 1c：确定项目根，所有调用都必须在项目根执行**

`switch-plugin.sh` 内部用 `PROJECT_DIR="$(pwd)"` 判定目标项目。**在子目录执行会静默误报
「项目版本: 未初始化」**，而不是报错——这是最容易踩的坑。

因此每次调用都要显式带上项目根：

```
cd <包含 .claude/.harness-manifest.json 的目录> && <SWITCHER> ...
```

项目根 = 向上查找到含 `.claude/.harness-manifest.json` 的最近目录。不要依赖当前 shell 的 cwd。

---

**步骤 2：按参数分派**

- 无参数、`--status`、`--list` → 直接执行 `$SWITCHER --status` 或 `$SWITCHER --list`，转述输出后结束。
- 带 `--dry-run` → 直接执行 `$SWITCHER <profile> --dry-run`，转述输出后结束（无副作用）。
- 指定 profile 且无 `--dry-run` → 进入步骤 3。

---

**步骤 3：切换前的安全确认**

**3a. 目标为 Codex-native profile（名称以 `codex-` 开头）时，强制二次确认。**

这类切换会**删除项目根 `CLAUDE.md`** 并改用 `AGENTS.md`，等于在当前 Claude 会话内自毁项目配置。
必须先向用户说明以下三点，并在用户明确确认前**不执行任何操作**：

- 项目根 `CLAUDE.md` 将被删除，改为 `AGENTS.md`
- 当前 Claude 会话的项目配置随之失效
- 后续需改用 Codex CLI 工作；要切回来须再次运行本命令并指定 Claude 侧 profile

**3b. 先跑一次 `--dry-run` 预览。**

正式切换前执行 `$SWITCHER <profile> --dry-run`，把将要发生的变更转述给用户。

若 dry-run 输出提示**检测到 profile 入口文件已被手动修改**（漂移），正式执行会以退出码 2
失败并拒绝继续——会话内不是交互终端，脚本无法安全地询问是否覆盖。

此时**先把漂移的具体内容告诉用户**（`git diff` 项目根 `CLAUDE.md` / `AGENTS.md`），
让用户决定，然后二选一：

- 用户确认丢弃本地修改 → 执行 `<SWITCHER> <profile> --force-overwrite`
- 用户想保留 → 中止，提示先把修改提交或备份

**不要自作主张加 `--force-overwrite`**：漂移意味着有人手工改过配置，覆盖是有损操作。

> 常见诱因：跑过 `/setup-matt-pocock-skills`——它会向 `CLAUDE.md` 追加 `## Agent skills` 块，
> 必然制造漂移。

---

**步骤 4：执行切换**

执行 `$SWITCHER <profile>`，然后转述脚本输出的注意事项。

无论脚本说什么，**必须**额外强调这两条：

1. **切换只对下一次会话生效**，当前会话仍在用旧配置，需退出后重新运行 `claude`
2. 切换期间脚本会重建 `.claude/hooks/`，**请勿并发执行其他操作**

若目标为 `mps`，额外提示首次使用需要：

```
claude plugin marketplace add mattpocock/skills
```

并提示运行 `/setup-matt-pocock-skills` 时选择**本地文件**模式——本 harness 以 `openspec/` 为规范
真相源，不使用 issue tracker。
