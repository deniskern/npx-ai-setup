#!/usr/bin/env bash
# hook-tokens-baseline.sh — Baseline token measurement for project hooks
# Usage: bash tests/hook-tokens-baseline.sh
# Dumps estimated output token totals per hook type to stdout.
# Use for before/after comparison when trimming hooks.

set -euo pipefail

AUDIT_SCRIPT="lib/hook-token-audit.sh"

if [ ! -f "$AUDIT_SCRIPT" ]; then
  echo "ERROR: $AUDIT_SCRIPT not found — run from project root" >&2
  exit 1
fi

echo "# Hook Token Baseline — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

# Full report from audit script (suppress exit code — we just want the output)
bash "$AUDIT_SCRIPT" || true

echo ""
echo "# Per-type totals"
echo ""

# Summarize by hook type using the audit output
bash "$AUDIT_SCRIPT" 2>/dev/null | grep -v '^$' | grep -v '^#' | grep -v '^HOOK_TYPE' | grep -v '^---' | grep -v '^RESULT' | \
awk '
  NF >= 3 {
    type = $1
    # Token column is 3rd field
    tokens = $3 + 0
    sum[type] += tokens
    count[type]++
    total += tokens
  }
  END {
    for (t in sum) {
      printf "  %-20s  %d tokens (%d hook(s))\n", t, sum[t], count[t]
    }
    printf "\n  %-20s  %d tokens\n", "TOTAL", total
  }
' || true

echo ""
echo "# Caps reference"
echo "  UserPromptSubmit/PreToolUse/other : 300 tokens per hook"
echo "  SessionStart/PreCompact           : 2000 tokens per hook"
