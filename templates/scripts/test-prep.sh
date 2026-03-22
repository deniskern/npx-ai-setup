#!/usr/bin/env bash
# test-prep.sh — auto-detect and run test suite, zero LLM tokens on green
# Exits 0 with "ALL_TESTS_PASSED" on success; exits 2 with filtered failure on red
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/prep-lib.sh"

# ---------------------------------------------------------------------------
# Auto-detect test command
# ---------------------------------------------------------------------------
detect_test_cmd() {
  # Node.js: parse package.json scripts
  if [[ -f "package.json" ]] && has node; then
    local scripts
    scripts=$(node -e "
      try {
        const p = require('./package.json');
        const s = p.scripts || {};
        const pref = ['test:unit','test:ci','test','vitest','jest'];
        for (const k of pref) if (s[k]) { console.log(k); break; }
      } catch(e) {}
    " 2>/dev/null || true)

    if [[ -n "$scripts" ]]; then
      echo "npm run $scripts"
      return
    fi

    # Fallback: check for vitest/jest config files
    if [[ -f "vitest.config.ts" ]] || [[ -f "vitest.config.js" ]]; then
      echo "npx vitest run"
      return
    fi
    if [[ -f "jest.config.js" ]] || [[ -f "jest.config.ts" ]]; then
      echo "npx jest"
      return
    fi
  fi

  # Python: pytest preferred, then unittest
  if [[ -f "pytest.ini" ]] || [[ -f "pyproject.toml" ]] || [[ -f "setup.cfg" ]] || [[ -d "tests" ]]; then
    if has pytest; then
      echo "pytest"
      return
    elif has python3; then
      echo "python3 -m pytest"
      return
    fi
  fi

  # Go
  if [[ -f "go.mod" ]] && has go; then
    echo "go test ./..."
    return
  fi

  # Makefile with test target
  if [[ -f "Makefile" ]] && grep -q "^test:" Makefile 2>/dev/null; then
    echo "make test"
    return
  fi

  echo ""
}

# ---------------------------------------------------------------------------
# Filter failure output — strip noise, keep actionable lines
# ---------------------------------------------------------------------------
filter_failures() {
  local input="$1"

  # Keep lines with: FAIL, Error, error, FAILED, assert, expect, ✗, ×, ✕
  echo "$input" | grep -E '(FAIL|Error|error|FAILED|assert|expect|✗|×|✕|at .*:[0-9]+|^  +\+|^  +-)' \
    | head -100 \
    || echo "$input" | tail -50
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
TEST_CMD=$(detect_test_cmd)

if [[ -z "$TEST_CMD" ]]; then
  echo "ERROR: No test framework detected." >&2
  echo "       Supported: npm/vitest/jest (Node.js), pytest (Python), go test (Go), make test" >&2
  exit 1
fi

echo "TEST_PREP_START $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "TEST_CMD: $TEST_CMD"
echo ""

# Run tests, capture output, do not let set -e abort us here
set +e
# rtk test compresses test output (failures only, -90% tokens)
if has rtk; then
  TEST_OUTPUT=$(eval "rtk test $TEST_CMD" 2>&1)
else
  TEST_OUTPUT=$(eval "$TEST_CMD" 2>&1)
fi
TEST_EXIT=$?
set -e

if [[ $TEST_EXIT -eq 0 ]]; then
  echo "ALL_TESTS_PASSED"
  exit 0
else
  echo "=== TEST FAILURES ==="
  echo "Exit code: $TEST_EXIT"
  echo ""
  filter_failures "$TEST_OUTPUT"
  echo ""
  echo "=== FULL OUTPUT (last 80 lines) ==="
  echo "$TEST_OUTPUT" | tail -80
  exit 2
fi
