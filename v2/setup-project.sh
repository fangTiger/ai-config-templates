#!/bin/zsh

# Claude Code V2 Project Setup Script
# 安装 V2 分层配置的项目部分（模式差异规则）
# 前置条件：全局 manifest 必须是 v2

# 不使用 set -e
if [ -f "$HOME/.zshrc" ]; then
    source "$HOME/.zshrc" 2>/dev/null || true
fi

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_step() { echo -e "${GREEN}▶${NC} $1"; }
print_info() { echo -e "${YELLOW}ℹ${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }

prompt_read() {
    local prompt_text=$1
    local var_name=$2
    echo -n "$prompt_text"
    read "$var_name"
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
V1_TEMPLATE_DIR="$TEMPLATE_DIR"
PROFILES_DIR="$SCRIPT_DIR/scripts/plugin-profiles"
SHARED_DIR="$PROFILES_DIR/shared"
SHARED_CODEX_DIR="$SHARED_DIR/codex"
GLOBAL_MANIFEST="$HOME/.claude/.harness-manifest.json"
TARGET_DIR="${1:-.}"
MIGRATE_MODE=false
RESET_SESSION_STATE=false
DEFAULT_MODE="superpowers"
GRAPHIFY_IGNORE_TEMPLATE="$SCRIPT_DIR/graphifyignore.template"

# 解析参数
for arg in "$@"; do
    case $arg in
        --migrate) MIGRATE_MODE=true; shift ;;
        --reset-session-state) RESET_SESSION_STATE=true; shift ;;
        --mode=*) DEFAULT_MODE="${arg#*=}"; shift ;;
        -*) ;;
        *) TARGET_DIR="$arg" ;;
    esac
done

is_codex_native_profile() {
    local profile_dir=$1
    [[ -f "$profile_dir/AGENTS.md" && -d "$profile_dir/.codex" ]]
}

copy_tree_contents() {
    local src=$1
    local dst=$2

    if [[ -d "$src" && "$(ls -A "$src" 2>/dev/null)" ]]; then
        mkdir -p "$dst"
        cp -R "$src"/. "$dst"/
    fi
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

validate_session_state_file() {
    local state_file=$1
    local profile_name=$2

    [[ -s "$state_file" ]] || return 1
    grep -q "^# $profile_name Workflow State" "$state_file" || return 1
    grep -q "^## Mode: $profile_name" "$state_file" || return 1
    grep -q '^## ChangeId:' "$state_file" || return 1
    grep -q '^## Current Stage:' "$state_file" || return 1
}

install_codex_session_state() {
    local target_state="$CODEX_DIR/session-state.md"
    local target_template="$CODEX_DIR/session-state.template.md"

    [[ -f "$target_template" ]] || return

    if [[ "$RESET_SESSION_STATE" == true || ! -s "$target_state" ]]; then
        cp "$target_template" "$target_state"
        return
    fi

    if validate_session_state_file "$target_state" "$DEFAULT_MODE"; then
        normalize_session_state_from_template "$target_state" "$target_template"
    else
        cp "$target_template" "$target_state"
        print_info "现有 .codex/session-state.md 与 $DEFAULT_MODE 不匹配，已按模板初始化"
    fi
}

available_profiles() {
    local profiles=()
    local profile_dir

    for profile_dir in "$PROFILES_DIR"/*/; do
        local name
        name="$(basename "$profile_dir")"
        [[ "$name" == "shared" ]] && continue
        profiles+=("$name")
    done

    printf "%s " "${profiles[@]}"
}

echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Claude Code V2 Project Setup${NC}"
echo -e "${BLUE}  分层配置：全局不变量 + 项目模式差异${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""

# ═══════════════════════════════════════════════
# Step 0: 前置检查
# ═══════════════════════════════════════════════
print_step "前置检查..."

# 检查全局 manifest
if [ -f "$GLOBAL_MANIFEST" ]; then
    if command -v python3 &> /dev/null; then
        global_version=$(python3 -c "import json; print(json.load(open('$GLOBAL_MANIFEST')).get('harnessVersion',''))" 2>/dev/null)
    elif command -v jq &> /dev/null; then
        global_version=$(jq -r '.harnessVersion' "$GLOBAL_MANIFEST" 2>/dev/null)
    else
        global_version=$(grep -o '"harnessVersion"[[:space:]]*:[[:space:]]*"[^"]*"' "$GLOBAL_MANIFEST" | grep -o '"v[^"]*"' | tr -d '"')
    fi

    if [ "$global_version" = "v2" ]; then
        print_success "全局 manifest: v2"
    else
        print_error "全局 manifest 版本不是 v2 (当前: ${global_version:-无})"
        print_info "请先运行 V2 全局安装: $SCRIPT_DIR/setup-global.sh"
        exit 1
    fi
else
    print_error "全局 manifest 不存在: $GLOBAL_MANIFEST"
    print_info "请先运行 V2 全局安装: $SCRIPT_DIR/setup-global.sh"
    exit 1
fi

# 进入目标目录
cd "$TARGET_DIR"
TARGET_DIR="$(pwd)"
CLAUDE_DIR="$TARGET_DIR/.claude"
CODEX_DIR="$TARGET_DIR/.codex"
PROJECT_MANIFEST="$CLAUDE_DIR/.harness-manifest.json"

print_info "目标目录: $TARGET_DIR"

# 检查是否是 V1 项目
# V1 识别：有 .active-plugin，或有 CLAUDE.md 但无 V2 manifest 且 .claude/ 目录存在
is_v1=false
if [ -f "$CLAUDE_DIR/.active-plugin" ] && [ ! -f "$PROJECT_MANIFEST" ]; then
    is_v1=true
elif [ -f "$TARGET_DIR/CLAUDE.md" ] && [ ! -f "$PROJECT_MANIFEST" ] && [ -d "$CLAUDE_DIR" ]; then
    # 检查 CLAUDE.md 是否不含 V2 标记（即 V1 安装的全量文件）
    if ! grep -q "harness-version: v2" "$TARGET_DIR/CLAUDE.md" 2>/dev/null; then
        is_v1=true
    fi
fi

if [ "$is_v1" = true ]; then
    if [ "$MIGRATE_MODE" = true ]; then
        print_info "检测到 V1 项目，--migrate 模式：将升级为 V2"
        # 完整备份 V1 配置（包括目录内容）
        v1_backup="$CLAUDE_DIR/.v1-backup-$(date +%Y%m%d%H%M%S)"
        mkdir -p "$v1_backup"
        [ -f "$TARGET_DIR/CLAUDE.md" ] && cp "$TARGET_DIR/CLAUDE.md" "$v1_backup/"
        [ -f "$CLAUDE_DIR/settings.json" ] && cp "$CLAUDE_DIR/settings.json" "$v1_backup/"
        [ -f "$CLAUDE_DIR/.active-plugin" ] && cp "$CLAUDE_DIR/.active-plugin" "$v1_backup/"
        for dir in hooks skills agents commands rules; do
            if [ -d "$CLAUDE_DIR/$dir" ] && [ "$(ls -A "$CLAUDE_DIR/$dir" 2>/dev/null)" ]; then
                cp -r "$CLAUDE_DIR/$dir" "$v1_backup/"
            fi
        done
        print_success "V1 配置已完整备份到 $v1_backup"
    else
        print_error "检测到 V1 项目（有 .claude/ 配置但无 V2 manifest）"
        print_info "如需升级到 V2，请使用: $0 --migrate"
        print_info "或手动删除 .claude/ 目录后重新运行"
        exit 1
    fi
fi

# 检查 profile 是否存在
if [ ! -d "$PROFILES_DIR/$DEFAULT_MODE" ]; then
    print_error "模式 '$DEFAULT_MODE' 不存在"
    print_info "可用模式: $(available_profiles)"
    exit 1
fi

echo ""

# ═══════════════════════════════════════════════
# Step 1: 创建目录结构
# ═══════════════════════════════════════════════
echo -e "${CYAN}  Step 1: 目录结构${NC}"
mkdir -p "$CLAUDE_DIR"/{skills,hooks,agents,commands,rules}
mkdir -p "$CODEX_DIR"/{hooks,skills}
mkdir -p "$TARGET_DIR/.opencode/plugins"
print_success "目录结构已创建"

# ═══════════════════════════════════════════════
# Step 2: 安装 shared 资源
# ═══════════════════════════════════════════════
echo -e "${CYAN}  Step 2: Shared 资源${NC}"
if [ -d "$SHARED_DIR" ]; then
    for dir in hooks commands skills; do
        if [ -d "$SHARED_DIR/$dir" ] && [ "$(ls -A "$SHARED_DIR/$dir" 2>/dev/null)" ]; then
            cp -r "$SHARED_DIR/$dir/"* "$CLAUDE_DIR/$dir/" 2>/dev/null || true
        fi
    done
    # 安装 hooks 依赖
    if [ -f "$CLAUDE_DIR/hooks/package.json" ]; then
        (cd "$CLAUDE_DIR/hooks" && npm install --silent 2>/dev/null) || true
    fi
    if [ -f "$SHARED_DIR/hooks/graphify-query-hook.sh" ]; then
        cp "$SHARED_DIR/hooks/graphify-query-hook.sh" "$CODEX_DIR/hooks/graphify-query-hook.sh"
    fi
    chmod +x "$CLAUDE_DIR/hooks/"*.sh "$CODEX_DIR/hooks/"*.sh 2>/dev/null || true
    print_success "Shared 资源已安装"
else
    print_info "无 shared 资源目录"
fi

# ═══════════════════════════════════════════════
# Step 3: 安装模式配置
# ═══════════════════════════════════════════════
echo -e "${CYAN}  Step 3: 安装 $DEFAULT_MODE 模式${NC}"

PROFILE_DIR="$PROFILES_DIR/$DEFAULT_MODE"

if is_codex_native_profile "$PROFILE_DIR"; then
    # Codex-native profile 以 AGENTS.md 和 .codex/ 为主入口。
    if [ -f "$TARGET_DIR/AGENTS.md" ]; then
        print_info "项目 AGENTS.md 已存在，备份中..."
        mv "$TARGET_DIR/AGENTS.md" "$TARGET_DIR/AGENTS.md.backup.$(date +%Y%m%d%H%M%S)"
    fi
    cp "$PROFILE_DIR/AGENTS.md" "$TARGET_DIR/AGENTS.md"
    print_success "项目 AGENTS.md 已安装 ($DEFAULT_MODE 模式)"

    if [ -f "$TARGET_DIR/CLAUDE.md" ]; then
        print_info "Codex-native 模式不使用根 CLAUDE.md，备份中..."
        mv "$TARGET_DIR/CLAUDE.md" "$TARGET_DIR/CLAUDE.md.backup.$(date +%Y%m%d%H%M%S)"
    fi
elif [ -f "$PROFILE_DIR/CLAUDE.md" ]; then
    if [ -f "$TARGET_DIR/CLAUDE.md" ]; then
        print_info "项目 CLAUDE.md 已存在，备份中..."
        mv "$TARGET_DIR/CLAUDE.md" "$TARGET_DIR/CLAUDE.md.backup.$(date +%Y%m%d%H%M%S)"
    fi
    cp "$PROFILE_DIR/CLAUDE.md" "$TARGET_DIR/CLAUDE.md"
    print_success "项目 CLAUDE.md 已安装 ($DEFAULT_MODE 模式)"
fi

# 复制 settings.json
if [ -f "$PROFILE_DIR/settings.json" ]; then
    if [ -f "$CLAUDE_DIR/settings.json" ]; then
        mv "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.json.backup.$(date +%Y%m%d%H%M%S)"
    fi
    cp "$PROFILE_DIR/settings.json" "$CLAUDE_DIR/settings.json"
    print_success "settings.json 已安装"
fi

if is_codex_native_profile "$PROFILE_DIR"; then
    copy_tree_contents "$SHARED_DIR/hooks" "$CODEX_DIR/hooks"
    copy_tree_contents "$SHARED_DIR/commands" "$CODEX_DIR/commands"
    copy_tree_contents "$SHARED_DIR/skills" "$CODEX_DIR/skills"
    copy_tree_contents "$SHARED_CODEX_DIR/hooks" "$CODEX_DIR/hooks"
    copy_tree_contents "$SHARED_CODEX_DIR/commands" "$CODEX_DIR/commands"
    copy_tree_contents "$SHARED_CODEX_DIR/skills" "$CODEX_DIR/skills"
    copy_tree_contents "$SHARED_CODEX_DIR/tools" "$CODEX_DIR/tools"
    if [[ "$DEFAULT_MODE" != "codex-codex-python-dev" ]]; then
        copy_tree_contents "$SHARED_CODEX_DIR/java/tools" "$CODEX_DIR/tools"
    fi
    copy_tree_contents "$PROFILE_DIR/skills" "$CODEX_DIR/skills"
    copy_tree_contents "$PROFILE_DIR/.codex" "$CODEX_DIR"
    install_codex_session_state
    chmod +x "$CODEX_DIR/hooks/"*.sh "$CODEX_DIR/tools/"*.sh 2>/dev/null || true
    print_success "Codex-native .codex 资源已安装"
else
    # 复制模式特有资源
    for dir in skills agents rules; do
        if [ -d "$PROFILE_DIR/$dir" ] && [ "$(ls -A "$PROFILE_DIR/$dir" 2>/dev/null)" ]; then
            cp -r "$PROFILE_DIR/$dir/"* "$CLAUDE_DIR/$dir/" 2>/dev/null || true
            print_success "$dir/ 资源已安装"
        fi
    done

    if [ -d "$PROFILE_DIR/codex/skills" ] && [ "$(ls -A "$PROFILE_DIR/codex/skills" 2>/dev/null)" ]; then
        cp -r "$PROFILE_DIR/codex/skills/"* "$CODEX_DIR/skills/" 2>/dev/null || true
        print_success "codex/skills 资源已安装"
    fi

    if [ -f "$CODEX_DIR/hooks.json" ]; then
        mv "$CODEX_DIR/hooks.json" "$CODEX_DIR/hooks.json.backup.$(date +%Y%m%d%H%M%S)"
    fi

    cat > "$CODEX_DIR/hooks.json" << 'HOOKSEOF'
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
    print_success ".codex/hooks.json 已安装"
fi

if [ -f "$TARGET_DIR/.graphifyignore" ]; then
    print_info ".graphifyignore 已存在，跳过"
elif [ -f "$GRAPHIFY_IGNORE_TEMPLATE" ]; then
    cp "$GRAPHIFY_IGNORE_TEMPLATE" "$TARGET_DIR/.graphifyignore"
    print_success ".graphifyignore 已安装"
fi

echo ""

# ═══════════════════════════════════════════════
# Step 4: OpenSpec 安装（可选）
# ═══════════════════════════════════════════════
echo -e "${CYAN}  Step 4: OpenSpec（可选）${NC}"
if [ -d "$TARGET_DIR/openspec" ]; then
    print_info "OpenSpec 目录已存在，跳过"
elif command -v openspec &> /dev/null; then
    prompt_read "安装 OpenSpec? (y/n): " install_openspec
    if [ "$install_openspec" = "y" ] || [ "$install_openspec" = "Y" ]; then
        openspec init --tools claude 2>/dev/null && {
            print_success "OpenSpec 已初始化"
        } || print_info "OpenSpec init 需要手动执行: openspec init"
    fi
else
    print_info "openspec 命令未找到，跳过"
fi

# ═══════════════════════════════════════════════
# Step 5: Graphify（可选）
# ═══════════════════════════════════════════════
echo -e "${CYAN}  Step 5: Graphify（可选）${NC}"
if command -v graphify &> /dev/null; then
    print_success "graphify 已安装"
else
    print_info "未检测到 graphify"
    prompt_read "安装 Graphify? (y/n): " install_graphify
    if [ "$install_graphify" = "y" ] || [ "$install_graphify" = "Y" ]; then
        if command -v python3 &> /dev/null; then
            python3 -m pip install --user graphifyy 2>/dev/null && {
                hash -r 2>/dev/null || true
                if command -v graphify &> /dev/null; then
                    graphify install 2>/dev/null && print_success "graphify 安装完成" || print_info "graphify 已安装，请手动执行: graphify install"
                else
                    print_info "graphify 包已安装，请重新打开终端后执行: graphify install"
                fi
            } || print_info "自动安装失败，请手动执行: pip install graphifyy && graphify install"
        else
            print_info "未检测到 python3，请手动执行: pip install graphifyy && graphify install"
        fi
    fi
fi
print_info "快速安装: pip install graphifyy && graphify install"
print_info "项目内常用命令: /graphify ."

# ═══════════════════════════════════════════════
# Step 6: MCP 安装（可选）
# ═══════════════════════════════════════════════
echo -e "${CYAN}  Step 6: MCP 工具（可选）${NC}"
if [ -f "$V1_TEMPLATE_DIR/.mcp.json" ] && [ ! -f "$TARGET_DIR/.mcp.json" ]; then
    prompt_read "安装 MCP 工具 (Codex + Gemini + OpenCode)? (y/n): " install_mcp
    if [ "$install_mcp" = "y" ] || [ "$install_mcp" = "Y" ]; then
        cp "$V1_TEMPLATE_DIR/.mcp.json" "$TARGET_DIR/.mcp.json"
        print_success "MCP 配置已安装"
    fi
elif [ -f "$TARGET_DIR/.mcp.json" ]; then
    print_info ".mcp.json 已存在，跳过"
fi

# OpenCode 项目配置
if [ -f "$V1_TEMPLATE_DIR/templates/opencode.json" ] && [ ! -f "$TARGET_DIR/opencode.json" ]; then
    cp "$V1_TEMPLATE_DIR/templates/opencode.json" "$TARGET_DIR/opencode.json"
    print_success "opencode.json 已安装"
elif [ -f "$TARGET_DIR/opencode.json" ]; then
    print_info "opencode.json 已存在，跳过"
fi
if [ -f "$V1_TEMPLATE_DIR/templates/.opencode/plugins/graphify.js" ]; then
    mkdir -p "$TARGET_DIR/.opencode/plugins"
    cp "$V1_TEMPLATE_DIR/templates/.opencode/plugins/graphify.js" "$TARGET_DIR/.opencode/plugins/graphify.js"
    print_success "OpenCode graphify 插件已安装"
fi
if [ -f "$V1_TEMPLATE_DIR/templates/AGENTS.md" ] && [ ! -f "$TARGET_DIR/AGENTS.md" ]; then
    cp "$V1_TEMPLATE_DIR/templates/AGENTS.md" "$TARGET_DIR/AGENTS.md"
    print_success "AGENTS.md 已安装"
elif [ -f "$TARGET_DIR/AGENTS.md" ]; then
    print_info "AGENTS.md 已存在，跳过"
fi

echo ""

# ═══════════════════════════════════════════════
# Step 7: 写入项目 manifest
# ═══════════════════════════════════════════════
echo -e "${CYAN}  Step 7: 项目 Manifest${NC}"

# 计算项目 profile 入口文件 hash
HASH_SOURCE="$TARGET_DIR/CLAUDE.md"
if is_codex_native_profile "$PROFILE_DIR"; then
    HASH_SOURCE="$TARGET_DIR/AGENTS.md"
fi

if command -v shasum &> /dev/null; then
    PROJ_HASH=$(shasum -a 256 "$HASH_SOURCE" 2>/dev/null | cut -d' ' -f1 | head -c 12)
elif command -v sha256sum &> /dev/null; then
    PROJ_HASH=$(sha256sum "$HASH_SOURCE" 2>/dev/null | cut -d' ' -f1 | head -c 12)
else
    PROJ_HASH="unknown"
fi

if command -v git &> /dev/null && [ -d "$V1_TEMPLATE_DIR/.git" ]; then
    SOURCE_REV=$(cd "$V1_TEMPLATE_DIR" && git rev-parse --short HEAD 2>/dev/null || echo "unknown")
else
    SOURCE_REV="unknown"
fi

cat > "$PROJECT_MANIFEST" << MANIFESTEOF
{
  "manifestSchemaVersion": 1,
  "harnessVersion": "v2",
  "role": "project",
  "mode": "$DEFAULT_MODE",
  "globalVersionRequired": "v2",
  "sourceRevision": "$SOURCE_REV",
  "templateHash": "$PROJ_HASH",
  "managedAssets": [
    "CLAUDE.md",
    "AGENTS.md",
    ".claude/settings.json",
    ".claude/skills",
    ".claude/agents",
    ".claude/hooks",
    ".claude/commands",
    ".claude/rules",
    ".codex/hooks.json",
    ".codex/hooks",
    ".codex/agents",
    ".codex/commands",
    ".codex/skills",
    ".codex/tools",
    ".codex/config.toml",
    ".codex/session-state.md",
    ".codex/session-state.template.md",
    ".graphifyignore"
  ],
  "installedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "switchedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
MANIFESTEOF

print_success "项目 manifest 已写入"

# 移除 V1 的 .active-plugin（如果存在且在迁移模式）
if [ "$MIGRATE_MODE" = true ] && [ -f "$CLAUDE_DIR/.active-plugin" ]; then
    rm "$CLAUDE_DIR/.active-plugin"
    print_info "已移除 V1 .active-plugin 文件"
fi

echo ""

# ═══════════════════════════════════════════════
# Step 8: 验证
# ═══════════════════════════════════════════════
echo -e "${CYAN}  Step 8: 验证${NC}"
ok=true

if is_codex_native_profile "$PROFILE_DIR"; then
    [ -f "$TARGET_DIR/AGENTS.md" ] && print_success "AGENTS.md 存在" || { print_error "AGENTS.md 缺失"; ok=false; }
    [ -f "$CODEX_DIR/config.toml" ] && print_success ".codex/config.toml 存在" || { print_error ".codex/config.toml 缺失"; ok=false; }
    [ -f "$CODEX_DIR/session-state.md" ] && print_success ".codex/session-state.md 存在" || { print_error ".codex/session-state.md 缺失"; ok=false; }
else
    [ -f "$TARGET_DIR/CLAUDE.md" ] && print_success "CLAUDE.md 存在" || { print_error "CLAUDE.md 缺失"; ok=false; }
fi
[ -f "$CLAUDE_DIR/settings.json" ] && print_success "settings.json 存在" || { print_error "settings.json 缺失"; ok=false; }
[ -f "$PROJECT_MANIFEST" ] && print_success "manifest 存在" || { print_error "manifest 缺失"; ok=false; }
[ -f "$CLAUDE_DIR/hooks/graphify-query-hook.sh" ] && print_success "Claude graphify hook 存在" || print_info "Claude graphify hook 未安装"
[ -f "$CODEX_DIR/hooks.json" ] && print_success ".codex/hooks.json 存在" || { print_error ".codex/hooks.json 缺失"; ok=false; }
[ -f "$CODEX_DIR/hooks/graphify-query-hook.sh" ] && print_success "Codex graphify hook 存在" || { print_error "Codex graphify hook 缺失"; ok=false; }
[ -d "$PROFILE_DIR/codex/skills" ] && [ "$(ls -A "$PROFILE_DIR/codex/skills" 2>/dev/null)" ] && (
    [ -d "$CODEX_DIR/skills" ] && [ "$(ls -A "$CODEX_DIR/skills" 2>/dev/null)" ] && print_success "Codex skills 存在"
) || [ ! -d "$PROFILE_DIR/codex/skills" ] || { print_error "Codex skills 缺失"; ok=false; }
[ -f "$TARGET_DIR/.graphifyignore" ] && print_success ".graphifyignore 存在" || print_info ".graphifyignore 未安装"

if ! is_codex_native_profile "$PROFILE_DIR"; then
    if grep -q "harness-version: v2" "$TARGET_DIR/CLAUDE.md" 2>/dev/null; then
        print_success "CLAUDE.md 包含 V2 标记"
    else
        print_error "CLAUDE.md 缺少 V2 标记"
        ok=false
    fi

    if grep -q "harness-mode: $DEFAULT_MODE" "$TARGET_DIR/CLAUDE.md" 2>/dev/null; then
        print_success "CLAUDE.md 标记模式: $DEFAULT_MODE"
    else
        print_info "CLAUDE.md 模式标记未检测到（可能格式不同）"
    fi
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
if [ "$ok" = true ]; then
    echo -e "${GREEN}✓ V2 项目配置安装完成！模式: $DEFAULT_MODE${NC}"
else
    echo -e "${YELLOW}⚠ 安装完成，但有警告${NC}"
fi
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""

print_step "下一步："
echo "  1. 启动 Claude Code 会话"
echo "  2. 切换模式: $SCRIPT_DIR/scripts/switch-plugin.sh [mode]"
echo "  3. 可用模式: $(available_profiles)"
echo ""
echo -e "${GREEN}V2 项目配置就绪！${NC}"
