#!/bin/bash
# SessionStart/UserPromptSubmit hook: update check + circuit breaker reset
# Fast path runs from cache; network lookup is backgrounded.

# Auto-reset circuit breaker — user sending a message = they've acknowledged the loop
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
PROJ_HASH=$(echo "$PROJECT_ROOT" | shasum | cut -c1-8)
CB_LOG="/tmp/claude-cb-${PROJ_HASH}.log"
[ -f "$CB_LOG" ] && rm -f "$CB_LOG"

# Skip update check in the source repo itself
[ -f "$PROJECT_ROOT/bin/ai-setup.sh" ] && exit 0

SETUP_JSON="$PROJECT_ROOT/.ai-setup.json"
[ ! -f "$SETUP_JSON" ] && exit 0

INSTALLED=$(jq -r '.version // empty' "$SETUP_JSON" 2>/dev/null | sed 's/^v//' | tr -d '[:space:]')
[ -z "$INSTALLED" ] && exit 0

# Cache per project (24h TTL)
CACHE="/tmp/ai-setup-update-$(echo "$PROJECT_ROOT" | cksum | cut -d' ' -f1).txt"

if [ -f "$CACHE" ]; then
  if [ "$(uname)" = "Darwin" ]; then
    AGE=$(( $(date +%s) - $(stat -f %m "$CACHE") ))
  else
    AGE=$(( $(date +%s) - $(stat -c %Y "$CACHE") ))
  fi

  if [ "$AGE" -lt 86400 ]; then
    LATEST=$(tr -d '[:space:]' < "$CACHE" | sed 's/^v//')
    if [ -n "$LATEST" ] && [ "$LATEST" != "$INSTALLED" ]; then
      # Semver compare: only notify if registry version is strictly newer
      _gt=0
      IFS=. read -ra _a <<< "$LATEST"
      IFS=. read -ra _b <<< "$INSTALLED"
      for _i in 0 1 2; do
        [ "${_a[$_i]:-0}" -gt "${_b[$_i]:-0}" ] 2>/dev/null && _gt=1 && break
        [ "${_a[$_i]:-0}" -lt "${_b[$_i]:-0}" ] 2>/dev/null && break
      done
      [ "$_gt" -eq 1 ] && echo "ai-setup v${LATEST} available (you have v${INSTALLED}). Run: npx github:onedot-digital-crew/npx-ai-setup"
    fi
    exit 0
  fi
fi

# Stale or no cache — background fetch
(
  LATEST=""

  # Preferred when package is published on npm.
  if command -v npm >/dev/null 2>&1; then
    LATEST=$(npm view @onedot/ai-setup version 2>/dev/null | head -n1 | tr -d '[:space:]' | sed 's/^v//')
  fi

  # Fallback for GitHub-only installs.
  if [ -z "$LATEST" ] && command -v curl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    LATEST=$(curl -fsSL --max-time 5 "https://api.github.com/repos/onedot-digital-crew/npx-ai-setup/releases/latest" 2>/dev/null \
      | jq -r '.tag_name // empty' \
      | head -n1 \
      | tr -d '[:space:]' \
      | sed 's/^v//')
  fi

  # Fallback if there is no release yet.
  if [ -z "$LATEST" ] && command -v curl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    LATEST=$(curl -fsSL --max-time 5 "https://api.github.com/repos/onedot-digital-crew/npx-ai-setup/tags?per_page=1" 2>/dev/null \
      | jq -r '.[0].name // empty' \
      | head -n1 \
      | tr -d '[:space:]' \
      | sed 's/^v//')
  fi

  [ -n "$LATEST" ] && printf '%s\n' "$LATEST" > "$CACHE"
) &
exit 0
