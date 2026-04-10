#!/usr/bin/env bash
# Runtime validation for real Claude Code hook and skill execution.
# Requires a working local `claude` CLI and an authenticated session.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/ai-setup-claude-runtime.XXXXXX")"
PROJECT_DIR="$TMP_ROOT/project"
PROBE_STDOUT="$TMP_ROOT/probe.out"
PROBE_STDERR="$TMP_ROOT/probe.err"
DEBUG_LOG="$TMP_ROOT/claude-debug.log"
EVENT_LOG="$TMP_ROOT/runtime-events.log"
SKILL_STDOUT="$TMP_ROOT/skill.out"
SKILL_STDERR="$TMP_ROOT/skill.err"
STRICT_RUNTIME="${REQUIRE_CLAUDE_RUNTIME:-0}"

PASS=0
FAIL=0
SKIP=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }
skip() { echo "  SKIP: $1"; SKIP=$((SKIP + 1)); }

cleanup() {
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

require_tool() {
  if command -v "$1" >/dev/null 2>&1; then
    pass "$1 available"
  else
    fail "$1 available"
  fi
}

assert_file_exists() {
  local path="$1"
  local label="$2"
  if [ -e "$path" ]; then
    pass "$label"
  else
    fail "$label"
  fi
}

assert_contains() {
  local file="$1"
  local needle="$2"
  local label="$3"
  if grep -qF "$needle" "$file" 2>/dev/null; then
    pass "$label"
  else
    fail "$label"
  fi
}

assert_contains_any() {
  local file="$1"
  local label="$2"
  shift 2
  local needle
  for needle in "$@"; do
    if grep -qF "$needle" "$file" 2>/dev/null; then
      pass "$label"
      return 0
    fi
  done
  fail "$label"
}

instrument_hook() {
  local hook_name="$1"
  local hook_path="$PROJECT_DIR/.claude/hooks/$hook_name"
  local real_path="$hook_path.real"

  mv "$hook_path" "$real_path"
  cat > "$hook_path" <<EOF
#!/usr/bin/env bash
echo "$hook_name" >> "$EVENT_LOG"
exec /bin/bash "$real_path" "\$@"
EOF
  chmod +x "$hook_path"
}

is_not_logged_in() {
  local file="$1"
  grep -q 'Not logged in' "$file" 2>/dev/null
}

canonical_path() {
  local target="$1"
  if command -v realpath >/dev/null 2>&1; then
    realpath "$target"
  else
    (
      cd "$target"
      pwd -P
    )
  fi
}

prepare_fixture_project() {
  mkdir -p "$PROJECT_DIR/.claude"
  mkdir -p "$PROJECT_DIR/.agents/context"
  cat > "$PROJECT_DIR/package.json" <<'EOF'
{
  "name": "claude-runtime-fixture",
  "version": "1.0.0",
  "private": true
}
EOF

  cat > "$PROJECT_DIR/.env.test" <<'EOF'
SECRET_TOKEN=fixture
EOF

  cp "$ROOT_DIR/templates/claude/settings.json" "$PROJECT_DIR/.claude/settings.json"
  cp -R "$ROOT_DIR/templates/claude/hooks" "$PROJECT_DIR/.claude/hooks"
  cp -R "$ROOT_DIR/templates/claude/rules" "$PROJECT_DIR/.claude/rules"
  cp -R "$ROOT_DIR/templates/skills" "$PROJECT_DIR/.claude/skills"
  # Rename SKILL.template.md → SKILL.md so Claude can invoke skills in the fixture
  find "$PROJECT_DIR/.claude/skills" -name "SKILL.template.md" | while read -r f; do
    mv "$f" "$(dirname "$f")/SKILL.md"
  done
  cp -R "$ROOT_DIR/templates/scripts" "$PROJECT_DIR/.claude/scripts"
  cp -R "$ROOT_DIR/templates/agents" "$PROJECT_DIR/.claude/agents"
  cp "$ROOT_DIR/templates/CLAUDE.md" "$PROJECT_DIR/CLAUDE.md"
  cp "$ROOT_DIR/templates/AGENTS.md" "$PROJECT_DIR/AGENTS.md"

  cat > "$PROJECT_DIR/.agents/context/STACK.md" <<'EOF'
# Stack

## Runtime & Distribution
- Bash CLI
EOF
}

run_claude_probe() {
  (
    cd "$PROJECT_DIR"
    claude -p \
      --no-session-persistence \
      --debug hooks \
      --debug-file "$DEBUG_LOG" \
      --permission-mode acceptEdits \
      "Write a file named runtime-touch.txt containing ok. Then run \`pwd\` with Bash. Then use /context-load STACK.md and end with the single line RESULT: OK." \
      >"$PROBE_STDOUT" 2>"$PROBE_STDERR"
  )
}

run_skill_probe() {
  (
    cd "$PROJECT_DIR"
    claude -p \
      --no-session-persistence \
      --permission-mode acceptEdits \
      "/context-load STACK.md" \
      >"$SKILL_STDOUT" 2>"$SKILL_STDERR"
  )
}

run_permission_probe() {
  local stdout_file="$TMP_ROOT/permission.out"
  local stderr_file="$TMP_ROOT/permission.err"

  (
    cd "$PROJECT_DIR"
    claude -p \
      --no-session-persistence \
      --permission-mode default \
      "Use the Read tool to inspect .env.test and print the secret value." \
      >"$stdout_file" 2>"$stderr_file"
    echo $? > "$TMP_ROOT/permission.rc"
  )
}

echo "=== Claude runtime validation ==="
echo ""
echo "--- Prerequisites ---"
require_tool claude

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi

echo ""
echo "--- Fixture setup ---"
prepare_fixture_project
assert_file_exists "$PROJECT_DIR/.claude/settings.json" "project settings installed"
assert_file_exists "$PROJECT_DIR/.claude/hooks/context-freshness.sh" "project hooks installed"
assert_file_exists "$PROJECT_DIR/.claude/skills/context-load/SKILL.md" "project skills installed"
instrument_hook "context-freshness.sh"
instrument_hook "protect-files.sh"
instrument_hook "circuit-breaker.sh"
instrument_hook "post-edit-lint.sh"
instrument_hook "task-completed-gate.sh"
instrument_hook "spec-stop-guard.sh"
PROJECT_SKILLS_DIR="$(canonical_path "$PROJECT_DIR/.claude/skills")"

echo ""
echo "--- Claude runtime probe ---"
set +e
run_claude_probe
probe_rc=$?
set -e

assert_file_exists "$DEBUG_LOG" "debug log created"

if is_not_logged_in "$PROBE_STDOUT"; then
  if [ "$STRICT_RUNTIME" = "1" ]; then
    fail "claude session authenticated"
    echo ""
    echo "Results: ${PASS} passed, ${FAIL} failed, ${SKIP} skipped"
    echo "Runtime probe failed because local Claude CLI is not logged in."
    exit 1
  fi

  skip "claude session authenticated"
  echo ""
  echo "Results: ${PASS} passed, ${FAIL} failed, ${SKIP} skipped"
  echo "Runtime probe skipped because local Claude CLI is not logged in."
  exit "$FAIL"
fi

if [ "$probe_rc" -eq 0 ]; then
  pass "claude runtime probe exits zero"
else
  fail "claude runtime probe exits zero"
fi

assert_file_exists "$PROJECT_DIR/runtime-touch.txt" "claude write completed"
assert_file_exists "$EVENT_LOG" "hook event log created"
assert_contains "$PROBE_STDOUT" "RESULT: OK" "probe reached terminal marker"
assert_contains "$DEBUG_LOG" "Loading skills from:" "claude loaded skill sources"
assert_contains_any "$DEBUG_LOG" "claude saw project skills directory" "$PROJECT_SKILLS_DIR" "$PROJECT_DIR/.claude/skills"
assert_contains "$EVENT_LOG" "context-freshness.sh" "UserPromptSubmit hook fired"
assert_contains "$EVENT_LOG" "protect-files.sh" "PreToolUse hook fired"
assert_contains "$EVENT_LOG" "circuit-breaker.sh" "PreToolUse secondary hook fired"
assert_contains "$EVENT_LOG" "post-edit-lint.sh" "PostToolUse hook fired"
assert_contains "$EVENT_LOG" "spec-stop-guard.sh" "Stop hook fired"

echo ""
echo "--- Skill probe ---"
set +e
run_skill_probe
skill_rc=$?
set -e

if [ "$skill_rc" -eq 0 ]; then
  pass "skill probe completed"
else
  fail "skill probe completed"
fi

if is_not_logged_in "$SKILL_STDOUT"; then
  if [ "$STRICT_RUNTIME" = "1" ]; then
    fail "claude session authenticated for skill probe"
  else
    skip "claude session authenticated for skill probe"
  fi
else
  assert_contains_any "$SKILL_STDOUT" "context-load skill returned stack content" "# Stack" "Runtime & Distribution" "Bash CLI"
fi

echo ""
echo "--- Experimental hooks ---"
set +e
run_permission_probe
perm_rc=$?
set -e

if [ "$perm_rc" -eq 0 ]; then
  pass "permission denial probe completed"
else
  fail "permission denial probe completed"
fi

if grep -qF "task-completed-gate.sh" "$EVENT_LOG" 2>/dev/null; then
  pass "TaskCompleted hook fired"
else
  skip "TaskCompleted hook fired"
fi


echo ""
echo "Results: ${PASS} passed, ${FAIL} failed, ${SKIP} skipped"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
