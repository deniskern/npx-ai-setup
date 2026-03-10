#!/usr/bin/env bash
# Smoke test for bin/ai-setup.sh and lib/ modules
# Checks syntax and key function presence — does NOT execute the script interactively.

set -euo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "=== Smoke test: modular ai-setup ==="

# Step 1: Verify all lib modules exist
echo ""
echo "--- Module existence ---"
MODULES=("_loader.sh" "core.sh" "process.sh" "detect.sh" "tui.sh" "skills.sh" "generate.sh" "update.sh" "setup.sh" "plugins.sh")
for mod in "${MODULES[@]}"; do
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

for mod in "${MODULES[@]}"; do
  if [ -f "lib/$mod" ]; then
    if bash -n "lib/$mod" 2>&1; then
      pass "lib/$mod syntax"
    else
      fail "lib/$mod syntax"
    fi
  fi
done

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
  "detect.sh:detect_system"
  "detect.sh:should_update_template"
  "tui.sh:select_system"
  "tui.sh:ask_regen_parts"
  "tui.sh:ask_update_parts"
  "skills.sh:search_skills"
  "skills.sh:get_keyword_skills"
  "skills.sh:install_skill"
  "generate.sh:run_generation"
  "update.sh:show_cli_update_notice"
  "update.sh:handle_version_check"
  "update.sh:run_smart_update"
  "update.sh:run_clean_reinstall"
  "setup.sh:check_requirements"
  "setup.sh:cleanup_legacy"
  "setup.sh:install_hooks"
  "setup.sh:install_workflow_guide"
  "setup.sh:install_commands"
  "setup.sh:install_spec_skills"
  "setup.sh:install_agents"
  "setup.sh:repair_canonical_skill_links"
  "setup.sh:ensure_skills_alias"
  "setup.sh:ensure_codex_skills_alias"
  "setup.sh:ensure_opencode_skills_alias"
  "setup.sh:setup_repo_group_context"
  "setup.sh:update_gitignore"
  "plugins.sh:install_gsd"
  "plugins.sh:install_claude_mem"
  "plugins.sh:install_coderabbit_plugin"
  "plugins.sh:install_context7"
  "plugins.sh:install_playwright"
  "plugins.sh:show_installation_summary"
  "plugins.sh:show_next_steps"
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
for mod in "${MODULES[@]}"; do
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

# Step 6: Verify update-check hook is wired for startup and prompt submit
echo ""
echo "--- Hook wiring checks ---"
if awk '/"SessionStart"[[:space:]]*:[[:space:]]*\[/,/^[[:space:]]*\],?$/' templates/claude/settings.json | grep -q 'update-check.sh'; then
  pass "templates/claude/settings.json wires update-check.sh on SessionStart"
else
  fail "templates/claude/settings.json missing SessionStart update-check.sh hook"
fi

if awk '/"SessionStart"[[:space:]]*:[[:space:]]*\[/,/^[[:space:]]*\],?$/' templates/claude/settings.json | grep -q 'cross-repo-context.sh'; then
  pass "templates/claude/settings.json wires cross-repo-context.sh on SessionStart"
else
  fail "templates/claude/settings.json missing SessionStart cross-repo-context.sh hook"
fi

if grep -q 'repo-group.json' templates/claude/hooks/cross-repo-context.sh 2>/dev/null; then
  pass "cross-repo-context hook supports repo-group.json map"
else
  fail "cross-repo-context hook missing repo-group.json map support"
fi

if awk '/"UserPromptSubmit"[[:space:]]*:[[:space:]]*\[/,/^[[:space:]]*\],?$/' templates/claude/settings.json | grep -q 'update-check.sh'; then
  pass "templates/claude/settings.json wires update-check.sh on UserPromptSubmit"
else
  fail "templates/claude/settings.json missing UserPromptSubmit update-check.sh hook"
fi

# Step 7: Verify skills alias migration is wired in both setup and update paths
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

if grep -q 'install_spec_skills' lib/update.sh 2>/dev/null; then
  pass "lib/update.sh installs spec workflow skills during smart update"
else
  fail "lib/update.sh missing install_spec_skills call"
fi

if grep -q 'repair_canonical_skill_links' lib/setup.sh 2>/dev/null; then
  pass "lib/setup.sh contains looping skill-link repair helper"
else
  fail "lib/setup.sh missing looping skill-link repair helper"
fi

if grep -Eq 'repair_canonical_skill_links .*\$canonical.*\$canonical_abs' lib/setup.sh 2>/dev/null; then
  pass "ensure_skills_alias invokes looping skill-link repair"
else
  fail "ensure_skills_alias missing looping skill-link repair call"
fi

# Summary
echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
