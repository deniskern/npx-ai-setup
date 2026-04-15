#!/usr/bin/env bash
# spec-stop-guard.sh — Stop hook
# Blocks the first stop while specs are in progress, then allows a second stop
# within 60 seconds to avoid trapping the session forever.

cat >/dev/null

PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
PROJECT_HASH=$(printf '%s' "$PROJECT_ROOT" | cksum | awk '{print $1}')
COOLDOWN_FILE="/tmp/claude-spec-stop-${PROJECT_HASH}.ts"
NOW=$(date +%s)
WINDOW=60

IN_PROGRESS=()
for spec_file in "$PROJECT_ROOT"/specs/*.md; do
  [ -f "$spec_file" ] || continue
  # Skip non-spec files (README, BOARD, etc.) — spec files have a numeric prefix
  case "$(basename "$spec_file")" in
    [0-9]*) ;;
    *) continue ;;
  esac
  if grep -qiE 'Status[^:]*:[[:space:]]*in-progress' "$spec_file" 2>/dev/null; then
    IN_PROGRESS+=("$(basename "$spec_file")")
  fi
done

[ "${#IN_PROGRESS[@]}" -gt 0 ] || exit 0

if [ -f "$COOLDOWN_FILE" ]; then
  LAST=$(cat "$COOLDOWN_FILE" 2>/dev/null)
  case "$LAST" in ''|*[!0-9]*) LAST=0 ;; esac
  if [ $((NOW - LAST)) -le "$WINDOW" ]; then
    rm -f "$COOLDOWN_FILE"
    exit 0
  fi
fi

printf '%s\n' "$NOW" > "$COOLDOWN_FILE"

{
  echo "Active spec in progress — do not stop yet."
  echo "In progress: ${IN_PROGRESS[*]}"
  echo "Check with: grep -l \"Status.*in-progress\" specs/*.md"
  echo "Your next action must continue the spec rather than claim completion."
  echo "To intentionally stop anyway, trigger Stop again within 60 seconds."
} >&2

exit 2
