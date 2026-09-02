import subprocess
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
CLAUDE_TRAILER = "Co-Authored-By: Claude Code <claude-code@anthropic.com>"
CODEX_TRAILER = "Co-Authored-By: Codex <codex@openai.com>"
COMMIT_HEADING = "## Git Commit 规范（强制）"
COMMIT_INSTRUCTION = "在生成 commit message 时，必须在末尾添加以下 trailer，不得省略："
DEDUPLICATION_INSTRUCTION = "如果已存在相同 trailer，不得重复追加。"


def tracked_templates(filename):
    result = subprocess.run(
        ["git", "ls-files"],
        cwd=REPO_ROOT,
        check=True,
        text=True,
        stdout=subprocess.PIPE,
    )
    return [
        REPO_ROOT / relative_path
        for relative_path in result.stdout.splitlines()
        if Path(relative_path).name == filename
    ]


class AiCommitAttributionTests(unittest.TestCase):
    def assert_template_attribution(self, filename, expected_trailer, unexpected_trailer):
        templates = tracked_templates(filename)
        self.assertTrue(templates, f"未发现受版本控制的 {filename} 模板")

        for template in templates:
            relative_path = template.relative_to(REPO_ROOT)
            with self.subTest(template=str(relative_path)):
                content = template.read_text(encoding="utf-8")
                self.assertEqual(content.count(COMMIT_HEADING), 1)
                self.assertIn(COMMIT_INSTRUCTION, content)
                self.assertIn(DEDUPLICATION_INSTRUCTION, content)
                self.assertEqual(content.count(expected_trailer), 1)
                self.assertNotIn(unexpected_trailer, content)

    def test_all_claude_templates_require_claude_code_trailer(self):
        self.assert_template_attribution("CLAUDE.md", CLAUDE_TRAILER, CODEX_TRAILER)

    def test_all_agents_templates_require_codex_trailer(self):
        self.assert_template_attribution("AGENTS.md", CODEX_TRAILER, CLAUDE_TRAILER)


if __name__ == "__main__":
    unittest.main()
