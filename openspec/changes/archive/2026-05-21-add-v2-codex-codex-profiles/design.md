## Context
The repository has two profile systems. V1 includes Codex-native profiles under `scripts/plugin-profiles/codex-codex-*` and a dedicated `scripts/switch-plugin_codex.sh`. V2 introduces cleaner global/project layering and manifest tracking, but its Codex story is currently limited to the lighter `codex-dev` profile.

Graphify context: unavailable. The project has no `graphify-out/` directory in this workspace, so analysis used the current OpenSpec files and source tree.

## Goals / Non-Goals
- Goals:
  - Promote the V1 `codex-codex-*` profiles into V2 as first-class profiles.
  - Preserve the Codex-first runtime surface: root `AGENTS.md`, `.codex/config.toml`, `.codex/agents`, `.codex/hooks`, `.codex/tools`, `.codex/skills`, `.codex/session-state.md`, and OpenSpec commands.
  - Reuse V2 manifest, drift detection, backup, and shared resource behavior.
  - Keep V1 Codex switching usable for compatibility while steering new installs to V2.
- Non-Goals:
  - Remove V1 scripts.
  - Change Codex model routing semantics beyond copying the existing profile templates.
  - Redesign the six-stage workflow content.

## Decisions
- Decision: add V2 profile directories for each `codex-codex-*` profile rather than expanding `codex-dev` into a single mega-profile.
  - Alternatives considered: folding everything into `codex-dev`, or keeping V1 as the only Codex path.
  - Rationale: separate profile names preserve current user intent and allow Java, GPT-5.5, claude-flow, and Python variants to evolve independently.
- Decision: V2 `setup-project.sh --mode=<profile>` and `v2/scripts/switch-plugin.sh <profile>` SHALL support both Claude-oriented and Codex-native profiles.
  - Rationale: users should not need a separate V1 switcher to get a V2 install.
- Decision: Codex-native V2 profiles SHALL install root `AGENTS.md` and replace managed `.codex/` assets as an atomic profile surface.
  - Rationale: Codex reads `AGENTS.md` as the project instruction entry point, so this is not optional metadata.
- Decision: session state is preserved by default and reset only with an explicit reset option.
  - Rationale: switching profiles should not silently delete active task context.

## Risks / Trade-offs
- Risk: copying V1 profile trees into V2 could duplicate content.
  - Mitigation: keep shared hooks/commands in V2 shared resources where practical, but prioritize behavior preservation for the first migration.
- Risk: V2 switcher currently assumes `.claude/CLAUDE.md`-centric profiles.
  - Mitigation: add profile capability detection so Codex-native profiles can use `AGENTS.md` and full `.codex/` assets without weakening existing Claude profiles.
- Risk: session-state preservation can carry incompatible fields between profile variants.
  - Mitigation: validate required session-state fields against the target template and fall back to template initialization when incompatible.

## Migration Plan
1. Copy or port V1 `scripts/plugin-profiles/codex-codex-*` templates into `v2/scripts/plugin-profiles/`.
2. Extend V2 setup and switch scripts to recognize Codex-native profiles and install their `AGENTS.md`, settings, `.codex/` assets, shared commands, hooks, and skills.
3. Add tests or scripted fixtures that run the V2 switcher against temporary project directories.
4. Update README so Codex-first users use V2 commands by default.
5. Keep V1 switcher documented as compatibility-only.

## Open Questions
- Should `codex-codex-claude-flow-gpt55-dev` become the default V2 Codex recommendation, or should the lighter `codex-codex-dev` stay the default?
