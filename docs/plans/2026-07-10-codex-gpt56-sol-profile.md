# Codex GPT-5.6 Sol Independent Profile Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 新增 `codex-codex-claude-flow-gpt56-sol-dev`，主线程使用 GPT-5.6 Sol xhigh，worker/review 使用 GPT-5.5 xhigh，并保持 V1/V2 双路径与旧 GPT-5.5 profile 不变。

**Architecture:** V2 采用 shared-first overlay，仅新增 profile 专属文件；V1 保持完整兼容模板并显式注册到 Codex switcher。测试通过真实 setup/switch 落盘与 TOML 解析验证模型路由。

**Tech Stack:** Bash、Python `unittest`、`tomllib`、TOML、JSON、Markdown、OpenSpec。

---

### Task 1: 为 V2 新 profile 建立 RED 测试

**Files:**

- Modify: `tests/test_v2_codex_profiles.py`
- Test: `tests/test_v2_codex_profiles.py`

**Step 1: 增加 TOML 读取帮助函数**

在 imports 中加入：

```python
import tomllib
```

在现有 helper 区域加入：

```python
def read_toml(path):
    with path.open("rb") as handle:
        return tomllib.load(handle)
```

**Step 2: 写入新 profile 的失败测试**

增加以下测试，直接检查源文件与 setup/switch 后的落盘文件：

```python
def test_v2_lists_gpt56_sol_profile(self):
    project = make_v2_project(self.tmp_path, self.env)
    result = run_cmd(
        [str(REPO_ROOT / "v2" / "scripts" / "switch-plugin.sh"), "--list"],
        cwd=project,
        env=self.env,
    )
    self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
    self.assertIn("codex-codex-claude-flow-gpt56-sol-dev", result.stdout)

def test_v2_setup_installs_gpt56_sol_model_routing(self):
    profile = "codex-codex-claude-flow-gpt56-sol-dev"
    project = make_v2_project(self.tmp_path, self.env, mode=profile)
    config = read_toml(project / ".codex" / "config.toml")
    worker = read_toml(project / ".codex" / "agents" / "worker-codex.toml")
    review = read_toml(project / ".codex" / "agents" / "review-codex.toml")

    self.assertEqual(
        (config["model"], config["model_provider"], config["model_reasoning_effort"]),
        ("gpt-5.6-sol", "openai", "xhigh"),
    )
    self.assertEqual(
        (worker["model"], worker["model_provider"], worker["model_reasoning_effort"]),
        ("gpt-5.5", "openai", "xhigh"),
    )
    self.assertEqual(worker["sandbox_mode"], "workspace-write")
    self.assertEqual(
        (review["model"], review["model_provider"], review["model_reasoning_effort"]),
        ("gpt-5.5", "openai", "xhigh"),
    )
    self.assertEqual(review["sandbox_mode"], "read-only")
    self.assertEqual(read_project_manifest(project)["mode"], profile)
    self.assertIn(
        f"# {profile} Workflow State",
        (project / ".codex" / "session-state.md").read_text(encoding="utf-8"),
    )
```

再增加：

- 从 GPT-5.5 profile 切到 GPT-5.6 Sol 后，manifest 更新且旧 Mode session-state 被重建。
- 使用 `git check-ignore --no-index` 断言目标 V2 `.codex/config.toml` 不再被忽略。
- 解析旧 GPT-5.5 profile，断言主模型仍是 5.5、worker/review 仍是 5.4。

**Step 3: 运行 RED 测试**

Run:

```bash
python3 tests/test_v2_codex_profiles.py -k gpt56 -v
```

Expected: FAIL；`--list` 不包含新 profile，setup 报 profile 不存在，目标隐藏文件仍命中 ignore。

**Step 4: 确认失败原因只来自缺失能力**

Run:

```bash
python3 tests/test_v2_codex_profiles.py -k gpt55 -v
```

Expected: PASS；旧 profile 基线不受新增 RED 测试影响。

**Step 5: Commit**

```bash
git add tests/test_v2_codex_profiles.py
git commit -m "test(profiles): specify GPT-5.6 Sol V2 routing"
```

### Task 2: 实现 V2 shared-first profile

**Files:**

- Modify: `.gitignore`
- Create: `v2/scripts/plugin-profiles/codex-codex-claude-flow-gpt56-sol-dev/AGENTS.md`
- Create: `v2/scripts/plugin-profiles/codex-codex-claude-flow-gpt56-sol-dev/settings.json`
- Create: `v2/scripts/plugin-profiles/codex-codex-claude-flow-gpt56-sol-dev/.codex/config.toml`
- Create: `v2/scripts/plugin-profiles/codex-codex-claude-flow-gpt56-sol-dev/.codex/hooks.json`
- Create: `v2/scripts/plugin-profiles/codex-codex-claude-flow-gpt56-sol-dev/.codex/session-state.template.md`
- Create: `v2/scripts/plugin-profiles/codex-codex-claude-flow-gpt56-sol-dev/.codex/skills/skill-rules.json`
- Create: `v2/scripts/plugin-profiles/codex-codex-claude-flow-gpt56-sol-dev/.codex/agents/worker-codex.toml`
- Create: `v2/scripts/plugin-profiles/codex-codex-claude-flow-gpt56-sol-dev/.codex/agents/review-codex.toml`

**Step 1: 解除 V2 profile-local 隐藏文件忽略**

在现有 V1 规则后加入：

```gitignore
!v2/scripts/plugin-profiles/*/.codex/
!v2/scripts/plugin-profiles/*/.codex/**
```

**Step 2: 机械复制 GPT-5.5 V2 profile**

Run:

```bash
cp -R v2/scripts/plugin-profiles/codex-codex-claude-flow-gpt55-dev v2/scripts/plugin-profiles/codex-codex-claude-flow-gpt56-sol-dev
```

只保留现有 8 个 profile 专属文件，不复制 `shared/codex` 中的 hooks、tools 或 workflow skills。

**Step 3: 更新 profile 身份**

在目标目录所有文本文件中，将 `codex-codex-claude-flow-gpt55-dev` 精确替换为 `codex-codex-claude-flow-gpt56-sol-dev`。特别检查：

- `AGENTS.md` 标题、定位、Mode。
- `session-state.template.md` 标题与 Mode。
- `skill-rules.json` 的 profile 描述。
- worker/review TOML 的 description 与 developer instructions。
- `config.toml` 的推荐 V2 switch 命令。

**Step 4: 写入模型路由**

`.codex/config.toml`：

```toml
model = "gpt-5.6-sol"
model_provider = "openai"
model_reasoning_effort = "xhigh"
```

`worker-codex.toml`：

```toml
model = "gpt-5.5"
model_provider = "openai"
model_reasoning_effort = "xhigh"
sandbox_mode = "workspace-write"
```

`review-codex.toml`：

```toml
model = "gpt-5.5"
model_provider = "openai"
model_reasoning_effort = "xhigh"
sandbox_mode = "read-only"
```

同步更新 `AGENTS.md` 的三条模型路由说明。

**Step 5: 运行 GREEN 测试**

Run:

```bash
python3 tests/test_v2_codex_profiles.py -k gpt56 -v
python3 tests/test_v2_codex_profiles.py -k gpt55 -v
```

Expected: PASS。

**Step 6: 检查隐藏文件进入 Git 视图**

Run:

```bash
git status --short
git check-ignore -v --no-index v2/scripts/plugin-profiles/codex-codex-claude-flow-gpt56-sol-dev/.codex/config.toml
```

Expected: 新 `.codex` 文件出现在 status；`git check-ignore` 返回非零且不输出匹配规则。

**Step 7: Commit**

```bash
git add .gitignore v2/scripts/plugin-profiles/codex-codex-claude-flow-gpt56-sol-dev tests/test_v2_codex_profiles.py
git commit -m "feat(profiles): add GPT-5.6 Sol V2 profile"
```

### Task 3: 以 TDD 接入 V1 兼容切换

**Files:**

- Create: `tests/test_v1_codex_profiles.py`
- Modify: `scripts/switch-plugin_codex.sh`
- Create: `scripts/plugin-profiles/codex-codex-claude-flow-gpt56-sol-dev/**`

**Step 1: 写 V1 失败测试**

创建临时项目、建立 `.claude/`，执行真实 switcher：

```python
import os
import subprocess
import tempfile
import tomllib
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
PROFILE = "codex-codex-claude-flow-gpt56-sol-dev"


class V1CodexProfileTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.project = Path(self.tmp.name) / "project"
        (self.project / ".claude").mkdir(parents=True)

    def tearDown(self):
        self.tmp.cleanup()

    def test_v1_switcher_installs_gpt56_sol_routing(self):
        result = subprocess.run(
            [str(REPO_ROOT / "scripts" / "switch-plugin_codex.sh"), PROFILE],
            cwd=self.project,
            env=os.environ.copy(),
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=30,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        with (self.project / ".codex" / "config.toml").open("rb") as handle:
            config = tomllib.load(handle)
        with (self.project / ".codex" / "agents" / "worker-codex.toml").open("rb") as handle:
            worker = tomllib.load(handle)
        with (self.project / ".codex" / "agents" / "review-codex.toml").open("rb") as handle:
            review = tomllib.load(handle)

        self.assertEqual((config["model"], config["model_reasoning_effort"]), ("gpt-5.6-sol", "xhigh"))
        self.assertEqual((worker["model"], worker["model_reasoning_effort"]), ("gpt-5.5", "xhigh"))
        self.assertEqual((review["model"], review["model_reasoning_effort"]), ("gpt-5.5", "xhigh"))
        self.assertEqual(
            (self.project / ".claude" / ".active-plugin").read_text(encoding="utf-8").strip(),
            PROFILE,
        )
```

同时断言：

- `.codex/session-state.md` 的标题和 Mode 使用新 profile。
- worker/review、hooks、tools、commands、skills 均落盘。
- `--help` 输出包含新 profile。

**Step 2: 运行 RED**

Run:

```bash
python3 tests/test_v1_codex_profiles.py -v
```

Expected: FAIL；V1 allowlist 拒绝新 profile。

**Step 3: 复制完整 V1 profile**

Run:

```bash
cp -R scripts/plugin-profiles/codex-codex-claude-flow-gpt55-dev scripts/plugin-profiles/codex-codex-claude-flow-gpt56-sol-dev
```

精确替换所有 profile ID，并按 Task 2 的模型矩阵更新主 config、worker/review、AGENTS、session state、skill rules 与 V1 workflow skill 文案。

**Step 4: 注册 V1 switcher**

在 `SUPPORTED_CODEX_PROFILES` 中加入新 profile。将 GPT-5.5 专用 layout 分支扩展为两者共享：

```bash
elif [[ "$PROFILE_NAME" == "codex-codex-claude-flow-gpt55-dev" ||
        "$PROFILE_NAME" == "codex-codex-claude-flow-gpt56-sol-dev" ]]; then
    [[ -f "$CODEX_DIR/agents/worker-codex.toml" ]] || ok=false
    [[ -f "$CODEX_DIR/agents/review-codex.toml" ]] || ok=false
    [[ -f "$CODEX_DIR/tools/graphify-java-project.sh" ]] || ok=false
```

**Step 5: 运行 GREEN**

Run:

```bash
python3 tests/test_v1_codex_profiles.py -v
bash -n scripts/switch-plugin_codex.sh
```

Expected: PASS。

**Step 6: Commit**

```bash
git add scripts/switch-plugin_codex.sh scripts/plugin-profiles/codex-codex-claude-flow-gpt56-sol-dev tests/test_v1_codex_profiles.py
git commit -m "feat(profiles): add GPT-5.6 Sol V1 compatibility"
```

### Task 4: 文档化并验证 profile/runtime 同步

**Files:**

- Modify: `README.md`
- Modify: `tests/test_v2_codex_profiles.py`

**Step 1: 写 README 失败断言**

新增测试，读取 `README.md` 并断言包含：

```text
v2/setup-project.sh --mode=codex-codex-claude-flow-gpt56-sol-dev
v2/scripts/switch-plugin.sh codex-codex-claude-flow-gpt56-sol-dev
scripts/switch-plugin_codex.sh codex-codex-claude-flow-gpt56-sol-dev
```

**Step 2: 运行 RED**

Run:

```bash
python3 tests/test_v2_codex_profiles.py -k readme -v
```

Expected: FAIL；README 尚无新命令。

**Step 3: 更新 README**

- 在 GPT-5.5 V2 setup 命令后增加 GPT-5.6 Sol 独立 profile 命令。
- 在 V2 switch 区增加新 profile 命令。
- 在 V1 compatibility 区增加新 profile 命令，并标明主 5.6 Sol xhigh、worker/review 5.5 xhigh。
- 保留 GPT-5.5 现有推荐与命令。

**Step 4: 搜索同步漂移**

Run:

```bash
rg -n --hidden "gpt55|gpt-5.5|gpt-5.4" scripts/plugin-profiles/codex-codex-claude-flow-gpt56-sol-dev v2/scripts/plugin-profiles/codex-codex-claude-flow-gpt56-sol-dev
```

Expected: 只允许 worker/review 的 `gpt-5.5`；不允许新 profile 中残留旧 profile ID 或 `gpt-5.4`。

**Step 5: 运行 GREEN**

Run:

```bash
python3 tests/test_v2_codex_profiles.py -k readme -v
```

Expected: PASS。

**Step 6: Commit**

```bash
git add README.md tests/test_v2_codex_profiles.py
git commit -m "docs(profiles): document GPT-5.6 Sol switching"
```

### Task 5: 完整验证、Graphify 更新与 OpenSpec 收口

**Files:**

- Modify: `openspec/changes/add-codex-gpt56-sol-profile/tasks.md`

**Step 1: 运行完整回归**

Run:

```bash
python3 tests/test_v1_codex_profiles.py
python3 tests/test_v2_codex_profiles.py
bash tests/test_v2_setup_global_codex.sh
```

Expected: 全部 PASS。

**Step 2: 验证配置与脚本语法**

Run:

```bash
bash -n scripts/switch-plugin_codex.sh v2/setup-project.sh v2/scripts/switch-plugin.sh
python3 -m json.tool v2/scripts/plugin-profiles/codex-codex-claude-flow-gpt56-sol-dev/settings.json
python3 -m json.tool v2/scripts/plugin-profiles/codex-codex-claude-flow-gpt56-sol-dev/.codex/hooks.json
python3 -m json.tool v2/scripts/plugin-profiles/codex-codex-claude-flow-gpt56-sol-dev/.codex/skills/skill-rules.json
```

使用 `tomllib` 遍历 V1/V2 新 profile 的三个 TOML 文件并解析，Expected: 无异常。

**Step 3: 验证 Git ignore**

Run:

```bash
git check-ignore -q --no-index v2/scripts/plugin-profiles/codex-codex-claude-flow-gpt56-sol-dev/.codex/config.toml
```

Expected: exit 1，表示目标文件未被忽略。

**Step 4: 按项目规则更新 Graphify**

Run:

```bash
python3 -c "from graphify.watch import _rebuild_code; from pathlib import Path; _rebuild_code(Path('.'))"
```

Expected: 图谱更新成功；若 `graphify` 模块仍不可用，记录命令、错误和降级依据，不阻断交付。

**Step 5: 标记 tasks 完成并严格校验**

只有前述任务均有证据后，才将 `tasks.md` 全部改为 `[x]`。

Run:

```bash
openspec validate add-codex-gpt56-sol-profile --strict --no-interactive
git diff --check
git status --short
```

Expected: OpenSpec valid；无 whitespace error；status 只包含本 change 的预期文件。

**Step 6: 请求独立审查**

使用 `requesting-code-review`，重点审查：

- 主/worker/review 路由是否与批准矩阵一致。
- V1/V2 profile 是否同步且未复制 V2 shared assets。
- GPT-5.5 profile 是否保持不变。
- session-state 与 manifest 是否使用新 profile ID。
- 测试是否检查实际 TOML 和真实切换结果。

**Step 7: Commit**

```bash
git add openspec/changes/add-codex-gpt56-sol-profile/tasks.md
git commit -m "chore(openspec): complete GPT-5.6 Sol profile change"
```
