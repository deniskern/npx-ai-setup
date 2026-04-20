#!/bin/bash
# context-size-check.sh — Check .agents/context/*.md against line-count caps
# Usage: bash lib/context-size-check.sh [context_dir]
# Exit 0: no violations. Exit 1: one or more violations.
# Env: CONTEXT_CAPS_RELAX=1 suppresses violations (warnings shown, exit 0).
#
# Caps defined in lib/data/context-caps.json (relative to script dir or CAPS_FILE env).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CAPS_FILE="${CAPS_FILE:-${SCRIPT_DIR}/data/context-caps.json}"
CONTEXT_DIR="${1:-.agents/context}"

# --- Verify caps file ---
if [ ! -f "$CAPS_FILE" ]; then
  echo "ERROR: caps file not found: $CAPS_FILE" >&2
  exit 2
fi

# --- Parse caps using python3 or jq ---
read_cap() {
  local key="$1"
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d.get(sys.argv[2], ''))" \
      "$CAPS_FILE" "$key" 2>/dev/null
  elif command -v jq >/dev/null 2>&1; then
    jq -r --arg k "$key" '.[$k] // ""' "$CAPS_FILE" 2>/dev/null
  else
    echo "" # no parser — caps unavailable
  fi
}

# --- Check if relaxed ---
RELAXED=0
[ "${CONTEXT_CAPS_RELAX:-0}" = "1" ] && RELAXED=1

# --- Iterate context files ---
violations=0
total_lines=0

if [ ! -d "$CONTEXT_DIR" ]; then
  echo "SKIP: $CONTEXT_DIR not found — no context files to check"
  exit 0
fi

for filepath in "$CONTEXT_DIR"/*.md; do
  [ -f "$filepath" ] || continue
  filename="$(basename "$filepath")"
  line_count="$(wc -l < "$filepath" | tr -d ' ')"
  total_lines=$((total_lines + line_count))
  cap="$(read_cap "$filename")"

  if [ -z "$cap" ]; then
    echo "OK: $filename has $line_count lines (no cap defined)"
    continue
  fi

  if [ "$line_count" -gt "$cap" ]; then
    over=$(( line_count - cap ))
    if [ "$RELAXED" = "1" ]; then
      echo "RELAXED: $filename has $line_count lines (cap: $cap, over by $over)"
    else
      echo "VIOLATION: $filename has $line_count lines (cap: $cap)"
      violations=$((violations + 1))
    fi
  else
    echo "OK: $filename has $line_count lines (cap: $cap)"
  fi
done

# --- Total directory check ---
total_cap="$(read_cap "total_directory")"
if [ -n "$total_cap" ]; then
  if [ "$total_lines" -gt "$total_cap" ]; then
    over=$(( total_lines - total_cap ))
    if [ "$RELAXED" = "1" ]; then
      echo "RELAXED TOTAL: $total_lines lines (cap: $total_cap, over by $over)"
    else
      echo "TOTAL: $total_lines lines (cap: $total_cap) — EXCEEDS CAP"
      violations=$((violations + 1))
    fi
  else
    echo "TOTAL: $total_lines lines (cap: $total_cap)"
  fi
fi

[ "$violations" -gt 0 ] && exit 1 || exit 0
