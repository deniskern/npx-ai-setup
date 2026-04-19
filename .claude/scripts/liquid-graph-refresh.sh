#!/bin/bash
# liquid-graph-refresh.sh — Idempotent Liquid dependency graph refresh
# Usage: bash .claude/scripts/liquid-graph-refresh.sh [project-dir]
#
# Only re-runs if any .liquid file is newer than liquid-graph.json.
# Safe to call repeatedly (e.g. from hooks or CI).

set -e

PROJECT_DIR="${1:-${CLAUDE_PROJECT_DIR:-$PWD}}"
GRAPH_FILE="${PROJECT_DIR}/.agents/context/liquid-graph.json"

# Resolve the generator script location (handles npx install and local dev)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GENERATOR="${SCRIPT_DIR}/../../lib/build-liquid-graph.sh"

if [ ! -f "$GENERATOR" ]; then
  echo "liquid-graph-refresh: generator not found at ${GENERATOR}" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Check if refresh is needed: any .liquid file newer than graph.json
# ---------------------------------------------------------------------------

NEEDS_REFRESH=0

if [ ! -f "$GRAPH_FILE" ]; then
  NEEDS_REFRESH=1
else
  for d in sections snippets templates layout blocks; do
    dir="${PROJECT_DIR}/${d}"
    [ -d "$dir" ] || continue
    if find "$dir" -maxdepth 2 -name "*.liquid" -newer "$GRAPH_FILE" 2>/dev/null | grep -q .; then
      NEEDS_REFRESH=1
      break
    fi
  done
fi

if [ "$NEEDS_REFRESH" -eq 0 ]; then
  echo "liquid-graph-refresh: graph is up to date, skipping" >&2
  exit 0
fi

echo "liquid-graph-refresh: refreshing ${GRAPH_FILE}" >&2
bash "$GENERATOR" "$PROJECT_DIR"
