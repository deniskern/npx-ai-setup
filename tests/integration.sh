#!/usr/bin/env bash
# Integration test for fresh offline installs with isolated home directories.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/ai-setup-integration.XXXXXX")"
BIN_DIR="$TMP_ROOT/bin"
WRITABLE_PROJECT="$TMP_ROOT/project-writable"
LOCKED_PROJECT="$TMP_ROOT/project-locked"
WRITABLE_HOME="$TMP_ROOT/home-writable"
LOCKED_HOME="$TMP_ROOT/home-locked"

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

cleanup() {
  chmod -R u+w "$TMP_ROOT" 2>/dev/null || true
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "❌ Missing required tool for integration test: $1"
    exit 1
  fi
}

link_tool() {
  local tool="$1"
  local source
  source="$(command -v "$tool" 2>/dev/null || true)"
  if [ -z "$source" ]; then
    echo "❌ Required tool not found for isolated PATH: $tool"
    exit 1
  fi
  ln -s "$source" "$BIN_DIR/$tool"
}

write_toolchain() {
  mkdir -p "$BIN_DIR"

  # Keep the isolated PATH free of jq so the setup must exercise the Node fallback.
  for tool in awk basename cat chmod cmp cp cksum cut date dirname find grep head id ln ls mkdir mktemp mv node pwd readlink rm sed sort stat tail touch tr uname wc; do
    link_tool "$tool"
  done

  rm -f "$BIN_DIR/npm" "$BIN_DIR/npx" "$BIN_DIR/curl"

  cat > "$BIN_DIR/npm" <<'EOF'
#!/bin/bash
case "${1:-}" in
  view) exit 1 ;;
  --version|-v|version) echo "10.0.0" ;;
  config)
    if [ "${2:-}" = "get" ] && [ "${3:-}" = "cache" ]; then
      exit 0
    fi
    ;;
esac
exit 0
EOF

  cat > "$BIN_DIR/npx" <<'EOF'
#!/bin/bash
exit 127
EOF

  cat > "$BIN_DIR/curl" <<'EOF'
#!/bin/bash
exit 1
EOF

  chmod +x "$BIN_DIR/npm" "$BIN_DIR/npx" "$BIN_DIR/curl"
}

prepare_project() {
  local project_dir="$1"
  mkdir -p "$project_dir"
  cat > "$project_dir/package.json" <<'EOF'
{
  "name": "integration-fixture",
  "version": "1.0.0",
  "private": true
}
EOF
}

run_install() {
  local project_dir="$1"
  local home_dir="$2"
  local log_file="$3"

  (
    cd "$project_dir"
    HOME="$home_dir" PATH="$BIN_DIR" /bin/bash "$ROOT_DIR/bin/ai-setup.sh" >"$log_file" 2>&1 </dev/null
  )
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

assert_log_contains() {
  local log_file="$1"
  local needle="$2"
  local label="$3"
  if grep -qF "$needle" "$log_file" 2>/dev/null; then
    pass "$label"
  else
    fail "$label"
  fi
}

check_project_artifacts() {
  local project_dir="$1"

  assert_path_exists "$project_dir/CLAUDE.md" "CLAUDE.md created"
  assert_path_exists "$project_dir/AGENTS.md" "AGENTS.md created"
  assert_path_exists "$project_dir/.ai-setup.json" ".ai-setup.json created"
  assert_path_exists "$project_dir/.gitignore" ".gitignore updated"
  assert_path_exists "$project_dir/.mcp.json" ".mcp.json created"
  assert_path_exists "$project_dir/.github/copilot-instructions.md" ".github/copilot-instructions.md created"
  assert_path_exists "$project_dir/.claude/settings.json" ".claude/settings.json created"
  assert_path_exists "$project_dir/WORKFLOW-GUIDE.md" "WORKFLOW-GUIDE.md created"
  assert_path_exists "$project_dir/.claude/hooks/update-check.sh" ".claude/hooks/update-check.sh created"
  assert_path_exists "$project_dir/.claude/rules/general.md" ".claude/rules/general.md created"
  assert_path_exists "$project_dir/.claude/agents/code-reviewer.md" ".claude/agents/code-reviewer.md created"
  assert_path_exists "$project_dir/.claude/scripts/doctor.sh" ".claude/scripts/doctor.sh created"
  assert_path_exists "$project_dir/.claude/scripts/release.sh" ".claude/scripts/release.sh created"
  assert_path_exists "$project_dir/.claude/scripts/spec-board.sh" ".claude/scripts/spec-board.sh created"
  assert_path_exists "$project_dir/.claude/skills/spec-work/SKILL.md" ".claude/skills/spec-work/SKILL.md created"
  assert_path_exists "$project_dir/specs/TEMPLATE.md" "specs/TEMPLATE.md created"
  assert_path_exists "$project_dir/specs/README.md" "specs/README.md created"
  assert_path_exists "$project_dir/specs/completed/.gitkeep" "specs/completed/.gitkeep created"
}

echo "=== Integration test: fresh offline install ==="

require_tool node
write_toolchain

prepare_project "$WRITABLE_PROJECT"
mkdir -p "$WRITABLE_HOME"
mkdir -p "$WRITABLE_HOME/.claude"
cat > "$WRITABLE_HOME/.claude/settings.json" <<'EOF'
{"statusLine":"preconfigured"}
EOF
WRITABLE_LOG="$TMP_ROOT/writable.log"
run_install "$WRITABLE_PROJECT" "$WRITABLE_HOME" "$WRITABLE_LOG"
check_project_artifacts "$WRITABLE_PROJECT"
assert_log_contains "$WRITABLE_LOG" "Node.js JSON fallback active" "Node fallback used without jq"

prepare_project "$LOCKED_PROJECT"
mkdir -p "$LOCKED_HOME"
mkdir -p "$LOCKED_HOME/.claude"
cat > "$LOCKED_HOME/.claude/settings.json" <<'EOF'
{"statusLine":"preconfigured"}
EOF
chmod 555 "$LOCKED_HOME" "$LOCKED_HOME/.claude"
LOCKED_LOG="$TMP_ROOT/locked.log"
run_install "$LOCKED_PROJECT" "$LOCKED_HOME" "$LOCKED_LOG"
check_project_artifacts "$LOCKED_PROJECT"
assert_log_contains "$LOCKED_LOG" "Global agents skipped" "global agent writes skipped cleanly"

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
