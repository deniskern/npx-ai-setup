#!/usr/bin/env bash
# changelog-prep.sh — parse conventional commits since last tag, group by type
# Exits 0 with "NO_NEW_COMMITS" if HEAD == last tag; exits 0 with grouped output otherwise
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/prep-lib.sh"

git_guard

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
section() { printf "\n=== %s ===\n" "$1"; }

# ---------------------------------------------------------------------------
# Get last tag
# ---------------------------------------------------------------------------
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

if [[ -z "$LAST_TAG" ]]; then
  echo "CHANGELOG_PREP_START $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "NOTE: No tags found — showing all commits"
  COMMITS=$(git log --oneline 2>/dev/null || echo "(no commits)")
  LAST_TAG="(none)"
else
  # Green path: nothing new since last tag
  HEAD_SHA=$(git rev-parse HEAD 2>/dev/null)
  TAG_SHA=$(git rev-parse "${LAST_TAG}^{}" 2>/dev/null || git rev-parse "${LAST_TAG}" 2>/dev/null)

  if [[ "$HEAD_SHA" == "$TAG_SHA" ]]; then
    echo "NO_NEW_COMMITS"
    exit 0
  fi

  COMMITS=$(git log "${LAST_TAG}..HEAD" --oneline 2>/dev/null || echo "")

  if [[ -z "$COMMITS" ]]; then
    echo "NO_NEW_COMMITS"
    exit 0
  fi

  echo "CHANGELOG_PREP_START $(date -u +%Y-%m-%dT%H:%M:%SZ)"
fi

echo "LAST_TAG: ${LAST_TAG}"
echo "HEAD: $(git rev-parse --abbrev-ref HEAD)"
echo ""

# ---------------------------------------------------------------------------
# Group by conventional commit type
# ---------------------------------------------------------------------------
BREAKING=""
FEATS=""
FIXES=""
REFACTORS=""
OTHERS=""

while IFS= read -r line; do
  [[ -z "$line" ]] && continue

  # Check for BREAKING CHANGE (full commit body check)
  SHA=$(echo "$line" | awk '{print $1}')
  BODY=$(git log -1 --format='%b' "$SHA" 2>/dev/null || true)

  if echo "$BODY" | grep -q "BREAKING CHANGE" 2>/dev/null || echo "$line" | grep -qE '^[a-f0-9]+ [a-z]+(\([^)]+\))?!:' 2>/dev/null; then
    BREAKING="${BREAKING}  ${line}\n"
  elif echo "$line" | grep -qE '^[a-f0-9]+ feat(\([^)]+\))?:'; then
    FEATS="${FEATS}  ${line}\n"
  elif echo "$line" | grep -qE '^[a-f0-9]+ fix(\([^)]+\))?:'; then
    FIXES="${FIXES}  ${line}\n"
  elif echo "$line" | grep -qE '^[a-f0-9]+ refactor(\([^)]+\))?:'; then
    REFACTORS="${REFACTORS}  ${line}\n"
  else
    OTHERS="${OTHERS}  ${line}\n"
  fi
done <<< "$COMMITS"

# Counts
BREAKING_COUNT=$(printf '%b' "$BREAKING" | grep -c '.' 2>/dev/null || echo 0)
FEAT_COUNT=$(printf '%b' "$FEATS" | grep -c '.' 2>/dev/null || echo 0)
FIX_COUNT=$(printf '%b' "$FIXES" | grep -c '.' 2>/dev/null || echo 0)
REFACTOR_COUNT=$(printf '%b' "$REFACTORS" | grep -c '.' 2>/dev/null || echo 0)
OTHER_COUNT=$(printf '%b' "$OTHERS" | grep -c '.' 2>/dev/null || echo 0)
TOTAL=$((BREAKING_COUNT + FEAT_COUNT + FIX_COUNT + REFACTOR_COUNT + OTHER_COUNT))

section "SUMMARY"
echo "Total commits since ${LAST_TAG}: ${TOTAL}"
echo "  breaking: ${BREAKING_COUNT}"
echo "  feat:     ${FEAT_COUNT}"
echo "  fix:      ${FIX_COUNT}"
echo "  refactor: ${REFACTOR_COUNT}"
echo "  other:    ${OTHER_COUNT}"

if [[ -n "$BREAKING" ]]; then
  section "BREAKING CHANGES (${BREAKING_COUNT})"
  printf '%b' "$BREAKING"
fi

if [[ -n "$FEATS" ]]; then
  section "FEATURES (${FEAT_COUNT})"
  printf '%b' "$FEATS"
fi

if [[ -n "$FIXES" ]]; then
  section "BUG FIXES (${FIX_COUNT})"
  printf '%b' "$FIXES"
fi

if [[ -n "$REFACTORS" ]]; then
  section "REFACTORS (${REFACTOR_COUNT})"
  printf '%b' "$REFACTORS"
fi

if [[ -n "$OTHERS" ]]; then
  section "OTHER (${OTHER_COUNT})"
  printf '%b' "$OTHERS"
fi

printf "\nCHANGELOG_PREP_END\n"
