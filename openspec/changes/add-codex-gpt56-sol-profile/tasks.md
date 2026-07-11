## 1. TDD Coverage

- [x] 1.1 Add failing V2 tests for GPT-5.6 Sol profile discovery, setup, switching, session-state identity, hidden-file tracking, and exact TOML routing.
- [x] 1.2 Add failing V1 tests for allowlist registration, layout installation, session-state identity, and exact TOML routing.
- [x] 1.3 Add a regression assertion that the GPT-5.5 profile keeps its existing 5.5/5.4 routing.

## 2. Profile Templates

- [x] 2.1 Add generic `.gitignore` exceptions for V2 profile-local `.codex` assets.
- [x] 2.2 Add the V2 `codex-codex-claude-flow-gpt56-sol-dev` profile with profile-specific assets only.
- [x] 2.3 Add the V1 `codex-codex-claude-flow-gpt56-sol-dev` compatibility profile with the complete runtime asset tree.
- [x] 2.4 Register the new profile in the V1 switcher allowlist and layout validation.

## 3. Documentation

- [x] 3.1 Add V2 setup/switch and V1 compatibility commands to `README.md` without replacing the existing GPT-5.5 recommendation.
- [x] 3.2 Ensure profile documentation, session-state templates, skill rules, and agent descriptions use the new profile ID and approved routing matrix.

## 4. Verification

- [x] 4.1 Run V1 and V2 profile tests and the existing V2 global setup regression test.
- [x] 4.2 Validate shell syntax, JSON, TOML, profile/runtime synchronization, and Git ignore behavior.
- [x] 4.3 Run Graphify's required code rebuild command or record the documented degraded result if Graphify remains unavailable.
- [x] 4.4 Run `openspec validate add-codex-gpt56-sol-profile --strict --no-interactive` and `git diff --check`.

## Verification Evidence (2026-07-11)

- `python3 tests/test_v1_codex_profiles.py`: 4 tests passed.
- `python3 tests/test_v2_codex_profiles.py`: 24 tests passed.
- `bash tests/test_v2_setup_global_codex.sh`: passed.
- Shell syntax validation passed for the V1 switcher, V2 setup script, and V2 switcher.
- All 6 new JSON files and all 6 new TOML files parsed successfully.
- V1 normalized parity passed for 18 files; V2 normalized parity passed for exactly 8 profile-specific files.
- Both V1 and V2 profile-local `.codex/config.toml` files are visible to Git; the GPT-5.5 source profile is unchanged.
- Graphify code rebuild succeeded with 209 nodes, 317 edges, and 14 communities.
- `openspec validate add-codex-gpt56-sol-profile --strict --no-interactive` reported the change as valid; `git diff --check` passed.
- Two independent reviews found no implementation defects; the requested OpenSpec task-state closeout is captured by this update.
