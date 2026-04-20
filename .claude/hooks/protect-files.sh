#!/bin/bash
# PreToolUse: block edits to Vite build output (assets/).
# .env, lockfiles, .git/ are handled by permissions.deny in .claude/settings.json — no duplication here.
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[ -z "$FILE_PATH" ] && exit 0

if [[ "$FILE_PATH" == */assets/* ]]; then
  for cfg in vite.config.js vite.config.ts vite.config.mjs vite.config.mts; do
    if [ -f "$cfg" ]; then
      echo "Blocked: $FILE_PATH is in assets/ (build output — edit src/ instead)" >&2
      exit 2
    fi
  done
fi

exit 0
