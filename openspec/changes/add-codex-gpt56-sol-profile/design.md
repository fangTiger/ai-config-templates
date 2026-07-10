## Context

The repository has two Codex profile delivery paths:

- V1 stores a complete profile tree under `scripts/plugin-profiles/` and uses an explicit allowlist plus layout validation in `scripts/switch-plugin_codex.sh`.
- V2 stores only profile-specific assets under `v2/scripts/plugin-profiles/` and installs common Codex hooks, tools, and workflow skills from `shared/codex` before applying profile overrides.

The existing GPT-5.5 profile routes Architecture Codex to `gpt-5.5` with `xhigh` reasoning and routes worker/review agents to `gpt-5.4` with `xhigh` reasoning. OpenAI's current Codex model documentation identifies Sol as `gpt-5.6-sol`. The configuration reference documents `xhigh` as a valid `model_reasoning_effort` value; `max` is exposed in model selection UX but is not yet listed in the strict configuration enum, so this profile remains on `xhigh`.

The project has no `graphify-out/` directory and no Graphify MCP tools in this session. Impact analysis therefore used the documented fallback: current specs, active changes, tests, profile templates, switch scripts, and Git history.

## Goals / Non-Goals

### Goals

- Provide an independent GPT-5.6 Sol profile without mutating the GPT-5.5 profile.
- Keep V1 and V2 switching behavior aligned.
- Reuse V2 shared Codex assets instead of restoring profile-local duplication.
- Verify installed TOML routing, not only explanatory text in `AGENTS.md`.
- Keep session-state identity and profile descriptions consistent with the new profile ID.

### Non-Goals

- Change the default/recommended profile away from GPT-5.5.
- Introduce GPT-5.6 Terra, Luna, Pro, Max, or Ultra profiles.
- Refactor the V1 profile asset layout.
- Archive the pre-existing `refactor-v2-codex-shared-assets` change.
- Update the local Codex CLI installation.

## Decisions

### Independent profile ID

Use `codex-codex-claude-flow-gpt56-sol-dev`. Including `sol` prevents ambiguity if Terra or Luna profiles are added later and makes the profile-to-model relationship explicit.

### Model routing

Use this fixed routing matrix:

| Role | Model | Reasoning |
| --- | --- | --- |
| Architecture Codex | `gpt-5.6-sol` | `xhigh` |
| Worker Codex | `gpt-5.5` | `xhigh` |
| Review Codex | `gpt-5.5` | `xhigh` |

The existing GPT-5.5 profile remains unchanged.

### V1 and V2 parity

V1 receives a full profile copy because its compatibility switcher owns complete profile assets. V2 receives the current eight profile-specific files and continues to inherit common hooks, tools, and workflow skills from `shared/codex`.

### Git tracking

Add generic V2 profile exceptions for `v2/scripts/plugin-profiles/*/.codex/**` to the root `.gitignore`. This avoids force-adding hidden profile assets and makes future V2 profile additions visible in normal status and diff output.

### Verification strategy

Tests will parse source and installed TOML files with `tomllib` and assert the exact model/provider/reasoning fields. V1 tests will execute the compatibility switcher in a temporary project. V2 tests will cover discovery, setup, switching, manifest mode, session-state identity, shared assets, and preservation of GPT-5.5 routing.

## Alternatives Considered

- Upgrade the GPT-5.5 profile in place: rejected because the profile name would become misleading and existing users would lose a reproducible routing option.
- Add only a V2 profile: rejected because the request is for a peer of the existing profile and the repository still documents a supported V1 compatibility path.
- Configure Architecture Codex with `max`: deferred because the strict configuration reference currently documents reasoning values only through `xhigh`.

## Risks / Trade-offs

- The current PATH resolves Codex CLI 0.142.3, while GPT-5.6 requires a newer runtime. Static config, setup, and switching tests remain valid; a live GPT-5.6 smoke run must be performed with an eligible, updated Codex runtime.
- V1 duplicates the full profile tree. Tests and profile-slug searches reduce drift risk, while V2 remains shared-first.
- The completed but unarchived shared-assets change touches the existing V2 support requirement. This proposal avoids modifying that requirement by adding a dedicated GPT-5.6 requirement; only the separate V1 entry requirement is modified.

## Migration Plan

1. Add failing V2 and V1 tests.
2. Add the V2 profile and generic hidden-file tracking exceptions.
3. Add the V1 profile and register it in the compatibility switcher.
4. Update documentation.
5. Run targeted and full regression verification.

Rollback removes only the new profile directories, V1 allowlist/layout branch, V2 ignore exceptions if no longer needed, tests, and documentation entries. Existing profiles remain intact throughout.

## Open Questions

None. The profile name, model routing, reasoning effort, and V1/V2 scope were approved before proposal creation.
