#!/usr/bin/env bash
# cli-health.sh — SessionStart hook: warn about missing token-saving tools
# Silent when all OK. Max 100ms execution time.
# Outputs warnings to stderr (visible to user, not consumed as tool output).

warnings=()

if ! command -v rtk >/dev/null 2>&1; then
  warnings+=("rtk not found — install with 'brew install rtk' for 60-90% token savings")
elif ! rtk gain >/dev/null 2>&1; then
  warnings+=("rtk installed but hooks not active — run 'rtk init --global' to enable")
fi

if ! command -v defuddle >/dev/null 2>&1; then
  warnings+=("defuddle not found — install with 'npm i -g defuddle' for 80% savings on web content")
fi

if [[ ${#warnings[@]} -gt 0 ]]; then
  for w in "${warnings[@]}"; do
    echo "[cli-health] $w" >&2
  done
fi

exit 0
