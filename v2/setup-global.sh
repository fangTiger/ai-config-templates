#!/bin/zsh

# Claude Code / Codex V2 Global Setup Script
# 安装 V2 分层配置的全局部分（不变量规则）
# V1 文件不会被修改，V2 只替换全局 CLAUDE.md / AGENTS.md 并写入 manifest

# 不使用 set -e，每步独立处理错误
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
CLAUDE_DIR="$HOME/.claude"
CODEX_DIR="$HOME/.codex"
CODEX_SKILLS_DIR="$CODEX_DIR/skills"
CLAUDE_MANIFEST_FILE="$CLAUDE_DIR/.harness-manifest.json"
CODEX_MANIFEST_FILE="$CODEX_DIR/.harness-manifest.json"
V1_SETUP="$TEMPLATE_DIR/setup-global.sh"
V2_CLAUDE_GLOBAL_TEMPLATE="$SCRIPT_DIR/global/CLAUDE.md"
V2_CODEX_GLOBAL_TEMPLATE="$SCRIPT_DIR/global/AGENTS.md"
CODEX_SKILLS_TEMPLATE_DIR="$TEMPLATE_DIR/global/codex-skills"

calc_file_hash() {
    local file_path=$1
    if command -v shasum &> /dev/null; then
        shasum -a 256 "$file_path" | cut -d' ' -f1 | head -c 12
    elif command -v sha256sum &> /dev/null; then
        sha256sum "$file_path" | cut -d' ' -f1 | head -c 12
    else
        echo "unknown"
    fi
}

get_source_rev() {
    if command -v git &> /dev/null && [ -d "$TEMPLATE_DIR/.git" ]; then
        cd "$TEMPLATE_DIR" && git rev-parse --short HEAD 2>/dev/null || echo "unknown"
    else
        echo "unknown"
    fi
}

write_global_manifest() {
    local manifest_file=$1
    local target=$2
    local template_hash=$3
    local managed_assets=$4

    cat > "$manifest_file" << MANIFESTEOF
{
  "manifestSchemaVersion": 1,
  "harnessVersion": "v2",
  "role": "global",
  "target": "$target",
  "managedAssets": $managed_assets,
  "sourceRevision": "$SOURCE_REV",
  "templateHash": "$template_hash",
  "installedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
MANIFESTEOF
}

echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Claude Code / Codex V2 Global Setup${NC}"
echo -e "${BLUE}  分层配置：全局不变量 + 项目模式差异${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""

# ═══════════════════════════════════════════════
# Step 0: 检查是否需要先运行 V1 基础安装
# ═══════════════════════════════════════════════
print_step "检查基础设施..."

# 检查 claude 命令
if ! command -v claude &> /dev/null; then
    print_error "Claude Code 未安装"
    print_info "请先运行 V1 全局安装脚本安装基础设施："
    print_info "  $V1_SETUP"
    exit 1
fi

if command -v codex &> /dev/null; then
    print_success "Codex CLI 已检测到"
else
    print_info "Codex CLI 未检测到，仍会安装 ~/.codex 全局模板"
fi

# 检查插件是否已安装
plugin_count=$(claude plugin list 2>/dev/null | grep -c "superpowers\|pyright-lsp\|pinecone" || true)
if [ "$plugin_count" -lt 1 ]; then
    print_info "插件未安装。V2 依赖 V1 的基础设施（插件、MCP、hooks）。"
    echo ""
    prompt_read "是否先运行 V1 全局安装？(y/n): " run_v1
    if [ "$run_v1" = "y" ] || [ "$run_v1" = "Y" ]; then
        if [ -f "$V1_SETUP" ]; then
            print_info "运行 V1 全局安装..."
            bash "$V1_SETUP"
            echo ""
            print_success "V1 基础安装完成，继续 V2 配置..."
            echo ""
        else
            print_error "V1 安装脚本不存在: $V1_SETUP"
            exit 1
        fi
    else
        print_info "跳过 V1 安装，继续 V2 配置..."
    fi
else
    print_success "基础设施已安装（插件已检测到）"
fi

echo ""

# ═══════════════════════════════════════════════
# Step 1: 安装 V2 全局 CLAUDE.md
# ═══════════════════════════════════════════════
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Step 1: V2 Global CLAUDE.md${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo ""

mkdir -p "$CLAUDE_DIR"

if [ ! -f "$V2_CLAUDE_GLOBAL_TEMPLATE" ]; then
    print_error "V2 全局模板不存在: $V2_CLAUDE_GLOBAL_TEMPLATE"
    exit 1
fi

# 备份现有 CLAUDE.md
if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    backup_name="CLAUDE.md.backup.$(date +%Y%m%d%H%M%S)"
    cp "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/$backup_name"
    print_info "已备份现有 CLAUDE.md → $backup_name"
fi

# 安装 V2 全局 CLAUDE.md
cp "$V2_CLAUDE_GLOBAL_TEMPLATE" "$CLAUDE_DIR/CLAUDE.md"
print_success "V2 全局 CLAUDE.md 已安装 ($(wc -l < "$CLAUDE_DIR/CLAUDE.md" | tr -d ' ') 行)"

echo ""

# ═══════════════════════════════════════════════
# Step 2: 安装 V2 全局 AGENTS.md 和 Codex skills
# ═══════════════════════════════════════════════
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Step 2: V2 Global AGENTS.md / Codex Skills${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo ""

mkdir -p "$CODEX_DIR" "$CODEX_SKILLS_DIR"

if [ ! -f "$V2_CODEX_GLOBAL_TEMPLATE" ]; then
    print_error "V2 Codex 全局模板不存在: $V2_CODEX_GLOBAL_TEMPLATE"
    exit 1
fi

# 备份现有 AGENTS.md
if [ -f "$CODEX_DIR/AGENTS.md" ]; then
    codex_backup_name="AGENTS.md.backup.$(date +%Y%m%d%H%M%S)"
    cp "$CODEX_DIR/AGENTS.md" "$CODEX_DIR/$codex_backup_name"
    print_info "已备份现有 AGENTS.md → $codex_backup_name"
fi

# 安装 V2 全局 AGENTS.md
cp "$V2_CODEX_GLOBAL_TEMPLATE" "$CODEX_DIR/AGENTS.md"
print_success "V2 全局 AGENTS.md 已安装 ($(wc -l < "$CODEX_DIR/AGENTS.md" | tr -d ' ') 行)"

skill_count=0
skill_backup_dir=""

if [ -d "$CODEX_SKILLS_TEMPLATE_DIR" ]; then
    for skill_dir in "$CODEX_SKILLS_TEMPLATE_DIR"/*(N); do
        if [ -d "$skill_dir" ]; then
            skill_name=$(basename "$skill_dir")
            target_skill="$CODEX_SKILLS_DIR/$skill_name"
            if [ -d "$target_skill" ]; then
                if [ -z "$skill_backup_dir" ]; then
                    skill_backup_dir="$CODEX_DIR/.harness-backups/codex-skills-$(date +%Y%m%d%H%M%S)"
                    mkdir -p "$skill_backup_dir"
                fi
                cp -R "$target_skill" "$skill_backup_dir/"
                rm -rf "$target_skill"
            fi
            cp -R "$skill_dir" "$CODEX_SKILLS_DIR/"
            ((skill_count++))
        fi
    done
    print_success "Codex skills 已同步: $skill_count 个"
    if [ -n "$skill_backup_dir" ]; then
        print_info "已备份被替换的 Codex skills → $skill_backup_dir"
    fi
else
    print_info "未找到 Codex skills 模板目录: $CODEX_SKILLS_TEMPLATE_DIR"
fi

echo ""

# ═══════════════════════════════════════════════
# Step 3: 写入全局 manifest
# ═══════════════════════════════════════════════
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Step 3: Global Manifests${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo ""

# 获取 source revision
SOURCE_REV=$(get_source_rev)
CLAUDE_TEMPLATE_HASH=$(calc_file_hash "$V2_CLAUDE_GLOBAL_TEMPLATE")
CODEX_TEMPLATE_HASH=$(calc_file_hash "$V2_CODEX_GLOBAL_TEMPLATE")

write_global_manifest "$CLAUDE_MANIFEST_FILE" "claude" "$CLAUDE_TEMPLATE_HASH" '["CLAUDE.md"]'
write_global_manifest "$CODEX_MANIFEST_FILE" "codex" "$CODEX_TEMPLATE_HASH" '["AGENTS.md", "skills/*"]'

print_success "Claude 全局 manifest 已写入: $CLAUDE_MANIFEST_FILE"
print_success "Codex 全局 manifest 已写入: $CODEX_MANIFEST_FILE"

echo ""

# ═══════════════════════════════════════════════
# Step 4: 验证
# ═══════════════════════════════════════════════
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Step 4: 验证${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo ""

ok=true

# 验证 CLAUDE.md
if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    if grep -q "harness-version: v2" "$CLAUDE_DIR/CLAUDE.md"; then
        print_success "CLAUDE.md 包含 V2 标记"
    else
        print_error "CLAUDE.md 缺少 V2 标记"
        ok=false
    fi
    line_count=$(wc -l < "$CLAUDE_DIR/CLAUDE.md" | tr -d ' ')
    print_success "CLAUDE.md: $line_count 行"
else
    print_error "CLAUDE.md 不存在"
    ok=false
fi

# 验证 Claude manifest
if [ -f "$CLAUDE_MANIFEST_FILE" ]; then
    if command -v python3 &> /dev/null; then
        if python3 -m json.tool "$CLAUDE_MANIFEST_FILE" > /dev/null 2>&1; then
            print_success "Claude manifest.json 格式正确"
        else
            print_error "Claude manifest.json 格式错误"
            ok=false
        fi
    fi
    print_success "Claude manifest.json 存在"
else
    print_error "Claude manifest.json 不存在"
    ok=false
fi

# 验证 AGENTS.md
if [ -f "$CODEX_DIR/AGENTS.md" ]; then
    if grep -q "harness-version: v2" "$CODEX_DIR/AGENTS.md"; then
        print_success "AGENTS.md 包含 V2 标记"
    else
        print_error "AGENTS.md 缺少 V2 标记"
        ok=false
    fi
    if grep -q "harness-target: codex" "$CODEX_DIR/AGENTS.md"; then
        print_success "AGENTS.md 包含 Codex 目标标记"
    else
        print_error "AGENTS.md 缺少 Codex 目标标记"
        ok=false
    fi
    codex_line_count=$(wc -l < "$CODEX_DIR/AGENTS.md" | tr -d ' ')
    print_success "AGENTS.md: $codex_line_count 行"
else
    print_error "AGENTS.md 不存在"
    ok=false
fi

# 验证 Codex skills
if [ -f "$CODEX_SKILLS_DIR/using-superpowers/SKILL.md" ]; then
    print_success "Codex skills 已安装"
else
    print_error "Codex skills 未安装"
    ok=false
fi

# 验证 Codex manifest
if [ -f "$CODEX_MANIFEST_FILE" ]; then
    if command -v python3 &> /dev/null; then
        if python3 -m json.tool "$CODEX_MANIFEST_FILE" > /dev/null 2>&1; then
            print_success "Codex manifest.json 格式正确"
        else
            print_error "Codex manifest.json 格式错误"
            ok=false
        fi
    fi
    print_success "Codex manifest.json 存在"
else
    print_error "Codex manifest.json 不存在"
    ok=false
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
if [ "$ok" = true ]; then
    echo -e "${GREEN}✓ V2 全局配置安装完成！${NC}"
else
    echo -e "${YELLOW}⚠ 安装完成，但有警告${NC}"
fi
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""

print_step "下一步："
echo "  cd your-project"
echo "  $SCRIPT_DIR/setup-project.sh"
echo ""
echo -e "${GREEN}V2 Claude/Codex 全局配置就绪！${NC}"
