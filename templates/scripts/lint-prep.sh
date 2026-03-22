#!/usr/bin/env bash
# lint-prep.sh — auto-detect and run linter, zero LLM tokens on clean
# Exits 0 with "NO_LINT_ERRORS" on clean; exits 2 with grouped findings on issues
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/prep-lib.sh"

# ---------------------------------------------------------------------------
# Auto-detect linter
# ---------------------------------------------------------------------------
detect_lint_cmd() {
  # biome
  if [[ -f "biome.json" ]] || [[ -f "biome.jsonc" ]]; then
    if has biome; then
      echo "biome check ."
      return
    fi
  fi

  # eslint (config file variants)
  if [[ -f ".eslintrc" ]] || [[ -f ".eslintrc.js" ]] || [[ -f ".eslintrc.cjs" ]] || \
     [[ -f ".eslintrc.json" ]] || [[ -f ".eslintrc.yaml" ]] || [[ -f ".eslintrc.yml" ]] || \
     [[ -f "eslint.config.js" ]] || [[ -f "eslint.config.mjs" ]] || [[ -f "eslint.config.cjs" ]]; then
    if has eslint; then
      echo "eslint ."
      return
    fi
  fi

  # ruff (Python)
  if [[ -f "ruff.toml" ]]; then
    if has ruff; then
      echo "ruff check ."
      return
    fi
  fi
  if [[ -f "pyproject.toml" ]] && grep -q '\[tool\.ruff\]' pyproject.toml 2>/dev/null; then
    if has ruff; then
      echo "ruff check ."
      return
    fi
  fi

  # golangci-lint (Go)
  if [[ -f ".golangci.yml" ]] || [[ -f ".golangci.yaml" ]] || [[ -f ".golangci.json" ]]; then
    if has golangci-lint; then
      echo "golangci-lint run"
      return
    fi
  fi

  # Fallback: package.json lint script
  if [[ -f "package.json" ]] && has node; then
    local scripts
    scripts=$(node -e "
      try {
        const p = require('./package.json');
        const s = p.scripts || {};
        if (s['lint']) { console.log('lint'); }
      } catch(e) {}
    " 2>/dev/null || true)

    if [[ -n "$scripts" ]]; then
      echo "npm run $scripts"
      return
    fi
  fi

  echo ""
}

# ---------------------------------------------------------------------------
# Group findings by severity
# ---------------------------------------------------------------------------
group_findings() {
  local input="$1"

  echo "=== ERRORS ==="
  echo "$input" | grep -iE '(^.*error.*$|Error\[|error:)' | head -50 || echo "  (none)"

  echo ""
  echo "=== WARNINGS ==="
  echo "$input" | grep -iE '(^.*warning.*$|Warning\[|warn:)' | head -50 || echo "  (none)"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
LINT_CMD=$(detect_lint_cmd)

if [[ -z "$LINT_CMD" ]]; then
  echo "ERROR: No linter detected." >&2
  echo "       Supported: biome (biome.json), eslint (.eslintrc*), ruff (ruff.toml or pyproject.toml [tool.ruff]), golangci-lint (.golangci.yml), npm run lint" >&2
  exit 1
fi

echo "LINT_PREP_START $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "LINT_CMD: $LINT_CMD"
echo ""

# Run linter, capture output, do not let set -e abort here
set +e
if has rtk; then
  LINT_OUTPUT=$(eval "rtk lint $LINT_CMD" 2>&1)
else
  LINT_OUTPUT=$(eval "$LINT_CMD" 2>&1)
fi
LINT_EXIT=$?
set -e

if [[ $LINT_EXIT -eq 0 ]]; then
  echo "NO_LINT_ERRORS"
  exit 0
else
  echo "=== LINT FINDINGS ==="
  echo "Exit code: $LINT_EXIT"
  echo ""
  group_findings "$LINT_OUTPUT"
  echo ""
  echo "=== FULL OUTPUT (last 80 lines) ==="
  echo "$LINT_OUTPUT" | tail -80
  exit 2
fi
