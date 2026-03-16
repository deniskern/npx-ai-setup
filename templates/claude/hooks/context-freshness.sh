#!/bin/bash
# context-freshness.sh — UserPromptSubmit hook
# Warns when .agents/context/ files may be outdated (package.json or tsconfig changed)
# Also warns when repomix snapshot is older than 7 days
# Silent pass when up-to-date or state file missing (~10ms runtime, no API calls)
#
# Cache note: Warning is injected as stderr output (shown as a system message in Claude's turn),
# NOT by editing CLAUDE.md. This preserves the prompt cache prefix — editing static layers
# mid-session would invalidate the cache for all subsequent turns.

STATE_FILE=".agents/context/.state"
[ ! -f "$STATE_FILE" ] && exit 0

# Read stored hashes and timestamps
STORED_PKG=""
STORED_TSC=""
SNAPSHOT_AT=""
while IFS='=' read -r key val; do
  case "$key" in
    PKG_HASH) STORED_PKG="$val" ;;
    TSCONFIG_HASH) STORED_TSC="$val" ;;
    SNAPSHOT_AT) SNAPSHOT_AT="$val" ;;
  esac
done < "$STATE_FILE"

CHANGED=""

# Compare package.json
if [ -n "$STORED_PKG" ] && [ -f "package.json" ]; then
  CURRENT_PKG=$(cksum package.json 2>/dev/null | cut -d' ' -f1,2)
  [ "$CURRENT_PKG" != "$STORED_PKG" ] && CHANGED="package.json"
fi

# Compare tsconfig.json
if [ -n "$STORED_TSC" ] && [ -f "tsconfig.json" ]; then
  CURRENT_TSC=$(cksum tsconfig.json 2>/dev/null | cut -d' ' -f1,2)
  [ "$CURRENT_TSC" != "$STORED_TSC" ] && CHANGED="${CHANGED:+$CHANGED, }tsconfig.json"
fi

if [ -n "$CHANGED" ]; then
  echo "[CONTEXT STALE] Project context may be outdated ($CHANGED changed since last setup)." >&2
fi

# Check snapshot age (warn if older than 7 days)
if [ -n "$SNAPSHOT_AT" ]; then
  NOW=$(date -u +%s 2>/dev/null)
  # Parse ISO timestamp portably (strip T and Z, use date -d or date -jf)
  SNAP_EPOCH=""
  if date -d "$SNAPSHOT_AT" +%s >/dev/null 2>&1; then
    SNAP_EPOCH=$(date -d "$SNAPSHOT_AT" +%s 2>/dev/null)
  elif date -jf "%Y-%m-%dT%H:%M:%SZ" "$SNAPSHOT_AT" +%s >/dev/null 2>&1; then
    SNAP_EPOCH=$(date -jf "%Y-%m-%dT%H:%M:%SZ" "$SNAPSHOT_AT" +%s 2>/dev/null)
  fi
  if [ -n "$SNAP_EPOCH" ] && [ -n "$NOW" ]; then
    AGE_DAYS=$(( (NOW - SNAP_EPOCH) / 86400 ))
    if [ "$AGE_DAYS" -ge 7 ]; then
      echo "[SNAPSHOT STALE] Repomix snapshot is ${AGE_DAYS} days old. Run /context-full to refresh." >&2
    fi
  fi
fi

exit 0
