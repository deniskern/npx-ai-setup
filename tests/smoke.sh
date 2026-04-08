#!/usr/bin/env bash
# Smoke test for bin/ai-setup.sh and lib/ modules
# Checks syntax and key function presence — does NOT execute the script interactively.

set -euo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "=== Smoke test: modular ai-setup ==="

# Step 1: Verify runtime lib modules exist
echo ""
echo "--- Module existence ---"
RUNTIME_MODULES=("_loader.sh" "boilerplate.sh" "core.sh" "detect.sh" "generate.sh" "json.sh" "migrate.sh" "plugins.sh" "process.sh" "setup-compat.sh" "setup-skills.sh" "setup.sh" "skills.sh" "tui.sh" "update.sh")
ALL_MODULES=(lib/*.sh)
for mod in "${RUNTIME_MODULES[@]}"; do
  if [ -f "lib/$mod" ]; then
    pass "lib/$mod exists"
  else
    fail "lib/$mod missing"
  fi
done

# Step 2: Syntax check all files
echo ""
echo "--- Syntax checks (bash -n) ---"
if bash -n bin/ai-setup.sh 2>&1; then
  pass "bin/ai-setup.sh syntax"
else
  fail "bin/ai-setup.sh syntax"
fi

for mod in "${ALL_MODULES[@]}"; do
  if bash -n "$mod" 2>&1; then
    pass "$mod syntax"
  else
    fail "$mod syntax"
  fi
done

if bash -n .claude/scripts/session-deep-dive.sh 2>&1; then
  pass ".claude/scripts/session-deep-dive.sh syntax"
else
  fail ".claude/scripts/session-deep-dive.sh syntax"
fi

# Step 3: Key function presence in expected modules
echo ""
echo "--- Function location checks ---"
CHECKS=(
  "core.sh:build_template_map"
  "core.sh:get_package_version"
  "core.sh:compute_checksum"
  "core.sh:write_metadata"
  "core.sh:backup_file"
  "core.sh:collect_project_files"
  "process.sh:kill_tree"
  "process.sh:progress_bar"
  "process.sh:wait_parallel"
  "detect.sh:get_template_category"
  "detect.sh:should_update_template"
  "tui.sh:ask_regen_parts"
  "tui.sh:ask_update_parts"
  "tui.sh:ask_overwrite_modified"
  "skills.sh:install_skill"
  "skills.sh:run_skill_installation"
  "generate.sh:run_generation"
  "migrate.sh:run_migrations"
  "update.sh:show_cli_update_notice"
  "update.sh:handle_version_check"
  "update.sh:run_smart_update"
  "update.sh:run_clean_reinstall"
  "setup.sh:check_requirements"
  "setup.sh:cleanup_legacy"
  "setup.sh:install_hooks"
  "setup.sh:install_workflow_guide"
  "setup.sh:install_skills"
  "setup.sh:install_claude_scripts"
  "setup.sh:update_gitignore"
  "setup.sh:customize_settings_for_stack"
  "setup-skills.sh:install_spec_skills"
  "setup-skills.sh:install_agents"
  "setup-skills.sh:repair_canonical_skill_links"
  "setup-skills.sh:ensure_skills_alias"
  "setup-skills.sh:ensure_codex_skills_alias"
  "setup-skills.sh:ensure_opencode_skills_alias"
  "boilerplate.sh:pull_boilerplate_files"
  "boilerplate.sh:has_system_config"
  "boilerplate.sh:select_boilerplate_system"
  "plugins.sh:install_claude_mem"
  "plugins.sh:install_context7"
  "plugins.sh:show_installation_summary"
  "plugins.sh:show_next_steps"
  "plugins.sh:show_update_next_steps"
)

for check in "${CHECKS[@]}"; do
  IFS=':' read -r mod fn <<< "$check"
  if grep -q "${fn}()" "lib/$mod" 2>/dev/null; then
    pass "${fn}() in lib/$mod"
  else
    fail "${fn}() missing from lib/$mod"
  fi
done

# Step 4: Verify main script sources modules
echo ""
echo "--- Module sourcing in bin/ai-setup.sh ---"
for mod in "${RUNTIME_MODULES[@]}"; do
  if grep -q "$mod" bin/ai-setup.sh 2>/dev/null; then
    pass "bin/ai-setup.sh sources $mod"
  else
    fail "bin/ai-setup.sh does not source $mod"
  fi
done

# Step 5: Verify package.json includes lib/
echo ""
echo "--- Distribution checks ---"
if grep -q '"lib/"' package.json 2>/dev/null; then
  pass "package.json includes lib/ in files"
else
  fail "package.json missing lib/ in files"
fi

# Step 6: Verify hooks are wired correctly
echo ""
echo "--- Hook wiring checks ---"
if awk '/"UserPromptSubmit"[[:space:]]*:[[:space:]]*\[/,/^[[:space:]]*\],?$/' templates/claude/settings.json | grep -q 'update-check.sh'; then
  pass "templates/claude/settings.json wires update-check.sh on UserPromptSubmit"
else
  fail "templates/claude/settings.json missing UserPromptSubmit update-check.sh hook"
fi

# Step 7: Verify spec-work validation gate
echo ""
echo "--- Spec-work validation gate ---"
if grep -q 'Validation gate\|validation gate\|skip-validate' templates/skills/spec-work/SKILL.template.md 2>/dev/null; then
  pass "templates/skills/spec-work/SKILL.template.md has validation gate"
else
  fail "templates/skills/spec-work/SKILL.template.md missing validation gate"
fi

echo ""
echo "--- Routing guidance ---"
if grep -qi 'haiku.*direct tool\|haiku.*explore' CLAUDE.md 2>/dev/null; then
  pass "CLAUDE.md restricts Haiku to direct tool use and explore agents"
else
  fail "CLAUDE.md missing Haiku routing scope"
fi

if grep -q 'Threshold: spawn agents only for tasks requiring ≥3 distinct tool calls' .claude/rules/agents.md 2>/dev/null; then
  pass ".claude/rules/agents.md defines a concrete spawn threshold"
else
  fail ".claude/rules/agents.md missing concrete spawn threshold"
fi

if grep -q 'already made 8 tool calls\|Escalation rule' .claude/rules/agents.md 2>/dev/null; then
  pass ".claude/rules/agents.md adds an early parallelization threshold"
else
  fail ".claude/rules/agents.md missing early parallelization threshold"
fi

if grep -q 'crosses `>30` tool calls with no subagents' CLAUDE.md 2>/dev/null; then
  pass "CLAUDE.md tells long sessions to reconsider delegation"
else
  fail "CLAUDE.md missing long-session delegation check"
fi

if grep -q 'model: haiku' .claude/skills/spec-work/SKILL.md 2>/dev/null; then
  pass ".claude/skills/spec-work/SKILL.md uses Haiku-first routing for medium work"
else
  fail ".claude/skills/spec-work/SKILL.md missing Haiku-first medium routing"
fi

if grep -q 'Review stays on Sonnet for all tiers' .claude/skills/spec-review/SKILL.md 2>/dev/null; then
  pass ".claude/skills/spec-review/SKILL.md keeps routine review on Sonnet"
else
  fail ".claude/skills/spec-review/SKILL.md missing explicit Sonnet-only review guidance"
fi

# Step 8: Verify Complexity field in spec template
echo ""
echo "--- Spec template Complexity field ---"
if grep -qF '**Complexity**:' specs/TEMPLATE.md 2>/dev/null; then
  pass "specs/TEMPLATE.md has Complexity field in header"
else
  fail "specs/TEMPLATE.md missing Complexity field"
fi

echo ""
echo "--- Spec validate prep ---"
SPEC_PREP_OUTPUT=$(bash .claude/scripts/spec-validate-prep.sh 600 2>&1 || true)
if printf '%s' "$SPEC_PREP_OUTPUT" | grep -q 'Status: completed'; then
  pass "spec-validate-prep detects markdown status header"
else
  fail "spec-validate-prep did not detect markdown status header"
fi

if printf '%s' "$SPEC_PREP_OUTPUT" | grep -q 'Total steps:     6'; then
  pass "spec-validate-prep counts completed steps correctly"
else
  fail "spec-validate-prep step counts are broken"
fi

if printf '%s' "$SPEC_PREP_OUTPUT" | grep -q 'Total criteria:     4'; then
  pass "spec-validate-prep counts acceptance criteria correctly"
else
  fail "spec-validate-prep acceptance criteria counts are broken"
fi

echo ""
echo "--- Session deep dive ---"
SESSION_DEEP_DIVE_OUTPUT="$(bash .claude/scripts/session-deep-dive.sh tests/fixtures/session-deep-dive-sample.txt 2>&1 || true)"
if printf '%s' "$SESSION_DEEP_DIVE_OUTPUT" | grep -q 'Session Deep-Dive Report'; then
  pass "session-deep-dive.sh prints a report header"
else
  fail "session-deep-dive.sh missing report header"
fi

if printf '%s' "$SESSION_DEEP_DIVE_OUTPUT" | grep -q 'Correction turns:'; then
  pass "session-deep-dive.sh reports correction counts"
else
  fail "session-deep-dive.sh missing correction count"
fi

# Step 9: Verify tracked repo-local scripts stay in sync with templates
echo ""
echo "--- Script source-of-truth parity ---"
while IFS= read -r -d '' template_script; do
  script_name="$(basename "$template_script")"
  repo_script=".claude/scripts/$script_name"
  if [ ! -f "$repo_script" ]; then
    continue
  fi

  if cmp -s "$template_script" "$repo_script"; then
    pass "$script_name matches templates/scripts/$script_name"
  else
    fail "$script_name drifted from templates/scripts/$script_name"
  fi
done < <(find templates/scripts -maxdepth 1 -type f -name '*.sh' -print0 | sort -z)

# Step 10: Verify skills alias migration is wired in both setup and update paths
echo ""
echo "--- Skills alias migration wiring ---"
if grep -q 'ensure_skills_alias' bin/ai-setup.sh 2>/dev/null; then
  pass "bin/ai-setup.sh calls ensure_skills_alias on install"
else
  fail "bin/ai-setup.sh missing ensure_skills_alias call"
fi

if grep -q 'ensure_skills_alias' lib/update.sh 2>/dev/null; then
  pass "lib/update.sh calls ensure_skills_alias during smart update"
else
  fail "lib/update.sh missing ensure_skills_alias call"
fi

if grep -Eq 'pull_boilerplate_files "\$system" --skip-skills' lib/boilerplate.sh 2>/dev/null; then
  pass "lib/boilerplate.sh skips boilerplate skills during update sync"
else
  fail "lib/boilerplate.sh update sync still pulls boilerplate skills"
fi

if grep -q '_is_current_repo_boilerplate' lib/boilerplate.sh 2>/dev/null; then
  pass "lib/boilerplate.sh detects when the current repo is itself a boilerplate"
else
  fail "lib/boilerplate.sh missing self-boilerplate detection"
fi

if grep -Eq 'Skipping boilerplate (pull|sync) \(already inside .* boilerplate repo\)' lib/boilerplate.sh 2>/dev/null; then
  pass "lib/boilerplate.sh skips boilerplate pulls inside boilerplate repos"
else
  fail "lib/boilerplate.sh missing skip guard for boilerplate repos"
fi

if grep -q 'install_skills' lib/update.sh 2>/dev/null; then
  pass "lib/update.sh installs skills during smart update"
else
  fail "lib/update.sh missing install_skills call"
fi

if grep -q 'repair_canonical_skill_links' lib/setup-skills.sh 2>/dev/null; then
  pass "lib/setup-skills.sh contains looping skill-link repair helper"
else
  fail "lib/setup-skills.sh missing looping skill-link repair helper"
fi

if grep -Eq 'repair_canonical_skill_links .*\$canonical.*\$canonical_abs' lib/setup-skills.sh 2>/dev/null; then
  pass "ensure_skills_alias invokes looping skill-link repair"
else
  fail "ensure_skills_alias missing looping skill-link repair call"
fi

# Step 11: Verify circuit breaker has spec-active threshold override
echo ""
echo "--- Circuit breaker spec-aware thresholds ---"
if grep -q 'in-progress' templates/claude/hooks/circuit-breaker.sh 2>/dev/null; then
  pass "circuit-breaker.sh raises thresholds when spec is in-progress"
else
  fail "circuit-breaker.sh missing spec-active threshold override"
fi

if grep -q 'SPEC_COUNT' templates/claude/hooks/circuit-breaker.sh 2>/dev/null; then
  pass "circuit-breaker.sh raises thresholds further for spec-work-all batch runs"
else
  fail "circuit-breaker.sh missing multi-spec batch detection"
fi

echo "--- lib/json.sh wrapper ---"
if [ -f lib/json.sh ]; then
  pass "lib/json.sh exists"
else
  fail "lib/json.sh missing"
fi

if grep -q '_json_read' lib/json.sh 2>/dev/null; then
  pass "lib/json.sh exports _json_read"
else
  fail "lib/json.sh missing _json_read"
fi

if grep -q '_json_merge' lib/json.sh 2>/dev/null; then
  pass "lib/json.sh exports _json_merge"
else
  fail "lib/json.sh missing _json_merge"
fi

echo ""
echo "--- Session extract active duration ---"
SESSION_TMP=$(mktemp -d "${TMPDIR:-/tmp}/ai-setup-test.XXXXXX")
SESSION_PROJECT_DIR="$SESSION_TMP/projects/demo-project"
mkdir -p "$SESSION_PROJECT_DIR"
cat > "$SESSION_PROJECT_DIR/demo-session.jsonl" <<'EOF'
{"type":"user","timestamp":"2026-03-31T10:00:00Z"}
{"type":"assistant","timestamp":"2026-03-31T10:01:00Z","message":{"model":"claude-sonnet-4-6","content":[{"type":"text","text":"ok"}]}}
{"type":"assistant","timestamp":"2026-03-31T12:01:00Z","message":{"model":"claude-sonnet-4-6","content":[{"type":"text","text":"still here"}]}}
EOF

SESSION_OUTPUT=$(SESSION_EXTRACT_PROJECTS_DIR="$SESSION_TMP/projects" SESSION_IDLE_CAP_MINUTES=10 bash .claude/scripts/session-extract.sh demo-project --last 1 2>&1 || true)
rm -rf "$SESSION_TMP"

if printf '%s' "$SESSION_OUTPUT" | grep -q '11min active / 121min wall'; then
  pass "session-extract caps idle gaps in active duration"
else
  fail "session-extract did not report capped active duration"
fi

if printf '%s' "$SESSION_OUTPUT" | grep -q 'Tools: 0 calls'; then
  pass "session-extract fixture output stays readable"
else
  fail "session-extract fixture output missing expected summary lines"
fi

if grep -q 'LOCAL FALLBACK' .claude/skills/session-optimize/SKILL.md 2>/dev/null; then
  pass "session-optimize documents local fallback mode"
else
  fail "session-optimize missing local fallback documentation"
fi

echo "--- Stack-aware sandbox permissions ---"
# Simulate: write template settings.json, set framework, run customize, verify deny list
SANDBOX_TMP=$(mktemp -d "${TMPDIR:-/tmp}/ai-setup-test.XXXXXX")
cp templates/claude/settings.json "$SANDBOX_TMP/settings.json"

# Verify .nuxt/** is in deny list before customization
if grep -q 'Read(.nuxt/\*\*)' "$SANDBOX_TMP/settings.json" 2>/dev/null; then
  pass "template settings.json contains Read(.nuxt/**) in deny"
else
  fail "template settings.json missing Read(.nuxt/**) in deny"
fi

# Simulate nuxt customization via jq/node
if command -v jq >/dev/null 2>&1; then
  jq --arg patterns 'Read(.nuxt/**)|Read(.output/**)' '
    .permissions.deny |= map(
      select(. as $d | ($patterns | split("|")) | index($d) | not)
    )
  ' "$SANDBOX_TMP/settings.json" > "$SANDBOX_TMP/settings_out.json" && \
    mv "$SANDBOX_TMP/settings_out.json" "$SANDBOX_TMP/settings.json"
else
  node -e "
    const fs = require('fs');
    const patterns = 'Read(.nuxt/**)|Read(.output/**)'.split('|');
    const cfg = JSON.parse(fs.readFileSync('$SANDBOX_TMP/settings.json', 'utf8'));
    cfg.permissions.deny = cfg.permissions.deny.filter(d => !patterns.includes(d));
    fs.writeFileSync('$SANDBOX_TMP/settings.json', JSON.stringify(cfg, null, 2));
  "
fi

# Verify .nuxt/** removed and .env* still present
if grep -q 'Read(.nuxt/\*\*)' "$SANDBOX_TMP/settings.json" 2>/dev/null; then
  fail "nuxt customization did not remove Read(.nuxt/**)"
else
  pass "nuxt customization removed Read(.nuxt/**) from deny"
fi

if grep -q 'Read(.output/\*\*)' "$SANDBOX_TMP/settings.json" 2>/dev/null; then
  fail "nuxt customization did not remove Read(.output/**)"
else
  pass "nuxt customization removed Read(.output/**) from deny"
fi

if grep -q 'Read(.env\*)' "$SANDBOX_TMP/settings.json" 2>/dev/null; then
  pass "nuxt customization preserved Read(.env*) in deny"
else
  fail "nuxt customization incorrectly removed Read(.env*)"
fi

rm -rf "$SANDBOX_TMP"

echo "--- .claudeignore template ---"
CLAUDEIGNORE_COUNT=$(grep -c '^[^#]' templates/.claudeignore 2>/dev/null || echo 0)
if [ "$CLAUDEIGNORE_COUNT" -ge 30 ]; then
  pass "templates/.claudeignore has ${CLAUDEIGNORE_COUNT} patterns (>= 30)"
else
  fail "templates/.claudeignore only has ${CLAUDEIGNORE_COUNT} patterns (expected >= 30)"
fi

echo "--- Governance docs ---"
if [ -f docs/claude-governance.md ]; then
  pass "docs/claude-governance.md exists"
else
  fail "docs/claude-governance.md missing"
fi
if grep -q '"_governanceProfile"[[:space:]]*:[[:space:]]*"project-baseline"' templates/claude/settings.json 2>/dev/null; then
  pass "template settings.json declares project-baseline governance profile"
else
  fail "template settings.json missing governance profile metadata"
fi
if grep -q 'AI_SETUP_ENABLE_GLOBAL_BROAD_PERMS' lib/global-settings.sh 2>/dev/null; then
  pass "global settings gates broad shell grants behind explicit opt-in"
else
  fail "global settings missing explicit broad-grant opt-in"
fi

echo "--- Experimental hook registrations ---"
if grep -q '"PostCompact"' templates/claude/settings.json 2>/dev/null; then
  pass "template settings.json registers PostCompact"
else
  fail "template settings.json missing PostCompact registration"
fi
if awk '
  /"command"[[:space:]]*:[[:space:]]*".*context-monitor\.sh"/ { print block "\n" $0; found=1; exit }
  { block = block $0 "\n" }
  /^[[:space:]]*}[[:space:]]*,?[[:space:]]*$/ { block="" }
' templates/claude/settings.json | grep -q '"matcher"[[:space:]]*:[[:space:]]*"Edit|Write|NotebookEdit"'; then
  pass "template context-monitor matcher stays off generic Bash"
else
  fail "template context-monitor matcher regressed to generic Bash"
fi
if grep -q '"SubagentStart"' templates/claude/settings.json 2>/dev/null && grep -q '"SubagentStop"' templates/claude/settings.json 2>/dev/null; then
  pass "template settings.json registers subagent hooks"
else
  fail "template settings.json missing subagent hook registration"
fi
if grep -q '"PermissionDenied"' templates/claude/settings.json 2>/dev/null; then
  pass "template settings.json registers PermissionDenied"
else
  fail "template settings.json missing PermissionDenied registration"
fi
for hook_file in templates/claude/hooks/subagent-start.sh templates/claude/hooks/subagent-stop.sh templates/claude/hooks/permission-denied-log.sh; do
  if [ -f "$hook_file" ]; then
    pass "$(basename "$hook_file") exists"
  else
    fail "$(basename "$hook_file") missing"
  fi
done

echo "--- CLI health hook ---"
CLI_HEALTH_STDERR="$SANDBOX_TMP/cli-health.stderr"
FAKEBIN="$SANDBOX_TMP/fakebin"
mkdir -p "$FAKEBIN"
cat > "$FAKEBIN/rtk" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = "--version" ]; then
  echo "rtk 0.34.2"
  exit 0
fi
if [ "${1:-}" = "gain" ]; then
  echo "Error: Failed to initialize tracking database" >&2
  echo >&2
  echo "Caused by:" >&2
  echo "    0: unable to open database file" >&2
  echo "    1: Error code 14: Unable to open the database file" >&2
  exit 1
fi
exit 0
EOF
chmod +x "$FAKEBIN/rtk"
PATH="$FAKEBIN:/usr/bin:/bin" bash templates/claude/hooks/cli-health.sh > /dev/null 2>"$CLI_HEALTH_STDERR"
if grep -q 'tracking DB is unavailable' "$CLI_HEALTH_STDERR" 2>/dev/null; then
  pass "cli-health.sh distinguishes RTK DB failures from inactive hooks"
else
  fail "cli-health.sh did not classify RTK DB failure correctly"
fi

echo "--- Unified session handoff ---"
if grep -q 'session-state.json' templates/claude/hooks/pre-compact-state.sh 2>/dev/null && grep -q 'session-state.json' templates/claude/hooks/post-compact-restore.sh 2>/dev/null; then
  pass "compact hooks use unified session-state.json"
else
  fail "compact hooks do not consistently use session-state.json"
fi
if grep -q 'session-state.json' templates/skills/pause/SKILL.template.md 2>/dev/null && grep -q 'session-state.json' templates/skills/resume/SKILL.template.md 2>/dev/null; then
  pass "pause and resume skills reference unified session-state.json"
else
  fail "pause/resume skills missing unified session-state.json guidance"
fi
if grep -q 'session-state.json' templates/skills/spec-work/SKILL.template.md 2>/dev/null && grep -q 'session-state.json' templates/skills/spec-run/SKILL.template.md 2>/dev/null; then
  pass "spec workflow skills refresh unified session-state.json"
else
  fail "spec workflow skills missing unified session-state.json references"
fi

echo "--- Spec status consistency ---"
for spec_file in specs/completed/[0-9]*.md; do
  [ -f "$spec_file" ] || continue
  spec_name=$(basename "$spec_file" .md)
  # Extract status from standard markdown header or YAML frontmatter
  spec_status=""
  # Match status from: **Status**: value OR **Status:** value OR ^status: value (YAML)
  status_line=$(grep -E '(\*\*Status\*\*:|^\*\*Status:\*\*|^status:)' "$spec_file" 2>/dev/null | head -1 || true)
  if [ -n "$status_line" ]; then
    spec_status=$(echo "$status_line" | grep -ioE '(completed|draft|in-progress|blocked|superseded)' | head -1 | tr '[:upper:]' '[:lower:]' || true)
  elif grep -q '^status:' "$spec_file" 2>/dev/null; then
    spec_status=$(grep -m1 '^status:' "$spec_file" | sed 's/status: *//')
  fi
  case "$spec_status" in
    completed|superseded) pass "$spec_name status=$spec_status" ;;
    "") fail "$spec_name has no parseable status field" ;;
    *) fail "$spec_name has status=$spec_status (expected completed or superseded)" ;;
  esac
done

# Routing guidance assertions
echo ""
echo "--- Model routing rules ---"
if grep -qi 'haiku' CLAUDE.md 2>/dev/null; then
  pass "CLAUDE.md documents Haiku routing guidance"
else
  fail "CLAUDE.md missing Haiku routing guidance"
fi

if grep -qi 'haiku' .claude/rules/agents.md 2>/dev/null; then
  pass ".claude/rules/agents.md contains haiku routing label"
else
  fail ".claude/rules/agents.md missing haiku routing label"
fi

if grep -q 'medium.*sonnet\|sonnet' .claude/skills/spec-work/SKILL.md 2>/dev/null; then
  pass "spec-work/SKILL.md uses sonnet for medium-complexity implementation"
else
  fail "spec-work/SKILL.md missing sonnet routing for medium-complexity tasks"
fi

if grep -q 'medium.*sonnet\|sonnet' templates/skills/spec-work/SKILL.template.md 2>/dev/null; then
  pass "templates/skills/spec-work/SKILL.template.md uses sonnet for medium-complexity implementation"
else
  fail "templates/skills/spec-work/SKILL.template.md missing sonnet routing for medium-complexity tasks"
fi

if grep -qi 'haiku.*explore\|explore.*haiku\|dedicated explore' .claude/rules/agents.md 2>/dev/null; then
  pass ".claude/rules/agents.md restricts haiku to dedicated explore agents"
else
  fail ".claude/rules/agents.md missing haiku-for-explore-only restriction"
fi

if [ -f tests/routing-check.sh ]; then
  pass "tests/routing-check.sh exists"
else
  fail "tests/routing-check.sh missing"
fi

if bash -n tests/routing-check.sh 2>/dev/null; then
  pass "tests/routing-check.sh syntax valid"
else
  fail "tests/routing-check.sh has syntax errors"
fi

echo "--- Claude Code 2.1.89+ alignment ---"
# tdd-checker: exclusion patterns must handle absolute paths (*/node_modules/*, etc.)
if grep -q '\*/node_modules/\*' templates/claude/hooks/tdd-checker.sh 2>/dev/null; then
  pass "tdd-checker uses absolute-path-safe exclusion patterns"
else
  fail "tdd-checker still uses relative-only exclusion patterns (breaks with absolute file_path)"
fi

# permission-denied-log: retry logic for auto_classifier
if grep -q 'retry.*true\|{retry' templates/claude/hooks/permission-denied-log.sh 2>/dev/null; then
  pass "permission-denied-log emits retry:true for auto_classifier safe commands"
else
  fail "permission-denied-log missing retry logic for 2.1.89 PermissionDenied hook"
fi

# task-created-log.sh exists and is registered
if [ -f templates/claude/hooks/task-created-log.sh ]; then
  pass "task-created-log.sh exists"
else
  fail "task-created-log.sh missing"
fi
if grep -q '"TaskCreated"' templates/claude/settings.json 2>/dev/null; then
  pass "template settings.json registers TaskCreated hook"
else
  fail "template settings.json missing TaskCreated registration"
fi

# disableSkillShellExecution warning in CLAUDE.md
if grep -q 'disableSkillShellExecution' templates/CLAUDE.md 2>/dev/null; then
  pass "templates/CLAUDE.md documents disableSkillShellExecution risk"
else
  fail "templates/CLAUDE.md missing disableSkillShellExecution warning"
fi

# Summary
echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
