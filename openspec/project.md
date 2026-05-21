# Project Context

## Purpose
ai-config-templates is a reusable AI coding configuration scaffold that provides multi-AI collaborative development infrastructure. It enables:
- Multi-AI coordination (Claude + Codex + Gemini)
- SDD (Specification-Driven Development) workflow
- Reusable Skills and Agents systems
- One-click deployment to any project

## Tech Stack
- Shell Script (Bash) - Deployment automation
- TypeScript/Node.js - Hooks system
- Markdown - Configuration, Skills, Agents definitions
- JSON - Settings and rules configuration
- Python - CLI executors for multi-model integration

### External Tools
- Claude Code CLI - Primary coordinator
- MCP Protocol - Model Context Protocol for tool integration
- Codex MCP - Code generation and cross-checking
- Gemini MCP - Large text analysis and frontend development
- OpenSpec - SDD workflow management

## Project Conventions

### Code Style
- Use English for all code, configs, logs, and formal documentation
- Use Chinese for daily communication and progress reports
- Follow existing patterns in the codebase
- Keep implementations minimal and focused

### Architecture Patterns
- Multi-layer configuration: Global (~/.claude/) → Project (.claude/)
- Multi-AI coordination: Claude (coordinator) → Codex (engineer) → Gemini (analyst)
- SDD workflow: REQUIREMENT → DESIGN → IMPLEMENTATION → REVIEW → TESTING → DONE

### Testing Strategy
- All tests in `tests/` directory
- Test file naming: `test_{module}.py`
- Run tests before committing changes

### Git Workflow
- Main branch: `develop`
- Feature branches: `feature/{name}`
- Commit messages in English, concise and descriptive

## Domain Context
This is a meta-project (configuration framework), not an application. Key concepts:
- **Skills**: Auto-activated domain knowledge templates
- **Agents**: Specialized autonomous task executors
- **Hooks**: Event-driven automation scripts
- **SDD**: Specification-Driven Development methodology

## Important Constraints
- Claude Code must consider Codex/Gemini for non-trivial tasks (Global Tool Rule)
- Each SDD phase requires prerequisite documents
- Cross-checking between AI models is mandatory for significant changes
- Skills auto-activate based on context patterns

## External Dependencies
- claude-mem (memory plugin)
- superpowers (built-in skills)
- pyright-lsp (Python LSP)
- openspec CLI tool
