#!/bin/bash
set -euo pipefail

# Python 项目 PostToolUse 追踪器。
# 在 Edit/MultiEdit/Write 后记录被修改文件，并生成建议验证命令。
# 默认只写入 /tmp/<project-name>/<project-name>-codex-runtime-cache，不直接执行验证，避免 hook 干扰模型主流程。

tool_info="$(cat 2>/dev/null || true)"

if [ -z "$tool_info" ]; then
    exit 0
fi

TOOL_INFO="$tool_info" python3 - <<'PY'
import json
import os
import re
import time
from pathlib import Path


def load_payload() -> dict:
    try:
        return json.loads(os.environ.get("TOOL_INFO", "") or "{}")
    except Exception:
        return {}


def normalize_path(path_value: str, cwd: Path) -> Path:
    path = Path(path_value)
    if not path.is_absolute():
        path = cwd / path
    return path.resolve(strict=False)


def detect_python_bin(cwd: Path) -> str:
    for name in (".venv", "venv", "env"):
        if (cwd / name / "bin" / "python").is_file():
            return f"{name}/bin/python"
    return "python"


def command_for(file_path: Path, cwd: Path) -> str:
    name = file_path.name
    path_text = str(file_path)
    python_bin = detect_python_bin(cwd)
    if name in {"pyproject.toml", "setup.cfg", "setup.py", "tox.ini", "noxfile.py"}:
        return f"{python_bin} -m pytest"
    if re.match(r"requirements.*\\.txt$", name):
        return f"{python_bin} -m pytest"
    if name.endswith(".py"):
        return f"{python_bin} -m pytest"
    if re.search(r"\\.(md|markdown)$", name, re.I):
        return "rg -n '[ \\\\t]+$' <changed-markdown-files>"
    if "/.codex/" in path_text:
        return "校验 JSON / shell / Node 脚本语法"
    return ""


payload = load_payload()
tool_name = payload.get("tool_name") or ""
tool_input = payload.get("tool_input") or {}
if tool_name not in {"Edit", "MultiEdit", "Write", "NotebookEdit"}:
    raise SystemExit(0)

file_value = (
    tool_input.get("file_path")
    or tool_input.get("path")
    or tool_input.get("notebook_path")
    or tool_input.get("target_file")
)
if not file_value:
    raise SystemExit(0)

cwd = Path(
    payload.get("cwd")
    or os.environ.get("CODEX_PROJECT_DIR")
    or os.environ.get("PROJECT_DIR")
    or os.environ.get("CLAUDE_PROJECT_DIR")
    or os.getcwd()
).resolve(strict=False)
file_path = normalize_path(str(file_value), cwd)

try:
    rel_path = file_path.relative_to(cwd)
except ValueError:
    rel_path = file_path

project_name = cwd.name or "project"
default_cache_root = Path("/tmp") / project_name / f"{project_name}-codex-runtime-cache"
cache_root = Path(os.environ.get("CODEX_RUNTIME_CACHE_DIR") or default_cache_root)
cache_dir = cache_root / (payload.get("session_id") or "default")

try:
    cache_dir.mkdir(parents=True, exist_ok=True)

    entry = f"{int(time.time())}:{rel_path}"
    (cache_dir / "edited-files.log").open("a", encoding="utf-8").write(entry + "\n")

    command = command_for(file_path, cwd)
    if command:
        commands_path = cache_dir / "verification-commands.txt"
        existing = set()
        if commands_path.exists():
            existing = {line.strip() for line in commands_path.read_text(encoding="utf-8").splitlines() if line.strip()}
        existing.add(command)
        commands_path.write_text("\n".join(sorted(existing)) + "\n", encoding="utf-8")
        print(f"建议验证命令: {command}")
except Exception:
    raise SystemExit(0)
PY
