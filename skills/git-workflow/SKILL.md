---
name: git-workflow
description: Git workflow management for team collaboration. Use when creating branches, making commits, conducting code reviews, merging branches, or managing Git operations. Enforces branch naming conventions, commit message standards, and pre-commit checks.
---

# Git Workflow Skill

## Purpose

Manage Git operations for team collaboration with standardized conventions:
1. Branch naming conventions (feature/, bugfix/, hotfix/)
2. Commit message standards (conventional commits)
3. Pre-commit validation checks
4. Merge and PR workflows

## When to Use This Skill

- Creating new feature/bugfix/hotfix branches
- Making commits with proper messages
- Running pre-commit checks
- Merging branches
- Managing pull requests
- Resolving conflicts

---

## Branch Naming Conventions

### Branch Types

| Type | Pattern | Use Case |
|------|---------|----------|
| feature | `feature/{task-id}-{description}` | New features |
| bugfix | `bugfix/{task-id}-{description}` | Bug fixes |
| hotfix | `hotfix/{task-id}-{description}` | Urgent production fixes |
| release | `release/{version}` | Release preparation |

### Examples

```bash
# Feature branch
feature/TASK-001-add-user-auth

# Bugfix branch
bugfix/TASK-002-fix-login-error

# Hotfix branch
hotfix/TASK-003-security-patch

# Release branch
release/v1.2.0
```

### Creating Branches

```bash
# Create feature branch
git checkout main
git pull origin main
git checkout -b feature/TASK-001-add-user-auth

# Create bugfix branch
git checkout develop
git pull origin develop
git checkout -b bugfix/TASK-002-fix-login-error

# Create hotfix branch (from main)
git checkout main
git pull origin main
git checkout -b hotfix/TASK-003-security-patch
```

---

## Commit Message Standards

### Format (Conventional Commits)

```
{type}({scope}): {subject}

{body}

{footer}
```

### Commit Types

| Type | Description | Example |
|------|-------------|---------|
| feat | New feature | `feat(auth): add JWT authentication` |
| fix | Bug fix | `fix(login): resolve session timeout` |
| docs | Documentation | `docs(readme): update installation guide` |
| style | Code formatting | `style(api): fix indentation` |
| refactor | Code refactoring | `refactor(user): simplify validation` |
| test | Tests | `test(auth): add login unit tests` |
| chore | Build/tools | `chore(deps): update dependencies` |
| perf | Performance | `perf(query): optimize user lookup` |

### Examples

```bash
# Simple commit
git commit -m "feat(auth): add password reset functionality"

# Commit with body
git commit -m "fix(api): resolve rate limiting issue

The rate limiter was not properly resetting after the window expired.
This caused legitimate requests to be blocked.

Task: TASK-123"

# Breaking change
git commit -m "feat(api): change response format

BREAKING CHANGE: API responses now use camelCase instead of snake_case.
All clients need to update their parsers.

Task: TASK-456"
```

---

## Pre-Commit Checks

### Checklist

Before committing, verify:

- [ ] All changes are staged
- [ ] Branch name follows convention
- [ ] No conflict markers in code
- [ ] Tests pass locally
- [ ] Linting passes

### Commands

```bash
# Check status
git status

# Check for conflict markers
git diff --check

# Run linting
ruff check .

# Run tests
pytest tests/ -v

# Stage all changes
git add -A

# Or stage specific files
git add path/to/file.py
```

### Automated Check Script

```bash
#!/bin/bash
# pre-commit-check.sh

echo "Running pre-commit checks..."

# Check branch naming
BRANCH=$(git branch --show-current)
if [[ ! $BRANCH =~ ^(feature|bugfix|hotfix|release)/ ]] && \
   [[ ! $BRANCH =~ ^(main|master|develop)$ ]]; then
    echo "ERROR: Branch name '$BRANCH' does not follow convention"
    exit 1
fi

# Check for conflict markers
if git diff --check; then
    echo "OK: No conflict markers"
else
    echo "ERROR: Conflict markers found"
    exit 1
fi

# Run linting
if ruff check .; then
    echo "OK: Linting passed"
else
    echo "ERROR: Linting failed"
    exit 1
fi

echo "All pre-commit checks passed!"
```

---

## Merge Workflow

### Feature Branch Merge

```bash
# Update feature branch with latest main
git checkout feature/TASK-001-add-user-auth
git fetch origin
git rebase origin/main

# Or merge (creates merge commit)
git merge origin/main

# Push updated branch
git push origin feature/TASK-001-add-user-auth

# Create PR (using GitHub CLI)
gh pr create --title "feat(auth): add user authentication" \
             --body "## Summary
- Add JWT authentication
- Add login/logout endpoints
- Add password reset

## Test Plan
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing complete"
```

### Merge to Main

```bash
# After PR approval
git checkout main
git pull origin main
git merge --no-ff feature/TASK-001-add-user-auth
git push origin main

# Delete feature branch
git branch -d feature/TASK-001-add-user-auth
git push origin --delete feature/TASK-001-add-user-auth
```

### Hotfix Merge

```bash
# Merge hotfix to main
git checkout main
git merge --no-ff hotfix/TASK-003-security-patch
git push origin main

# Also merge to develop
git checkout develop
git merge --no-ff hotfix/TASK-003-security-patch
git push origin develop

# Delete hotfix branch
git branch -d hotfix/TASK-003-security-patch
```

---

## Conflict Resolution

### Steps

1. **Identify conflicts**
   ```bash
   git status
   # Shows files with conflicts
   ```

2. **Open conflicting files**
   ```
   <<<<<<< HEAD
   Your changes
   =======
   Their changes
   >>>>>>> branch-name
   ```

3. **Resolve conflicts**
   - Keep your changes, their changes, or combine
   - Remove conflict markers

4. **Mark as resolved**
   ```bash
   git add path/to/resolved/file.py
   ```

5. **Continue merge/rebase**
   ```bash
   # If merging
   git commit -m "Merge branch 'feature/xxx' into main"

   # If rebasing
   git rebase --continue
   ```

### Abort if needed

```bash
# Abort merge
git merge --abort

# Abort rebase
git rebase --abort
```

---

## Common Operations

### View Status

```bash
# Working directory status
git status

# Short status
git status -s

# Branch info
git branch -vv
```

### View History

```bash
# Recent commits
git log --oneline -10

# With graph
git log --oneline --graph --all

# Specific file history
git log --oneline path/to/file.py
```

### View Changes

```bash
# Unstaged changes
git diff

# Staged changes
git diff --staged

# Changes in specific file
git diff path/to/file.py
```

### Undo Changes

```bash
# Unstage file
git reset HEAD path/to/file.py

# Discard changes in file
git checkout -- path/to/file.py

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1
```

---

## Best Practices

### DO

- Use descriptive branch names with task IDs
- Write clear commit messages
- Run pre-commit checks before committing
- Keep commits atomic (one logical change)
- Pull/rebase before pushing
- Delete merged branches

### DON'T

- Commit directly to main/master
- Use vague commit messages ("fix bug", "update")
- Force push to shared branches
- Leave conflict markers in code
- Commit sensitive data (secrets, credentials)
- Create huge commits with unrelated changes

---

## API Reference

### Python API (for external agents)

```python
from devos.skills.git_workflow import get_git_workflow_skill

skill = get_git_workflow_skill()

# Create feature branch
result = skill.create_branch(
    branch_type="feature",
    task_id="TASK-001",
    description="add user auth"
)

# Get status
result = skill.get_status()

# Stage files
result = skill.stage_files(["path/to/file.py"])

# Commit
result = skill.commit(
    commit_type="feat",
    scope="auth",
    subject="add JWT authentication",
    task_id="TASK-001"
)

# Pre-commit check
result = skill.pre_commit_check()

# Merge branch
result = skill.merge_branch(
    source_branch="feature/TASK-001-add-user-auth",
    target_branch="main"
)
```

---

## Related Files

- `devos/skills/git_workflow.py` - Python API implementation
- `.gitignore` - Git ignore patterns
- `.pre-commit-config.yaml` - Pre-commit hooks (if configured)

---

**Skill Status**: COMPLETE
**Line Count**: < 500 (following 500-line rule)
