#!/usr/bin/env bash
# review-prep.sh — Pre-collect diff data and duplicate findings for /review
# Usage: bash .claude/scripts/review-prep.sh
# Requires: bash 3.2+, git
set -euo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
section() { printf "\n## %s\n\n" "$1"; }
hr()      { printf '%s\n' "---"; }

# ---------------------------------------------------------------------------
# 1. Header
# ---------------------------------------------------------------------------
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

printf "# Review Prep Report\n"
printf "Branch: \`%s\`  |  Generated: %s\n" "$BRANCH" "$TIMESTAMP"
hr

# ---------------------------------------------------------------------------
# 2. Changed files
# ---------------------------------------------------------------------------
section "Changed Files"

STAGED_FILES="$(git diff --cached --name-only 2>/dev/null || true)"
UNSTAGED_FILES="$(git diff --name-only 2>/dev/null || true)"

# Combine and deduplicate
ALL_CHANGED="$(printf '%s\n%s\n' "$STAGED_FILES" "$UNSTAGED_FILES" \
  | grep -v '^$' | sort -u || true)"

if [ -z "$ALL_CHANGED" ]; then
  printf "No changed files found (working tree clean, nothing staged).\n"
else
  CHANGED_COUNT="$(printf '%s\n' "$ALL_CHANGED" | wc -l | tr -d ' ')"
  printf "%s file(s) changed:\n\n" "$CHANGED_COUNT"
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    if printf '%s\n' "$STAGED_FILES" | grep -qxF "$f" 2>/dev/null; then
      printf '%s\n' "- \`${f}\` (staged)"
    else
      printf '%s\n' "- \`${f}\` (unstaged)"
    fi
  done <<< "$ALL_CHANGED"
fi

# ---------------------------------------------------------------------------
# 3. Diff statistics
# ---------------------------------------------------------------------------
section "Diff Statistics"

STAGED_STAT="$(git diff --cached --stat 2>/dev/null || true)"
UNSTAGED_STAT="$(git diff --stat 2>/dev/null || true)"
BRANCH_STAT="$(git diff main...HEAD --stat 2>/dev/null || git diff origin/main...HEAD --stat 2>/dev/null || true)"

if [ -n "$STAGED_STAT" ]; then
  printf "### Staged\n\`\`\`\n%s\n\`\`\`\n\n" "$STAGED_STAT"
else
  printf "### Staged\nNothing staged.\n\n"
fi

if [ -n "$UNSTAGED_STAT" ]; then
  printf "### Unstaged\n\`\`\`\n%s\n\`\`\`\n\n" "$UNSTAGED_STAT"
else
  printf "### Unstaged\nNothing unstaged.\n\n"
fi

if [ -n "$BRANCH_STAT" ]; then
  printf "### Branch vs main\n\`\`\`\n%s\n\`\`\`\n\n" "$BRANCH_STAT"
else
  printf "### Branch vs main\nNo diff vs main (or main not reachable).\n\n"
fi

# ---------------------------------------------------------------------------
# 4. Full diffs (staged + unstaged)
# ---------------------------------------------------------------------------
section "Full Diff (Staged)"
STAGED_DIFF="$(git diff --cached 2>/dev/null || true)"
if [ -n "$STAGED_DIFF" ]; then
  printf "\`\`\`diff\n%s\n\`\`\`\n" "$STAGED_DIFF"
else
  printf "Nothing staged.\n"
fi

section "Full Diff (Unstaged)"
UNSTAGED_DIFF="$(git diff 2>/dev/null || true)"
if [ -n "$UNSTAGED_DIFF" ]; then
  printf "\`\`\`diff\n%s\n\`\`\`\n" "$UNSTAGED_DIFF"
else
  printf "Nothing unstaged.\n"
fi

# ---------------------------------------------------------------------------
# 5. Duplicate / similar pattern detection
# ---------------------------------------------------------------------------
section "Duplicate Pattern Detection"

if [ -z "$ALL_CHANGED" ]; then
  printf "No changed files — duplicate scan skipped.\n"
else
  DUPE_FINDINGS=""

  while IFS= read -r file; do
    [ -z "$file" ] && continue
    [ ! -f "$file" ] && continue

    # Extract function/method definitions from the changed file
    # Supports: bash functions, JS/TS functions, Python defs
    FUNC_NAMES="$(grep -E \
      '^\s*(function [a-zA-Z_][a-zA-Z0-9_]*|[a-zA-Z_][a-zA-Z0-9_]*\s*\(\s*\)\s*\{|def [a-zA-Z_][a-zA-Z0-9_]*|const [a-zA-Z_][a-zA-Z0-9_]* = (function|\()|(export )?(async )?function [a-zA-Z_][a-zA-Z0-9_]*)' \
      "$file" 2>/dev/null \
      | grep -oE '(function |def )[a-zA-Z_][a-zA-Z0-9_]*|[a-zA-Z_][a-zA-Z0-9_]*\s*\(' \
      | grep -oE '[a-zA-Z_][a-zA-Z0-9_]+' \
      | sort -u || true)"

    if [ -z "$FUNC_NAMES" ]; then
      continue
    fi

    while IFS= read -r fname; do
      [ -z "$fname" ] && continue
      # Skip very short or generic names
      [ "${#fname}" -lt 4 ] && continue

      # Search for this name in the codebase (excluding the file itself and build dirs)
      MATCHES="$(git grep -l --word-regexp "$fname" -- \
        ':!dist/' ':!.output/' ':!node_modules/' ':!*.min.js' \
        2>/dev/null \
        | grep -vxF "$file" || true)"

      if [ -n "$MATCHES" ]; then
        MATCH_COUNT="$(printf '%s\n' "$MATCHES" | wc -l | tr -d ' ')"
        DUPE_FINDINGS="${DUPE_FINDINGS}- \`${fname}\` (defined in \`${file}\`) also found in ${MATCH_COUNT} other file(s):\n"
        while IFS= read -r m; do
          [ -z "$m" ] && continue
          LINE="$(git grep -n --word-regexp "$fname" "$m" 2>/dev/null | head -3 | tr '\n' ' ' || true)"
          DUPE_FINDINGS="${DUPE_FINDINGS}  - \`${m}\`: ${LINE}\n"
        done <<< "$MATCHES"
      fi
    done <<< "$FUNC_NAMES"
  done <<< "$ALL_CHANGED"

  if [ -n "$DUPE_FINDINGS" ]; then
    printf "The following names from changed files also appear elsewhere — verify these are not accidental duplicates:\n\n"
    printf '%b' "$DUPE_FINDINGS"
  else
    printf "No duplicate function/pattern names detected across changed files.\n"
  fi
fi

# ---------------------------------------------------------------------------
# 6. Summary
# ---------------------------------------------------------------------------
section "Summary for Claude"

STAGED_COUNT="$(printf '%s\n' "$STAGED_FILES" | grep -c '.' 2>/dev/null || echo 0)"
UNSTAGED_COUNT="$(printf '%s\n' "$UNSTAGED_FILES" | grep -c '.' 2>/dev/null || echo 0)"

printf "- Staged files: %s\n" "$STAGED_COUNT"
printf "- Unstaged files: %s\n" "$UNSTAGED_COUNT"
printf "- Branch: \`%s\`\n" "$BRANCH"
printf "\nUse the diffs and duplicate findings above as focused input for your review.\n"
printf "Do NOT re-run git diff — all data is already captured above.\n"
