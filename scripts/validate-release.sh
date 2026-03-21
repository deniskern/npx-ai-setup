#!/usr/bin/env bash
# validate-release.sh — pre-release sanity checks
# Exit 0: all checks pass. Exit 1: first failure, details printed.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS="[PASS]"
FAIL="[FAIL]"
ERRORS=0

_pass() { printf '%s %s\n' "$PASS" "$1"; }
_fail() { printf '%s %s\n' "$FAIL" "$1" >&2; ERRORS=$(( ERRORS + 1 )); }

# ── 1. Extract current version from package.json ─────────────────────────────
VERSION=""
if command -v jq >/dev/null 2>&1; then
    VERSION="$(jq -r '.version' "${REPO_ROOT}/package.json")"
else
    VERSION="$(grep -m1 '"version"' "${REPO_ROOT}/package.json" | sed 's/.*"version":[[:space:]]*"\([^"]*\)".*/\1/')"
fi

if [ -z "$VERSION" ]; then
    _fail "Could not extract version from package.json"
    exit 1
fi
_pass "Version extracted from package.json: $VERSION"

# ── 2. CHANGELOG.md has entry for current version ────────────────────────────
CHANGELOG="${REPO_ROOT}/CHANGELOG.md"
if grep -qF "## [v${VERSION}]" "$CHANGELOG" || grep -qF "## [${VERSION}]" "$CHANGELOG"; then
    _pass "CHANGELOG.md has entry for v${VERSION}"
else
    _fail "CHANGELOG.md has no entry for v${VERSION} (expected '## [v${VERSION}]' or '## [${VERSION}]')"
fi

# ── 3. No uncommitted changes ─────────────────────────────────────────────────
if [ -z "$(git -C "${REPO_ROOT}" status --porcelain)" ]; then
    _pass "Working tree is clean (no uncommitted changes)"
else
    _fail "Uncommitted changes detected — commit or stash before releasing"
    git -C "${REPO_ROOT}" status --short >&2
fi

# ── 4. Template integrity — no empty files ───────────────────────────────────
TEMPLATES_DIR="${REPO_ROOT}/templates"
EMPTY_FILES="$(find "${TEMPLATES_DIR}" -type f -empty 2>/dev/null)"
if [ -z "$EMPTY_FILES" ]; then
    _pass "No empty files in templates/"
else
    _fail "Empty files found in templates/:"
    printf '%s\n' "$EMPTY_FILES" >&2
fi

# ── 5. Template integrity — no broken symlinks ───────────────────────────────
BROKEN_LINKS="$(find "${TEMPLATES_DIR}" -type l ! -exec test -e {} \; -print 2>/dev/null)"
if [ -z "$BROKEN_LINKS" ]; then
    _pass "No broken symlinks in templates/"
else
    _fail "Broken symlinks found in templates/:"
    printf '%s\n' "$BROKEN_LINKS" >&2
fi

# ── 6. Command / agent counts ────────────────────────────────────────────────
CMD_COUNT=0
if [ -d "${TEMPLATES_DIR}/commands" ]; then
    CMD_COUNT="$(find "${TEMPLATES_DIR}/commands" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')"
fi
AGENT_COUNT=0
if [ -d "${TEMPLATES_DIR}/agents" ]; then
    AGENT_COUNT="$(find "${TEMPLATES_DIR}/agents" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')"
fi
if [ "$CMD_COUNT" -lt 1 ]; then
    _fail "templates/commands/ is empty (expected at least 1 command)"
else
    _pass "templates/commands/ contains ${CMD_COUNT} command(s)"
fi
if [ "$AGENT_COUNT" -lt 1 ]; then
    _fail "templates/agents/ is empty (expected at least 1 agent)"
else
    _pass "templates/agents/  contains ${AGENT_COUNT} agent(s)"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
if [ "$ERRORS" -eq 0 ]; then
    printf '[PASS] All checks passed. Ready to release v%s.\n' "$VERSION"
    exit 0
else
    printf '[FAIL] %d check(s) failed. Fix the issues above before releasing.\n' "$ERRORS" >&2
    exit 1
fi
