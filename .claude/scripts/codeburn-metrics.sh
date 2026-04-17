#!/usr/bin/env bash
# codeburn-metrics.sh — Pull token/cost metrics from codeburn CLI for session-optimize
# Usage: bash .claude/scripts/codeburn-metrics.sh [--period 30d|7d|today] [--json]
#
# Falls back gracefully if codeburn is not installed (skill will skip enrichment).

set -euo pipefail

PERIOD="30d"
RAW_JSON=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --period) PERIOD="${2:-30d}"; shift 2 ;;
    --json) RAW_JSON=true; shift ;;
    *) shift ;;
  esac
done

case "$PERIOD" in
  today) KEY="Today" ;;
  7d)    KEY="7 Days" ;;
  30d)   KEY="30 Days" ;;
  *)     KEY="30 Days" ;;
esac

if ! command -v codeburn >/dev/null 2>&1; then
  echo "codeburn CLI not installed — skip token enrichment" >&2
  echo "install: brew install agentseal/tap/codeburn  (or see https://github.com/AgentSeal/codeburn)" >&2
  exit 1
fi

TMP="${TMPDIR:-/tmp}/codeburn-export-$$.json"
trap 'rm -f "$TMP"' EXIT

codeburn export --format json -o "$TMP" >/dev/null 2>&1 || {
  echo "codeburn export failed" >&2
  exit 1
}

if $RAW_JSON; then
  jq --arg k "$KEY" '.periods[$k]' "$TMP"
  exit 0
fi

jq -r --arg k "$KEY" '
  .periods[$k] as $p |
  "# Codeburn Snapshot — \($k)",
  "",
  "Cost: $\($p.summary["Cost (USD)"])  |  Calls: \($p.summary["API Calls"])  |  Sessions: \($p.summary.Sessions)",
  "",
  "## Model Split (cost share)",
  ($p.models | map("- \(.Model): $\(.["Cost (USD)"]) (\(.["API Calls"]) calls)") | .[]),
  "",
  "## Activity Breakdown (top 6 by cost)",
  ($p.activity | sort_by(-.["Cost (USD)"]) | .[0:6] | map("- \(.Activity): $\(.["Cost (USD)"]) over \(.Turns) turns") | .[])
' "$TMP"
