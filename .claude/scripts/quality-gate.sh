#!/usr/bin/env bash
# quality-gate.sh — local quality check, zero tokens on green
# Runs bash -n syntax check + shellcheck on changed .sh files, then smoke tests.
# Exits 0 with "QUALITY_GATE_PASSED" on green.
# Exits 2 with filtered failure output on red — Claude only sees this on failure.
#
# Usage:
#   ! bash .claude/scripts/quality-gate.sh        # zero-token green path
#   bash .claude/scripts/quality-gate.sh          # manual check
set -euo pipefail

PASS=1
ERRORS=""

append_error() {
  ERRORS="${ERRORS}\n$1"
  PASS=0
}

# ── Determine files to check ────────────────────────────────────────────────
# Changed files since HEAD; fall back to all .sh files if not in a git repo
if command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1; then
  CHANGED_SH=$(git diff --name-only HEAD 2>/dev/null | grep '\.sh$' || true)
  STAGED_SH=$(git diff --name-only --cached 2>/dev/null | grep '\.sh$' || true)
  SH_FILES=$(printf '%s\n%s\n' "$CHANGED_SH" "$STAGED_SH" | sort -u | grep -v '^$' || true)
else
  SH_FILES=$(find . -name '*.sh' -not -path './.git/*' 2>/dev/null || true)
fi

# ── bash -n syntax check ────────────────────────────────────────────────────
while IFS= read -r f; do
  [ -z "$f" ] && continue
  [ -f "$f" ] || continue
  if ! OUT=$(bash -n "$f" 2>&1); then
    append_error "SYNTAX ERROR ($f):\n$OUT"
  fi
done <<< "$SH_FILES"

# ── shellcheck ──────────────────────────────────────────────────────────────
if command -v shellcheck >/dev/null 2>&1 && [ -n "$SH_FILES" ]; then
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    [ -f "$f" ] || continue
    if ! OUT=$(shellcheck "$f" 2>&1); then
      # Filter to first 30 lines per file to stay token-efficient
      append_error "SHELLCHECK ($f):\n$(echo "$OUT" | head -30)"
    fi
  done <<< "$SH_FILES"
fi

# ── Smoke tests ─────────────────────────────────────────────────────────────
if [ -f "tests/smoke.sh" ]; then
  if ! SMOKE_OUT=$(bash tests/smoke.sh 2>&1); then
    append_error "SMOKE TESTS FAILED:\n$(echo "$SMOKE_OUT" | tail -40)"
  fi
fi

# ── Result ──────────────────────────────────────────────────────────────────
if [ "$PASS" -eq 1 ]; then
  echo "QUALITY_GATE_PASSED"
  exit 0
fi

printf "=== QUALITY GATE FAILURES ===%b\n" "$ERRORS"
exit 2
