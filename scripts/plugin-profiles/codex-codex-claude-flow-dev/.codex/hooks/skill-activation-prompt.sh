#!/bin/bash
set -e

project_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"
export CLAUDE_PROJECT_DIR="$project_dir"

cd "$project_dir/.codex/hooks"
cat | node skill-activation-prompt.cjs
