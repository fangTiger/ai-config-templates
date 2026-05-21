# Design: codex-dev Plugin Profile

## Architecture Decision

### Thin Overlay (not Full Fork)

codex-dev is implemented as a thin overlay on superpowers, not a complete independent profile:
- Shares superpowers plugin (enabledPlugins)
- Shares OpenSpec commands, hooks from shared/
- Only overrides: CLAUDE.md (role definitions), settings.json (security), codex-handoff skill

### Role Inversion in Implementation Stage

| Role | superpowers | codex-dev |
|------|-----------|-----------|
| Claude | Implementer + Reviewer | Architect + Orchestrator + Final Reviewer |
| Codex | Backend Consultant (review only) | **Primary Implementer** (workspace-write) |
| Gemini | Frontend Developer + Reviewer | Frontend Developer + Reviewer (unchanged) |

### 6-Stage Pipeline

```
Stage 1: ANALYZE → Stage 2: DESIGN → Stage 3: HANDOFF → Stage 4: IMPLEMENT → Stage 5: REVIEW → Stage 6: VERIFY
(Claude)          (Claude+3-party)   (Claude→Codex/Gemini) (Codex+Gemini)    (Self-review→3-party) (Claude)
```

Key difference from superpowers: Stage 3 (HANDOFF) is new, Stage 4 uses Codex instead of Claude.

### Context Handoff Protocol

Structured context package passed to Codex via MCP:
- `developer-instructions`: TDD rules, coding standards, file scope constraints, negative constraints
- `prompt`: proposal summary, design summary, full tasks.md, spec deltas, source file paths
- `sandbox`: "workspace-write"
- Session continuity via `codex-reply` + `threadId`

### Mixed Frontend/Backend Flow (Contract-First)

```
Phase A: Backend (Codex) → Phase B: Sync Gate (Claude) → Phase C: Frontend (Gemini) → Phase D: Integration
```

API contract defined in Stage 2 serves as the boundary between Codex and Gemini work.

### Programmatic Guardrails

- Run Codex in worktree or temporary branch
- Pre-call: `git status --porcelain` baseline
- Post-call: `git diff --name-only` vs file allowlist
- Out-of-scope changes: auto-halt + manual confirmation

### Evidence-Driven Self-Review

Each slice completion requires Codex to output:
- RED command + failure evidence
- GREEN command + pass evidence
- Changed files list
- Requirement coverage matrix
- Out-of-scope flag

### Degradation Rules

- Single task fix > 3 attempts → degrade to superpowers
- Codex self-review fails 2 consecutive times → degrade
- File scope exceeded + cannot auto-fix → degrade

## Trade-offs

| Decision | Pro | Con |
|----------|-----|-----|
| workspace-write | Efficient, direct file writes | Less control, needs guardrails |
| Single session per proposal | Context continuity | Risk of context overflow on large tasks |
| Contract-First for mixed tasks | Clean boundary | Sequential, not parallel |
| Thin overlay | Low maintenance, DRY | Less customization flexibility |
