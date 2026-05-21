#!/bin/bash
set -euo pipefail

PRINT_PLAN=false
PROJECT_DIR="$(pwd)"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --print-plan)
            PRINT_PLAN=true
            shift
            ;;
        -h|--help)
            echo "用法: $0 [--print-plan] [project-dir]"
            exit 0
            ;;
        *)
            PROJECT_DIR="$1"
            shift
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DETECTION_JSON="$(bash "$SCRIPT_DIR/detect-python-project.sh" "$PROJECT_DIR")"

if [[ "$PRINT_PLAN" == "true" ]]; then
    DETECTION_JSON="$DETECTION_JSON" python3 - <<'PY'
import json
import os

detected = json.loads(os.environ["DETECTION_JSON"])
payload = {
    "classification": detected["classification"],
    "project_dir": detected["project_dir"],
    "will_execute": False,
    "commands": detected["recommended_validation_commands"],
}
print(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True))
PY
    exit 0
fi

CLASSIFICATION="$(DETECTION_JSON="$DETECTION_JSON" python3 - <<'PY'
import json
import os

print(json.loads(os.environ["DETECTION_JSON"])["classification"])
PY
)"

if [[ "$CLASSIFICATION" == "empty-python-project" ]]; then
    echo "Python 项目尚未初始化：请先使用 codex-python-bootstrap 创建 OpenSpec 初始化提案。" >&2
    exit 2
fi

mapfile -t COMMANDS < <(DETECTION_JSON="$DETECTION_JSON" python3 - <<'PY'
import json
import os

for command in json.loads(os.environ["DETECTION_JSON"])["recommended_validation_commands"]:
    print(command)
PY
)

for command in "${COMMANDS[@]}"; do
    echo "运行: $command"
    (cd "$PROJECT_DIR" && bash -lc "$command")
done
