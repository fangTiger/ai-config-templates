# Change: Refactor V2 Codex Shared Assets

## Why
V2 Codex-native profiles currently duplicate hooks, tools, and workflow skills across profile directories. This violates the V2 shared-first layering model and leaves runtime bugs, such as the broken embedded Python in the duplicated Java graphify tool, replicated across profiles.

## What Changes
- Add a Codex-native shared asset layer under `v2/scripts/plugin-profiles/shared/codex/`.
- Install shared Codex hooks, tools, and skills before profile-specific `.codex/` assets during V2 setup and switching.
- Move duplicated Codex workflow skills and common tools/hooks out of profile-specific directories, leaving only real profile overrides.
- Add tests that verify shared Codex assets are installed and embedded Python in shell tools is syntactically valid.

## Impact
- Affected specs: plugin-profiles
- Affected code: `v2/setup-project.sh`, `v2/scripts/switch-plugin.sh`, `v2/scripts/plugin-profiles/shared/codex/**`, `v2/scripts/plugin-profiles/codex-codex-*/**`, `tests/test_v2_codex_profiles.py`
