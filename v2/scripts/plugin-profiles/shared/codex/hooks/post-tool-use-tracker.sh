#!/bin/bash
set -euo pipefail

# Java/Maven 项目 PostToolUse 追踪器。
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


def java_test_name(file_path: Path) -> str:
    return file_path.stem


def related_test_name(file_path: Path, cwd: Path) -> str:
    try:
        rel = file_path.relative_to(cwd)
    except ValueError:
        return ""
    parts = list(rel.parts)
    if len(parts) < 4 or parts[:3] != ["src", "main", "java"]:
        return ""
    test_rel = Path("src/test/java", *parts[3:]).with_name(file_path.stem + "Test.java")
    return test_rel.stem if (cwd / test_rel).is_file() else ""


def command_for(file_path: Path, cwd: Path) -> str:
    name = file_path.name
    path_text = str(file_path)
    if name == "pom.xml":
        return "mvn -q -DskipTests package"
    if "/src/test/java/" in path_text and name.endswith(".java"):
        return f"mvn -q -Dtest={java_test_name(file_path)} test"
    if "/src/main/java/" in path_text and name.endswith(".java"):
        related = related_test_name(file_path, cwd)
        if related:
            return f"mvn -q -Dtest={related} test"
        if "/ontology/" in path_text:
            return "mvn -q -Dtest='*Ontology*Test,*Ttl*Test,*Agent*Test' test"
        return "mvn -q test"
    if re.search(r"\.(md|markdown)$", name, re.I):
        return "rg -n '[ \\\\t]+$' <changed-markdown-files>"
    if "/.codex/" in path_text:
        return "校验 JSON / shell / Node 脚本语法"
    return ""


def first_non_empty(*values: object) -> str:
    for value in values:
        if value:
            return str(value)
    return ""


def extract_patch_paths(command: object) -> list[str]:
    text = first_non_empty(command)
    if not text:
        return []

    prefixes = (
        "*** Update File: ",
        "*** Add File: ",
        "*** Delete File: ",
        "*** Move to: ",
    )
    paths: list[str] = []
    for line in text.splitlines():
        for prefix in prefixes:
            if line.startswith(prefix):
                value = line[len(prefix):].strip()
                if value:
                    paths.append(value)
                break
    return paths


payload = load_payload()
tool_name = payload.get("tool_name") or ""
tool_input = payload.get("tool_input") or {}
if tool_name not in {"Edit", "MultiEdit", "Write", "NotebookEdit", "apply_patch"}:
    raise SystemExit(0)

cwd = Path(
    payload.get("cwd")
    or os.environ.get("CODEX_PROJECT_DIR")
    or os.environ.get("PROJECT_DIR")
    or os.environ.get("CLAUDE_PROJECT_DIR")
    or os.getcwd()
).resolve(strict=False)

file_values: list[str]
if tool_name == "apply_patch":
    file_values = extract_patch_paths(tool_input.get("command"))
else:
    file_value = (
        tool_input.get("file_path")
        or tool_input.get("path")
        or tool_input.get("notebook_path")
        or tool_input.get("target_file")
    )
    file_values = [str(file_value)] if file_value else []

if not file_values:
    raise SystemExit(0)

project_name = cwd.name or "project"
default_cache_root = Path("/tmp") / project_name / f"{project_name}-codex-runtime-cache"
cache_root = Path(os.environ.get("CODEX_RUNTIME_CACHE_DIR") or default_cache_root)
cache_dir = cache_root / (payload.get("session_id") or "default")

try:
    cache_dir.mkdir(parents=True, exist_ok=True)

    commands_path = cache_dir / "verification-commands.txt"
    existing = set()
    if commands_path.exists():
        existing = {line.strip() for line in commands_path.read_text(encoding="utf-8").splitlines() if line.strip()}

    rel_paths = []
    for file_value in file_values:
        file_path = normalize_path(str(file_value), cwd)
        try:
            rel_path = file_path.relative_to(cwd)
        except ValueError:
            rel_path = file_path

        rel_paths.append(str(rel_path))
        entry = f"{int(time.time())}:{rel_path}"
        (cache_dir / "edited-files.log").open("a", encoding="utf-8").write(entry + "\n")

        command = command_for(file_path, cwd)
        if command:
            existing.add(command)

    if existing:
        commands_path.write_text("\n".join(sorted(existing)) + "\n", encoding="utf-8")
except Exception as exc:
    print(f"PostToolUse tracker 记录失败，已跳过：{exc}")
    raise SystemExit(0)

print(f"已记录改动文件：{', '.join(rel_paths)}。")
PY
