#!/usr/bin/env bash
# build-prep.sh — auto-detect and run build, zero LLM tokens on green
# Exits 0 with "BUILD_PASSED" on success; exits 2 with first error group on red
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/prep-lib.sh"

# ---------------------------------------------------------------------------
# Auto-detect build command
# ---------------------------------------------------------------------------
detect_build_cmd() {
  # Node.js: parse package.json scripts
  if [[ -f "package.json" ]] && has node; then
    local scripts
    scripts=$(node -e "
      try {
        const p = require('./package.json');
        const s = p.scripts || {};
        const pref = ['build:ci','build:prod','build'];
        for (const k of pref) if (s[k]) { console.log(k); break; }
      } catch(e) {}
    " 2>/dev/null || true)

    if [[ -n "$scripts" ]]; then
      echo "npm run $scripts"
      return
    fi

    # Fallback: tsconfig present
    if [[ -f "tsconfig.json" ]] && has tsc; then
      echo "tsc --noEmit"
      return
    fi
  fi

  # Go
  if [[ -f "go.mod" ]] && has go; then
    echo "go build ./..."
    return
  fi

  # Makefile with build target
  if [[ -f "Makefile" ]] && grep -q "^build:" Makefile 2>/dev/null; then
    echo "make build"
    return
  fi

  # Bare tsc fallback
  if [[ -f "tsconfig.json" ]] && has tsc; then
    echo "tsc --noEmit"
    return
  fi

  echo ""
}

# ---------------------------------------------------------------------------
# Filter build errors — strip noise, keep first actionable group
# ---------------------------------------------------------------------------
filter_errors() {
  local input="$1"

  # Keep lines with error keywords, limit to first 60 lines
  echo "$input" | grep -E '(error TS|Error:|error:|ERROR|FAILED|failed|✗|× |SyntaxError|TypeError|Cannot find|does not exist|is not|has no)' \
    | head -60 \
    || echo "$input" | tail -40
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
BUILD_CMD=$(detect_build_cmd)

if [[ -z "$BUILD_CMD" ]]; then
  echo "ERROR: No build system detected." >&2
  echo "       Supported: npm run build (Node.js), go build (Go), make build (Makefile), tsc (TypeScript)" >&2
  exit 1
fi

echo "BUILD_PREP_START $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "BUILD_CMD: $BUILD_CMD"
echo ""

# Run build, capture output, do not let set -e abort here
set +e
if has rtk; then
  BUILD_OUTPUT=$(eval "rtk err $BUILD_CMD" 2>&1)
else
  BUILD_OUTPUT=$(eval "$BUILD_CMD" 2>&1)
fi
BUILD_EXIT=$?
set -e

if [[ $BUILD_EXIT -eq 0 ]]; then
  echo "BUILD_PASSED"
  exit 0
else
  echo "=== BUILD ERRORS ==="
  echo "Exit code: $BUILD_EXIT"
  echo ""
  filter_errors "$BUILD_OUTPUT"
  echo ""
  echo "=== FULL OUTPUT (last 60 lines) ==="
  echo "$BUILD_OUTPUT" | tail -60
  exit 2
fi
