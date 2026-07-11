import os
import subprocess
import tempfile
import tomllib
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SWITCHER = REPO_ROOT / "scripts" / "switch-plugin_codex.sh"
GPT55_PROFILE = "codex-codex-claude-flow-gpt55-dev"
GPT56_SOL_PROFILE = "codex-codex-claude-flow-gpt56-sol-dev"


def run_switcher(args, cwd, env):
    return subprocess.run(
        ["bash", str(SWITCHER), *args],
        cwd=cwd,
        env=env,
        text=True,
        errors="replace",
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=30,
    )


def read_toml(path):
    with path.open("rb") as handle:
        return tomllib.load(handle)


class V1CodexProfileTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.tmp_path = Path(self.tmp.name)
        self.project = self.tmp_path / "project"
        self.project.mkdir()

        bin_dir = self.tmp_path / "bin"
        bin_dir.mkdir()
        npm = bin_dir / "npm"
        npm.write_text("#!/bin/sh\nexit 0\n", encoding="utf-8")
        npm.chmod(0o755)

        self.env = os.environ.copy()
        self.env["PATH"] = f"{bin_dir}{os.pathsep}{self.env.get('PATH', '')}"

    def tearDown(self):
        self.tmp.cleanup()

    def assert_routing(self, profile, main_model, delegated_model):
        profile_dir = REPO_ROOT / "scripts" / "plugin-profiles" / profile / ".codex"
        config = read_toml(profile_dir / "config.toml")
        worker = read_toml(profile_dir / "agents" / "worker-codex.toml")
        review = read_toml(profile_dir / "agents" / "review-codex.toml")

        self.assertEqual(
            (config["model"], config["model_provider"], config["model_reasoning_effort"]),
            (main_model, "openai", "xhigh"),
        )
        self.assertEqual(
            (worker["model"], worker["model_provider"], worker["model_reasoning_effort"]),
            (delegated_model, "openai", "xhigh"),
        )
        self.assertEqual(worker["sandbox_mode"], "workspace-write")
        self.assertEqual(
            (review["model"], review["model_provider"], review["model_reasoning_effort"]),
            (delegated_model, "openai", "xhigh"),
        )
        self.assertEqual(review["sandbox_mode"], "read-only")

    def test_v1_help_lists_gpt56_sol_profile(self):
        result = run_switcher(["--help"], self.project, self.env)

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(GPT56_SOL_PROFILE, result.stdout)
        self.assertIn(GPT55_PROFILE, result.stdout)

    def test_v1_switch_installs_gpt56_sol_profile(self):
        result = run_switcher([GPT56_SOL_PROFILE], self.project, self.env)

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(
            (self.project / ".claude" / ".active-plugin").read_text(encoding="utf-8").strip(),
            GPT56_SOL_PROFILE,
        )
        self.assertTrue((self.project / "AGENTS.md").is_file())
        self.assertTrue((self.project / ".codex" / "hooks" / "graphify-query-hook.sh").is_file())
        self.assertTrue((self.project / ".codex" / "tools" / "graphify-java-project.sh").is_file())
        self.assertTrue((self.project / ".codex" / "skills" / "codex-orchestrate" / "SKILL.md").is_file())

        state = (self.project / ".codex" / "session-state.md").read_text(encoding="utf-8")
        self.assertIn(f"# {GPT56_SOL_PROFILE} Workflow State", state)
        self.assertIn(f"## Mode: {GPT56_SOL_PROFILE}", state)

        config = read_toml(self.project / ".codex" / "config.toml")
        worker = read_toml(self.project / ".codex" / "agents" / "worker-codex.toml")
        review = read_toml(self.project / ".codex" / "agents" / "review-codex.toml")
        self.assertEqual(
            (config["model"], config["model_provider"], config["model_reasoning_effort"]),
            ("gpt-5.6-sol", "openai", "xhigh"),
        )
        self.assertEqual(
            (worker["model"], worker["model_provider"], worker["model_reasoning_effort"], worker["sandbox_mode"]),
            ("gpt-5.5", "openai", "xhigh", "workspace-write"),
        )
        self.assertEqual(
            (review["model"], review["model_provider"], review["model_reasoning_effort"], review["sandbox_mode"]),
            ("gpt-5.5", "openai", "xhigh", "read-only"),
        )

    def test_v1_gpt55_profile_routing_remains_unchanged(self):
        self.assert_routing(GPT55_PROFILE, "gpt-5.5", "gpt-5.4")


if __name__ == "__main__":
    unittest.main()
