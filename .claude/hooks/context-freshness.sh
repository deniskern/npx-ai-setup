#!/bin/bash
# context-freshness.sh — UserPromptSubmit hook
# 1. Resets circuit breaker on user message (acknowledges the loop)
# 2. Warns when .agents/context/ files may be outdated
# Silent pass when up-to-date or state file missing (~10ms runtime, no API calls)

# --- Circuit breaker reset ---
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
PROJ_HASH=$(echo "$PROJECT_ROOT" | shasum | cut -c1-8)
CB_LOG="/tmp/claude-cb-${PROJ_HASH}.log"
[ -f "$CB_LOG" ] && rm -f "$CB_LOG"

# --- Context freshness check ---
STATE_FILE=".agents/context/.state"
[ ! -f "$STATE_FILE" ] && exit 0

# Age check — warn if last refresh >7 days ago
STATE_AGE_DAYS=$(( ( $(date +%s) - $(stat -f %m "$STATE_FILE" 2>/dev/null || stat -c %Y "$STATE_FILE" 2>/dev/null || echo "0") ) / 86400 ))
AGE_WARNING=""
[ "$STATE_AGE_DAYS" -gt 7 ] 2>/dev/null && AGE_WARNING="context is ${STATE_AGE_DAYS} days old"

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

REASON="${CHANGED}${CHANGED:+${AGE_WARNING:+, }}${AGE_WARNING}"
if [ -n "$REASON" ]; then
  echo "[CONTEXT STALE] .agents/context/ may be outdated ($REASON). Run the context-refresher agent to update." >&2
fi

exit 0
