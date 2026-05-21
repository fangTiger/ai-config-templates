#!/bin/bash
set -u

# 在 Java/Maven 写入工具执行前，尝试用 graphify 图谱补充上下文。
# Hook 本身 fail-open 以避免工具层卡死；AGENTS.md 仍要求代理执行 Graphify 强制 Gate 并记录降级依据。

tool_info="$(cat 2>/dev/null || true)"

if [ -z "$tool_info" ]; then
    exit 0
fi

TOOL_INFO="$tool_info" python3 - <<'PY'
import json
import os
import shutil
import subprocess
from pathlib import Path
from typing import Iterable, Optional


FILE_TOOLS = {"Edit", "MultiEdit", "Write", "apply_patch"}


def emit(context: str) -> None:
    if not context:
        return
    print(json.dumps({"systemMessage": context}, ensure_ascii=False))


def trim(text: str, limit: int = 6000) -> str:
    text = text.strip()
    if len(text) > limit:
        text = text[:limit].rstrip() + "\n...[truncated]"
    return text


def first_non_empty(*values: object) -> str:
    for value in values:
        if value:
            return str(value)
    return ""


def normalize_to_project(path_value: object, cwd: str) -> str:
    raw = first_non_empty(path_value)
    if not raw:
        return ""

    candidate = Path(raw)
    if not candidate.is_absolute():
        candidate = Path(cwd) / candidate

    try:
        resolved = candidate.resolve(strict=False)
    except Exception:
        resolved = candidate

    try:
        return os.path.relpath(str(resolved), cwd)
    except Exception:
        return str(resolved)


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


def is_graphify_target(target_file: str) -> bool:
    normalized = target_file.replace("\\", "/")
    return (
        normalized == "pom.xml"
        or normalized.startswith("src/main/java/")
        or normalized.startswith("src/test/java/")
    )


def run_graphify(query: str, graph_file: str, cwd: str) -> Optional[str]:
    graphify_bin = (
        os.environ.get("GRAPHIFY_BIN")
        or shutil.which("graphify")
        or "/Users/captain/Library/Python/3.11/bin/graphify"
    )
    if graphify_bin and not os.path.isfile(graphify_bin) and os.path.sep in graphify_bin:
        graphify_bin = ""
    if not graphify_bin:
        return None

    try:
        completed = subprocess.run(
            [graphify_bin, "query", query, "--budget", "1500", "--graph", graph_file],
            cwd=cwd,
            capture_output=True,
            text=True,
            check=False,
        )
    except Exception:
        return ""

    output = (completed.stdout or "").strip()
    if not output and completed.stderr:
        output = completed.stderr.strip()
    if not output or output == "No relevant nodes found.":
        return ""
    return trim(output)


def candidate_targets(tool_name: str, tool_input: dict, cwd: str) -> Iterable[str]:
    if tool_name == "apply_patch":
        for value in extract_patch_paths(tool_input.get("command")):
            yield normalize_to_project(value, cwd)
        return

    value = first_non_empty(
        tool_input.get("file_path"),
        tool_input.get("path"),
        tool_input.get("target_file"),
        tool_input.get("target_path"),
        tool_input.get("uri"),
    )
    if value:
        yield normalize_to_project(value, cwd)


raw = os.environ.get("TOOL_INFO", "")
try:
    payload = json.loads(raw)
except Exception:
    raise SystemExit(0)

tool_name = str(payload.get("tool_name", "") or "")
tool_input = payload.get("tool_input") or {}
cwd = str(
    payload.get("cwd", "")
    or os.environ.get("CODEX_PROJECT_DIR")
    or os.environ.get("PROJECT_DIR")
    or os.environ.get("CLAUDE_PROJECT_DIR")
    or os.getcwd()
)
graph_file = os.environ.get("GRAPHIFY_GRAPH_PATH") or os.path.join(cwd, "graphify-out", "graph.json")

if not tool_name or not os.path.isfile(graph_file):
    raise SystemExit(0)

if tool_name not in FILE_TOOLS:
    raise SystemExit(0)

target_files = []
seen = set()
for target in candidate_targets(tool_name, tool_input, cwd):
    if target and target not in seen and is_graphify_target(target):
        seen.add(target)
        target_files.append(target)

if not target_files:
    raise SystemExit(0)

lines = [
    "graphify: Before modifying project files, inspect structure and impact first.",
    "Recommended graphify checks:",
    "Summarize graphify impact, callers, dependencies, and affected tests before you continue.",
]

for target_file in target_files[:5]:
    structure_query = f"{target_file} architecture dependencies"
    impact_query = f"{target_file} impact callers tests dependencies"
    lines.append(f'- `graphify query "{structure_query}"`')
    lines.append(f'- `graphify query "{impact_query}"`')

    query_result = run_graphify(impact_query, graph_file, cwd)
    if query_result is None:
        lines.append("Mandatory fallback: read `graphify-out/GRAPH_REPORT.md` before editing.")
        emit("\n".join(lines))
        raise SystemExit(0)

    if not query_result:
        query_result = run_graphify(structure_query, graph_file, cwd) or ""

    if query_result:
        lines.append(f"graphify impact for `{target_file}`:")
        lines.append(query_result)
    else:
        lines.append(f"graphify impact: no relevant nodes found yet for `{target_file}`.")

if len(target_files) > 5:
    lines.append(f"graphify: {len(target_files) - 5} additional changed files omitted from hook context.")

emit("\n".join(lines))
PY

exit 0
