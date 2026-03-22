#!/usr/bin/env bash
# commit-prep.sh — collect git context for commit message generation, zero LLM tokens
# Outputs structured context block to stdout; exits 0 on success
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/prep-lib.sh"

git_guard

# ---------------------------------------------------------------------------
# Collect context (rtk compresses git output when available)
# ---------------------------------------------------------------------------
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
STAGED_DIFF=$(rtk_or_raw git diff --staged 2>/dev/null || true)
RECENT_LOG=$(rtk_or_raw git log --oneline -5 2>/dev/null || echo "(no commits yet)")
UNSTAGED_SUMMARY=$(rtk_or_raw git diff --stat 2>/dev/null || true)
STAGED_STAT=$(rtk_or_raw git diff --staged --stat 2>/dev/null || true)

# ---------------------------------------------------------------------------
# Guard: nothing staged
# ---------------------------------------------------------------------------
if [[ -z "$STAGED_DIFF" ]]; then
  echo "NO_STAGED_CHANGES"
  exit 0
fi

# ---------------------------------------------------------------------------
# Emit structured context block
# ---------------------------------------------------------------------------
cat <<EOF
COMMIT_PREP_START $(date -u +%Y-%m-%dT%H:%M:%SZ)

=== BRANCH ===
$BRANCH

=== STAGED FILES (stat) ===
${STAGED_STAT:-"(none)"}

=== RECENT COMMITS (last 5) ===
$RECENT_LOG

=== UNSTAGED CHANGES (stat only) ===
${UNSTAGED_SUMMARY:-"(none)"}

=== STAGED DIFF ===
$STAGED_DIFF

COMMIT_PREP_END
EOF
