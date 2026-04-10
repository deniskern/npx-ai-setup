#!/bin/bash
# shellcheck-guard.sh — PreToolUse hook for .sh file edits
# Runs shellcheck on the target file BEFORE Claude edits it.
# Injects existing issues as context (advisory, not blocking) so Claude
# can fix them while making its change rather than introducing more.
# Zero output = zero tokens when no issues are found.

command -v shellcheck >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -z "$FILE_PATH" ] && exit 0

case "$FILE_PATH" in
  *.sh) ;;
  *) exit 0 ;;
esac

[ -f "$FILE_PATH" ] || exit 0

# Run shellcheck with gcc-style output for compact reporting
ISSUES=$(shellcheck -f gcc "$FILE_PATH" 2>/dev/null | head -20) || true
[ -z "$ISSUES" ] && exit 0

jq -n --arg ctx "[shellcheck] Existing issues in $(basename "$FILE_PATH") (fix while editing):\n$ISSUES" \
  '{"additionalContext": $ctx}'
