#!/bin/bash
set -euo pipefail

TARGET="${1:-.}"
PROJECT_DIR="${2:-$(pwd)}"
GRAPH_FILE="$PROJECT_DIR/graphify-out/graph.json"
REPORT_FILE="$PROJECT_DIR/graphify-out/GRAPH_REPORT.md"

if [[ -f "$GRAPH_FILE" ]] && command -v graphify >/dev/null 2>&1; then
    graphify query "$TARGET impact callers tests dependencies" --budget 1500 --graph "$GRAPH_FILE"
    exit 0
fi

if [[ -f "$REPORT_FILE" ]]; then
    echo "graphify CLI 或 graph.json 不可用；必须先阅读 graphify-out/GRAPH_REPORT.md，并围绕 $TARGET 检查影响面。"
    exit 0
fi

echo "Graphify: unavailable；当前项目没有可用 graphify-out，必须记录此降级原因后再按源码、测试和 OpenSpec 分析 $TARGET。"
