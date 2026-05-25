#!/bin/bash
set -euo pipefail

PROJECT_DIR="${1:-$(pwd)}"

python3 - "$PROJECT_DIR" <<'PY'
import json
import os
import sys
from pathlib import Path


root = Path(sys.argv[1]).expanduser().resolve()

dependency_candidates = [
    "pyproject.toml",
    "requirements.txt",
    "requirements-dev.txt",
    "requirements-test.txt",
    "setup.py",
    "setup.cfg",
    "tox.ini",
    "noxfile.py",
    "Pipfile",
    "poetry.lock",
    "uv.lock",
]
layout_candidates = ["src", "app", "tests", "test"]
venv_candidates = [".venv", "venv", "env"]


def rel(path: Path) -> str:
    return path.relative_to(root).as_posix()


dependency_files = [
    name for name in dependency_candidates if (root / name).is_file()
]

layout = [
    name for name in layout_candidates if (root / name).is_dir()
]

virtualenv = ""
for name in venv_candidates:
    if (root / name / "bin" / "python").is_file():
        virtualenv = name
        break

python_files: list[str] = []
for pattern in ("*.py", "src/**/*.py", "app/**/*.py", "tests/**/*.py", "test/**/*.py"):
    for path in sorted(root.glob(pattern)):
        if path.is_file():
            python_files.append(rel(path))
        if len(python_files) >= 25:
            break
    if len(python_files) >= 25:
        break

python_indicators = dependency_files + layout + python_files
if virtualenv:
    python_indicators.append(virtualenv)

classification = "existing-python-project" if python_indicators else "empty-python-project"
python_bin = f"{virtualenv}/bin/python" if virtualenv else "python"
recommended_test_command = f"{python_bin} -m pytest"
recommended_validation_commands = [recommended_test_command]

payload = {
    "classification": classification,
    "project_dir": str(root),
    "python_indicators": python_indicators,
    "dependency_files": dependency_files,
    "layout": layout,
    "python_files": python_files,
    "virtualenv": virtualenv,
    "recommended_test_command": recommended_test_command,
    "recommended_validation_commands": recommended_validation_commands,
    "init_allowed": False,
    "next_action": (
        "create or update an OpenSpec initialization proposal before scaffolding"
        if classification == "empty-python-project"
        else "reuse existing project layout and validation commands"
    ),
}

json.dump(payload, sys.stdout, ensure_ascii=False, indent=2, sort_keys=True)
sys.stdout.write("\n")
PY
