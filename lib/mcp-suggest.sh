#!/bin/bash
# mcp-suggest.sh — Resolve MCP list for a given stack_profile
# Usage: bash lib/mcp-suggest.sh <stack_profile>
# Outputs: JSON array of MCP objects (global + profile-specific)
# Requires: lib/data/mcp-defaults.json
# shellcheck source=lib/_loader.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULTS_FILE="${SCRIPT_DIR}/lib/data/mcp-defaults.json"

if [ ! -f "$DEFAULTS_FILE" ]; then
  echo "[]"
  exit 0
fi

STACK_PROFILE="${1:-default}"

# ------------------------------------------------------------------
# jq path: clean, single pass
# ------------------------------------------------------------------
if command -v jq >/dev/null 2>&1; then
  jq -c --arg p "$STACK_PROFILE" '
    (.global // []) +
    (.profiles[$p] // [])
  ' "$DEFAULTS_FILE"
  exit 0
fi

# ------------------------------------------------------------------
# Fallback path: node (available on any machine with npm/npx)
# ------------------------------------------------------------------
if command -v node >/dev/null 2>&1; then
  node - "$DEFAULTS_FILE" "$STACK_PROFILE" <<'NODESCRIPT'
    const fs = require('fs');
    const data = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
    const profile = process.argv[3];
    const globals = data.global || [];
    const extras  = (data.profiles && data.profiles[profile]) || [];
    process.stdout.write(JSON.stringify(globals.concat(extras)));
NODESCRIPT
  exit 0
fi

# ------------------------------------------------------------------
# Last-resort: awk/grep — only handles the known fixed structure
# Produces a valid JSON array for the two known MCPs.
# ------------------------------------------------------------------
# Extract global entries via grep (one per line, JSON object form)
globals=""
in_global=0
while IFS= read -r line; do
  if printf '%s' "$line" | grep -q '"global"'; then
    in_global=1; continue
  fi
  if [ "$in_global" = "1" ]; then
    # Stop at closing bracket for the global array
    printf '%s' "$line" | grep -q '^\s*\]' && break
    # Accumulate object lines (skip bare [ and ])
    printf '%s' "$line" | grep -qE '^\s*[\[\]]' && continue
    globals="${globals}${line}"
  fi
done < "$DEFAULTS_FILE"

# Extract profile-specific entries
profile_entries=""
in_profile=0
in_target=0
while IFS= read -r line; do
  if printf '%s' "$line" | grep -q '"profiles"'; then
    in_profile=1; continue
  fi
  if [ "$in_profile" = "1" ]; then
    if printf '%s' "$line" | grep -q "\"${STACK_PROFILE}\""; then
      in_target=1; continue
    fi
    if [ "$in_target" = "1" ]; then
      printf '%s' "$line" | grep -qE '^\s*\]' && break
      printf '%s' "$line" | grep -qE '^\s*[\[\]]' && continue
      profile_entries="${profile_entries}${line}"
    fi
  fi
done < "$DEFAULTS_FILE"

# Build output array
all=""
[ -n "$globals" ]       && all="${globals}"
[ -n "$profile_entries" ] && all="${all},${profile_entries}"
# Strip trailing comma artefacts and wrap
all=$(printf '%s' "$all" | sed 's/^,//;s/,$//')
printf '[%s]\n' "$all"
