#!/usr/bin/env bash
# Integration test for a fresh offline install in a temp project.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/ai-setup-integration.XXXXXX")"
PROJECT_DIR="$TMP_ROOT/project"
BIN_DIR="$TMP_ROOT/bin"

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

cleanup() {
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "❌ Missing required tool for integration test: $1"
    exit 1
  fi
}

assert_path_exists() {
  local path="$1"
  local label="$2"
  if [ -e "$path" ]; then
    pass "$label"
  else
    fail "$label"
  fi
}

write_stub_binaries() {
  mkdir -p "$BIN_DIR"
  ln -s "$(command -v node)" "$BIN_DIR/node"
  ln -s "$(command -v jq)" "$BIN_DIR/jq"

  cat > "$BIN_DIR/npm" <<'EOF'
#!/usr/bin/env bash
case "${1:-}" in
  view) exit 1 ;;
  --version|-v|version) echo "10.0.0" ;;
esac
exit 0
EOF

  cat > "$BIN_DIR/npx" <<'EOF'
#!/usr/bin/env bash
exit 127
EOF

  cat > "$BIN_DIR/curl" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF

  chmod +x "$BIN_DIR/npm" "$BIN_DIR/npx" "$BIN_DIR/curl"
}

run_install() {
  mkdir -p "$PROJECT_DIR"

  cat > "$PROJECT_DIR/package.json" <<'EOF'
{
  "name": "integration-fixture",
  "version": "1.0.0",
  "private": true
}
EOF

  (
    cd "$PROJECT_DIR"
    PATH="$BIN_DIR:/usr/bin:/bin:/usr/sbin:/sbin" \
      bash "$ROOT_DIR/bin/ai-setup.sh" --system auto >/dev/null <<'EOF'
n
n
EOF
  )
}

check_expected_install_artifacts() {
  echo ""
  echo "--- Installed files and directories ---"

  assert_path_exists "$PROJECT_DIR/CLAUDE.md" "CLAUDE.md created"
  assert_path_exists "$PROJECT_DIR/AGENTS.md" "AGENTS.md created"
  assert_path_exists "$PROJECT_DIR/.ai-setup.json" ".ai-setup.json created"
  assert_path_exists "$PROJECT_DIR/.gitignore" ".gitignore updated"
  assert_path_exists "$PROJECT_DIR/repomix.config.json" "repomix.config.json created"
  assert_path_exists "$PROJECT_DIR/.mcp.json" ".mcp.json created"
  assert_path_exists "$PROJECT_DIR/.github/copilot-instructions.md" ".github/copilot-instructions.md created"
  assert_path_exists "$PROJECT_DIR/.claude/settings.json" ".claude/settings.json created"
  assert_path_exists "$PROJECT_DIR/.claude/WORKFLOW-GUIDE.md" ".claude/WORKFLOW-GUIDE.md created"
  assert_path_exists "$PROJECT_DIR/.claude/hooks/update-check.sh" ".claude/hooks/update-check.sh created"
  assert_path_exists "$PROJECT_DIR/.claude/rules/general.md" ".claude/rules/general.md created"
  assert_path_exists "$PROJECT_DIR/.claude/agents/code-reviewer.md" ".claude/agents/code-reviewer.md created"
  assert_path_exists "$PROJECT_DIR/.claude/skills/spec-work/SKILL.md" ".claude/skills/spec-work/SKILL.md created"
  assert_path_exists "$PROJECT_DIR/specs/TEMPLATE.md" "specs/TEMPLATE.md created"
  assert_path_exists "$PROJECT_DIR/specs/README.md" "specs/README.md created"
  assert_path_exists "$PROJECT_DIR/specs/completed/.gitkeep" "specs/completed/.gitkeep created"
}

check_command_template_sync() {
  echo ""
  echo "--- Command template sync ---"

  local template
  local installed_count=0
  local template_count=0

  while IFS= read -r -d '' template; do
    local name
    name="$(basename "$template")"
    template_count=$((template_count + 1))
    if [ -f "$PROJECT_DIR/.claude/commands/$name" ]; then
      pass ".claude/commands/$name installed"
      installed_count=$((installed_count + 1))
    else
      fail ".claude/commands/$name missing"
    fi
  done < <(find "$ROOT_DIR/templates/commands" -maxdepth 1 -type f -name '*.md' -print0 | sort -z)

  if [ "$installed_count" -eq "$template_count" ] && [ "$template_count" -gt 0 ]; then
    pass "all template commands installed"
  else
    fail "template command count mismatch"
  fi
}

echo "=== Integration test: fresh offline install ==="

require_tool node
require_tool jq

write_stub_binaries
run_install
check_expected_install_artifacts
check_command_template_sync

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
