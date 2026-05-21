#!/bin/bash
set -euo pipefail

# 汇总 PostToolUse tracker 记录的编辑文件和建议验证命令。
# 本脚本只读运行时缓存并输出摘要，不执行测试、构建、git 或删除操作。

PROJECT_DIR="${CODEX_PROJECT_DIR:-${PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-$(pwd)}}}"
PROJECT_NAME="$(basename "$PROJECT_DIR")"
CACHE_ROOT="${CODEX_RUNTIME_CACHE_DIR:-/tmp/$PROJECT_NAME/$PROJECT_NAME-codex-runtime-cache}"
SESSION_ID="${1:-${CODEX_SESSION_ID:-}}"

if [ -n "$SESSION_ID" ]; then
    case "$SESSION_ID" in
        *[!A-Za-z0-9._-]*|.*|*..*|*/*)
            echo "忽略非法 session id：$SESSION_ID"
            echo "Session id 只能包含字母、数字、点、下划线和短横线，且不能包含路径片段。"
            exit 0
            ;;
    esac
fi

mtime() {
    local path="$1"
    if stat -f "%m" "$path" >/dev/null 2>&1; then
        stat -f "%m" "$path"
    else
        stat -c "%Y" "$path"
    fi
}

pick_latest_session_dir() {
    local latest_dir=""
    local latest_mtime="-1"
    local candidate
    local candidate_mtime
    local file_mtime

    if [ ! -d "$CACHE_ROOT" ]; then
        return 0
    fi

    while IFS= read -r candidate; do
        if [ ! -f "$candidate/edited-files.log" ] && [ ! -f "$candidate/verification-commands.txt" ]; then
            continue
        fi
        candidate_mtime="0"
        if [ -f "$candidate/edited-files.log" ]; then
            file_mtime="$(mtime "$candidate/edited-files.log" 2>/dev/null || printf '0')"
            if [ "$file_mtime" -gt "$candidate_mtime" ]; then
                candidate_mtime="$file_mtime"
            fi
        fi
        if [ -f "$candidate/verification-commands.txt" ]; then
            file_mtime="$(mtime "$candidate/verification-commands.txt" 2>/dev/null || printf '0')"
            if [ "$file_mtime" -gt "$candidate_mtime" ]; then
                candidate_mtime="$file_mtime"
            fi
        fi
        if [ "$candidate_mtime" -gt "$latest_mtime" ]; then
            latest_mtime="$candidate_mtime"
            latest_dir="$candidate"
        fi
    done < <(find "$CACHE_ROOT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)

    printf "%s" "$latest_dir"
}

if [ -n "$SESSION_ID" ]; then
    SESSION_DIR="$CACHE_ROOT/$SESSION_ID"
else
    SESSION_DIR="$(pick_latest_session_dir)"
fi

if [ -z "${SESSION_DIR:-}" ] || [ ! -d "$SESSION_DIR" ]; then
    echo "未找到 PostToolUse tracker 运行时缓存。"
    echo "Cache root: $CACHE_ROOT"
    exit 0
fi

EDITED_LOG="$SESSION_DIR/edited-files.log"
COMMANDS_FILE="$SESSION_DIR/verification-commands.txt"

if [ ! -f "$EDITED_LOG" ] && [ ! -f "$COMMANDS_FILE" ]; then
    echo "当前 session 未记录编辑文件或建议验证命令。"
    echo "Session dir: $SESSION_DIR"
    exit 0
fi

echo "PostToolUse tracker 摘要"
echo "Session: $(basename "$SESSION_DIR")"
echo "Cache: $SESSION_DIR"
echo

echo "编辑文件："
if [ -f "$EDITED_LOG" ]; then
    sed 's/^[0-9][0-9]*://' "$EDITED_LOG" | sed '/^[[:space:]]*$/d' | sort -u | sed 's/^/- /'
else
    echo "- N/A"
fi

echo
echo "建议验证命令："
if [ -f "$COMMANDS_FILE" ]; then
    sed '/^[[:space:]]*$/d' "$COMMANDS_FILE" | sort -u | sed 's/^/- /'
else
    echo "- N/A"
fi

echo
echo "说明：本脚本只输出摘要，不会执行上述命令。最终交付时请对照实际验证结果说明已执行或未执行原因。"
