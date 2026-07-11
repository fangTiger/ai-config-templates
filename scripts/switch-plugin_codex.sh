#!/bin/bash
set -euo pipefail

# ============================================================
# Codex 模式切换器
# 用法: scripts/switch-plugin_codex.sh <codex-profile>
#
# 仅负责受控 Codex profile 的项目级落盘。
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROFILES_DIR="$SCRIPT_DIR/plugin-profiles"
SUPPORTED_CODEX_PROFILES=("codex-codex-dev" "codex-codex-python-dev" "codex-codex-claude-flow-dev" "codex-codex-claude-flow-gpt55-dev" "codex-codex-claude-flow-gpt56-sol-dev")
PROFILE_NAME=""
PROFILE_DIR=""
SHARED_DIR="$PROFILES_DIR/shared"

PROJECT_DIR="$(pwd)"
CLAUDE_DIR="$PROJECT_DIR/.claude"
CODEX_DIR="$PROJECT_DIR/.codex"
ACTIVE_FILE="$CLAUDE_DIR/.active-plugin"
RESET_SESSION_STATE=false
PRESERVED_CODEX_SESSION_STATE=""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    echo -e "${BLUE}Codex 模式切换器${NC}"
    echo ""
    echo "用法: $0 <codex-profile> [--reset-session-state]"
    echo ""
    echo "说明:"
    echo "  该脚本仅支持受控 Codex profile: ${SUPPORTED_CODEX_PROFILES[*]}"
    echo "  Claude 相关模式请使用 scripts/switch-plugin_claude.sh"
    echo ""
    echo "选项:"
    echo "  --reset-session-state  使用 profile 模板重置 .codex/session-state.md"
}

is_supported_codex_profile() {
    local profile=$1
    local supported

    for supported in "${SUPPORTED_CODEX_PROFILES[@]}"; do
        [[ "$profile" == "$supported" ]] && return 0
    done

    return 1
}

select_profile() {
    local profile=$1

    if ! is_supported_codex_profile "$profile"; then
        reject_non_codex_profile "$profile"
    fi

    PROFILE_NAME="$profile"
    PROFILE_DIR="$PROFILES_DIR/$PROFILE_NAME"

    if [[ ! -d "$PROFILE_DIR" ]]; then
        echo -e "${RED}错误: profile 模板不存在: $PROFILE_DIR${NC}"
        exit 1
    fi
}

ensure_project_dir() {
    if [[ ! -d "$PROJECT_DIR" ]]; then
        echo -e "${RED}错误: 当前目录不是有效项目目录${NC}"
        exit 1
    fi
}

reject_non_codex_profile() {
    local profile=$1
    echo -e "${RED}错误: switch-plugin_codex.sh 仅支持受控 Codex profile: ${SUPPORTED_CODEX_PROFILES[*]}${NC}"
    echo "收到参数: $profile"
    echo "Claude profile 请使用 scripts/switch-plugin_claude.sh"
    exit 1
}

cleanup_preserved_session_state() {
    if [[ -n "${PRESERVED_CODEX_SESSION_STATE:-}" && -f "$PRESERVED_CODEX_SESSION_STATE" ]]; then
        rm -f "$PRESERVED_CODEX_SESSION_STATE"
        PRESERVED_CODEX_SESSION_STATE=""
    fi
}

backup_existing_state() {
    local backup_dir="$CODEX_DIR/.backup-codex-$(date +%Y%m%d%H%M%S)"
    local has_backup=false
    local entry
    local name

    if [[ -f "$PROJECT_DIR/CLAUDE.md" ]]; then
        mkdir -p "$backup_dir"
        cp "$PROJECT_DIR/CLAUDE.md" "$backup_dir/CLAUDE.md"
        has_backup=true
    fi

    if [[ -d "$PROJECT_DIR/.codex" ]]; then
        mkdir -p "$backup_dir/project-dot-codex"
        shopt -s dotglob nullglob
        for entry in "$PROJECT_DIR/.codex"/*; do
            name="$(basename "$entry")"
            [[ "$name" == ".backup-codex-"* ]] && continue
            cp -R "$entry" "$backup_dir/project-dot-codex/"
        done
        shopt -u dotglob nullglob
        has_backup=true
    fi

    for entry in settings.json session-state.md hooks commands skills .codex; do
        if [[ -e "$CLAUDE_DIR/$entry" ]]; then
            mkdir -p "$backup_dir"
            cp -R "$CLAUDE_DIR/$entry" "$backup_dir/"
            has_backup=true
        fi
    done

    if [[ "$has_backup" == "true" ]]; then
        echo -e "${YELLOW}已备份旧配置到 $backup_dir${NC}"
    fi
}

capture_existing_session_state() {
    local state="$CODEX_DIR/session-state.md"

    if [[ "$RESET_SESSION_STATE" == "true" ]]; then
        return
    fi

    if [[ -s "$state" ]]; then
        PRESERVED_CODEX_SESSION_STATE="$(mktemp /tmp/codex-session-state.XXXXXX)"
        cp "$state" "$PRESERVED_CODEX_SESSION_STATE"
    fi
}

clean_target_dirs() {
    local entry
    local name

    backup_existing_state

    rm -f "$PROJECT_DIR/CLAUDE.md"

    rm -rf "$CLAUDE_DIR/.codex"
    rm -rf "$CLAUDE_DIR/hooks"
    rm -rf "$CLAUDE_DIR/commands"
    rm -rf "$CLAUDE_DIR/skills"

    mkdir -p "$CODEX_DIR"
    shopt -s dotglob nullglob
    for entry in "$CODEX_DIR"/*; do
        name="$(basename "$entry")"
        [[ "$name" == ".backup-codex-"* ]] && continue
        rm -rf "$entry"
    done
    shopt -u dotglob nullglob
}

copy_tree_contents() {
    local src=$1
    local dst=$2

    if [[ -d "$src" && "$(ls -A "$src" 2>/dev/null)" ]]; then
        mkdir -p "$dst"
        cp -R "$src"/. "$dst"/
    fi
}

copy_project_files() {
    cp "$PROFILE_DIR/settings.json" "$CLAUDE_DIR/settings.json"
    cp "$PROFILE_DIR/AGENTS.md" "$PROJECT_DIR/AGENTS.md"

    copy_tree_contents "$SHARED_DIR/hooks" "$CODEX_DIR/hooks"
    copy_tree_contents "$SHARED_DIR/commands" "$CODEX_DIR/commands"
    copy_tree_contents "$SHARED_DIR/skills" "$CODEX_DIR/skills"
    copy_tree_contents "$PROFILE_DIR/skills" "$CODEX_DIR/skills"
    copy_tree_contents "$PROFILE_DIR/.codex" "$CODEX_DIR"
}

ensure_session_state_field() {
    local state_file=$1
    local field_name=$2
    local default_value=$3
    local tmp_file

    grep -q "^## $field_name:" "$state_file" && return

    tmp_file="$(mktemp /tmp/codex-session-state-field.XXXXXX)"
    awk -v line="## $field_name: $default_value" '
        !inserted && /^## NextPromptSeed:/ {
            print line
            inserted = 1
        }
        { print }
        END {
            if (!inserted) {
                print line
            }
        }
    ' "$state_file" > "$tmp_file"
    mv "$tmp_file" "$state_file"
}

normalize_session_state_from_template() {
    local state_file=$1
    local template_file=$2

    if grep -q '^## CompletedTasks:' "$template_file"; then
        ensure_session_state_field "$state_file" "CompletedTasks" "[]"
    fi

    if grep -q '^## PendingTasks:' "$template_file"; then
        ensure_session_state_field "$state_file" "PendingTasks" "[]"
    fi

    if grep -q '^## DegradationCount:' "$template_file"; then
        ensure_session_state_field "$state_file" "DegradationCount" "0"
    fi
}

copy_session_state() {
    local legacy_state="$CLAUDE_DIR/session-state.md"
    local target_state="$CODEX_DIR/session-state.md"
    local target_template="$CODEX_DIR/session-state.template.md"
    local template_state="$PROFILE_DIR/.codex/session-state.template.md"

    cp "$template_state" "$target_template"

    if [[ "$RESET_SESSION_STATE" == "true" ]]; then
        cp "$target_template" "$target_state"
        echo -e "${YELLOW}已按模板重置 .codex/session-state.md${NC}"
        return
    fi

    if [[ -n "${PRESERVED_CODEX_SESSION_STATE:-}" && -s "$PRESERVED_CODEX_SESSION_STATE" ]]; then
        if validate_session_state_file "$PRESERVED_CODEX_SESSION_STATE"; then
            cp "$PRESERVED_CODEX_SESSION_STATE" "$target_state"
            normalize_session_state_from_template "$target_state" "$target_template"
            echo -e "${YELLOW}已保留现有 .codex/session-state.md${NC}"
        else
            cp "$target_template" "$target_state"
            echo -e "${YELLOW}现有 .codex/session-state.md 与 $PROFILE_NAME 不匹配，已按目标模板初始化${NC}"
        fi
        cleanup_preserved_session_state
        return
    fi

    if [[ -s "$legacy_state" ]]; then
        local migrated_state
        migrated_state="$(mktemp /tmp/codex-migrated-session-state.XXXXXX)"
        sed 's#\.claude/session-state\.md#\.codex/session-state.md#g' "$legacy_state" > "$migrated_state"
        rm -f "$legacy_state"
        if validate_session_state_file "$migrated_state"; then
            cp "$migrated_state" "$target_state"
            normalize_session_state_from_template "$target_state" "$target_template"
        else
            cp "$target_template" "$target_state"
            echo -e "${YELLOW}旧 .claude/session-state.md 与 $PROFILE_NAME 不匹配，已按目标模板初始化${NC}"
        fi
        rm -f "$migrated_state"
        return
    fi

    if [[ -f "$legacy_state" ]]; then
        rm -f "$legacy_state"
    fi

    cp "$target_template" "$target_state"
}

ensure_graphify_assets() {
    if [[ ! -f "$CODEX_DIR/hooks.json" ]]; then
        cat > "$CODEX_DIR/hooks.json" <<'HOOKSEOF'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash|Read|Grep|Glob|Edit|MultiEdit|Write|NotebookEdit",
        "hooks": [
          {
            "type": "command",
            "command": "bash .codex/hooks/graphify-query-hook.sh"
          }
        ]
      }
    ]
  }
}
HOOKSEOF
    fi

    if [[ ! -f "$PROJECT_DIR/.graphifyignore" && -f "$TEMPLATE_DIR/graphifyignore.template" ]]; then
        cp "$TEMPLATE_DIR/graphifyignore.template" "$PROJECT_DIR/.graphifyignore"
    fi
}

install_hook_dependencies() {
    if [[ -f "$CODEX_DIR/hooks/package.json" ]]; then
        echo -e "${BLUE}安装 hooks 依赖...${NC}"
        (cd "$CODEX_DIR/hooks" && npm install --silent 2>/dev/null) || true
    fi
}

write_active_profile() {
    echo "$PROFILE_NAME" > "$ACTIVE_FILE"
}

validate_layout() {
    local ok=true

    [[ -f "$PROJECT_DIR/AGENTS.md" ]] || ok=false
    [[ -f "$CLAUDE_DIR/.active-plugin" ]] || ok=false
    [[ -f "$CLAUDE_DIR/settings.json" ]] || ok=false
    if [[ -f "$PROFILE_DIR/.codex/instructions.md" ]]; then
        [[ -f "$CODEX_DIR/instructions.md" ]] || ok=false
    fi
    if [[ -f "$PROFILE_DIR/.codex/workflow.md" ]]; then
        [[ -f "$CODEX_DIR/workflow.md" ]] || ok=false
    fi
    [[ -f "$CODEX_DIR/config.toml" ]] || ok=false
    [[ -f "$CODEX_DIR/session-state.template.md" ]] || ok=false
    validate_session_state_file "$CODEX_DIR/session-state.md" || ok=false
    validate_session_state_template_fields "$CODEX_DIR/session-state.md" "$CODEX_DIR/session-state.template.md" || ok=false
    [[ -f "$CODEX_DIR/hooks.json" ]] || ok=false
    [[ -f "$CODEX_DIR/hooks/graphify-query-hook.sh" ]] || ok=false
    [[ -f "$CODEX_DIR/hooks/post-tool-use-tracker.sh" ]] || ok=false
    [[ -f "$CODEX_DIR/hooks/skill-activation-prompt.sh" ]] || ok=false
    [[ -f "$CODEX_DIR/hooks/skill-activation-prompt.cjs" ]] || ok=false
    [[ -d "$CODEX_DIR/tools" ]] || ok=false
    [[ -f "$CODEX_DIR/tools/README.md" ]] || ok=false
    if [[ "$PROFILE_NAME" == "codex-codex-dev" ]]; then
        [[ -f "$CODEX_DIR/agents/review-codex.toml" ]] || ok=false
        [[ -f "$CODEX_DIR/tools/graphify-java-project.sh" ]] || ok=false
    elif [[ "$PROFILE_NAME" == "codex-codex-claude-flow-dev" ]]; then
        [[ -f "$CODEX_DIR/agents/review-codex.toml" ]] || ok=false
        [[ -f "$CODEX_DIR/tools/graphify-java-project.sh" ]] || ok=false
    elif [[ "$PROFILE_NAME" == "codex-codex-claude-flow-gpt55-dev" || "$PROFILE_NAME" == "codex-codex-claude-flow-gpt56-sol-dev" ]]; then
        [[ -f "$CODEX_DIR/agents/worker-codex.toml" ]] || ok=false
        [[ -f "$CODEX_DIR/agents/review-codex.toml" ]] || ok=false
        [[ -f "$CODEX_DIR/tools/graphify-java-project.sh" ]] || ok=false
    elif [[ "$PROFILE_NAME" == "codex-codex-python-dev" ]]; then
        [[ -f "$CODEX_DIR/agents/worker-codex.toml" ]] || ok=false
        [[ -f "$CODEX_DIR/agents/review-codex.toml" ]] || ok=false
        [[ -f "$CODEX_DIR/tools/detect-python-project.sh" ]] || ok=false
        [[ -f "$CODEX_DIR/tools/verify-python-project.sh" ]] || ok=false
        [[ -f "$CODEX_DIR/tools/graphify-python-project.sh" ]] || ok=false
        [[ -f "$CODEX_DIR/skills/codex-python-bootstrap/SKILL.md" ]] || ok=false
        [[ -f "$CODEX_DIR/skills/codex-python-project/SKILL.md" ]] || ok=false
        [[ -f "$CODEX_DIR/skills/codex-python-testing/SKILL.md" ]] || ok=false
        [[ -f "$CODEX_DIR/skills/codex-python-security/SKILL.md" ]] || ok=false
    fi
    [[ -f "$PROJECT_DIR/.graphifyignore" ]] || ok=false
    [[ -d "$CODEX_DIR/hooks" ]] || ok=false
    [[ -d "$CODEX_DIR/commands/openspec" ]] || ok=false
    [[ -d "$CODEX_DIR/skills" ]] || ok=false

    if [[ "$ok" != "true" ]]; then
        echo -e "${RED}错误: $PROFILE_NAME 关键文件落盘不完整${NC}"
        exit 1
    fi
}

validate_session_state_file() {
    local state_file=$1

    [[ -s "$state_file" ]] || return 1
    grep -q "^# $PROFILE_NAME Workflow State" "$state_file" || return 1
    grep -q "^## Mode: $PROFILE_NAME" "$state_file" || return 1
    grep -q '^## ChangeId:' "$state_file" || return 1
    grep -q '^## Current Stage:' "$state_file" || return 1
}

validate_session_state_template_fields() {
    local state_file=$1
    local template_file=$2
    local field

    for field in CompletedTasks PendingTasks DegradationCount; do
        if grep -q "^## $field:" "$template_file"; then
            grep -q "^## $field:" "$state_file" || return 1
        fi
    done
}

switch_profile() {
    echo -e "${BLUE}切换到 $PROFILE_NAME${NC}"

    mkdir -p "$CLAUDE_DIR"
    capture_existing_session_state
    clean_target_dirs
    copy_project_files
    copy_session_state
    ensure_graphify_assets
    write_active_profile
    install_hook_dependencies
    validate_layout

    echo -e "${GREEN}切换完成！当前 profile: $PROFILE_NAME${NC}"
}

main() {
    if [[ $# -eq 0 ]]; then
        usage
        exit 0
    fi

    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        *)
            ensure_project_dir
            select_profile "$1"
            shift
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --reset-session-state)
                        RESET_SESSION_STATE=true
                        ;;
                    *)
                        echo -e "${RED}错误: 未知选项 $1${NC}"
                        usage
                        exit 1
                        ;;
                esac
                shift
            done
            switch_profile
            ;;
    esac
}

trap cleanup_preserved_session_state EXIT

main "$@"
