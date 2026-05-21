#!/bin/zsh

# Claude Code Configuration Setup Script
# This script deploys Claude Code infrastructure to any project
# Including: Skills, Hooks, Agents, CLAUDE.md, OpenSpec, MCP (Codex/Gemini)

# 不使用 set -e，每步独立处理错误

# 加载用户环境（nvm、自定义 PATH 等）
if [ -f "$HOME/.zshrc" ]; then
    source "$HOME/.zshrc" 2>/dev/null || true
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR"
TARGET_DIR="${1:-.}"

echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Claude Code Configuration Setup${NC}"
echo -e "${BLUE}  OpenSpec + Superpowers Unified Workflow${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""

# Function to print step
print_step() {
    echo -e "${GREEN}▶${NC} $1"
}

# Function to print info
print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# Function to print error
print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

# zsh 兼容的 read 函数
prompt_read() {
    local prompt_text=$1
    local var_name=$2
    echo -n "$prompt_text"
    read "$var_name"
}

# Check if template directory exists
if [ ! -d "$TEMPLATE_DIR" ]; then
    print_error "Template directory not found: $TEMPLATE_DIR"
    echo "Please run this script from the checked-out config template repository."
    exit 1
fi

# Determine target directory
cd "$TARGET_DIR"
TARGET_DIR="$(pwd)"
print_info "Target directory: $TARGET_DIR"
echo ""

# Step 1: Create .claude directory
print_step "Creating .claude directory structure..."
mkdir -p .claude/{skills,hooks,agents,commands}
mkdir -p .codex/hooks
print_success "Directory structure created"
echo ""

# Step 2: Copy CLAUDE.md (Multi-AI Collaboration Rules)
print_step "Installing CLAUDE.md (Multi-AI Collaboration Rules)..."
if [ -f CLAUDE.md ]; then
    print_info "CLAUDE.md already exists. Backing up..."
    mv CLAUDE.md CLAUDE.md.backup
fi
cp "$TEMPLATE_DIR/CLAUDE.md" ./CLAUDE.md
print_success "CLAUDE.md installed"
echo ""

# Step 3: Copy hooks
print_step "Installing skill activation hooks..."
cp "$TEMPLATE_DIR/hooks/skill-activation-prompt.sh" .claude/hooks/ 2>/dev/null || true
cp "$TEMPLATE_DIR/hooks/skill-activation-prompt.ts" .claude/hooks/ 2>/dev/null || true
cp "$TEMPLATE_DIR/hooks/post-tool-use-tracker.sh" .claude/hooks/ 2>/dev/null || true
cp "$TEMPLATE_DIR/hooks/graphify-query-hook.sh" .claude/hooks/ 2>/dev/null || true
cp "$TEMPLATE_DIR/hooks/package.json" .claude/hooks/ 2>/dev/null || true

chmod +x .claude/hooks/*.sh 2>/dev/null || true
cp "$TEMPLATE_DIR/hooks/graphify-query-hook.sh" .codex/hooks/ 2>/dev/null || true
chmod +x .codex/hooks/*.sh 2>/dev/null || true

cat > .codex/hooks.json << 'HOOKSEOF'
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

if [ -f "$TEMPLATE_DIR/graphifyignore.template" ] && [ ! -f .graphifyignore ]; then
    cp "$TEMPLATE_DIR/graphifyignore.template" .graphifyignore
fi
print_success "Hooks installed"
echo ""

# Step 4: Install hook dependencies
print_step "Installing hook dependencies..."
if [ -f .claude/hooks/package.json ]; then
    (cd .claude/hooks && npm install --silent 2>/dev/null) || print_info "npm install skipped"
    print_success "Dependencies installed"
else
    print_info "No package.json found, skipping"
fi
echo ""

# Step 5: Copy skills
print_step "Installing skills..."

echo "Available skills:"
echo ""
echo "  --- 项目自定义技能 ---"
echo "  1) openspec-workflow (OpenSpec Workflow)"
echo "  2) git-workflow (Git Workflow Management)"
echo "  3) python-backend-guidelines (Python/Django/FastAPI)"
echo "  4) python-error-tracking (Sentry for Python)"
echo "  5) skill-developer (Create Custom Skills)"
echo "  6) ppt-generator (PPT素材生成)"
echo "  7) document-reader (Word/Excel文档读取)"
echo "  8) design-doc-generator (Markdown转Word/XML)"
echo "  9) session-recovery (会话状态持久化与恢复)"
echo "  10) e2e-testing (端到端测试规范与脚手架)"
echo ""
echo "  --- Anthropic 官方技能 ---"
echo "  11) skill-creator (Skill创建/评估/优化)"
echo "  12) algorithmic-art (算法艺术SVG生成)"
echo "  13) brand-guidelines (品牌指南文档)"
echo "  14) canvas-design (Canvas交互设计)"
echo "  15) claude-api (Claude API集成)"
echo "  16) doc-coauthoring (文档协作撰写)"
echo "  17) docx (Word文档生成)"
echo "  18) frontend-design (前端UI设计)"
echo "  19) internal-comms (内部沟通文档)"
echo "  20) mcp-builder (MCP Server开发)"
echo "  21) pdf (PDF文档生成)"
echo "  22) pptx (PowerPoint生成)"
echo "  23) slack-gif-creator (Slack GIF创建)"
echo "  24) theme-factory (主题/样式工厂)"
echo "  25) web-artifacts-builder (Web组件构建)"
echo "  26) webapp-testing (Web应用测试)"
echo "  27) xlsx (Excel文档生成)"
echo ""
echo "  28) All of the above (Recommended)"
echo ""
prompt_read "Select skills to install (1-28, comma-separated e.g. 1,3,5): " skill_choice

# 技能名称映射
declare -A SKILL_MAP=(
    [1]="openspec-workflow"
    [2]="git-workflow"
    [3]="python-backend-guidelines"
    [4]="python-error-tracking"
    [5]="skill-developer"
    [6]="ppt-generator"
    [7]="document-reader"
    [8]="design-doc-generator"
    [9]="session-recovery"
    [10]="e2e-testing"
    [11]="skill-creator"
    [12]="algorithmic-art"
    [13]="brand-guidelines"
    [14]="canvas-design"
    [15]="claude-api"
    [16]="doc-coauthoring"
    [17]="docx"
    [18]="frontend-design"
    [19]="internal-comms"
    [20]="mcp-builder"
    [21]="pdf"
    [22]="pptx"
    [23]="slack-gif-creator"
    [24]="theme-factory"
    [25]="web-artifacts-builder"
    [26]="webapp-testing"
    [27]="xlsx"
)

install_skill() {
    local skill_name=$1
    if [ -d "$TEMPLATE_DIR/skills/$skill_name" ]; then
        cp -r "$TEMPLATE_DIR/skills/$skill_name" .claude/skills/
        print_success "Installed: $skill_name"
    else
        print_info "Skill not found: $skill_name"
    fi
}

install_all_skills() {
    for skill_name in "${SKILL_MAP[@]}"; do
        install_skill "$skill_name"
    done
    print_success "Installed: All skills"
}

# 清理旧的已废弃 skill
if [ -d ".claude/skills/dev-workflow" ]; then
    print_info "Removing deprecated skill: dev-workflow"
    rm -rf ".claude/skills/dev-workflow"
fi

if [[ "$skill_choice" == "28" || -z "$skill_choice" ]]; then
    install_all_skills
else
    IFS=',' read -rA CHOICES <<< "$skill_choice"
    for choice in "${CHOICES[@]}"; do
        choice=$(echo "$choice" | tr -d ' ')
        if [[ -n "${SKILL_MAP[$choice]}" ]]; then
            install_skill "${SKILL_MAP[$choice]}"
        else
            print_info "Unknown option: $choice"
        fi
    done
fi
echo ""

# Step 6: Copy skill-rules.json
print_step "Installing skill-rules.json..."
if [ -f .claude/skills/skill-rules.json ]; then
    print_info "skill-rules.json already exists. Backing up..."
    mv .claude/skills/skill-rules.json .claude/skills/skill-rules.json.backup
fi
cp "$TEMPLATE_DIR/skills/skill-rules.json" .claude/skills/
print_success "skill-rules.json installed"
echo ""

# Step 7: Copy agents
print_step "Installing agents..."
prompt_read "Install all agents? (y/n): " install_agents
if [ "$install_agents" = "y" ] || [ "$install_agents" = "Y" ]; then
    cp "$TEMPLATE_DIR/agents"/*.md .claude/agents/ 2>/dev/null || true
    agent_count=$(ls -1 .claude/agents/*.md 2>/dev/null | wc -l)
    print_success "Installed $agent_count agents"
else
    print_info "Skipping agents installation"
fi
echo ""

# Step 8: Create or update settings.json
print_step "Configuring settings.json..."
if [ -f .claude/settings.json ]; then
    print_info "settings.json already exists. Manual merge required."
    cp "$TEMPLATE_DIR/settings.json" .claude/settings.json.template
    print_info "Template saved as .claude/settings.json.template"
else
    cp "$TEMPLATE_DIR/settings.json" .claude/settings.json
    print_success "settings.json created"
fi
echo ""

# Step 9: OpenSpec Installation
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "${CYAN}  OpenSpec (Spec-Driven Workflow Tool)${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo ""
print_step "OpenSpec provides: Proposal → Review → Implement → Archive workflow"
echo ""
prompt_read "Install OpenSpec? (y/n): " install_openspec

if [ "$install_openspec" = "y" ] || [ "$install_openspec" = "Y" ]; then
    # Check Node.js version
    if command -v node &> /dev/null; then
        node_version=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$node_version" -ge 20 ]; then
            print_info "Installing OpenSpec globally..."
            npm install -g @fission-ai/openspec@latest 2>/dev/null && {
                print_success "OpenSpec installed"

                # Auto-initialize OpenSpec in project (non-interactive)
                print_info "Initializing OpenSpec in project..."
                openspec init --tools claude 2>/dev/null && {
                    print_success "OpenSpec initialized (openspec/ directory created)"
                    print_success "Commands injected to .claude/commands/openspec/"

                    # Copy project.md template if exists
                    if [ -f "$TEMPLATE_DIR/openspec/project.md" ]; then
                        cp "$TEMPLATE_DIR/openspec/project.md" openspec/project.md
                        print_success "OpenSpec project.md template installed"
                    fi

                    # Create specs directory structure
                    mkdir -p openspec/specs openspec/changes
                    print_success "OpenSpec directory structure created"
                } || {
                    print_info "OpenSpec init requires manual setup: openspec init"
                }
            } || print_error "OpenSpec installation failed"
        else
            print_error "Node.js >= 20 required (current: $(node --version))"
        fi
    else
        print_error "Node.js not found. Please install Node.js >= 20"
    fi
else
    print_info "Skipping OpenSpec installation"
    print_info "You can install later: npm install -g @fission-ai/openspec@latest"
fi
echo ""

# Step 10: Graphify Installation
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Graphify (Code Knowledge Graph)${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo ""
print_step "Graphify 为 Claude/Codex 搜索提供代码图谱上下文"
echo ""
if command -v graphify &> /dev/null; then
    print_success "graphify 已安装"
else
    prompt_read "Install Graphify? (y/n): " install_graphify
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
    else
        print_info "Skipping Graphify installation"
    fi
fi
print_info "快速安装: pip install graphifyy && graphify install"
print_info "项目内常用命令: /graphify ."
echo ""

# Step 11: MCP Tools Installation
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "${CYAN}  MCP Tools (Multi-AI Collaboration)${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo ""
print_step "MCP enables Claude to call Codex, Gemini and OpenCode as tools"
echo ""

prompt_read "Install MCP tools (Codex + Gemini + OpenCode)? (y/n): " install_mcp
if [ "$install_mcp" = "y" ] || [ "$install_mcp" = "Y" ]; then
    # Method 1: Copy .mcp.json template (recommended)
    if [ -f "$TEMPLATE_DIR/.mcp.json" ]; then
        print_info "Installing MCP configuration via .mcp.json..."
        if [ -f .mcp.json ]; then
            print_info ".mcp.json already exists. Backing up..."
            mv .mcp.json .mcp.json.backup
        fi
        cp "$TEMPLATE_DIR/.mcp.json" ./.mcp.json
        print_success "MCP configuration installed (.mcp.json)"
        print_info "Included: codex (Codex CLI), gemini-cli (Gemini), opencode (OpenCode)"
    else
        # Method 2: Fallback to claude mcp add commands
        print_info "No .mcp.json template found, using claude mcp add..."
        if command -v claude &> /dev/null; then
            # Codex MCP
            print_info "Installing Codex MCP..."
            claude mcp remove codex -s project 2>/dev/null || true
            claude mcp add codex -s project -- codex mcp-server 2>/dev/null && {
                print_success "Codex MCP installed"
            } || print_error "Codex MCP installation failed"

            # Gemini MCP
            print_info "Installing Gemini MCP..."
            claude mcp remove gemini-cli -s project 2>/dev/null || true
            claude mcp add gemini-cli -s project -- npx -y gemini-mcp-tool 2>/dev/null && {
                print_success "Gemini MCP installed"
            } || print_error "Gemini MCP installation failed"

            # OpenCode MCP
            print_info "Installing OpenCode MCP..."
            claude mcp remove opencode -s project 2>/dev/null || true
            claude mcp add opencode -s project -- npx -y opencode-mcp 2>/dev/null && {
                print_success "OpenCode MCP installed"
            } || print_error "OpenCode MCP installation failed"
        else
            print_error "Claude CLI not found. Please install Claude Code first."
            print_info "Manual install:"
            print_info "  claude mcp add codex -s project -- codex mcp-server"
            print_info "  claude mcp add gemini-cli -s project -- npx -y gemini-mcp-tool"
            print_info "  claude mcp add opencode -s project -- npx -y opencode-mcp"
        fi
    fi

    # OpenCode project config
    print_step "Installing OpenCode project config..."
    if [ -f "$TEMPLATE_DIR/templates/opencode.json" ] && [ ! -f ./opencode.json ]; then
        cp "$TEMPLATE_DIR/templates/opencode.json" ./opencode.json
        print_success "opencode.json installed"
    elif [ -f ./opencode.json ]; then
        print_info "opencode.json already exists, skipping"
    fi
    mkdir -p .opencode/plugins
    if [ -f "$TEMPLATE_DIR/templates/.opencode/plugins/graphify.js" ]; then
        cp "$TEMPLATE_DIR/templates/.opencode/plugins/graphify.js" .opencode/plugins/graphify.js
        print_success "OpenCode graphify plugin installed"
    fi
    if [ -f "$TEMPLATE_DIR/templates/AGENTS.md" ] && [ ! -f ./AGENTS.md ]; then
        cp "$TEMPLATE_DIR/templates/AGENTS.md" ./AGENTS.md
        print_success "AGENTS.md installed"
    elif [ -f ./AGENTS.md ]; then
        print_info "AGENTS.md already exists, skipping"
    fi
else
    print_info "Skipping MCP tools installation"
fi
echo ""

# Step 12: Verification
print_step "Verifying installation..."
echo ""

# Check hooks are executable
if [ -x .claude/hooks/skill-activation-prompt.sh ] 2>/dev/null; then
    print_success "Hooks are executable"
else
    print_info "Hooks not found or not executable"
fi

# Check JSON validity
if command -v python3 &> /dev/null; then
    if [ -f .claude/skills/skill-rules.json ]; then
        if python3 -m json.tool .claude/skills/skill-rules.json > /dev/null 2>&1; then
            print_success "skill-rules.json is valid JSON"
        else
            print_error "skill-rules.json has syntax errors"
        fi
    fi

    if [ -f .claude/settings.json ]; then
        if python3 -m json.tool .claude/settings.json > /dev/null 2>&1; then
            print_success "settings.json is valid JSON"
        else
            print_error "settings.json has syntax errors"
        fi
    fi

    if [ -f .codex/hooks.json ]; then
        if python3 -m json.tool .codex/hooks.json > /dev/null 2>&1; then
            print_success ".codex/hooks.json is valid JSON"
        else
            print_error ".codex/hooks.json has syntax errors"
        fi
    fi
else
    print_info "Python3 not found, skipping JSON validation"
fi

# Check directory structure
dirs_ok=true
for dir in .claude/skills .claude/hooks; do
    if [ -d "$dir" ]; then
        print_success "$dir exists"
    else
        print_error "$dir missing"
        dirs_ok=false
    fi
done

if [ -f .codex/hooks/graphify-query-hook.sh ]; then
    print_success ".codex graphify hook exists"
else
    print_error ".codex graphify hook missing"
    dirs_ok=false
fi

# Check CLAUDE.md
if [ -f CLAUDE.md ]; then
    print_success "CLAUDE.md exists"
else
    print_error "CLAUDE.md missing"
    dirs_ok=false
fi

# Check MCP
if command -v claude &> /dev/null; then
    echo ""
    print_step "MCP Status:"
    claude mcp list 2>/dev/null || print_info "Could not list MCP tools"
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
if [ "$dirs_ok" = true ]; then
    echo -e "${GREEN}✓ Installation Complete!${NC}"
else
    echo -e "${YELLOW}⚠ Installation completed with warnings${NC}"
fi
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""

# Next steps
print_step "Next Steps:"
echo ""
echo "1. Review and customize CLAUDE.md for your project"
echo "2. Customize .claude/skills/skill-rules.json for your project paths"
echo "3. Verify MCP tools:"
echo "   claude mcp list"
echo "4. Verify OpenSpec:"
echo "   openspec list --specs"
echo "5. Test Multi-AI collaboration:"
echo "   - Ask Claude to call Codex for code review"
echo "   - Ask Claude to call Gemini for large text analysis"
echo ""
echo "Documentation:"
echo "  - CLAUDE.md: OpenSpec + Superpowers unified workflow"
echo "  - Skills: ls .claude/skills/*/SKILL.md"
echo "  - Agents: ls .claude/agents/*.md"
echo ""
echo -e "${GREEN}Happy coding with Multi-AI Collaboration!${NC}"
