#!/usr/bin/env bash
# prep-lib.sh — shared helpers for all prep-scripts
# Source this at the top of every *-prep.sh script:
#   SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
#   source "$SCRIPT_DIR/prep-lib.sh"
#
# CONVENTIONS for prep-scripts:
#   - Exit 0: success / green path (e.g. ALL_TESTS_PASSED, NO_STAGED_CHANGES)
#   - Exit 1: error / missing prerequisites
#   - Exit 2: found issues requiring Claude analysis
#   - Every prep-script MUST have a green-path early-exit when there is nothing to do
#   - Use rtk_or_raw for all git/test/lint commands (transparent RTK compression)
#   - Use git_guard at the top if the script requires a git repo

# ---------------------------------------------------------------------------
# has — check if a command exists
# ---------------------------------------------------------------------------
has() { command -v "$1" >/dev/null 2>&1; }

# ---------------------------------------------------------------------------
# rtk_or_raw — run command through rtk if available, raw otherwise
# Usage: rtk_or_raw git status
#        rtk_or_raw npm test
# ---------------------------------------------------------------------------
rtk_or_raw() {
  if has rtk; then
    rtk "$@"
  else
    "$@"
  fi
}

# ---------------------------------------------------------------------------
# git_guard — abort if not inside a git repository
# ---------------------------------------------------------------------------
git_guard() {
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "ERROR: Not inside a git repository" >&2
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# main_branch — detect the main branch name (main or master)
# ---------------------------------------------------------------------------
main_branch() {
  if git rev-parse --verify main >/dev/null 2>&1; then
    echo "main"
  elif git rev-parse --verify master >/dev/null 2>&1; then
    echo "master"
  else
    echo "main"
  fi
}
