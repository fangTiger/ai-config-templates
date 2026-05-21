---
name: dev-workflow
description: Development workflow management for AI coding scaffold projects. Use when creating requirements, writing design documents, conducting code reviews, running tests, or tracking development progress. Enforces strict phase ordering (requirement -> design -> implementation -> review -> testing) and directory conventions.
---

# Development Workflow Skill

## Purpose

Manage the complete development workflow with strict phase ordering and directory conventions. This skill ensures:
1. Proper phase transitions (requirement -> design -> implementation -> review -> testing)
2. Documents saved to correct locations
3. Prerequisites validated before advancing phases
4. Progress tracking and status reporting

## When to Use This Skill

- Starting a new development task
- Writing requirement documents
- Creating design documents
- Conducting code reviews
- Running tests and generating reports
- Checking development progress
- Validating phase transitions

---

## Development Phases

### Phase Order (Strict)

```
REQUIREMENT -> DESIGN -> IMPLEMENTATION -> REVIEW -> TESTING -> DONE
```

**Rules:**
- Cannot skip phases
- Each phase requires prerequisite documents
- Phase transitions are validated

### Phase Prerequisites

| Phase | Required Documents | Output |
|-------|-------------------|--------|
| REQUIREMENT | - | requirement.md |
| DESIGN | requirement.md | design.md |
| IMPLEMENTATION | requirement.md, design.md | source code |
| REVIEW | requirement.md, design.md, code | review.md |
| TESTING | all above | test-report.md |

---

## Directory Structure

### Task Documents

All task documents are stored in `.devos/tasks/{task-id}/`:

```
.devos/
└── tasks/
    └── {task-id}/
        ├── requirement.md    # Requirement document
        ├── design.md         # Design document
        ├── review.md         # Code review report
        ├── test-report.md    # Test results
        └── progress.md       # Progress tracking
```

### Source Code

```
devos/                        # Main source code
├── agents/                   # Agent implementations
├── core/                     # Core modules
├── orchestration/            # Orchestration layer
├── skills/                   # Skill implementations
├── tools/                    # Tool integrations
└── workflow/                 # Workflow management
```

### Tests

```
tests/                        # All test files
├── agents/                   # Agent tests
├── core/                     # Core module tests
├── integration/              # Integration tests
├── orchestration/            # Orchestration tests
└── tools/                    # Tool tests
```

---

## Writing Requirements

### Template

```markdown
# Requirement Document

## 1. Overview
- Task ID: {task_id}
- Title: {title}
- Priority: P0/P1/P2/P3
- Created: {timestamp}

## 2. Description
{detailed description}

## 3. Features
- [ ] Feature 1
- [ ] Feature 2
- [ ] Feature 3

## 4. Acceptance Criteria
- [ ] AC1: {criterion}
- [ ] AC2: {criterion}

## 5. Technical Constraints
- {constraint 1}
- {constraint 2}

## 6. Related Context
{context from codebase analysis}
```

### Command

```bash
# Save to: .devos/tasks/{task-id}/requirement.md
```

---

## Writing Design Documents

### Prerequisites

- `requirement.md` must exist in task directory

### Template

```markdown
# Design Document

## 1. Overview
- Task ID: {task_id}
- Created: {timestamp}
- Version: v1.0

## 2. Architecture
{architecture description}

## 3. Modules
### {Module Name}
- Responsibility: {what it does}
- Interface: {public API}
- Dependencies: {what it depends on}

## 4. Tech Stack
| Domain | Technology | Reason |
|--------|------------|--------|
| {domain} | {tech} | {reason} |

## 5. Interfaces
### {Interface Name}
- Input: {input format}
- Output: {output format}
- Example: {usage example}

## 6. Key Decisions
### Decision 1: {title}
- Background: {context}
- Options: {alternatives}
- Choice: {selected option}
- Reason: {why}

## 7. Implementation Plan
- [ ] Step 1
- [ ] Step 2
- [ ] Step 3

## 8. Risks & Constraints
{identified risks}
```

### Command

```bash
# Save to: .devos/tasks/{task-id}/design.md
```

---

## Code Review

### Prerequisites

- `requirement.md` must exist
- `design.md` must exist
- Implementation code must exist

### Review Checklist

- [ ] Code matches design document
- [ ] All features from requirement implemented
- [ ] No security vulnerabilities
- [ ] Error handling is comprehensive
- [ ] Tests are adequate
- [ ] Documentation is complete

### Report Template

```markdown
# Code Review Report

## Overview
- Task ID: {task_id}
- Review Time: {timestamp}
- Developer: {dev_executor}
- Reviewer: {check_executor}
- Consistency: PASS/FAIL

## Issues Found
| Severity | Category | Description | Suggestion |
|----------|----------|-------------|------------|
| HIGH | {category} | {issue} | {fix} |

## Missing Features
- {feature not implemented}

## Suggestions
- {improvement suggestion}
```

### Command

```bash
# Save to: .devos/tasks/{task-id}/review.md
```

---

## Test Reports

### Template

```markdown
# Test Report

## Latest Result
- Time: {timestamp}
- Attempt: {attempt_number}
- Status: PASS/FAIL

## Statistics
- Total: {total}
- Passed: {passed}
- Failed: {failed}
- Skipped: {skipped}
- Pass Rate: {rate}%

## Failed Tests
### {test_name}
- File: {test_file}
- Error: {error_message}
- Fix Attempts: {count}
```

### Command

```bash
# Run tests
pytest tests/ -v

# Save report to: .devos/tasks/{task-id}/test-report.md
```

---

## Progress Tracking

### Update Progress

```markdown
## [{timestamp}] {phase} - {status}

{message}

### Completed
- [x] {completed item}

### Pending
- [ ] {pending item}
```

### Command

```bash
# Append to: .devos/tasks/{task-id}/progress.md
```

---

## Phase Validation

### Check Current Phase

Before advancing to next phase, validate:

1. **Requirement -> Design**
   - requirement.md exists and is complete

2. **Design -> Implementation**
   - design.md exists and is complete
   - Architecture is clear

3. **Implementation -> Review**
   - Code is implemented
   - Basic tests pass

4. **Review -> Testing**
   - Review issues are addressed
   - Code is approved

5. **Testing -> Done**
   - All tests pass
   - Test coverage is adequate

---

## Best Practices

### DO

- Always start with requirement document
- Validate prerequisites before advancing
- Keep documents in designated directories
- Update progress regularly
- Run tests before marking complete

### DON'T

- Skip phases
- Put documents in wrong directories
- Advance without prerequisites
- Ignore review feedback
- Mark done without passing tests

---

## API Reference

### Python API (for external agents)

```python
from devos.skills.dev_workflow import get_dev_workflow_skill

skill = get_dev_workflow_skill()

# Write requirement
result = skill.write_requirement(
    task_id="TASK-001",
    title="Feature Title",
    description="Description",
    features=["Feature 1", "Feature 2"],
    acceptance_criteria=["AC1", "AC2"]
)

# Read design
result = skill.read_design(task_id="TASK-001")

# Get task status
result = skill.get_task_status(task_id="TASK-001")

# Validate phase transition
result = skill.validate_phase_transition(
    task_id="TASK-001",
    from_phase="requirement",
    to_phase="design"
)
```

---

## Related Files

- `.devos/tasks/` - Task documents directory
- `devos/workflow/dev_rules.py` - Phase rules and validation
- `devos/skills/dev_workflow.py` - Python API implementation

---

**Skill Status**: COMPLETE
**Line Count**: < 500 (following 500-line rule)
