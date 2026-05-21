#!/bin/bash
set -euo pipefail

# ============================================================
# 插件配置切换器
# 用法: ~/.claude/config-templates/scripts/switch-plugin.sh [superpowers|ecc|omc|teams|codex-dev]
# 默认: superpowers
#
# 在任意项目目录下执行，切换该项目的插件配置。
# 模板文件从 ~/.claude/config-templates/scripts/plugin-profiles/ 读取。
# ============================================================

# 模板目录（脚本所在位置）
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROFILES_DIR="$SCRIPT_DIR/plugin-profiles"

# 目标项目目录（当前工作目录）
PROJECT_DIR="$(pwd)"
CLAUDE_DIR="$PROJECT_DIR/.claude"
CODEX_DIR="$PROJECT_DIR/.codex"
ACTIVE_FILE="$CLAUDE_DIR/.active-plugin"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 可切换的目录（切换时清理后重新复制）
SWITCHABLE_DIRS=(hooks skills agents commands rules)
CODEX_SWITCHABLE_DIRS=(skills)

ensure_graphify_assets() {
    local dry_run=$1
    local shared_dir="$PROFILES_DIR/shared"

    if [[ "$dry_run" == "true" ]]; then
        echo -e "  ${YELLOW}[DRY-RUN]${NC} 确保 .codex/hooks.json、.codex/hooks/*、.graphifyignore"
        return
    fi

    mkdir -p "$CODEX_DIR/hooks"

    for hook_file in "$shared_dir"/hooks/*; do
        [[ -f "$hook_file" ]] || continue
        cp "$hook_file" "$CODEX_DIR/hooks/$(basename "$hook_file")"
        chmod +x "$CODEX_DIR/hooks/$(basename "$hook_file")" 2>/dev/null || true
    done

    cat > "$CODEX_DIR/hooks.json" << 'HOOKSEOF'
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash .codex/hooks/skill-activation-prompt.sh"
          }
        ]
      }
    ],
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
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|MultiEdit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash .codex/hooks/post-tool-use-tracker.sh"
          }
        ]
      }
    ]
  }
}
HOOKSEOF

    if [[ ! -f "$PROJECT_DIR/.graphifyignore" && -f "$TEMPLATE_DIR/graphifyignore.template" ]]; then
        cp "$TEMPLATE_DIR/graphifyignore.template" "$PROJECT_DIR/.graphifyignore"
    fi
}

usage() {
    echo -e "${BLUE}插件配置切换器${NC}"
    echo ""
    echo "用法: $0 [profile] [options]"
    echo ""
    echo "Profiles:"
    echo "  superpowers  Superpowers 插件（默认）- 多 Agent 编排 + TDD + brainstorming"
    echo "  ecc          Everything Claude Code - AgentShield + Plankton + 持续学习"
    echo "  omc          Oh My ClaudeCode - Team/Ultrawork 编排 + 32 专业 Agent"
    echo "  teams        Superpowers Teams - 原生 Agent Teams + 5 阶段流水线"
    echo "  codex-dev    Codex 实现模式 — Claude 设计 + Codex 实现 + Gemini 前端 + 三方审核"
    echo ""
    echo "Options:"
    echo "  --install    首次安装：全局安装三个插件（只需执行一次）"
    echo "  --status     显示当前激活的 profile"
    echo "  --list       列出所有可用 profiles"
    echo "  --dry-run    预览切换操作，不实际执行"
    echo "  -h, --help   显示帮助"
    echo ""
    echo "首次使用："
    echo "  $0 --install         # 全局安装三个插件"
    echo "  $0 superpowers       # 激活 Superpowers（默认）"
    echo ""
    echo "日常切换："
    echo "  $0 ecc               # 切换到 ECC"
    echo "  $0 omc               # 切换到 OMC"
    echo "  $0 teams             # 切换到 teams"
    echo "  $0 codex-dev         # 切换到 codex-dev"
    echo "  $0 superpowers       # 切回 Superpowers"
}

# ============================================================
# 全局安装三个插件（一次性）
# ============================================================
install_plugins() {
    echo -e "${BLUE}=== 全局安装三个插件 ===${NC}"
    echo ""

    # 检查 claude 命令
    if ! command -v claude &>/dev/null; then
        echo -e "${RED}错误: 未找到 claude 命令${NC}"
        exit 1
    fi

    echo -e "${YELLOW}[1/4] 添加插件市场源...${NC}"
    # Superpowers（可能已有）
    claude plugin marketplace add superpowers-marketplace/superpowers 2>/dev/null || true
    # ECC
    claude plugin marketplace add affaan-m/everything-claude-code 2>/dev/null || true
    # OMC
    claude plugin marketplace add Yeachan-Heo/oh-my-claudecode 2>/dev/null || true

    echo -e "${YELLOW}[2/4] 安装 Superpowers...${NC}"
    claude plugin install superpowers 2>/dev/null || echo "  (可能已安装)"

    echo -e "${YELLOW}[3/4] 安装 Everything Claude Code...${NC}"
    claude plugin install everything-claude-code 2>/dev/null || echo "  (可能已安装)"

    echo -e "${YELLOW}[4/4] 安装 Oh My ClaudeCode...${NC}"
    claude plugin install oh-my-claudecode 2>/dev/null || echo "  (可能已安装)"

    echo ""
    echo -e "${YELLOW}[5/5] 设置全局默认：只启用 superpowers + 公共插件...${NC}"
    # 读取全局 settings.json，更新 enabledPlugins 只保留 superpowers + 公共
    local global_settings="$HOME/.claude/settings.json"
    if [[ -f "$global_settings" ]]; then
        # 用 jq 更新 enabledPlugins（如果有 jq）
        if command -v jq &>/dev/null; then
            local tmp=$(mktemp)
            jq '.enabledPlugins = {
                "superpowers@superpowers-marketplace": true,
                "code-review@claude-plugins-official": true,
                "commit-commands@claude-plugins-official": true,
                "pinecone@claude-plugins-official": true,
                "pyright-lsp@claude-plugins-official": true
            }' "$global_settings" > "$tmp" && mv "$tmp" "$global_settings"
            echo -e "  ${GREEN}全局 enabledPlugins 已更新（默认 superpowers）${NC}"
        else
            echo -e "  ${YELLOW}未找到 jq，请手动编辑 ~/.claude/settings.json 的 enabledPlugins${NC}"
            echo "  只保留: superpowers, code-review, commit-commands, pinecone, pyright-lsp"
        fi
    fi

    echo ""
    echo -e "${GREEN}安装完成！${NC}"
    echo ""
    echo "全局默认启用 superpowers，其他项目不受影响。"
    echo "在本项目中切换插件：$0 [superpowers|ecc|omc|teams]"
}

# ============================================================
# 状态查询
# ============================================================
get_current_profile() {
    if [[ -f "$ACTIVE_FILE" ]]; then
        cat "$ACTIVE_FILE"
    else
        echo "superpowers"
    fi
}

show_status() {
    local current=$(get_current_profile)
    echo -e "${BLUE}当前激活的 profile:${NC} ${GREEN}$current${NC}"
    echo ""
    echo "可用 profiles:"
    for profile in superpowers ecc omc teams codex-dev; do
        if [[ "$profile" == "$current" ]]; then
            echo -e "  ${GREEN}● $profile (激活)${NC}"
        else
            echo -e "  ○ $profile"
        fi
    done
}

list_profiles() {
    echo "可用 profiles:"
    for profile_dir in "$PROFILES_DIR"/*/; do
        local name=$(basename "$profile_dir")
        [[ "$name" == "shared" ]] && continue
        local has_claude="✗"; local has_settings="✗"
        [[ -f "$profile_dir/CLAUDE.md" ]] && has_claude="✓"
        [[ -f "$profile_dir/settings.json" ]] && has_settings="✓"
        echo "  $name  [CLAUDE.md:$has_claude] [settings.json:$has_settings]"
    done
}

# ============================================================
# 清理可切换目录（保留 node_modules 等）
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
                    # hooks 目录保留 node_modules 和 package-lock.json
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
    for dir in "${CODEX_SWITCHABLE_DIRS[@]}"; do
        local target="$CODEX_DIR/$dir"
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

# ============================================================
# 复制 profile 文件到 .claude/
# ============================================================
copy_profile() {
    local profile=$1
    local dry_run=$2
    local profile_dir="$PROFILES_DIR/$profile"
    local shared_dir="$PROFILES_DIR/shared"

    # 1. 复制 shared 组件（OpenSpec 等）
    if [[ -d "$shared_dir" ]]; then
        for dir in "${SWITCHABLE_DIRS[@]}"; do
            if [[ -d "$shared_dir/$dir" && "$(ls -A "$shared_dir/$dir" 2>/dev/null)" ]]; then
                if [[ "$dry_run" == "true" ]]; then
                    echo -e "  ${YELLOW}[DRY-RUN]${NC} 复制 shared/$dir/ → .claude/$dir/"
                else
                    cp -r "$shared_dir/$dir/"* "$CLAUDE_DIR/$dir/" 2>/dev/null || true
                fi
            fi
        done
    fi

    # 2. 复制 profile 特定组件（覆盖 shared 同名文件）
    for dir in "${SWITCHABLE_DIRS[@]}"; do
        if [[ -d "$profile_dir/$dir" && "$(ls -A "$profile_dir/$dir" 2>/dev/null)" ]]; then
            if [[ "$dry_run" == "true" ]]; then
                echo -e "  ${YELLOW}[DRY-RUN]${NC} 复制 $profile/$dir/ → .claude/$dir/"
            else
                cp -r "$profile_dir/$dir/"* "$CLAUDE_DIR/$dir/" 2>/dev/null || true
            fi
        fi
    done

    # 2.5 复制 profile 特定的 .codex 资源
    for dir in "${CODEX_SWITCHABLE_DIRS[@]}"; do
        if [[ -d "$profile_dir/codex/$dir" && "$(ls -A "$profile_dir/codex/$dir" 2>/dev/null)" ]]; then
            if [[ "$dry_run" == "true" ]]; then
                echo -e "  ${YELLOW}[DRY-RUN]${NC} 复制 $profile/codex/$dir/ → .codex/$dir/"
            else
                mkdir -p "$CODEX_DIR/$dir"
                cp -r "$profile_dir/codex/$dir/"* "$CODEX_DIR/$dir/" 2>/dev/null || true
            fi
        fi
    done

    # 3. 替换项目级 settings.json（含 enabledPlugins）
    if [[ -f "$profile_dir/settings.json" ]]; then
        if [[ "$dry_run" == "true" ]]; then
            echo -e "  ${YELLOW}[DRY-RUN]${NC} 替换 .claude/settings.json"
        else
            cp "$profile_dir/settings.json" "$CLAUDE_DIR/settings.json"
        fi
    fi

    # 4. 替换项目级 CLAUDE.md
    if [[ -f "$profile_dir/CLAUDE.md" ]]; then
        if [[ "$dry_run" == "true" ]]; then
            echo -e "  ${YELLOW}[DRY-RUN]${NC} 替换 CLAUDE.md"
        else
            cp "$profile_dir/CLAUDE.md" "$PROJECT_DIR/CLAUDE.md"
        fi
    fi

    # 5. hooks 依赖安装
    if [[ "$dry_run" != "true" && -f "$CLAUDE_DIR/hooks/package.json" ]]; then
        echo -e "  ${BLUE}安装 hooks 依赖...${NC}"
        (cd "$CLAUDE_DIR/hooks" && npm install --silent 2>/dev/null) || true
    fi
}

# ============================================================
# 切换 profile
# ============================================================
switch_profile() {
    local target=$1
    local dry_run=${2:-false}
    local current=$(get_current_profile)

    # 验证当前目录是有效项目（有 .claude/ 目录）
    if [[ ! -d "$CLAUDE_DIR" ]]; then
        echo -e "${RED}错误: 当前目录不是有效的 Claude Code 项目（缺少 .claude/ 目录）${NC}"
        echo "请先 cd 到项目目录，或运行 setup-claude-config.sh 初始化项目"
        exit 1
    fi

    # 验证 profile 存在
    if [[ ! -d "$PROFILES_DIR/$target" ]]; then
        echo -e "${RED}错误: profile '$target' 不存在${NC}"
        echo "可用: superpowers, ecc, omc, teams, codex-dev"
        exit 1
    fi

    if [[ "$current" == "$target" && "$dry_run" != "true" ]]; then
        echo -e "${YELLOW}当前已是 $target 配置，无需切换${NC}"
        exit 0
    fi

    echo -e "${BLUE}切换配置: ${current} → ${target}${NC}"
    echo ""

    # Step 1: 备份当前配置
    echo -e "${YELLOW}[1/6] 备份当前配置...${NC}"
    local backup_dir="$CLAUDE_DIR/.backup-${current}-$(date +%Y%m%d%H%M%S)"
    if [[ "$dry_run" == "true" ]]; then
        echo -e "  ${YELLOW}[DRY-RUN]${NC} 备份到 $backup_dir"
    else
        mkdir -p "$backup_dir"
        [[ -f "$CLAUDE_DIR/settings.json" ]] && cp "$CLAUDE_DIR/settings.json" "$backup_dir/"
        [[ -f "$PROJECT_DIR/CLAUDE.md" ]] && cp "$PROJECT_DIR/CLAUDE.md" "$backup_dir/"
        for dir in "${CODEX_SWITCHABLE_DIRS[@]}"; do
            if [[ -d "$CODEX_DIR/$dir" && "$(ls -A "$CODEX_DIR/$dir" 2>/dev/null)" ]]; then
                mkdir -p "$backup_dir/.codex"
                cp -r "$CODEX_DIR/$dir" "$backup_dir/.codex/"
            fi
        done
        echo -e "  ${GREEN}已备份到 .claude/.backup-${current}-*${NC}"
    fi

    # Step 2: 清理可切换目录
    echo -e "${YELLOW}[2/6] 清理可切换目录...${NC}"
    clean_switchable "$dry_run"
    clean_codex_switchable "$dry_run"

    # Step 2.5: 清理前一个 profile 的特殊目录
    if [[ "$current" == "omc" && "$target" != "omc" ]]; then
        if [[ "$dry_run" == "true" ]]; then
            echo -e "  ${YELLOW}[DRY-RUN]${NC} 清理 .omc/ 目录（OMC 状态）"
        else
            if [[ -d "$PROJECT_DIR/.omc" ]]; then
                rm -rf "$PROJECT_DIR/.omc"
                echo -e "  ${GREEN}已清理 .omc/ 目录${NC}"
            fi
        fi
    fi

    # Step 3: 复制文件
    echo -e "${YELLOW}[3/6] 复制 shared + profile 文件...${NC}"
    copy_profile "$target" "$dry_run"
    ensure_graphify_assets "$dry_run"

    # Step 4: 更新标记
    echo -e "${YELLOW}[4/6] 更新 .active-plugin 标记...${NC}"
    if [[ "$dry_run" == "true" ]]; then
        echo -e "  ${YELLOW}[DRY-RUN]${NC} 写入 .active-plugin = $target"
    else
        echo "$target" > "$ACTIVE_FILE"
    fi

    # Step 5: 验证
    echo -e "${YELLOW}[5/6] 验证关键文件...${NC}"
    local ok=true
    if [[ "$dry_run" != "true" ]]; then
        [[ ! -f "$CLAUDE_DIR/settings.json" ]] && echo -e "  ${RED}✗ 缺失 settings.json${NC}" && ok=false
        [[ ! -f "$PROJECT_DIR/CLAUDE.md" ]] && echo -e "  ${RED}✗ 缺失 CLAUDE.md${NC}" && ok=false
        [[ ! -d "$CLAUDE_DIR/hooks" ]] && echo -e "  ${RED}✗ 缺失 hooks/${NC}" && ok=false
        [[ ! -d "$CLAUDE_DIR/skills" ]] && echo -e "  ${RED}✗ 缺失 skills/${NC}" && ok=false
        [[ ! -d "$CLAUDE_DIR/commands/openspec" ]] && echo -e "  ${RED}✗ 缺失 commands/openspec/${NC}" && ok=false
        if [[ -d "$PROFILES_DIR/$target/codex/skills" && ! -d "$CODEX_DIR/skills" ]]; then
            echo -e "  ${RED}✗ 缺失 .codex/skills/${NC}"
            ok=false
        fi

        # 验证 enabledPlugins 包含目标插件
        if command -v jq &>/dev/null; then
            local plugin_key=""
            case "$target" in
                superpowers) plugin_key="superpowers@superpowers-marketplace" ;;
                ecc) plugin_key="everything-claude-code@everything-claude-code" ;;
                omc) plugin_key="oh-my-claudecode@omc" ;;
                teams) plugin_key="superpowers@superpowers-marketplace" ;;
                codex-dev) plugin_key="superpowers@superpowers-marketplace" ;;
            esac
            local enabled=$(jq -r ".enabledPlugins[\"$plugin_key\"] // false" "$CLAUDE_DIR/settings.json")
            if [[ "$enabled" != "true" ]]; then
                echo -e "  ${RED}✗ enabledPlugins 未启用 $plugin_key${NC}"
                ok=false
            else
                echo -e "  ${GREEN}✓ enabledPlugins 已启用 $plugin_key${NC}"
            fi
        fi

        if [[ "$ok" == "true" ]]; then
            echo -e "  ${GREEN}✓ 所有验证通过${NC}"
        else
            echo -e "  ${RED}验证失败！可从备份恢复: cp $backup_dir/* 对应位置${NC}"
            exit 1
        fi
    else
        echo -e "  ${YELLOW}[DRY-RUN]${NC} 跳过验证"
    fi

    # Step 6: 提示
    echo -e "${YELLOW}[6/6] 完成提示${NC}"
    echo ""
    echo -e "${GREEN}切换完成！当前 profile: $target${NC}"
    echo ""
    echo -e "${YELLOW}注意事项：${NC}"
    echo "  1. 需要重启 Claude Code 会话才能生效"
    echo "  2. 退出当前会话，重新运行 claude 即可"
    if [[ "$target" == "ecc" ]]; then
        echo "  3. 首次使用 ECC 请运行 /configure-ecc 完成初始化"
    elif [[ "$target" == "omc" ]]; then
        echo "  3. 首次使用 OMC 请运行 /oh-my-claudecode:omc-setup 完成初始化"
    elif [[ "$target" == "teams" ]]; then
        echo "  3. Teams 模式已启用原生 Agent Teams（CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1）"
        echo "  4. 建议安装 tmux 以获得最佳体验：brew install tmux"
    elif [[ "$target" == "codex-dev" ]]; then
        echo "  3. codex-dev 模式：Claude 设计 + Codex 实现 + Gemini 前端"
        echo "  4. 提案通过后使用 codex-handoff skill 进行上下文交接"
    fi
    echo ""
    echo -e "  备份位置: ${backup_dir}"
}

# ============================================================
# 主入口
# ============================================================
main() {
    local profile=""
    local dry_run=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --install)
                install_plugins
                exit 0
                ;;
            --status)
                show_status
                exit 0
                ;;
            --list)
                list_profiles
                exit 0
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            superpowers|ecc|omc|teams|codex-dev)
                profile=$1
                shift
                ;;
            *)
                echo -e "${RED}未知参数: $1${NC}"
                usage
                exit 1
                ;;
        esac
    done

    if [[ -z "$profile" ]]; then
        usage
        exit 0
    fi

    switch_profile "$profile" "$dry_run"
}

main "$@"
