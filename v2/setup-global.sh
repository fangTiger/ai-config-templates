#!/bin/zsh

# Claude Code V2 Global Setup Script
# 安装 V2 分层配置的全局部分（不变量规则）
# V1 文件不会被修改，V2 只替换全局 CLAUDE.md 并写入 manifest

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
MANIFEST_FILE="$CLAUDE_DIR/.harness-manifest.json"
V1_SETUP="$TEMPLATE_DIR/setup-global.sh"

echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Claude Code V2 Global Setup${NC}"
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

V2_GLOBAL_TEMPLATE="$SCRIPT_DIR/global/CLAUDE.md"

if [ ! -f "$V2_GLOBAL_TEMPLATE" ]; then
    print_error "V2 全局模板不存在: $V2_GLOBAL_TEMPLATE"
    exit 1
fi

# 备份现有 CLAUDE.md
if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    backup_name="CLAUDE.md.backup.$(date +%Y%m%d%H%M%S)"
    cp "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/$backup_name"
    print_info "已备份现有 CLAUDE.md → $backup_name"
fi

# 安装 V2 全局 CLAUDE.md
cp "$V2_GLOBAL_TEMPLATE" "$CLAUDE_DIR/CLAUDE.md"
print_success "V2 全局 CLAUDE.md 已安装 ($(wc -l < "$CLAUDE_DIR/CLAUDE.md" | tr -d ' ') 行)"

echo ""

# ═══════════════════════════════════════════════
# Step 2: 写入全局 manifest
# ═══════════════════════════════════════════════
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Step 2: Global Manifest${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo ""

# 计算模板 hash
if command -v shasum &> /dev/null; then
    TEMPLATE_HASH=$(shasum -a 256 "$V2_GLOBAL_TEMPLATE" | cut -d' ' -f1 | head -c 12)
elif command -v sha256sum &> /dev/null; then
    TEMPLATE_HASH=$(sha256sum "$V2_GLOBAL_TEMPLATE" | cut -d' ' -f1 | head -c 12)
else
    TEMPLATE_HASH="unknown"
fi

# 获取 source revision
if command -v git &> /dev/null && [ -d "$TEMPLATE_DIR/.git" ]; then
    SOURCE_REV=$(cd "$TEMPLATE_DIR" && git rev-parse --short HEAD 2>/dev/null || echo "unknown")
else
    SOURCE_REV="unknown"
fi

# 写入 manifest
cat > "$MANIFEST_FILE" << MANIFESTEOF
{
  "manifestSchemaVersion": 1,
  "harnessVersion": "v2",
  "role": "global",
  "sourceRevision": "$SOURCE_REV",
  "templateHash": "$TEMPLATE_HASH",
  "installedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
MANIFESTEOF

print_success "全局 manifest 已写入: $MANIFEST_FILE"

echo ""

# ═══════════════════════════════════════════════
# Step 3: 验证
# ═══════════════════════════════════════════════
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Step 3: 验证${NC}"
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

# 验证 manifest
if [ -f "$MANIFEST_FILE" ]; then
    if command -v python3 &> /dev/null; then
        if python3 -m json.tool "$MANIFEST_FILE" > /dev/null 2>&1; then
            print_success "manifest.json 格式正确"
        else
            print_error "manifest.json 格式错误"
            ok=false
        fi
    fi
    print_success "manifest.json 存在"
else
    print_error "manifest.json 不存在"
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
echo -e "${GREEN}V2 全局配置就绪！${NC}"
