#!/usr/bin/env bash
# pr-prep.sh — collect PR context: branch, commits, diff, CI status, linked issues
# Always outputs structured context block to stdout; exits 0 on success
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/prep-lib.sh"

git_guard

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
section() { printf "\n=== %s ===\n" "$1"; }

# ---------------------------------------------------------------------------
# Collect context
# ---------------------------------------------------------------------------
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
MAIN=$(main_branch)

# Commits ahead of main
COMMITS=$(rtk_or_raw git log "${MAIN}..HEAD" --oneline 2>/dev/null || echo "(no commits ahead of ${MAIN})")

# Diff stat vs main
DIFF_STAT=$(rtk_or_raw git diff "${MAIN}...HEAD" --stat 2>/dev/null || echo "(no diff)")

# Full diff vs main (rtk compresses if available)
FULL_DIFF=$(rtk_or_raw git diff "${MAIN}...HEAD" 2>/dev/null || echo "(no diff)")

# Linked issues: scan commit messages for #NNN, fixes #NNN, closes #NNN
ISSUE_REFS=$(rtk_or_raw git log "${MAIN}..HEAD" --format='%s %b' 2>/dev/null \
  | grep -oiE '(fixes|closes|resolves|refs?|#)\s*#?[0-9]+' \
  | grep -oE '#?[0-9]+' \
  | sort -u \
  | sed 's/^#//' \
  | awk '{print "#"$0}' \
  || true)

# CI status via gh CLI (if available)
CI_STATUS=""
if has gh; then
  CI_STATUS=$(gh run list --branch "$BRANCH" --limit 3 2>/dev/null || echo "(gh run list failed or no CI runs)")
fi

# ---------------------------------------------------------------------------
# Emit structured context block
# ---------------------------------------------------------------------------
printf "PR_PREP_START %s\n" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

section "BRANCH"
echo "$BRANCH"

section "BASE BRANCH"
echo "$MAIN"

section "COMMITS AHEAD OF ${MAIN}"
echo "$COMMITS"

section "DIFF STAT vs ${MAIN}"
echo "$DIFF_STAT"

section "LINKED ISSUES"
if [[ -n "$ISSUE_REFS" ]]; then
  echo "$ISSUE_REFS"
else
  echo "(none detected — checked for: fixes/closes/resolves/refs #NNN)"
fi

if [[ -n "$CI_STATUS" ]]; then
  section "CI STATUS (last 3 runs)"
  echo "$CI_STATUS"
fi

section "FULL DIFF vs ${MAIN}"
echo "$FULL_DIFF"

printf "\nPR_PREP_END\n"
