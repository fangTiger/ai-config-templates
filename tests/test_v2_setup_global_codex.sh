#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmpdir="$(mktemp -d /tmp/v2-setup-global-codex.XXXXXX)"
fake_home="$tmpdir/home"
fake_bin="$tmpdir/bin"

mkdir -p "$fake_home" "$fake_bin"
touch "$fake_home/.zshrc"

cat > "$fake_bin/claude" <<'SH'
#!/usr/bin/env bash
if [ "${1:-}" = "plugin" ] && [ "${2:-}" = "list" ]; then
  echo "superpowers"
  exit 0
fi
echo "claude stub"
SH
chmod +x "$fake_bin/claude"

cat > "$fake_bin/codex" <<'SH'
#!/usr/bin/env bash
echo "codex stub"
SH
chmod +x "$fake_bin/codex"

PATH="$fake_bin:$PATH" HOME="$fake_home" zsh "$repo_root/v2/setup-global.sh"

test -f "$fake_home/.claude/CLAUDE.md"
test -f "$fake_home/.claude/.harness-manifest.json"
test -f "$fake_home/.codex/AGENTS.md"
test -f "$fake_home/.codex/.harness-manifest.json"
test -f "$fake_home/.codex/skills/using-superpowers/SKILL.md"

grep -q "harness-version: v2" "$fake_home/.codex/AGENTS.md"
grep -q '"target": "codex"' "$fake_home/.codex/.harness-manifest.json"

if [ -f "$fake_home/.codex/config.toml" ]; then
  echo "setup-global.sh must not create or overwrite ~/.codex/config.toml" >&2
  exit 1
fi

python3 -m json.tool "$fake_home/.claude/.harness-manifest.json" >/dev/null
python3 -m json.tool "$fake_home/.codex/.harness-manifest.json" >/dev/null
