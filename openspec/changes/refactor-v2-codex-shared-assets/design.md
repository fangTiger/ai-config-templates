## Context
V2 separates global invariants from profile-specific project assets. Codex-native profiles need `.codex/` runtime assets, but common hooks, tools, and workflow skills are currently copied into each profile directory.

## Goals / Non-Goals
- Goals:
  - Centralize Codex-native shared hooks, tools, and workflow skills.
  - Preserve existing installed file paths in target projects.
  - Keep profile-specific `.codex/` assets able to override shared defaults.
  - Fix the duplicated Java graphify tool syntax issue at the shared source.
- Non-Goals:
  - Redesign the six-stage workflow semantics.
  - Change model routing for GPT-5.5 profiles.
  - Add `UserPromptSubmit` skill activation behavior in this change.

## Decisions
- Decision: add `v2/scripts/plugin-profiles/shared/codex/` instead of reusing existing `shared/hooks` or `shared/skills`.
  - Rationale: existing shared assets are also copied into `.claude/`, while these assets are Codex-native and use `.codex/` runtime paths.
- Decision: keep language-specific Codex tools under a sublayer such as `shared/codex/java/tools`.
  - Rationale: `runtime-verification-summary.sh` is common to all Codex-native profiles, while `graphify-java-project.sh` applies only to Java-oriented Codex profiles and must not be installed into `codex-codex-python-dev`.
- Decision: copy `shared/codex` before profile `.codex` assets.
  - Rationale: profile-specific files can still override shared defaults.
- Decision: remove duplicate profile copies for files now owned by `shared/codex`.
  - Rationale: otherwise profile `.codex` copy order would silently shadow future shared fixes.

## Risks / Trade-offs
- Risk: a profile may rely on a profile-specific variant that looks duplicated.
  - Mitigation: only extract files that are byte-identical or differ only by profile naming where the generic name remains valid.
- Risk: existing tests only check presence, not script internals.
  - Mitigation: add syntax validation for embedded Python heredocs in installed Codex tools.

## Migration Plan
1. Add failing tests for shared Codex asset installation and embedded Python syntax.
2. Create `shared/codex/{hooks,tools,skills}` and move common assets there.
3. Update setup and switch scripts to copy `shared/codex` before profile `.codex`.
4. Remove duplicate profile copies that would shadow shared assets.
5. Run OpenSpec validation and targeted tests.
