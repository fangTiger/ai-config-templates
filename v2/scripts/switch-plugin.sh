#!/bin/bash
set -euo pipefail

# ============================================================
# V2 插件配置切换器
# 用法: ~/.claude/config-templates/v2/scripts/switch-plugin.sh [profile]
# 
# V2 版本：切换项目级 profile 资源；Codex-native profile 以 AGENTS.md + .codex/ 为主
# 全局 CLAUDE.md 不变
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
V2_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROFILES_DIR="$SCRIPT_DIR/plugin-profiles"
SHARED_DIR="$PROFILES_DIR/shared"

PROJECT_DIR="$(pwd)"
CLAUDE_DIR="$PROJECT_DIR/.claude"
CODEX_DIR="$PROJECT_DIR/.codex"
GLOBAL_MANIFEST="$HOME/.claude/.harness-manifest.json"
PROJECT_MANIFEST="$CLAUDE_DIR/.harness-manifest.json"
GRAPHIFY_IGNORE_TEMPLATE="$V2_DIR/graphifyignore.template"
RESET_SESSION_STATE=false
PRESERVED_CODEX_SESSION_STATE=""

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 可切换的目录
SWITCHABLE_DIRS=(hooks skills agents commands rules)
CODEX_SWITCHABLE_DIRS=(skills)
CODEX_NATIVE_DIRS=(agents commands hooks skills tools)

is_codex_native_profile_dir() {
    local profile_dir=$1
    [[ -f "$profile_dir/AGENTS.md" && -d "$profile_dir/.codex" ]]
}

is_codex_native_profile() {
    local profile=$1
    is_codex_native_profile_dir "$PROFILES_DIR/$profile"
}

copy_tree_contents() {
    local src=$1
    local dst=$2

    if [[ -d "$src" && "$(ls -A "$src" 2>/dev/null)" ]]; then
        mkdir -p "$dst"
        cp -R "$src"/. "$dst"/
    fi
}

cleanup_preserved_session_state() {
    if [[ -n "${PRESERVED_CODEX_SESSION_STATE:-}" && -f "$PRESERVED_CODEX_SESSION_STATE" ]]; then
        rm -f "$PRESERVED_CODEX_SESSION_STATE"
        PRESERVED_CODEX_SESSION_STATE=""
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

copy_session_state() {
    local profile_name=$1
    local target_state="$CODEX_DIR/session-state.md"
    local target_template="$CODEX_DIR/session-state.template.md"

    [[ -f "$target_template" ]] || return

    if [[ "$RESET_SESSION_STATE" == "true" ]]; then
        cp "$target_template" "$target_state"
        echo -e "  ${YELLOW}已按模板重置 .codex/session-state.md${NC}"
        return
    fi

    if [[ -n "${PRESERVED_CODEX_SESSION_STATE:-}" && -s "$PRESERVED_CODEX_SESSION_STATE" ]]; then
        if validate_session_state_file "$PRESERVED_CODEX_SESSION_STATE" "$profile_name"; then
            cp "$PRESERVED_CODEX_SESSION_STATE" "$target_state"
            normalize_session_state_from_template "$target_state" "$target_template"
            echo -e "  ${YELLOW}已保留现有 .codex/session-state.md${NC}"
        else
            cp "$target_template" "$target_state"
            echo -e "  ${YELLOW}现有 .codex/session-state.md 与 $profile_name 不匹配，已按目标模板初始化${NC}"
        fi
        cleanup_preserved_session_state
        return
    fi

    if [[ ! -s "$target_state" ]]; then
        cp "$target_template" "$target_state"
    fi
}

profile_hash_source() {
    local profile=$1
    local profile_dir="$PROFILES_DIR/$profile"

    if [[ -f "$profile_dir/CLAUDE.md" ]]; then
        echo "$PROJECT_DIR/CLAUDE.md"
    elif [[ -f "$profile_dir/AGENTS.md" ]]; then
        echo "$PROJECT_DIR/AGENTS.md"
    else
        echo "$PROJECT_DIR/CLAUDE.md"
    fi
}

ensure_graphify_assets() {
    local dry_run=$1

    if [[ "$dry_run" == "true" ]]; then
        echo -e "  ${YELLOW}[DRY-RUN]${NC} 确保 .codex/hooks.json、.codex/hooks/graphify-query-hook.sh、.graphifyignore"
        return
    fi

    mkdir -p "$CODEX_DIR/hooks"

    if [[ -f "$SHARED_DIR/hooks/graphify-query-hook.sh" ]]; then
        cp "$SHARED_DIR/hooks/graphify-query-hook.sh" "$CODEX_DIR/hooks/graphify-query-hook.sh"
        chmod +x "$CODEX_DIR/hooks/graphify-query-hook.sh" 2>/dev/null || true
    fi

    cat > "$CODEX_DIR/hooks.json" << 'HOOKSEOF'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|MultiEdit|Write",
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

    if [[ ! -f "$PROJECT_DIR/.graphifyignore" && -f "$GRAPHIFY_IGNORE_TEMPLATE" ]]; then
        cp "$GRAPHIFY_IGNORE_TEMPLATE" "$PROJECT_DIR/.graphifyignore"
    fi
}

usage() {
    echo -e "${BLUE}V2 插件配置切换器${NC}"
    echo ""
    echo "用法: $0 [profile] [options]"
    echo ""
    echo "Profiles:"
    echo "  superpowers  Superpowers（默认）— Claude 主实现 + 多 Agent 编排"
    echo "  ecc          Everything Claude Code — AgentShield + Plankton"
    echo "  omc          Oh My ClaudeCode — Team/Ultrawork + 32 Agent"
    echo "  teams        Superpowers Teams — 原生 Agent Teams"
    echo "  codex-dev    Codex 实现模式 — Claude 设计 + Codex 实现"
    echo "  codex-codex-* Codex-native 模式 — Codex 主工作台"
    echo ""
    echo "Options:"
    echo "  --status     显示当前状态"
    echo "  --list       列出可用 profiles"
    echo "  --dry-run    预览（不执行）"
    echo "  --reset-session-state  切换 Codex-native profile 时重置 .codex/session-state.md"
    echo "  -h, --help   帮助"
}

# 读取 manifest 中的字段
read_manifest_field() {
    local file=$1
    local field=$2
    if command -v python3 &>/dev/null; then
        python3 -c "import json; print(json.load(open('$file')).get('$field',''))" 2>/dev/null
    elif command -v jq &>/dev/null; then
        jq -r ".$field // empty" "$file" 2>/dev/null
    else
        grep -o "\"$field\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$file" | sed 's/.*:.*"\(.*\)"/\1/'
    fi
}

# 更新 manifest 字段
update_manifest() {
    local file=$1
    local mode=$2
    local hash=$3
    if command -v python3 &>/dev/null; then
        python3 -c "
import json, datetime
with open('$file', 'r') as f:
    d = json.load(f)
d['mode'] = '$mode'
d['templateHash'] = '$hash'
d['switchedAt'] = datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
with open('$file', 'w') as f:
    json.dump(d, f, indent=2)
" 2>/dev/null
    elif command -v jq &>/dev/null; then
        local tmp=$(mktemp)
        jq --arg m "$mode" --arg h "$hash" --arg t "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
            '.mode=$m | .templateHash=$h | .switchedAt=$t' "$file" > "$tmp" && mv "$tmp" "$file"
    fi
}

# 计算文件 hash
file_hash() {
    local file=$1
    if command -v shasum &>/dev/null; then
        shasum -a 256 "$file" 2>/dev/null | cut -d' ' -f1 | head -c 12
    elif command -v sha256sum &>/dev/null; then
        sha256sum "$file" 2>/dev/null | cut -d' ' -f1 | head -c 12
    else
        echo "unknown"
    fi
}

# ============================================================
# 状态查询
# ============================================================
show_status() {
    echo -e "${BLUE}V2 Harness 状态${NC}"
    echo ""

    # 全局
    if [ -f "$GLOBAL_MANIFEST" ]; then
        local gv=$(read_manifest_field "$GLOBAL_MANIFEST" "harnessVersion")
        echo -e "全局版本: ${GREEN}$gv${NC}"
    else
        echo -e "全局版本: ${RED}未安装${NC}"
    fi

    # 项目
    if [ -f "$PROJECT_MANIFEST" ]; then
        local pv=$(read_manifest_field "$PROJECT_MANIFEST" "harnessVersion")
        local pm=$(read_manifest_field "$PROJECT_MANIFEST" "mode")
        echo -e "项目版本: ${GREEN}$pv${NC}"
        echo -e "当前模式: ${GREEN}$pm${NC}"
        echo ""
        echo "可用模式:"
        for profile_dir in "$PROFILES_DIR"/*/; do
            local profile=$(basename "$profile_dir")
            [[ "$profile" == "shared" ]] && continue
            if [ "$profile" = "$pm" ]; then
                echo -e "  ${GREEN}● $profile (激活)${NC}"
            else
                echo -e "  ○ $profile"
            fi
        done
    elif [ -f "$CLAUDE_DIR/.active-plugin" ]; then
        echo -e "项目版本: ${YELLOW}v1${NC} (检测到 .active-plugin)"
        echo -e "当前模式: $(cat "$CLAUDE_DIR/.active-plugin")"
        echo ""
        echo -e "${YELLOW}提示: 使用 v2/setup-project.sh --migrate 升级到 V2${NC}"
    else
        echo -e "项目版本: ${RED}未初始化${NC}"
    fi
}

list_profiles() {
    echo "可用 V2 profiles:"
    for profile_dir in "$PROFILES_DIR"/*/; do
        local name=$(basename "$profile_dir")
        [[ "$name" == "shared" ]] && continue
        local has_claude="✗"; local has_settings="✗"
        [[ -f "$profile_dir/CLAUDE.md" ]] && has_claude="✓"
        [[ -f "$profile_dir/AGENTS.md" ]] && has_claude="AGENTS"
        [[ -f "$profile_dir/settings.json" ]] && has_settings="✓"
        echo "  $name  [CLAUDE.md:$has_claude] [settings.json:$has_settings]"
    done
}

# ============================================================
# 清理可切换目录
# ============================================================
clean_switchable() {
    local dry_run=$1
    for dir in "${SWITCHABLE_DIRS[@]}"; do
        local target="$CLAUDE_DIR/$dir"
        if [[ -d "$target" ]]; then
            if [[ "$dry_run" == "true" ]]; then
                echo -e "  ${YELLOW}[DRY-RUN]${NC} 清理 .claude/$dir/"
            else
                if [[ "$dir" == "hooks" ]]; then
                    find "$target" -maxdepth 1 \
                        -not -name "hooks" \
                        -not -name "node_modules" \
                        -not -name "package-lock.json" \
                        -exec rm -rf {} + 2>/dev/null || true
                else
                    rm -rf "$target"
                    mkdir -p "$target"
                fi
            fi
        else
            if [[ "$dry_run" != "true" ]]; then
                mkdir -p "$target"
            fi
        fi
    done
}

clean_codex_switchable() {
    local dry_run=$1
    local codex_dir="$PROJECT_DIR/.codex"
    for dir in "${CODEX_SWITCHABLE_DIRS[@]}"; do
        local target="$codex_dir/$dir"
        if [[ -d "$target" ]]; then
            if [[ "$dry_run" == "true" ]]; then
                echo -e "  ${YELLOW}[DRY-RUN]${NC} 清理 .codex/$dir/"
            else
                rm -rf "$target"
                mkdir -p "$target"
            fi
        else
            if [[ "$dry_run" != "true" ]]; then
                mkdir -p "$target"
            fi
        fi
    done
}

clean_codex_native() {
    local dry_run=$1

    mkdir -p "$CODEX_DIR"

    for dir in "${CODEX_NATIVE_DIRS[@]}"; do
        local target="$CODEX_DIR/$dir"
        if [[ -d "$target" ]]; then
            if [[ "$dry_run" == "true" ]]; then
                echo -e "  ${YELLOW}[DRY-RUN]${NC} 清理 .codex/$dir/"
            else
                rm -rf "$target"
                mkdir -p "$target"
            fi
        elif [[ "$dry_run" != "true" ]]; then
            mkdir -p "$target"
        fi
    done

    for file in config.toml hooks.json instructions.md workflow.md session-state.md session-state.template.md; do
        if [[ -f "$CODEX_DIR/$file" ]]; then
            if [[ "$dry_run" == "true" ]]; then
                echo -e "  ${YELLOW}[DRY-RUN]${NC} 清理 .codex/$file"
            else
                rm -f "$CODEX_DIR/$file"
            fi
        fi
    done
}

# ============================================================
# 切换 profile
# ============================================================
switch_profile() {
    local target=$1
    local dry_run=${2:-false}
    local profile_dir="$PROFILES_DIR/$target"
    local target_is_codex_native=false
    local current_is_codex_native=false

    # 前置检查：全局 manifest
    if [[ ! -f "$GLOBAL_MANIFEST" ]]; then
        echo -e "${RED}错误: 全局 manifest 不存在${NC}"
        echo "请先运行: $V2_DIR/setup-global.sh"
        exit 1
    fi
    local gv=$(read_manifest_field "$GLOBAL_MANIFEST" "harnessVersion")
    if [[ "$gv" != "v2" ]]; then
        echo -e "${RED}错误: 全局版本不是 v2 (当前: $gv)${NC}"
        echo "请先运行: $V2_DIR/setup-global.sh"
        exit 1
    fi

    # 前置检查：项目 manifest
    if [[ ! -f "$PROJECT_MANIFEST" ]]; then
        echo -e "${RED}错误: 项目 manifest 不存在（未初始化 V2）${NC}"
        echo "请先运行: $V2_DIR/setup-project.sh"
        exit 1
    fi
    local pv=$(read_manifest_field "$PROJECT_MANIFEST" "harnessVersion")
    if [[ "$pv" != "v2" ]]; then
        echo -e "${RED}错误: 项目版本不是 v2 (当前: $pv)${NC}"
        exit 1
    fi

    # 检查 profile 存在
    if [[ ! -d "$profile_dir" ]]; then
        echo -e "${RED}错误: profile '$target' 不存在${NC}"
        exit 1
    fi
    if is_codex_native_profile "$target"; then
        target_is_codex_native=true
    fi

    local current=$(read_manifest_field "$PROJECT_MANIFEST" "mode")
    if [[ -n "$current" && -d "$PROFILES_DIR/$current" ]] && is_codex_native_profile "$current"; then
        current_is_codex_native=true
    fi
    if [[ "$current" == "$target" && "$dry_run" != "true" && "$RESET_SESSION_STATE" != "true" ]]; then
        echo -e "${YELLOW}当前已是 $target，无需切换${NC}"
        exit 0
    fi

    echo -e "${BLUE}V2 切换: ${current} → ${target}${NC}"
    echo ""

    # 漂移检测
    echo -e "${YELLOW}[1/6] 漂移检测...${NC}"
    local recorded_hash=$(read_manifest_field "$PROJECT_MANIFEST" "templateHash")
    local hash_source
    hash_source=$(profile_hash_source "$current")
    local actual_hash=$(file_hash "$hash_source")
    if [[ "$recorded_hash" != "$actual_hash" && "$recorded_hash" != "unknown" && "$actual_hash" != "unknown" ]]; then
        echo -e "  ${YELLOW}⚠ 检测到 profile 入口文件已被手动修改${NC}"
        echo -e "  记录 hash: $recorded_hash"
        echo -e "  实际 hash: $actual_hash"
        if [[ "$dry_run" != "true" ]]; then
            echo -n "  覆盖本地修改？(y=覆盖, n=取消): "
            read confirm
            if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
                echo "已取消切换"
                exit 0
            fi
        fi
    else
        echo -e "  ${GREEN}✓ 无手动修改${NC}"
    fi

    # 备份
    echo -e "${YELLOW}[2/6] 备份当前配置...${NC}"
    local backup_dir="$CLAUDE_DIR/.backup-${current}-$(date +%Y%m%d%H%M%S)"
    if [[ "$dry_run" == "true" ]]; then
        echo -e "  ${YELLOW}[DRY-RUN]${NC} 备份到 $backup_dir"
    else
        mkdir -p "$backup_dir"
        [[ -f "$CLAUDE_DIR/settings.json" ]] && cp "$CLAUDE_DIR/settings.json" "$backup_dir/"
        [[ -f "$PROJECT_DIR/CLAUDE.md" ]] && cp "$PROJECT_DIR/CLAUDE.md" "$backup_dir/"
        [[ -f "$PROJECT_DIR/AGENTS.md" ]] && cp "$PROJECT_DIR/AGENTS.md" "$backup_dir/"
        # 备份所有受管目录的内容
        for dir in "${SWITCHABLE_DIRS[@]}"; do
            if [[ -d "$CLAUDE_DIR/$dir" && "$(ls -A "$CLAUDE_DIR/$dir" 2>/dev/null)" ]]; then
                cp -r "$CLAUDE_DIR/$dir" "$backup_dir/"
            fi
        done
        if [[ -d "$CODEX_DIR" && "$(ls -A "$CODEX_DIR" 2>/dev/null)" ]]; then
            mkdir -p "$backup_dir"
            cp -r "$CODEX_DIR" "$backup_dir/.codex"
        fi
        echo -e "  ${GREEN}已完整备份（含 hooks/skills/agents/commands/rules）${NC}"
    fi

    # 清理
    echo -e "${YELLOW}[3/6] 清理可切换目录...${NC}"
    if [[ "$target_is_codex_native" == "true" && "$dry_run" != "true" ]]; then
        capture_existing_session_state
    fi
    clean_switchable "$dry_run"
    if [[ "$target_is_codex_native" == "true" || "$current_is_codex_native" == "true" ]]; then
        clean_codex_native "$dry_run"
    else
        clean_codex_switchable "$dry_run"
    fi

    # 清理前一个 profile 的特殊目录
    if [[ "$current" == "omc" && "$target" != "omc" ]]; then
        if [[ -d "$PROJECT_DIR/.omc" ]]; then
            if [[ "$dry_run" == "true" ]]; then
                echo -e "  ${YELLOW}[DRY-RUN]${NC} 清理 .omc/"
            else
                rm -rf "$PROJECT_DIR/.omc"
            fi
        fi
    fi

    # 复制 shared + profile 文件
    echo -e "${YELLOW}[4/6] 安装 shared + $target 文件...${NC}"
    if [[ "$dry_run" != "true" ]]; then
        if [[ "$target_is_codex_native" == "true" ]]; then
            copy_tree_contents "$SHARED_DIR/hooks" "$CODEX_DIR/hooks"
            copy_tree_contents "$SHARED_DIR/commands" "$CODEX_DIR/commands"
            copy_tree_contents "$SHARED_DIR/skills" "$CODEX_DIR/skills"
            copy_tree_contents "$profile_dir/skills" "$CODEX_DIR/skills"
            copy_tree_contents "$profile_dir/.codex" "$CODEX_DIR"
            copy_session_state "$target"

            if [[ -f "$profile_dir/AGENTS.md" ]]; then
                cp "$profile_dir/AGENTS.md" "$PROJECT_DIR/AGENTS.md"
            fi
            rm -f "$PROJECT_DIR/CLAUDE.md"
            if [[ -f "$profile_dir/settings.json" ]]; then
                cp "$profile_dir/settings.json" "$CLAUDE_DIR/settings.json"
            fi
            chmod +x "$CODEX_DIR/hooks/"*.sh "$CODEX_DIR/tools/"*.sh 2>/dev/null || true
        else
            # Shared
            if [[ -d "$SHARED_DIR" ]]; then
                for dir in "${SWITCHABLE_DIRS[@]}"; do
                    if [[ -d "$SHARED_DIR/$dir" && "$(ls -A "$SHARED_DIR/$dir" 2>/dev/null)" ]]; then
                        cp -r "$SHARED_DIR/$dir/"* "$CLAUDE_DIR/$dir/" 2>/dev/null || true
                    fi
                done
            fi
            # Profile
            for dir in "${SWITCHABLE_DIRS[@]}"; do
                if [[ -d "$profile_dir/$dir" && "$(ls -A "$profile_dir/$dir" 2>/dev/null)" ]]; then
                    cp -r "$profile_dir/$dir/"* "$CLAUDE_DIR/$dir/" 2>/dev/null || true
                fi
            done
            # Profile-specific .codex assets
            for dir in "${CODEX_SWITCHABLE_DIRS[@]}"; do
                if [[ -d "$profile_dir/codex/$dir" && "$(ls -A "$profile_dir/codex/$dir" 2>/dev/null)" ]]; then
                    mkdir -p "$PROJECT_DIR/.codex/$dir"
                    cp -r "$profile_dir/codex/$dir/"* "$PROJECT_DIR/.codex/$dir/" 2>/dev/null || true
                fi
            done
            # CLAUDE.md
            if [[ -f "$profile_dir/CLAUDE.md" ]]; then
                cp "$profile_dir/CLAUDE.md" "$PROJECT_DIR/CLAUDE.md"
            fi
            if [[ "$current_is_codex_native" == "true" ]]; then
                rm -f "$PROJECT_DIR/AGENTS.md"
            fi
            # settings.json
            if [[ -f "$profile_dir/settings.json" ]]; then
                cp "$profile_dir/settings.json" "$CLAUDE_DIR/settings.json"
            fi
            # hooks 依赖
            if [[ -f "$CLAUDE_DIR/hooks/package.json" ]]; then
                (cd "$CLAUDE_DIR/hooks" && npm install --silent 2>/dev/null) || true
            fi
        fi
    else
        echo -e "  ${YELLOW}[DRY-RUN]${NC} 复制 shared + $target 文件"
    fi

    if [[ "$target_is_codex_native" != "true" ]]; then
        ensure_graphify_assets "$dry_run"
    elif [[ ! -f "$PROJECT_DIR/.graphifyignore" && -f "$GRAPHIFY_IGNORE_TEMPLATE" && "$dry_run" != "true" ]]; then
        cp "$GRAPHIFY_IGNORE_TEMPLATE" "$PROJECT_DIR/.graphifyignore"
    fi

    # 更新 manifest
    echo -e "${YELLOW}[5/6] 更新 manifest...${NC}"
    if [[ "$dry_run" != "true" ]]; then
        local new_hash_source
        new_hash_source=$(profile_hash_source "$target")
        local new_hash=$(file_hash "$new_hash_source")
        update_manifest "$PROJECT_MANIFEST" "$target" "$new_hash"
        echo -e "  ${GREEN}✓ mode=$target, hash=$new_hash${NC}"
    fi

    # 验证
    echo -e "${YELLOW}[6/6] 验证...${NC}"
    if [[ "$dry_run" != "true" ]]; then
        local ok=true
        [[ ! -f "$CLAUDE_DIR/settings.json" ]] && echo -e "  ${RED}✗ 缺失 settings.json${NC}" && ok=false
        if [[ "$target_is_codex_native" == "true" ]]; then
            [[ ! -f "$PROJECT_DIR/AGENTS.md" ]] && echo -e "  ${RED}✗ 缺失 AGENTS.md${NC}" && ok=false
            [[ ! -f "$CODEX_DIR/config.toml" ]] && echo -e "  ${RED}✗ 缺失 .codex/config.toml${NC}" && ok=false
            [[ ! -f "$CODEX_DIR/hooks.json" ]] && echo -e "  ${RED}✗ 缺失 .codex/hooks.json${NC}" && ok=false
            [[ ! -f "$CODEX_DIR/hooks/graphify-query-hook.sh" ]] && echo -e "  ${RED}✗ 缺失 .codex graphify hook${NC}" && ok=false
            [[ ! -f "$CODEX_DIR/session-state.md" ]] && echo -e "  ${RED}✗ 缺失 .codex/session-state.md${NC}" && ok=false
        else
            [[ ! -f "$PROJECT_DIR/CLAUDE.md" ]] && echo -e "  ${RED}✗ 缺失 CLAUDE.md${NC}" && ok=false
            [[ ! -f "$CODEX_DIR/hooks.json" ]] && echo -e "  ${RED}✗ 缺失 .codex/hooks.json${NC}" && ok=false
            [[ ! -f "$CODEX_DIR/hooks/graphify-query-hook.sh" ]] && echo -e "  ${RED}✗ 缺失 .codex graphify hook${NC}" && ok=false
            if [[ -d "$PROFILES_DIR/$target/codex/skills" && ! -d "$PROJECT_DIR/.codex/skills" ]]; then
                echo -e "  ${RED}✗ 缺失 .codex/skills${NC}"
                ok=false
            fi

            if grep -q "harness-mode: $target" "$PROJECT_DIR/CLAUDE.md" 2>/dev/null; then
                echo -e "  ${GREEN}✓ CLAUDE.md 标记模式: $target${NC}"
            fi
        fi

        if [[ "$ok" == "true" ]]; then
            echo -e "  ${GREEN}✓ 验证通过${NC}"
        fi
    fi

    echo ""
    echo -e "${GREEN}V2 切换完成！当前模式: $target${NC}"
    echo ""
    echo -e "${YELLOW}注意事项：${NC}"
    echo "  1. 需要重启 Claude Code 会话才能生效"
    echo "  2. 退出当前会话，重新运行 claude 即可"
    if [[ "$target" == "ecc" ]]; then
        echo "  3. 首次使用 ECC 请运行 /configure-ecc"
    elif [[ "$target" == "omc" ]]; then
        echo "  3. 首次使用 OMC 请运行 /oh-my-claudecode:omc-setup"
    elif [[ "$target" == "teams" ]]; then
        echo "  3. Teams 需要 CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1"
        echo "  4. 建议安装 tmux: brew install tmux"
    elif [[ "$target" == "codex-dev" ]]; then
        echo "  3. 提案通过后使用 codex-handoff skill 进行上下文交接"
    elif [[ "$target_is_codex_native" == "true" ]]; then
        echo "  3. 重启 Codex 会话后读取项目根 AGENTS.md"
    fi
    echo ""
    echo "  备份位置: $backup_dir"
}

# ============================================================
# 主入口
# ============================================================
main() {
    local profile=""
    local dry_run=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --status) show_status; exit 0 ;;
            --list) list_profiles; exit 0 ;;
            --dry-run) dry_run=true; shift ;;
            --reset-session-state) RESET_SESSION_STATE=true; shift ;;
            -h|--help) usage; exit 0 ;;
            -*)
                echo -e "${RED}未知参数: $1${NC}"
                usage
                exit 1
                ;;
            *)
                if [[ -d "$PROFILES_DIR/$1" && "$1" != "shared" ]]; then
                    profile=$1
                    shift
                else
                    echo -e "${RED}未知 profile: $1${NC}"
                    usage
                    exit 1
                fi
                ;;
        esac
    done

    if [[ -z "$profile" ]]; then
        usage
        exit 0
    fi

    switch_profile "$profile" "$dry_run"
}

trap cleanup_preserved_session_state EXIT

main "$@"
