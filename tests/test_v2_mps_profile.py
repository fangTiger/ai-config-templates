"""V2 mps profile 与 /switch-profile 命令的回归测试。

覆盖：
- mps profile 目录结构与 settings.json 插件开关
- 产出落点走 docs/agents/issue-tracker.md 这一 skill 原生扩展点
- 第三方插件引入的外部写操作有 deny 兜底
- skill-rules.json 为全量文件而非增量
- /switch-profile 命令随 shared/commands 分发
- manifest 的 templateRoot 字段与 schema 版本
"""

import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
PROFILES_DIR = REPO_ROOT / "v2" / "scripts" / "plugin-profiles"
MPS_PROFILE = "mps"
MPS_CODEX_PROFILE = "codex-codex-mps-dev"
MPS_HANDOFF_PROFILE = "codex-mps-dev"
MATTPOCOCK_PLUGIN_KEY = "mattpocock-skills@mattpocock"
SUPERPOWERS_PLUGIN_KEY = "superpowers@superpowers-marketplace"

# shared/skills/skill-rules.json 的基线条目，mps 必须全量继承（覆盖而非增量）
SHARED_SKILL_KEYS = {
    "dev-workflow",
    "git-workflow",
    "skill-developer",
    "python-backend-guidelines",
    "python-error-tracking",
}


def run_cmd(args, cwd, env):
    return subprocess.run(
        args,
        cwd=cwd,
        env=env,
        input="n\nn\nn\n",
        text=True,
        errors="replace",
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=60,
    )


def make_env(tmp_path):
    home = tmp_path / "home"
    home.mkdir()
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    npm = bin_dir / "npm"
    npm.write_text("#!/bin/sh\nexit 0\n", encoding="utf-8")
    npm.chmod(0o755)
    claude_dir = home / ".claude"
    claude_dir.mkdir()
    (claude_dir / ".harness-manifest.json").write_text(
        json.dumps({"harnessVersion": "v2"}),
        encoding="utf-8",
    )
    env = os.environ.copy()
    env["HOME"] = str(home)
    env["PATH"] = f"{bin_dir}{os.pathsep}{env.get('PATH', '')}"
    return env


def make_v2_project(tmp_path, env, mode="superpowers"):
    project = tmp_path / "project"
    project.mkdir()
    result = run_cmd(
        [str(REPO_ROOT / "v2" / "setup-project.sh"), f"--mode={mode}", str(project)],
        cwd=REPO_ROOT,
        env=env,
    )
    assert result.returncode == 0, result.stdout + result.stderr
    return project


def switch_to(project, env, profile, *extra):
    return run_cmd(
        [str(REPO_ROOT / "v2" / "scripts" / "switch-plugin.sh"), profile, *extra],
        cwd=project,
        env=env,
    )


def read_project_manifest(project):
    return json.loads(
        (project / ".claude" / ".harness-manifest.json").read_text(encoding="utf-8")
    )


def read_json(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))


class MpsProfileTemplateTests(unittest.TestCase):
    """不依赖切换执行的静态模板检查。"""

    def test_profile_directory_structure(self):
        profile = PROFILES_DIR / MPS_PROFILE
        self.assertTrue((profile / "CLAUDE.md").is_file(), "缺少 CLAUDE.md")
        self.assertTrue((profile / "settings.json").is_file(), "缺少 settings.json")
        self.assertTrue(
            (profile / "skills" / "skill-rules.json").is_file(),
            "缺少 skills/skill-rules.json",
        )

    def test_settings_toggles_plugins(self):
        settings = read_json(PROFILES_DIR / MPS_PROFILE / "settings.json")
        plugins = settings["enabledPlugins"]
        self.assertIs(
            plugins[MATTPOCOCK_PLUGIN_KEY], True, "mattpocock 插件必须启用"
        )
        self.assertIs(
            plugins[SUPERPOWERS_PLUGIN_KEY], False, "mps 模式下必须关闭 superpowers"
        )

    def test_settings_keeps_hooks(self):
        settings = read_json(PROFILES_DIR / MPS_PROFILE / "settings.json")
        for event in ("UserPromptSubmit", "PreToolUse", "PostToolUse"):
            self.assertIn(event, settings["hooks"], f"缺少 {event} hook")

    def test_claude_md_declares_mode(self):
        text = (PROFILES_DIR / MPS_PROFILE / "CLAUDE.md").read_text(encoding="utf-8")
        self.assertIn("<!-- harness-mode: mps -->", text)

    def test_claude_md_declares_output_mapping(self):
        """产出落点映射必须存在，且权威定义指向 skill 原生扩展点。"""
        text = (PROFILES_DIR / MPS_PROFILE / "CLAUDE.md").read_text(encoding="utf-8")
        for skill in ("to-spec", "to-tickets", "grill-with-docs", "domain-modeling"):
            self.assertIn(skill, text, f"落点映射缺少 {skill}")
        self.assertIn("openspec/changes/", text)
        self.assertIn("CONTEXT.md", text)
        # 权威定义必须落在 skill 原生扩展点上，而不是靠本文件声明压制 skill 正文
        self.assertIn(
            "docs/agents/issue-tracker.md", text, "未指向 skill 原生扩展点"
        )
        self.assertTrue(
            "以 `docs/agents/issue-tracker.md` 为准" in text,
            "未声明冲突时以扩展点配置为准",
        )

    def test_claude_md_inlines_superpowers_gaps(self):
        """关闭 superpowers 后，验证与分支集成能力必须以内联规则补齐。"""
        text = (PROFILES_DIR / MPS_PROFILE / "CLAUDE.md").read_text(encoding="utf-8")
        self.assertIn("证据先于断言", text)
        self.assertIn("分支集成", text)

    def test_claude_md_keeps_commit_trailer(self):
        text = (PROFILES_DIR / MPS_PROFILE / "CLAUDE.md").read_text(encoding="utf-8")
        self.assertIn("Co-Authored-By: Claude Code <claude-code@anthropic.com>", text)

    def test_skill_rules_is_full_file_not_delta(self):
        """profile 的 skill-rules.json 覆盖 shared 同名文件，必须全量包含基线条目。"""
        rules = read_json(PROFILES_DIR / MPS_PROFILE / "skills" / "skill-rules.json")
        keys = set(rules["skills"].keys())
        missing = SHARED_SKILL_KEYS - keys
        self.assertFalse(missing, f"丢失 shared 基线条目: {sorted(missing)}")

    def test_switch_profile_command_ships_in_shared(self):
        command = PROFILES_DIR / "shared" / "commands" / "switch-profile.md"
        self.assertTrue(command.is_file(), "缺少 shared/commands/switch-profile.md")
        text = command.read_text(encoding="utf-8")
        self.assertIn("AI_CONFIG_TEMPLATES_ROOT", text, "缺少环境变量回退")
        self.assertIn("templateRoot", text, "缺少 manifest 路径解析")
        self.assertIn("codex-", text, "缺少 codex-native 二次确认说明")

    def test_switch_profile_command_guards_stale_template_copy(self):
        """机器上可能有多个模板副本，命令必须校验目标 profile 在该副本中存在。"""
        command = PROFILES_DIR / "shared" / "commands" / "switch-profile.md"
        text = command.read_text(encoding="utf-8")
        self.assertIn("plugin-profiles/<profile>", text, "缺少 profile 存在性校验")
        self.assertIn("依次检查其余候选", text, "未在多副本中择优")
        self.assertIn("templateRoot", text, "未说明切换后 manifest 自愈")

    def test_switch_profile_command_pins_project_root(self):
        """switch-plugin.sh 用 pwd 判定项目，子目录执行会静默误报未初始化。"""
        command = PROFILES_DIR / "shared" / "commands" / "switch-profile.md"
        text = command.read_text(encoding="utf-8")
        self.assertIn("PROJECT_DIR", text, "未说明脚本依赖 pwd")
        self.assertIn("未初始化", text, "未警示子目录执行会误报")
        self.assertIn(".claude/.harness-manifest.json", text, "未给出项目根判定依据")

    def test_ships_issue_tracker_config_as_project_file(self):
        """落点必须走 skill 原生扩展点 docs/agents/issue-tracker.md，而非只靠 CLAUDE.md 声明。"""
        tracker = (
            PROFILES_DIR
            / MPS_PROFILE
            / "project-files"
            / "docs"
            / "agents"
            / "issue-tracker.md"
        )
        self.assertTrue(tracker.is_file(), "缺少 project-files/docs/agents/issue-tracker.md")
        text = tracker.read_text(encoding="utf-8")
        # skill 正文里的三个查询锚点必须被应答
        self.assertIn("publish to the issue tracker", text)
        self.assertIn("fetch the relevant ticket", text)
        self.assertIn("openspec/changes/", text)
        # 文件会提到 .scratch/，但必须是禁止语义而非落点
        self.assertIn("do not create `.scratch/`", text.lower().replace("**", ""),
                      "未显式禁止 .scratch 落点")
        self.assertIn("gh issue create", text, "未显式禁止外部 tracker 调用")

    def test_issue_tracker_config_resolves_one_file_per_ticket(self):
        """上游 to-tickets 明确禁止单一合并文件，配置必须正面处理该冲突。"""
        tracker = (
            PROFILES_DIR / MPS_PROFILE / "project-files" / "docs" / "agents" / "issue-tracker.md"
        )
        text = tracker.read_text(encoding="utf-8")
        self.assertIn("tasks.md", text, "未说明 ticket 在 OpenSpec 下的载体")
        self.assertIn("one file per ticket", text, "未正面处理一票一文件的冲突")

    def test_claude_md_does_not_claim_local_file_mode(self):
        """上游本地模式路径写死 .scratch/，'选本地文件模式'是错误指引。"""
        text = (PROFILES_DIR / MPS_PROFILE / "CLAUDE.md").read_text(encoding="utf-8")
        self.assertNotIn("本地文件", text, "残留错误的 setup 指引")
        self.assertIn("Other", text, "未指向正确的 setup 选项")

    def test_settings_denies_external_tracker_mutations(self):
        """第三方 skill 可创建/关闭 issue、触碰 secrets，必须有 deny 兜底。"""
        settings = read_json(PROFILES_DIR / MPS_PROFILE / "settings.json")
        deny = settings["permissions"]["deny"]
        for rule in (
            "Bash(gh issue:*)",
            "Bash(gh secret:*)",
            "Bash(git push --force:*)",
            "Bash(rm -rf /:*)",
        ):
            self.assertIn(rule, deny, f"缺少 deny 规则: {rule}")

    def test_switcher_refuses_drift_confirm_without_tty(self):
        """set -e + 裸 read 在非 TTY 下会静默退出；必须显式检测 TTY。"""
        text = (REPO_ROOT / "v2" / "scripts" / "switch-plugin.sh").read_text(
            encoding="utf-8"
        )
        self.assertIn("-t 0", text, "漂移确认未检测 TTY")

    def test_setup_escapes_template_root_for_json(self):
        """heredoc 直插路径，含引号/反斜杠的安装路径会生成非法 manifest。"""
        text = (REPO_ROOT / "v2" / "setup-project.sh").read_text(encoding="utf-8")
        self.assertIn("TEMPLATE_ROOT_JSON", text, "templateRoot 未做 JSON 转义")

    def test_switcher_lists_mps(self):
        text = (REPO_ROOT / "v2" / "scripts" / "switch-plugin.sh").read_text(
            encoding="utf-8"
        )
        self.assertTrue("mps" in text, "switch-plugin.sh usage 未提及 mps")


class MpsHandoffProfileTests(unittest.TestCase):
    """codex-mps-dev：Claude 设计 + Codex 实现，mps 工作流。"""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.tmp_path = Path(self.tmp.name)
        self.env = make_env(self.tmp_path)

    def tearDown(self):
        self.tmp.cleanup()

    def test_is_claude_side_not_codex_native(self):
        """入口是 CLAUDE.md：Claude 仍是主脑，不能被识别为 codex-native。"""
        profile = PROFILES_DIR / MPS_HANDOFF_PROFILE
        self.assertTrue((profile / "CLAUDE.md").is_file(), "缺少 CLAUDE.md")
        self.assertFalse(
            (profile / "AGENTS.md").is_file() and (profile / ".codex").is_dir(),
            "不应被判定为 codex-native",
        )

    def test_ships_handoff_and_codex_openspec_skills(self):
        profile = PROFILES_DIR / MPS_HANDOFF_PROFILE
        self.assertTrue(
            (profile / "skills" / "codex-handoff" / "SKILL.md").is_file(),
            "缺少 codex-handoff skill",
        )
        for name in (
            "openspec-propose",
            "openspec-apply-change",
            "openspec-archive-change",
            "openspec-explore",
        ):
            self.assertTrue(
                (profile / "codex" / "skills" / name / "SKILL.md").is_file(),
                f"缺少 Codex 侧 {name}",
            )

    def test_claude_md_uses_mattpocock_chain_not_superpowers(self):
        """关闭 superpowers 后，流水线各阶段必须换成 mattpocock 对应物。"""
        text = (PROFILES_DIR / MPS_HANDOFF_PROFILE / "CLAUDE.md").read_text(
            encoding="utf-8"
        )
        self.assertIn("<!-- harness-mode: codex-mps-dev -->", text)
        for skill in ("grill-with-docs", "to-spec", "to-tickets", "code-review"):
            self.assertIn(skill, text, f"流水线未使用 {skill}")
        self.assertNotIn(
            "superpowers:brainstorming", text, "仍引用已关闭的 superpowers skill"
        )
        self.assertNotIn("superpowers:writing-plans", text)
        self.assertNotIn("superpowers:verification-before-completion", text)

    def test_claude_md_keeps_handoff_pipeline(self):
        """必须保留 codex-dev 的交接流水线，这是本 profile 的存在理由。"""
        text = (PROFILES_DIR / MPS_HANDOFF_PROFILE / "CLAUDE.md").read_text(
            encoding="utf-8"
        )
        for marker in ("HANDOFF", "codex-handoff", "FileAllowlist", "Executor"):
            self.assertIn(marker, text, f"交接流水线缺少 {marker}")

    def test_settings_match_mps_plugin_and_deny(self):
        settings = read_json(PROFILES_DIR / MPS_HANDOFF_PROFILE / "settings.json")
        plugins = settings["enabledPlugins"]
        self.assertIs(plugins[MATTPOCOCK_PLUGIN_KEY], True)
        self.assertIs(plugins[SUPERPOWERS_PLUGIN_KEY], False)
        self.assertIn("Bash(gh issue:*)", settings["permissions"]["deny"])
        # Codex MCP 必须可用，否则交接无从谈起
        self.assertIn("mcp__codex__*", settings["permissions"]["allow"])

    def test_switch_installs_handoff_profile(self):
        project = make_v2_project(self.tmp_path, self.env)
        result = switch_to(project, self.env, MPS_HANDOFF_PROFILE)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

        self.assertIn(
            "<!-- harness-mode: codex-mps-dev -->",
            (project / "CLAUDE.md").read_text(encoding="utf-8"),
        )
        # AGENTS.md 是 setup 装的 OpenCode 模板，Claude 侧 profile 间切换不动它；
        # 关键是项目未被当作 codex-native（入口仍是 CLAUDE.md）
        self.assertFalse(
            (PROFILES_DIR / MPS_HANDOFF_PROFILE / "AGENTS.md").exists(),
            "profile 自身不应带 AGENTS.md",
        )
        self.assertTrue(
            (project / ".claude/skills/codex-handoff/SKILL.md").is_file(),
            "codex-handoff 未安装到 .claude/skills/",
        )
        self.assertTrue(
            (project / ".codex/skills/openspec-propose/SKILL.md").is_file(),
            "Codex 侧 openspec skill 未安装",
        )
        self.assertTrue(
            (project / "docs/agents/issue-tracker.md").is_file(),
            "缺少落点配置",
        )

    def test_three_mps_profiles_share_one_tracker_config(self):
        """三个 mps profile 必须共用同一份落点配置，语义不得分叉。"""
        texts = {}
        for name in (MPS_PROFILE, MPS_HANDOFF_PROFILE, MPS_CODEX_PROFILE):
            f = (
                PROFILES_DIR
                / name
                / "project-files"
                / "docs"
                / "agents"
                / "issue-tracker.md"
            )
            self.assertTrue(f.is_file(), f"{name} 缺少落点配置")
            texts[name] = f.read_text(encoding="utf-8")
        self.assertEqual(
            len(set(texts.values())), 1, "三个 profile 的落点配置内容不一致"
        )


class MpsCodexNativeProfileTests(unittest.TestCase):
    """codex-codex-mps-dev：Codex 主工作台上的 mps。"""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.tmp_path = Path(self.tmp.name)
        self.env = make_env(self.tmp_path)

    def tearDown(self):
        self.tmp.cleanup()

    def test_is_recognised_as_codex_native(self):
        profile = PROFILES_DIR / MPS_CODEX_PROFILE
        self.assertTrue((profile / "AGENTS.md").is_file(), "缺少 AGENTS.md")
        self.assertTrue((profile / ".codex").is_dir(), "缺少 .codex/")

    def test_ships_exactly_the_plugin_skill_set(self):
        """Codex 侧的文件副本必须与 Claude 侧插件发布的 skill 集合一致。"""
        plugin_json = (
            Path.home()
            / ".claude/plugins/marketplaces/mattpocock/.claude-plugin/plugin.json"
        )
        if not plugin_json.is_file():
            self.skipTest("mattpocock marketplace 未安装，跳过集合比对")
        wanted = {
            p.rsplit("/", 1)[-1] for p in json.loads(plugin_json.read_text())["skills"]
        }
        shipped = {
            d.name
            for d in (PROFILES_DIR / MPS_CODEX_PROFILE / ".codex" / "skills").iterdir()
            if d.is_dir()
        }
        self.assertEqual(shipped, wanted, "skill 集合与插件发布清单不一致")

    def test_session_state_template_passes_validator(self):
        """必须满足 switch-plugin.sh 的 validate_session_state_file。"""
        text = (
            PROFILES_DIR
            / MPS_CODEX_PROFILE
            / ".codex"
            / "session-state.template.md"
        ).read_text(encoding="utf-8")
        for pattern in (
            f"# {MPS_CODEX_PROFILE} Workflow State",
            f"## Mode: {MPS_CODEX_PROFILE}",
            "## ChangeId:",
            "## Current Stage:",
        ):
            self.assertIn(pattern, text, f"session-state 模板缺少: {pattern}")

    def test_agents_md_defers_to_tracker_config(self):
        """不得重复 Claude 侧被证伪的'声明压制'做法，必须指向扩展点。"""
        text = (PROFILES_DIR / MPS_CODEX_PROFILE / "AGENTS.md").read_text(
            encoding="utf-8"
        )
        self.assertIn("docs/agents/issue-tracker.md", text, "未指向落点配置文件")
        self.assertIn("以 `docs/agents/issue-tracker.md` 为准", text)
        self.assertIn("gh issue create", text, "未禁止外部 tracker 调用")

    def test_switch_installs_codex_native_assets(self):
        project = make_v2_project(self.tmp_path, self.env)
        result = switch_to(project, self.env, MPS_CODEX_PROFILE)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

        self.assertTrue((project / "AGENTS.md").is_file(), "缺少 AGENTS.md")
        self.assertFalse((project / "CLAUDE.md").exists(), "CLAUDE.md 未被移除")
        for rel in (
            ".codex/config.toml",
            ".codex/hooks.json",
            ".codex/session-state.md",
            ".codex/session-state.template.md",
        ):
            self.assertTrue((project / rel).is_file(), f"缺少 {rel}")
        self.assertTrue(
            (project / ".codex/skills/to-spec/SKILL.md").is_file(),
            "skill 文件副本未安装",
        )
        # 落点配置在 codex-native 分支同样要安装
        self.assertTrue(
            (project / "docs/agents/issue-tracker.md").is_file(),
            "codex-native 分支缺少落点配置",
        )
        self.assertEqual(read_project_manifest(project)["mode"], MPS_CODEX_PROFILE)

    def test_switch_back_to_claude_side_restores_claude_md(self):
        project = make_v2_project(self.tmp_path, self.env)
        switch_to(project, self.env, MPS_CODEX_PROFILE)
        result = switch_to(project, self.env, MPS_PROFILE)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue((project / "CLAUDE.md").is_file(), "CLAUDE.md 未恢复")
        self.assertFalse((project / "AGENTS.md").exists(), "AGENTS.md 未清理")


class MpsProfileSwitchTests(unittest.TestCase):
    """执行真实切换流程的集成检查。"""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.tmp_path = Path(self.tmp.name)
        self.env = make_env(self.tmp_path)

    def tearDown(self):
        self.tmp.cleanup()

    def test_setup_writes_template_root(self):
        project = make_v2_project(self.tmp_path, self.env)
        manifest = read_project_manifest(project)
        self.assertEqual(manifest["manifestSchemaVersion"], 2)
        self.assertIn("templateRoot", manifest)
        template_root = Path(manifest["templateRoot"])
        self.assertTrue(
            (template_root / "v2" / "scripts" / "switch-plugin.sh").is_file(),
            "templateRoot 未指向有效的模板仓库",
        )

    def test_setup_installs_project_files(self):
        """setup --mode=<profile> 必须和 switch 一样安装 project-files，否则落点机制失效。"""
        project = make_v2_project(self.tmp_path, self.env, mode=MPS_PROFILE)
        tracker = project / "docs" / "agents" / "issue-tracker.md"
        self.assertTrue(
            tracker.is_file(),
            "setup --mode=mps 未安装 docs/agents/issue-tracker.md",
        )
        self.assertIn("openspec/changes/", tracker.read_text(encoding="utf-8"))

    def test_list_includes_mps(self):
        project = make_v2_project(self.tmp_path, self.env)
        result = run_cmd(
            [str(REPO_ROOT / "v2" / "scripts" / "switch-plugin.sh"), "--list"],
            cwd=project,
            env=self.env,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("mps", result.stdout)

    def test_switch_to_mps_installs_profile(self):
        project = make_v2_project(self.tmp_path, self.env)
        result = switch_to(project, self.env, MPS_PROFILE)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

        claude_md = (project / "CLAUDE.md").read_text(encoding="utf-8")
        self.assertIn("<!-- harness-mode: mps -->", claude_md)

        settings = read_json(project / ".claude" / "settings.json")
        self.assertIs(settings["enabledPlugins"][MATTPOCOCK_PLUGIN_KEY], True)
        self.assertIs(settings["enabledPlugins"][SUPERPOWERS_PLUGIN_KEY], False)

        self.assertEqual(read_project_manifest(project)["mode"], MPS_PROFILE)

    def test_switch_preserves_template_root(self):
        project = make_v2_project(self.tmp_path, self.env)
        before = read_project_manifest(project)["templateRoot"]
        switch_to(project, self.env, MPS_PROFILE)
        after = read_project_manifest(project)
        self.assertEqual(after.get("templateRoot"), before, "切换擦除了 templateRoot")

    def test_switch_installs_switch_profile_command(self):
        project = make_v2_project(self.tmp_path, self.env)
        switch_to(project, self.env, MPS_PROFILE)
        self.assertTrue(
            (project / ".claude" / "commands" / "switch-profile.md").is_file(),
            "切换后缺少 .claude/commands/switch-profile.md",
        )

    def test_refuses_to_switch_inside_template_repo(self):
        """在模板仓库自身执行切换会覆盖其交付物（V1 CLAUDE.md 模板），必须拒绝。"""
        result = run_cmd(
            [str(REPO_ROOT / "v2" / "scripts" / "switch-plugin.sh"), MPS_PROFILE],
            cwd=REPO_ROOT,
            env=self.env,
        )
        self.assertNotEqual(result.returncode, 0, "在模板仓库内切换本应被拒绝")
        self.assertIn("模板仓库", result.stdout + result.stderr)

    def test_switch_self_heals_template_root(self):
        """切换器知道自己的位置，应把 templateRoot 写回 manifest，使旧项目自愈。"""
        project = make_v2_project(self.tmp_path, self.env)
        # 模拟 schema v1 旧项目：抹掉 templateRoot
        mf = project / ".claude" / ".harness-manifest.json"
        data = json.loads(mf.read_text(encoding="utf-8"))
        data.pop("templateRoot", None)
        data["manifestSchemaVersion"] = 1
        mf.write_text(json.dumps(data, indent=2), encoding="utf-8")

        switch_to(project, self.env, MPS_PROFILE)

        healed = read_project_manifest(project)
        self.assertEqual(healed["manifestSchemaVersion"], 2, "未升级 schema 版本")
        self.assertEqual(
            Path(healed["templateRoot"]).resolve(),
            REPO_ROOT.resolve(),
            "templateRoot 未指向执行切换的那个模板副本",
        )

    def test_switch_installs_project_files(self):
        """project-files/** 必须落到项目根，否则落点配置不生效。"""
        project = make_v2_project(self.tmp_path, self.env)
        switch_to(project, self.env, MPS_PROFILE)
        tracker = project / "docs" / "agents" / "issue-tracker.md"
        self.assertTrue(tracker.is_file(), "切换后缺少 docs/agents/issue-tracker.md")
        self.assertIn("openspec/changes/", tracker.read_text(encoding="utf-8"))

    def test_switch_installs_full_skill_rules(self):
        project = make_v2_project(self.tmp_path, self.env)
        switch_to(project, self.env, MPS_PROFILE)
        rules = read_json(project / ".claude" / "skills" / "skill-rules.json")
        missing = SHARED_SKILL_KEYS - set(rules["skills"].keys())
        self.assertFalse(missing, f"安装后丢失 shared 基线条目: {sorted(missing)}")

    def test_drift_without_stdin_fails_loudly_not_silently(self):
        """裸 read + set -e 在无 stdin 时会静默退出；必须显式报错并给出出路。

        注意：本用例刻意不注入 stdin（run_cmd 会注入 "n\n"，会掩盖该缺陷）。
        """
        project = make_v2_project(self.tmp_path, self.env)
        # 手改入口文件制造漂移
        claude_md = project / "CLAUDE.md"
        claude_md.write_text(
            claude_md.read_text(encoding="utf-8") + "\n<!-- 手工修改 -->\n",
            encoding="utf-8",
        )

        result = subprocess.run(
            [str(REPO_ROOT / "v2" / "scripts" / "switch-plugin.sh"), MPS_PROFILE],
            cwd=project,
            env=self.env,
            stdin=subprocess.DEVNULL,
            text=True,
            errors="replace",
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=60,
        )
        combined = result.stdout + result.stderr
        self.assertEqual(result.returncode, 2, f"应以退出码 2 明确失败:\n{combined}")
        self.assertIn("不是交互终端", combined, "未说明失败原因")
        self.assertIn("--force-overwrite", combined, "未给出可执行的出路")

    def test_force_overwrite_bypasses_drift_confirm(self):
        """--force-overwrite 应在无 stdin 时也能完成切换。"""
        project = make_v2_project(self.tmp_path, self.env)
        claude_md = project / "CLAUDE.md"
        claude_md.write_text(
            claude_md.read_text(encoding="utf-8") + "\n<!-- 手工修改 -->\n",
            encoding="utf-8",
        )

        result = subprocess.run(
            [
                str(REPO_ROOT / "v2" / "scripts" / "switch-plugin.sh"),
                MPS_PROFILE,
                "--force-overwrite",
            ],
            cwd=project,
            env=self.env,
            stdin=subprocess.DEVNULL,
            text=True,
            errors="replace",
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=60,
        )
        self.assertEqual(
            result.returncode, 0, result.stdout + result.stderr
        )
        self.assertIn(
            "<!-- harness-mode: mps -->", claude_md.read_text(encoding="utf-8")
        )

    def test_switch_back_to_superpowers_is_reversible(self):
        project = make_v2_project(self.tmp_path, self.env)
        switch_to(project, self.env, MPS_PROFILE)
        result = switch_to(project, self.env, "superpowers")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

        claude_md = (project / "CLAUDE.md").read_text(encoding="utf-8")
        self.assertIn("<!-- harness-mode: superpowers -->", claude_md)

        settings = read_json(project / ".claude" / "settings.json")
        self.assertIs(settings["enabledPlugins"][SUPERPOWERS_PLUGIN_KEY], True)
        self.assertNotIn(MATTPOCOCK_PLUGIN_KEY, settings["enabledPlugins"])


if __name__ == "__main__":
    unittest.main()
