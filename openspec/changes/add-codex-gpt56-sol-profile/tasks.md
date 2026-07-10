## 1. TDD Coverage

- [ ] 1.1 Add failing V2 tests for GPT-5.6 Sol profile discovery, setup, switching, session-state identity, hidden-file tracking, and exact TOML routing.
- [ ] 1.2 Add failing V1 tests for allowlist registration, layout installation, session-state identity, and exact TOML routing.
- [ ] 1.3 Add a regression assertion that the GPT-5.5 profile keeps its existing 5.5/5.4 routing.

## 2. Profile Templates

- [ ] 2.1 Add generic `.gitignore` exceptions for V2 profile-local `.codex` assets.
- [ ] 2.2 Add the V2 `codex-codex-claude-flow-gpt56-sol-dev` profile with profile-specific assets only.
- [ ] 2.3 Add the V1 `codex-codex-claude-flow-gpt56-sol-dev` compatibility profile with the complete runtime asset tree.
- [ ] 2.4 Register the new profile in the V1 switcher allowlist and layout validation.

## 3. Documentation

- [ ] 3.1 Add V2 setup/switch and V1 compatibility commands to `README.md` without replacing the existing GPT-5.5 recommendation.
- [ ] 3.2 Ensure profile documentation, session-state templates, skill rules, and agent descriptions use the new profile ID and approved routing matrix.

## 4. Verification

- [ ] 4.1 Run V1 and V2 profile tests and the existing V2 global setup regression test.
- [ ] 4.2 Validate shell syntax, JSON, TOML, profile/runtime synchronization, and Git ignore behavior.
- [ ] 4.3 Run Graphify's required code rebuild command or record the documented degraded result if Graphify remains unavailable.
- [ ] 4.4 Run `openspec validate add-codex-gpt56-sol-profile --strict --no-interactive` and `git diff --check`.
