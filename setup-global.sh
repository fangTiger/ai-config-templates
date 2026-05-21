#!/bin/zsh

# Claude Code Complete Setup Script
# This script sets up Claude Code with all plugins, MCP tools, and configurations
# Run this on a new machine to get a fully configured Claude Code environment

# 不使用 set -e，每步独立处理错误，避免单步失败导致整个脚本退出

# 加载用户环境（nvm、自定义 PATH 等）
# 非交互式 shell 可能不会自动加载 .zshrc
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

echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Claude Code Complete Setup${NC}"
echo -e "${BLUE}  Multi-AI Collaboration + Plugins + MCP${NC}"
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

# zsh 兼容的 read 函数（替代 bash 的 read -p）
prompt_read() {
    local prompt_text=$1
    local var_name=$2
    echo -n "$prompt_text"
    read "$var_name"
}

# Check prerequisites
print_step "Checking prerequisites..."

# Check Node.js
if command -v node &> /dev/null; then
    node_version=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$node_version" -ge 20 ]; then
        print_success "Node.js $(node --version) installed"
    else
        print_error "Node.js >= 20 required (current: $(node --version))"
        exit 1
    fi
else
    print_error "Node.js not found. Please install Node.js >= 20"
    exit 1
fi

# Check Python
if command -v python3 &> /dev/null; then
    print_success "Python3 installed"
else
    print_info "Python3 not found (optional, some features may not work)"
fi

# Check jq (for statusline)
if command -v jq &> /dev/null; then
    print_success "jq installed"
else
    print_info "jq not found. Installing (required for statusline)..."
    if command -v brew &> /dev/null; then
        brew install jq 2>/dev/null || print_info "jq install failed, statusline may not work"
    else
        print_info "Install jq manually: brew install jq"
    fi
fi

# Check uv (for Codex MCP)
if command -v uvx &> /dev/null; then
    print_success "uv installed"
else
    print_info "uv not found. Installing..."
    curl -LsSf https://astral.sh/uv/install.sh | sh 2>/dev/null || {
        print_error "Failed to install uv"
        print_info "Manual install: curl -LsSf https://astral.sh/uv/install.sh | sh"
    }
fi

echo ""

# ═══════════════════════════════════════════════
# Step 0: Install AI CLI Tools
# ═══════════════════════════════════════════════
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Step 0: AI CLI Tools Installation${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo ""

# Check and install Claude Code
if command -v claude &> /dev/null; then
    print_success "Claude Code installed: $(claude --version 2>/dev/null || echo 'version unknown')"
else
    print_info "Claude Code not found. Installing..."
    npm install -g @anthropic-ai/claude-code 2>/dev/null && {
        print_success "Claude Code installed"
    } || {
        print_error "Failed to install Claude Code"
        print_info "Manual install: npm install -g @anthropic-ai/claude-code"
        exit 1
    }
fi

# Check and install Codex CLI
if command -v codex &> /dev/null; then
    print_success "Codex CLI installed: $(codex --version 2>/dev/null || echo 'version unknown')"
else
    print_info "Codex CLI not found. Installing..."
    npm install -g @openai/codex 2>/dev/null && {
        print_success "Codex CLI installed"
    } || {
        print_error "Failed to install Codex CLI"
        print_info "Manual install: npm install -g @openai/codex"
    }
fi

# Check and install Gemini CLI
if command -v gemini &> /dev/null; then
    print_success "Gemini CLI installed: $(gemini --version 2>/dev/null || echo 'version unknown')"
else
    print_info "Gemini CLI not found. Installing..."
    npm install -g @google/gemini-cli 2>/dev/null && {
        print_success "Gemini CLI installed"
    } || {
        print_error "Failed to install Gemini CLI"
        print_info "Manual install: npm install -g @google/gemini-cli"
    }
fi

# Check and install OpenCode
if command -v opencode &> /dev/null; then
    print_success "OpenCode installed: $(opencode --version 2>/dev/null || echo 'version unknown')"
else
    print_info "OpenCode not found. Installing..."
    npm install -g opencode-ai 2>/dev/null && {
        print_success "OpenCode installed"
    } || {
        print_error "Failed to install OpenCode"
        print_info "Manual install: npm install -g opencode-ai"
    }
fi

echo ""

# ═══════════════════════════════════════════════
# Step 1: Global CLAUDE.md
# ═══════════════════════════════════════════════
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Step 1: Global CLAUDE.md${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

# 确保全局 .claude 目录存在
mkdir -p "$CLAUDE_DIR"

print_step "Installing global CLAUDE.md..."
if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    print_info "CLAUDE.md already exists. Backing up..."
    mv "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.backup.$(date +%Y%m%d%H%M%S)"
fi

if [ -f "$SCRIPT_DIR/global/CLAUDE.md" ]; then
    cp "$SCRIPT_DIR/global/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
    print_success "Global CLAUDE.md installed"
else
    print_info "No global CLAUDE.md template found, skipping"
fi

echo ""

# ═══════════════════════════════════════════════
# Step 2: Plugins Installation
# ═══════════════════════════════════════════════
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Step 2: Plugins Installation${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo ""

print_step "Installing Claude Code plugins..."
echo ""
echo "Available plugins:"
echo "  1) superpowers (Enhanced capabilities with 13 skills)"
echo "  2) pyright-lsp (Python LSP)"
echo "  3) pinecone (Vector database for RAG)"
echo "  4) commit-commands (Git commit helpers)"
echo "  5) code-review (Code review helpers)"
echo "  6) All of the above (Recommended)"
echo ""
prompt_read "Select plugins to install (1-6, comma-separated e.g. 1,2,4): " plugin_choice

# 注册 marketplace（如果尚未注册）
register_marketplace() {
    local marketplace_repo=$1
    local marketplace_name=$(basename "$marketplace_repo")
    print_info "注册 marketplace: $marketplace_name ($marketplace_repo)..."
    claude plugin marketplace add "$marketplace_repo" 2>/dev/null && {
        print_success "Marketplace 已注册: $marketplace_name"
    } || print_info "Marketplace 可能已注册或注册失败: $marketplace_name"
}

install_plugin() {
    local plugin_name=$1
    local marketplace=$2
    print_info "Installing ${plugin_name}@${marketplace}..."
    claude plugin install "${plugin_name}@${marketplace}" 2>/dev/null && {
        print_success "Installed: $plugin_name"
    } || print_error "Failed to install: $plugin_name (try: claude plugin install ${plugin_name}@${marketplace})"
}

# 插件映射
declare -A PLUGIN_MAP=(
    [1]="superpowers:superpowers-marketplace"
    [2]="pyright-lsp:claude-plugins-official"
    [3]="pinecone:claude-plugins-official"
    [4]="commit-commands:claude-plugins-official"
    [5]="code-review:claude-plugins-official"
)

install_all_plugins() {
    # 先注册所有需要的 marketplace
    print_step "注册 plugin marketplaces..."
    register_marketplace "anthropics/claude-plugins-official"
    register_marketplace "obra/superpowers-marketplace"
    echo ""

    for entry in "${PLUGIN_MAP[@]}"; do
        IFS=':' read -r name marketplace <<< "$entry"
        install_plugin "$name" "$marketplace"
    done
}

if [[ "$plugin_choice" == "6" || -z "$plugin_choice" ]]; then
    install_all_plugins
else
    # 先注册可能需要的 marketplace
    print_step "注册 plugin marketplaces..."
    register_marketplace "anthropics/claude-plugins-official"
    register_marketplace "obra/superpowers-marketplace"
    echo ""

    IFS=',' read -rA CHOICES <<< "$plugin_choice"
    for choice in "${CHOICES[@]}"; do
        choice=$(echo "$choice" | tr -d ' ')
        if [[ -n "${PLUGIN_MAP[$choice]}" ]]; then
            IFS=':' read -r name marketplace <<< "${PLUGIN_MAP[$choice]}"
            install_plugin "$name" "$marketplace"
        else
            print_info "Unknown option: $choice"
        fi
    done
fi

echo ""

# ═══════════════════════════════════════════════
# Step 3: MCP Tools Installation
# ═══════════════════════════════════════════════
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Step 3: MCP Tools (Multi-AI Collaboration)${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo ""

print_step "MCP enables Claude to call Codex and Gemini as tools"
echo ""

# Codex MCP
prompt_read "Install Codex MCP? (y/n): " install_codex
if [ "$install_codex" = "y" ] || [ "$install_codex" = "Y" ]; then
    print_info "Installing Codex MCP..."
    # Remove existing if any
    claude mcp remove codex 2>/dev/null || true
    # Install new
    claude mcp add codex -s user --transport stdio -- uvx --from git+https://github.com/GuDaStudio/codexmcp.git codexmcp 2>/dev/null && {
        print_success "Codex MCP installed"
    } || {
        print_error "Codex MCP installation failed"
        print_info "Manual install: claude mcp add codex -s user --transport stdio -- uvx --from git+https://github.com/GuDaStudio/codexmcp.git codexmcp"
    }
else
    print_info "Skipping Codex MCP"
fi
echo ""

# Gemini MCP
prompt_read "Install Gemini MCP? (y/n): " install_gemini
if [ "$install_gemini" = "y" ] || [ "$install_gemini" = "Y" ]; then
    print_info "Installing Gemini MCP..."
    claude mcp remove gemini-cli 2>/dev/null || true
    claude mcp add gemini-cli -- npx -y gemini-mcp-tool 2>/dev/null && {
        print_success "Gemini MCP installed"
    } || {
        print_error "Gemini MCP installation failed"
        print_info "Manual install: claude mcp add gemini-cli -- npx -y gemini-mcp-tool"
    }
else
    print_info "Skipping Gemini MCP"
fi
echo ""

# OpenCode MCP
prompt_read "Install OpenCode MCP? (y/n): " install_opencode
if [ "$install_opencode" = "y" ] || [ "$install_opencode" = "Y" ]; then
    print_info "Installing OpenCode MCP..."
    claude mcp remove opencode 2>/dev/null || true
    claude mcp add opencode -- npx -y opencode-mcp 2>/dev/null && {
        print_success "OpenCode MCP installed"
    } || {
        print_error "OpenCode MCP installation failed"
        print_info "Manual install: claude mcp add opencode -- npx -y opencode-mcp"
    }
else
    print_info "Skipping OpenCode MCP"
fi
echo ""

# ═══════════════════════════════════════════════
# Step 4: Codex & Gemini Skills Sync
# ═══════════════════════════════════════════════
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Step 4: Codex & Gemini Skills Sync${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo ""

CODEX_DIR="$HOME/.codex"
GEMINI_DIR="$HOME/.gemini"

# Sync Codex Skills (superpowers)
if command -v codex &> /dev/null; then
    print_step "Syncing skills to Codex..."
    mkdir -p "$CODEX_DIR/skills"

    if [ -d "$SCRIPT_DIR/global/codex-skills" ]; then
        skill_count=0
        for skill_dir in "$SCRIPT_DIR/global/codex-skills"/*; do
            if [ -d "$skill_dir" ]; then
                skill_name=$(basename "$skill_dir")
                cp -r "$skill_dir" "$CODEX_DIR/skills/"
                ((skill_count++))
            fi
        done
        print_success "Synced $skill_count skills to Codex (superpowers)"
    else
        print_info "No Codex skills template found"
    fi
else
    print_info "Codex CLI not installed, skipping skills sync"
fi
echo ""

# Sync Gemini Config
if command -v gemini &> /dev/null; then
    print_step "Syncing config to Gemini..."
    mkdir -p "$GEMINI_DIR"

    # Copy GEMINI.md if exists
    if [ -f "$SCRIPT_DIR/global/GEMINI.md" ]; then
        cp "$SCRIPT_DIR/global/GEMINI.md" "$GEMINI_DIR/GEMINI.md"
        print_success "Synced GEMINI.md"
    else
        # Create basic GEMINI.md from CLAUDE.md
        if [ -f "$SCRIPT_DIR/global/CLAUDE.md" ]; then
            print_info "Creating GEMINI.md from CLAUDE.md template..."
            cat > "$GEMINI_DIR/GEMINI.md" << 'GEMINIEOF'
# Gemini CLI Configuration

## Role
You are Gemini, a large text analyst in a multi-AI collaboration system.

## Responsibilities
- Multi-document and long document analysis
- Large codebase pattern discovery
- Global view and pattern finding
- Frontend code development (your strength)

## Collaboration Rules
- Work with Claude (coordinator) and Codex (engineer)
- Provide analysis and insights, not final decisions
- Focus on patterns, summaries, and recommendations

## Skills (from superpowers)
- brainstorming: Creative ideation
- systematic-debugging: Methodical problem solving
- writing-plans: Structured planning
- verification-before-completion: Quality checks
GEMINIEOF
            print_success "Created GEMINI.md"
        fi
    fi
else
    print_info "Gemini CLI not installed, skipping config sync"
fi
echo ""

# Sync OpenCode Config
if command -v opencode &> /dev/null; then
    print_step "Syncing config to OpenCode..."
    OPENCODE_DIR="$HOME/.config/opencode"
    mkdir -p "$OPENCODE_DIR"

    # 1. opencode.json（动态替换 $HOME）
    if [ -f "$SCRIPT_DIR/global/opencode/opencode.json.template" ]; then
        if [ -f "$OPENCODE_DIR/opencode.json" ]; then
            print_info "opencode.json already exists. Backing up..."
            cp "$OPENCODE_DIR/opencode.json" "$OPENCODE_DIR/opencode.json.backup.$(date +%Y%m%d%H%M%S)"
        fi
        sed "s|\\\$HOME|$HOME|g" "$SCRIPT_DIR/global/opencode/opencode.json.template" > "$OPENCODE_DIR/opencode.json"
        print_success "Synced opencode.json"
    else
        print_info "No opencode.json template found"
    fi

    # 2. oh-my-opencode.json
    if [ -f "$SCRIPT_DIR/global/opencode/oh-my-opencode.json" ]; then
        if [ ! -f "$OPENCODE_DIR/oh-my-opencode.json" ]; then
            cp "$SCRIPT_DIR/global/opencode/oh-my-opencode.json" "$OPENCODE_DIR/oh-my-opencode.json"
            print_success "Synced oh-my-opencode.json"
        else
            print_info "oh-my-opencode.json already exists, skipping"
        fi
    fi

    # 3. tui.json
    if [ -f "$SCRIPT_DIR/global/opencode/tui.json" ]; then
        if [ ! -f "$OPENCODE_DIR/tui.json" ]; then
            cp "$SCRIPT_DIR/global/opencode/tui.json" "$OPENCODE_DIR/tui.json"
            print_success "Synced tui.json"
        else
            print_info "tui.json already exists, skipping"
        fi
    fi

    # 4. 安装 @opencode-ai/plugin 依赖
    if [ ! -f "$OPENCODE_DIR/package.json" ]; then
        cat > "$OPENCODE_DIR/package.json" << 'PKGEOF'
{
  "dependencies": {
    "@opencode-ai/plugin": "1.4.6"
  }
}
PKGEOF
    fi
    (cd "$OPENCODE_DIR" && npm install --silent 2>/dev/null) && {
        print_success "OpenCode plugin SDK installed"
    } || {
        print_info "npm install in opencode config dir failed, please run manually"
    }

    # 5. 全局插件安装
    print_info "Installing OpenCode global plugins..."
    OPENCODE_PLUGINS=(
        "opencode-aicodewith-auth"
        "oh-my-openagent@latest"
        "opencode-agent-memory"
        "@tarquinen/opencode-dcp"
        "opencode-vibeguard"
    )
    for plugin in "${OPENCODE_PLUGINS[@]}"; do
        if npm list -g "$plugin" &>/dev/null; then
            print_success "Already installed: $plugin"
        else
            npm install -g "$plugin" 2>/dev/null && {
                print_success "Installed: $plugin"
            } || {
                print_info "Failed: $plugin (install manually: npm install -g $plugin)"
            }
        fi
    done
else
    print_info "OpenCode not installed, skipping config sync"
fi
echo ""

# ═══════════════════════════════════════════════
# Step 5: OpenSpec Installation
# ═══════════════════════════════════════════════
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Step 5: OpenSpec (Spec-Driven Workflow Tool)${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo ""

print_step "OpenSpec provides: Proposal → Review → Implement → Archive workflow"
echo ""
prompt_read "Install OpenSpec? (y/n): " install_openspec

if [ "$install_openspec" = "y" ] || [ "$install_openspec" = "Y" ]; then
    print_info "Installing OpenSpec globally..."
    npm install -g @fission-ai/openspec@latest 2>/dev/null && {
        print_success "OpenSpec installed"
        print_info "Run 'openspec init' in your project to initialize"
    } || {
        print_error "OpenSpec installation failed"
        print_info "Manual install: npm install -g @fission-ai/openspec@latest"
    }
else
    print_info "Skipping OpenSpec installation"
fi
echo ""

# ═══════════════════════════════════════════════
# Step 5.5: Global Claude Skills
# ═══════════════════════════════════════════════
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Step 5.5: Global Claude Skills${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo ""

print_step "Installing global Claude skills to ~/.claude/skills/..."
mkdir -p "$CLAUDE_DIR/skills"

# 安装脚手架项目中的通用 skills 到全局
GLOBAL_SKILLS=("session-recovery" "design-doc-generator" "document-reader" "ppt-generator")
for skill_name in "${GLOBAL_SKILLS[@]}"; do
    if [ -d "$SCRIPT_DIR/skills/$skill_name" ]; then
        cp -r "$SCRIPT_DIR/skills/$skill_name" "$CLAUDE_DIR/skills/"
        print_success "Installed global skill: $skill_name"
    else
        print_info "Skill not found: $skill_name"
    fi
done
echo ""

# ═══════════════════════════════════════════════
# Step 5.6: Statusline
# ═══════════════════════════════════════════════
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Step 5.6: Claude Code Statusline${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo ""

print_step "Statusline shows: Model | Version | Dir | Branch | Context | Cost | Lines"
echo ""
prompt_read "Install statusline? (y/n): " install_statusline

if [ "$install_statusline" = "y" ] || [ "$install_statusline" = "Y" ]; then
    # 安装 statusline 脚本
    if [ -f "$SCRIPT_DIR/global/statusline-command.sh" ]; then
        cp "$SCRIPT_DIR/global/statusline-command.sh" "$CLAUDE_DIR/statusline-command.sh"
        chmod +x "$CLAUDE_DIR/statusline-command.sh"
        print_success "statusline-command.sh installed"
    else
        print_info "No statusline template found, creating default..."
        cat > "$CLAUDE_DIR/statusline-command.sh" << 'STATUSEOF'
#!/bin/bash
input=$(cat)
model_name=$(echo "$input" | jq -r '.model.display_name')
version=$(echo "$input" | jq -r '.version')
current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
context_window=$(echo "$input" | jq '.context_window')
current_usage=$(echo "$context_window" | jq '.current_usage')
window_size=$(echo "$context_window" | jq -r '.context_window_size')

if [ "$current_usage" != "null" ]; then
    input_tokens=$(echo "$current_usage" | jq '.input_tokens // 0')
    cache_creation=$(echo "$current_usage" | jq '.cache_creation_input_tokens // 0')
    cache_read=$(echo "$current_usage" | jq '.cache_read_input_tokens // 0')
    current_total=$((input_tokens + cache_creation + cache_read))
    context_pct=$((current_total * 100 / window_size))
    context_display="${current_total}/${window_size} (${context_pct}%)"
else
    context_display="0/${window_size} (0%)"
fi

cost_total=$(echo "$input" | jq -r '.cost.total_cost_usd // "0.00"')
lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // "0"')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // "0"')

if [[ "$current_dir" == "$HOME"* ]]; then
    display_dir="~${current_dir#$HOME}"
else
    display_dir="$current_dir"
fi

cd "$current_dir" 2>/dev/null
git_branch=$(git branch --show-current 2>/dev/null || echo "no-git")

printf "\033[36m%s\033[0m | " "$model_name"
printf "\033[90m%s\033[0m | " "v$version"
printf "\033[33m%s\033[0m | " "$display_dir"
printf "\033[35m%s\033[0m | " "$git_branch"
printf "\033[32mContext: %s\033[0m | " "$context_display"
printf "\033[35mCost: \$%s\033[0m | " "$cost_total"
printf "\033[34m+%s/-%s lines\033[0m" "$lines_added" "$lines_removed"
STATUSEOF
        chmod +x "$CLAUDE_DIR/statusline-command.sh"
        print_success "statusline-command.sh created"
    fi

    # 配置 settings.json 中的 statusLine
    if [ -f "$CLAUDE_DIR/settings.json" ]; then
        # 检查是否已有 statusLine 配置
        if python3 -c "import json; d=json.load(open('$CLAUDE_DIR/settings.json')); exit(0 if 'statusLine' in d else 1)" 2>/dev/null; then
            print_info "statusLine already configured in settings.json"
        else
            # 追加 statusLine 配置
            python3 -c "
import json
with open('$CLAUDE_DIR/settings.json', 'r') as f:
    d = json.load(f)
d['statusLine'] = {'type': 'command', 'command': 'bash ~/.claude/statusline-command.sh'}
with open('$CLAUDE_DIR/settings.json', 'w') as f:
    json.dump(d, f, indent=2)
" 2>/dev/null && {
                print_success "statusLine configured in settings.json"
            } || print_info "Could not auto-configure statusLine, add manually"
        fi
    else
        print_info "settings.json not found, statusLine needs manual configuration"
        print_info "Add to ~/.claude/settings.json:"
        print_info '  "statusLine": {"type": "command", "command": "bash ~/.claude/statusline-command.sh"}'
    fi
    print_success "Statusline installation complete"
else
    print_info "Skipping statusline installation"
fi
echo ""

# ═══════════════════════════════════════════════
# Step 6: Global Hooks
# ═══════════════════════════════════════════════
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Step 6: Global Hooks${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo ""

print_step "Installing global hooks..."
mkdir -p "$CLAUDE_DIR/hooks"

if [ -d "$SCRIPT_DIR/hooks" ]; then
    cp "$SCRIPT_DIR/hooks"/*.sh "$CLAUDE_DIR/hooks/" 2>/dev/null || true
    cp "$SCRIPT_DIR/hooks"/*.ts "$CLAUDE_DIR/hooks/" 2>/dev/null || true
    cp "$SCRIPT_DIR/hooks/package.json" "$CLAUDE_DIR/hooks/" 2>/dev/null || true
    chmod +x "$CLAUDE_DIR/hooks"/*.sh 2>/dev/null || true

    # Install hook dependencies
    if [ -f "$CLAUDE_DIR/hooks/package.json" ]; then
        (cd "$CLAUDE_DIR/hooks" && npm install --silent 2>/dev/null) || print_info "npm install skipped"
    fi
    print_success "Global hooks installed"
else
    print_info "No hooks template found, skipping"
fi
echo ""

# ═══════════════════════════════════════════════
# Step 7: Verification
# ═══════════════════════════════════════════════
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Step 7: Verification${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo ""

print_step "Verifying installation..."
echo ""

# Check CLAUDE.md
if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    line_count=$(wc -l < "$CLAUDE_DIR/CLAUDE.md" | tr -d ' ')
    print_success "Global CLAUDE.md exists ($line_count lines)"
else
    print_info "Global CLAUDE.md not found"
fi

# Check plugins
print_step "Installed plugins:"
claude plugin list 2>/dev/null || print_info "Could not list plugins"
echo ""

# Check MCP
print_step "MCP Status:"
claude mcp list 2>/dev/null || print_info "Could not list MCP tools"
echo ""

# Check OpenSpec
if command -v openspec &> /dev/null; then
    print_success "OpenSpec installed: $(openspec --version 2>/dev/null || echo 'version unknown')"
else
    print_info "OpenSpec not installed"
fi

# Check Codex skills
if [ -d "$CODEX_DIR/skills" ]; then
    codex_skill_count=$(ls -d "$CODEX_DIR/skills"/*/ 2>/dev/null | wc -l | tr -d ' ')
    print_success "Codex skills: $codex_skill_count installed"
else
    print_info "Codex skills directory not found"
fi

# Check Claude global skills
if [ -d "$CLAUDE_DIR/skills" ]; then
    claude_skill_count=$(ls -d "$CLAUDE_DIR/skills"/*/ 2>/dev/null | wc -l | tr -d ' ')
    print_success "Claude global skills: $claude_skill_count installed"
else
    print_info "Claude global skills directory not found"
fi

# Check statusline
if [ -f "$CLAUDE_DIR/statusline-command.sh" ]; then
    print_success "Statusline script installed"
else
    print_info "Statusline script not found"
fi

# Check Gemini config
if [ -f "$GEMINI_DIR/GEMINI.md" ]; then
    print_success "Gemini GEMINI.md exists"
else
    print_info "Gemini GEMINI.md not found"
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Global Setup Complete!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""

# Next steps
print_step "Next Steps:"
echo ""
echo "1. Configure API keys (if needed):"
echo "   - ANTHROPIC_API_KEY for Claude"
echo "   - OPENAI_API_KEY for Codex"
echo "   - GOOGLE_API_KEY for Gemini"
echo ""
echo "2. Deploy to a project:"
echo "   $SCRIPT_DIR/setup-claude-config.sh /path/to/your/project"
echo ""
echo "3. Verify MCP tools work:"
echo "   claude mcp list"
echo ""
echo "4. Test plugins:"
echo "   claude plugin list"
echo ""
echo -e "${GREEN}Happy coding with Multi-AI Collaboration!${NC}"
