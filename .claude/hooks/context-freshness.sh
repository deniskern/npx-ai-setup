#!/bin/bash
# context-freshness.sh — UserPromptSubmit hook
# Warns when .agents/context/ files may be outdated (package.json or tsconfig changed)
# Silent pass when up-to-date or state file missing (~10ms runtime, no API calls)
#
# Cache note: Warning is injected as stderr output (shown as a system message in Claude's turn),
# NOT by editing CLAUDE.md. This preserves the prompt cache prefix — editing static layers
# mid-session would invalidate the cache for all subsequent turns.

STATE_FILE=".agents/context/.state"
[ ! -f "$STATE_FILE" ] && exit 0

# Read stored hashes
STORED_PKG=""
STORED_TSC=""
STORED_GIT=""
while IFS='=' read -r key val; do
  case "$key" in
    PKG_HASH) STORED_PKG="$val" ;;
    TSCONFIG_HASH) STORED_TSC="$val" ;;
    GIT_HASH) STORED_GIT="$val" ;;
  esac
done < "$STATE_FILE"

CHANGED=""

# Compare git commit hash (~5ms)
if [ -n "$STORED_GIT" ]; then
  CURRENT_GIT=$(git rev-parse HEAD 2>/dev/null)
  [ -n "$CURRENT_GIT" ] && [ "$CURRENT_GIT" != "$STORED_GIT" ] && CHANGED="source code"
fi

# Compare package.json
if [ -n "$STORED_PKG" ] && [ -f "package.json" ]; then
  CURRENT_PKG=$(cksum package.json 2>/dev/null | cut -d' ' -f1,2)
  [ "$CURRENT_PKG" != "$STORED_PKG" ] && CHANGED="${CHANGED:+$CHANGED, }package.json"
fi

# Compare tsconfig.json
if [ -n "$STORED_TSC" ] && [ -f "tsconfig.json" ]; then
  CURRENT_TSC=$(cksum tsconfig.json 2>/dev/null | cut -d' ' -f1,2)
  [ "$CURRENT_TSC" != "$STORED_TSC" ] && CHANGED="${CHANGED:+$CHANGED, }tsconfig.json"
fi

if [ -n "$CHANGED" ]; then
  echo "[CONTEXT STALE] Project context may be outdated ($CHANGED changed since last refresh)." >&2
fi

exit 0
