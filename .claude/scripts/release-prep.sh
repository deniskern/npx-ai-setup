#!/usr/bin/env bash
# release-prep.sh — Pre-flight data for /release Phase 1
# Collects: dirty state, verify:release output, last tag, commits, changelog, version
# Zero LLM tokens on green path (all data pre-collected)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/prep-lib.sh"

git_guard

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
section() { printf "\n=== %s ===\n\n" "$1"; }

# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")"
printf "RELEASE_PREP_START %s\n" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf "Branch: %s\n" "$BRANCH"

# ---------------------------------------------------------------------------
# 1. Dirty state check
# ---------------------------------------------------------------------------
section "DIRTY STATE"
UNCOMMITTED="$(git status --porcelain 2>/dev/null || true)"
STAGED="$(git diff --cached --name-only 2>/dev/null || true)"

if [[ -n "$UNCOMMITTED" ]]; then
  printf "UNCOMMITTED_CHANGES\n%s\n" "$UNCOMMITTED"
else
  printf "CLEAN\n"
fi

if [[ -n "$STAGED" ]]; then
  printf "\nSTAGED_FILES\n%s\n" "$STAGED"
fi

# ---------------------------------------------------------------------------
# 2. verify:release output
# ---------------------------------------------------------------------------
section "VERIFY RELEASE"
if grep -q '"verify:release"' package.json 2>/dev/null; then
  VERIFY_OUTPUT="$(npm run verify:release 2>&1)" && VERIFY_EXIT=0 || VERIFY_EXIT=$?
  printf "exit_code: %s\n" "$VERIFY_EXIT"
  printf "%s\n" "$VERIFY_OUTPUT"
else
  printf "SKIP — no verify:release script in package.json\n"
  VERIFY_EXIT=0
fi

# ---------------------------------------------------------------------------
# 3. Last tag + commits since
# ---------------------------------------------------------------------------
section "VERSION INFO"
LAST_TAG="$(git describe --tags --abbrev=0 2>/dev/null || echo "")"
PKG_VERSION="$(node -p "require('./package.json').version" 2>/dev/null || echo "unknown")"

printf "package.json version: %s\n" "$PKG_VERSION"
printf "last git tag: %s\n" "${LAST_TAG:-"(none)"}"

section "COMMITS SINCE LAST TAG"
if [[ -n "$LAST_TAG" ]]; then
  rtk_or_raw git log --oneline "${LAST_TAG}..HEAD" 2>/dev/null || echo "(no new commits)"
else
  rtk_or_raw git log --oneline -20 2>/dev/null || echo "(no commits)"
fi

# ---------------------------------------------------------------------------
# 4. CHANGELOG [Unreleased] section
# ---------------------------------------------------------------------------
section "CHANGELOG UNRELEASED"
if [[ -f "CHANGELOG.md" ]]; then
  # Extract everything between [Unreleased] and the next version heading
  awk '/^## \[Unreleased\]/{found=1; next} found && /^## \[/{exit} found{print}' CHANGELOG.md
  UNRELEASED_LINES="$(awk '/^## \[Unreleased\]/{found=1; next} found && /^## \[/{exit} found && /\S/{count++} END{print count+0}' CHANGELOG.md)"
  printf "\n(%s non-empty lines in [Unreleased])\n" "$UNRELEASED_LINES"
else
  printf "NO CHANGELOG.md found\n"
fi

# ---------------------------------------------------------------------------
# 5. Quick inventory counts (for Phase 2 cross-check)
# ---------------------------------------------------------------------------
section "INVENTORY COUNTS"
count_dir() {
  local dir="$1" label="$2"
  if [[ -d "$dir" ]]; then
    local n
    n="$(find "$dir" -maxdepth 1 -type f -o -type l 2>/dev/null | wc -l | tr -d ' ')"
    printf "%-20s %s\n" "$label" "$n"
  else
    printf "%-20s %s\n" "$label" "0 (dir missing)"
  fi
}

count_dir ".claude/commands" "commands:"
count_dir ".claude/skills" "skills (dirs):"
count_dir ".claude/rules" "rules:"
# Hooks from settings.json
if [[ -f ".claude/settings.json" ]]; then
  HOOK_COUNT="$(python3 -c "
import json
d = json.load(open('.claude/settings.json'))
hooks = d.get('hooks', {})
print(sum(len(v) if isinstance(v, list) else 1 for v in hooks.values()))
" 2>/dev/null || echo "?")"
  printf "%-20s %s\n" "hooks:" "$HOOK_COUNT"
fi

# ---------------------------------------------------------------------------
# 6. WORKFLOW-GUIDE.md coverage check
# ---------------------------------------------------------------------------
section "WORKFLOW-GUIDE COVERAGE"
GUIDE_FILE="WORKFLOW-GUIDE.md"
SKILLS_DIR=".claude/skills"
MISSING_FROM_GUIDE=()

if [[ -f "$GUIDE_FILE" && -d "$SKILLS_DIR" ]]; then
  while IFS= read -r skill_dir; do
    skill_name="$(basename "$skill_dir")"
    # Skip non-user-facing utility skills
    if [[ "$skill_name" == "skill-creator-workspace" ]]; then
      continue
    fi
    in_guide=0
    grep -qF "/$skill_name" "$GUIDE_FILE" 2>/dev/null && in_guide=1
    grep -qF "\"$skill_name\"" "$GUIDE_FILE" 2>/dev/null && in_guide=1
    if [[ "$in_guide" -eq 0 ]]; then
      MISSING_FROM_GUIDE+=("$skill_name")
    fi
  done < <(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d | sort)

  if [[ "${#MISSING_FROM_GUIDE[@]}" -eq 0 ]]; then
    printf "GUIDE_COVERAGE: OK — all skills mentioned in WORKFLOW-GUIDE.md\n"
  else
    printf "GUIDE_COVERAGE: WARN — %d skill(s) missing from WORKFLOW-GUIDE.md:\n" "${#MISSING_FROM_GUIDE[@]}"
    for s in "${MISSING_FROM_GUIDE[@]}"; do
      printf "  - %s\n" "$s"
    done
    printf "\nAction: Update WORKFLOW-GUIDE.md (and templates/WORKFLOW-GUIDE.md) before releasing.\n"
  fi
else
  printf "GUIDE_COVERAGE: SKIP — %s or %s not found\n" "$GUIDE_FILE" "$SKILLS_DIR"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
section "SUMMARY FOR CLAUDE"
printf "Branch: %s\n" "$BRANCH"
printf "Version: %s → next release\n" "$PKG_VERSION"
printf "Last tag: %s\n" "${LAST_TAG:-"(none)"}"
printf "Dirty: %s\n" "$([[ -n "$UNCOMMITTED" ]] && echo "YES — abort" || echo "clean")"
printf "Verify: %s\n" "$([[ "$VERIFY_EXIT" -eq 0 ]] && echo "PASS" || echo "FAIL (exit $VERIFY_EXIT)")"
printf "\nUse this data for Phase 1 decisions. Do NOT re-run git status, verify:release, or read CHANGELOG.\n"
printf "\nRELEASE_PREP_END\n"
