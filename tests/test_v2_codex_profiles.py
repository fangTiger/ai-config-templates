import json
import hashlib
import os
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]


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
        timeout=30,
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


def install_mock_claude(env):
    bin_dir = Path(env["PATH"].split(os.pathsep)[0])
    claude = bin_dir / "claude"
    claude.write_text(
        "#!/bin/sh\n"
        "if [ \"$1\" = \"plugin\" ] && [ \"$2\" = \"list\" ]; then\n"
        "  echo superpowers\n"
        "fi\n"
        "exit 0\n",
        encoding="utf-8",
    )
    claude.chmod(0o755)


def make_v2_project(tmp_path, env, mode="codex-dev"):
    project = tmp_path / "project"
    project.mkdir()
    result = run_cmd(
        [str(REPO_ROOT / "v2" / "setup-project.sh"), f"--mode={mode}", str(project)],
        cwd=REPO_ROOT,
        env=env,
    )
    assert result.returncode == 0, result.stdout + result.stderr
    return project


def read_project_manifest(project):
    return json.loads((project / ".claude" / ".harness-manifest.json").read_text(encoding="utf-8"))


def short_file_hash(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()[:12]


def embedded_python_from_shell_tool(path):
    text = path.read_text(encoding="utf-8")
    marker = "<<'PY'\n"
    start = text.index(marker) + len(marker)
    end = text.rindex("\nPY")
    return text[start:end]


def profile_agents_text(profile):
    return (
        REPO_ROOT
        / "v2"
        / "scripts"
        / "plugin-profiles"
        / profile
        / "AGENTS.md"
    ).read_text(encoding="utf-8")


class V2CodexProfileTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.tmp_path = Path(self.tmp.name)
        self.env = make_env(self.tmp_path)

    def tearDown(self):
        self.tmp.cleanup()

    def test_v2_global_setup_installs_codex_global_agents(self):
        install_mock_claude(self.env)

        result = run_cmd(
            [str(REPO_ROOT / "v2" / "setup-global.sh")],
            cwd=REPO_ROOT,
            env=self.env,
        )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        codex_dir = self.tmp_path / "home" / ".codex"
        agents = codex_dir / "AGENTS.md"
        self.assertTrue(agents.is_file())
        agents_text = agents.read_text(encoding="utf-8")
        self.assertIn("harness-version: v2", agents_text)
        self.assertIn("harness-target: codex", agents_text)
        self.assertTrue((codex_dir / "skills" / "using-superpowers" / "SKILL.md").is_file())
        manifest = json.loads((codex_dir / ".harness-manifest.json").read_text(encoding="utf-8"))
        self.assertEqual(manifest["target"], "codex")
        self.assertIn("AGENTS.md", manifest["managedAssets"])

    def test_v2_lists_codex_native_profiles(self):
        project = make_v2_project(self.tmp_path, self.env)

        result = run_cmd(
            [str(REPO_ROOT / "v2" / "scripts" / "switch-plugin.sh"), "--list"],
            cwd=project,
            env=self.env,
        )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("codex-codex-dev", result.stdout)
        self.assertIn("codex-codex-claude-flow-dev", result.stdout)
        self.assertIn("codex-codex-claude-flow-gpt55-dev", result.stdout)
        self.assertNotIn("codex-codex-python-dev", result.stdout)

    def test_v2_status_reports_codex_native_profiles(self):
        project = make_v2_project(self.tmp_path, self.env, mode="codex-codex-claude-flow-gpt55-dev")

        result = run_cmd(
            [str(REPO_ROOT / "v2" / "scripts" / "switch-plugin.sh"), "--status"],
            cwd=project,
            env=self.env,
        )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("当前模式:", result.stdout)
        self.assertIn("codex-codex-claude-flow-gpt55-dev", result.stdout)
        self.assertNotIn("codex-codex-python-dev", result.stdout)

    def test_v2_switch_rejects_unknown_profile(self):
        project = make_v2_project(self.tmp_path, self.env)

        result = run_cmd(
            [str(REPO_ROOT / "v2" / "scripts" / "switch-plugin.sh"), "missing-profile"],
            cwd=project,
            env=self.env,
        )

        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("未知 profile", result.stdout)

    def test_v2_setup_installs_gpt55_codex_native_profile(self):
        project = make_v2_project(self.tmp_path, self.env, mode="codex-codex-claude-flow-gpt55-dev")

        self.assertTrue((project / "AGENTS.md").is_file())
        self.assertTrue((project / ".codex" / "config.toml").is_file())
        self.assertTrue((project / ".codex" / "agents" / "worker-codex.toml").is_file())
        self.assertTrue((project / ".codex" / "agents" / "review-codex.toml").is_file())
        self.assertTrue((project / ".codex" / "hooks.json").is_file())
        self.assertTrue((project / ".codex" / "hooks" / "graphify-query-hook.sh").is_file())
        self.assertTrue((project / ".codex" / "hooks" / "post-tool-use-tracker.sh").is_file())
        self.assertTrue((project / ".codex" / "hooks" / "skill-activation-prompt.sh").is_file())
        self.assertTrue((project / ".codex" / "hooks" / "skill-activation-prompt.cjs").is_file())
        self.assertTrue((project / ".codex" / "tools" / "runtime-verification-summary.sh").is_file())
        self.assertTrue((project / ".codex" / "tools" / "graphify-java-project.sh").is_file())
        self.assertTrue((project / ".codex" / "session-state.md").is_file())
        self.assertTrue((project / ".codex" / "session-state.template.md").is_file())
        self.assertEqual(read_project_manifest(project)["mode"], "codex-codex-claude-flow-gpt55-dev")

    def test_shared_graphify_java_tool_embedded_python_is_valid(self):
        tool = (
            REPO_ROOT
            / "v2"
            / "scripts"
            / "plugin-profiles"
            / "shared"
            / "codex"
            / "java"
            / "tools"
            / "graphify-java-project.sh"
        )

        compile(embedded_python_from_shell_tool(tool), str(tool), "exec")

    def test_v2_setup_installs_shared_codex_assets_before_profile_overrides(self):
        shared_codex = REPO_ROOT / "v2" / "scripts" / "plugin-profiles" / "shared" / "codex"
        shared_graphify_tool = shared_codex / "java" / "tools" / "graphify-java-project.sh"
        shared_runtime_summary = shared_codex / "tools" / "runtime-verification-summary.sh"
        shared_graphify_hook = shared_codex / "hooks" / "graphify-query-hook.sh"
        shared_orchestrate_skill = shared_codex / "skills" / "codex-orchestrate" / "SKILL.md"

        self.assertTrue(shared_graphify_tool.is_file())
        self.assertTrue(shared_runtime_summary.is_file())
        self.assertTrue(shared_graphify_hook.is_file())
        self.assertTrue(shared_orchestrate_skill.is_file())

        project = make_v2_project(self.tmp_path, self.env, mode="codex-codex-claude-flow-gpt55-dev")

        installed_graphify_tool = project / ".codex" / "tools" / "graphify-java-project.sh"
        installed_orchestrate_skill = project / ".codex" / "skills" / "codex-orchestrate" / "SKILL.md"
        self.assertEqual(
            shared_graphify_tool.read_text(encoding="utf-8"),
            installed_graphify_tool.read_text(encoding="utf-8"),
        )
        self.assertEqual(
            shared_orchestrate_skill.read_text(encoding="utf-8"),
            installed_orchestrate_skill.read_text(encoding="utf-8"),
        )
        compile(embedded_python_from_shell_tool(installed_graphify_tool), str(installed_graphify_tool), "exec")

    def test_v2_switch_installs_shared_codex_assets_before_profile_overrides(self):
        shared_codex = REPO_ROOT / "v2" / "scripts" / "plugin-profiles" / "shared" / "codex"
        shared_graphify_tool = shared_codex / "java" / "tools" / "graphify-java-project.sh"
        shared_orchestrate_skill = shared_codex / "skills" / "codex-orchestrate" / "SKILL.md"
        project = make_v2_project(self.tmp_path, self.env)

        result = run_cmd(
            [str(REPO_ROOT / "v2" / "scripts" / "switch-plugin.sh"), "codex-codex-claude-flow-gpt55-dev"],
            cwd=project,
            env=self.env,
        )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(
            shared_graphify_tool.read_text(encoding="utf-8"),
            (project / ".codex" / "tools" / "graphify-java-project.sh").read_text(encoding="utf-8"),
        )
        self.assertEqual(
            shared_orchestrate_skill.read_text(encoding="utf-8"),
            (project / ".codex" / "skills" / "codex-orchestrate" / "SKILL.md").read_text(encoding="utf-8"),
        )

    def test_v2_setup_rejects_removed_python_codex_native_profile(self):
        project = self.tmp_path / "python-profile-project"
        project.mkdir()

        result = run_cmd(
            [str(REPO_ROOT / "v2" / "setup-project.sh"), "--mode=codex-codex-python-dev", str(project)],
            cwd=REPO_ROOT,
            env=self.env,
        )

        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("模式 'codex-codex-python-dev' 不存在", result.stdout)

    def test_v2_switch_rejects_removed_python_codex_native_profile(self):
        project = make_v2_project(self.tmp_path, self.env)

        result = run_cmd(
            [str(REPO_ROOT / "v2" / "scripts" / "switch-plugin.sh"), "codex-codex-python-dev"],
            cwd=project,
            env=self.env,
        )

        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("未知 profile", result.stdout)
        self.assertFalse((REPO_ROOT / "v2" / "scripts" / "plugin-profiles" / "codex-codex-python-dev").exists())

    def test_v2_switch_allows_legacy_removed_python_manifest_to_supported_profile(self):
        project = make_v2_project(self.tmp_path, self.env, mode="codex-codex-claude-flow-gpt55-dev")
        manifest_path = project / ".claude" / ".harness-manifest.json"
        manifest = read_project_manifest(project)
        manifest["mode"] = "codex-codex-python-dev"
        manifest["templateHash"] = short_file_hash(project / "AGENTS.md")
        manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

        result = run_cmd(
            [str(REPO_ROOT / "v2" / "scripts" / "switch-plugin.sh"), "codex-codex-dev"],
            cwd=project,
            env=self.env,
        )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotIn("覆盖本地修改", result.stdout)
        self.assertIn("V2 切换完成", result.stdout)
        self.assertEqual(read_project_manifest(project)["mode"], "codex-codex-dev")

    def test_claude_flow_agents_keep_only_profile_specific_charter(self):
        duplicated_global_rules = [
            "规范先行",
            "测试先行",
            "安全优先",
            "证据先于断言",
            "specs/ 是唯一真相",
        ]

        for profile in ("codex-codex-claude-flow-dev", "codex-codex-claude-flow-gpt55-dev"):
            with self.subTest(profile=profile):
                text = profile_agents_text(profile)
                for rule in duplicated_global_rules:
                    self.assertNotIn(rule, text)
                self.assertIn("实现者委托", text)
                self.assertIn("审查独立", text)

    def test_claude_flow_agents_use_compact_graphify_overlay(self):
        detailed_global_graphify_phrases = [
            'graphify query "<module/file> architecture dependencies"',
            'graphify query "<module/file> impact callers tests dependencies"',
            "如果 graphify CLI / MCP 不可用",
            "不得把 graphify 结果当作唯一依据",
        ]

        for profile in ("codex-codex-claude-flow-dev", "codex-codex-claude-flow-gpt55-dev"):
            with self.subTest(profile=profile):
                text = profile_agents_text(profile)
                for phrase in detailed_global_graphify_phrases:
                    self.assertNotIn(phrase, text)
                self.assertIn("Handoff Task Package", text)
                self.assertIn("Review Input", text)
                self.assertIn("最终交付", text)

    def test_gpt55_claude_flow_agents_keep_positioning_and_model_routing(self):
        text = profile_agents_text("codex-codex-claude-flow-gpt55-dev")

        self.assertIn(
            "`codex-codex-claude-flow-gpt55-dev` ：架构者先想清楚",
            text,
        )
        self.assertIn("Architecture Codex / 最外层主线程", text)
        self.assertIn("`gpt-5.5` + `xhigh`", text)
        self.assertIn("Implementation Codex / coding worker", text)
        self.assertIn(
            "Review Codex：`.codex/agents/review-codex.toml`，`gpt-5.4` + `xhigh`",
            text,
        )

    def test_v2_switch_preserves_session_state_by_default_and_resets_on_request(self):
        project = make_v2_project(self.tmp_path, self.env, mode="codex-codex-claude-flow-gpt55-dev")
        state_file = project / ".codex" / "session-state.md"
        original = state_file.read_text(encoding="utf-8")
        marker = "\n## CustomNote: keep-me\n"
        state_file.write_text(original + marker, encoding="utf-8")

        switcher = REPO_ROOT / "v2" / "scripts" / "switch-plugin.sh"
        result = run_cmd([str(switcher), "codex-codex-claude-flow-gpt55-dev"], cwd=project, env=self.env)

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("CustomNote: keep-me", state_file.read_text(encoding="utf-8"))

        result = run_cmd(
            [str(switcher), "codex-codex-claude-flow-gpt55-dev", "--reset-session-state"],
            cwd=project,
            env=self.env,
        )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        reset_state = state_file.read_text(encoding="utf-8")
        self.assertNotIn("CustomNote: keep-me", reset_state)
        self.assertIn("# codex-codex-claude-flow-gpt55-dev Workflow State", reset_state)

    def test_v2_switch_back_to_superpowers_replaces_codex_native_assets(self):
        project = make_v2_project(self.tmp_path, self.env, mode="codex-codex-claude-flow-gpt55-dev")
        self.assertTrue((project / "AGENTS.md").is_file())

        result = run_cmd(
            [str(REPO_ROOT / "v2" / "scripts" / "switch-plugin.sh"), "superpowers"],
            cwd=project,
            env=self.env,
        )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue((project / "CLAUDE.md").is_file())
        self.assertFalse((project / ".codex" / "agents" / "worker-codex.toml").exists())
        self.assertEqual(read_project_manifest(project)["mode"], "superpowers")


if __name__ == "__main__":
    unittest.main()
