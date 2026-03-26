#!/bin/bash
# Dead-loop prevention:
# Keep formatter/linter output suppressed unless there is a genuine syntax issue that
# must reach the model. Exposing normal lint output here can trigger repetitive
# self-correction loops on the same file.
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')

# Ignore events without a concrete file (or deleted/moved files).
[ -n "$FILE_PATH" ] || exit 0
[ -f "$FILE_PATH" ] || exit 0

# Optional project formatter script.
# Try file-scoped format first; on failure, continue with per-file fallback below.
if [ -f "package.json" ] && jq -e '.scripts.format' package.json >/dev/null 2>&1; then
  if command -v bun >/dev/null 2>&1 && bun run format -- "$FILE_PATH" >/dev/null 2>&1; then
    exit 0
  fi
  if command -v npm >/dev/null 2>&1 && npm run -s format -- "$FILE_PATH" >/dev/null 2>&1; then
    exit 0
  fi
fi

# ESLint for JS/TS files
if [[ "$FILE_PATH" == *.js || "$FILE_PATH" == *.ts || "$FILE_PATH" == *.jsx || "$FILE_PATH" == *.tsx ]]; then
  if [ -x "node_modules/.bin/eslint" ]; then
    ./node_modules/.bin/eslint "$FILE_PATH" --fix >/dev/null 2>&1
  else
    npx eslint "$FILE_PATH" --fix >/dev/null 2>&1
  fi
  # Silent by design: lint output must not be shown to Claude.

fi

# Validate JSON syntax for Shopify schema/config files
if [[ "$FILE_PATH" == */config/*.json || "$FILE_PATH" == */templates/*.json || "$FILE_PATH" == */locales/*.json ]]; then
  if command -v jq >/dev/null 2>&1; then
    if ! jq . "$FILE_PATH" >/dev/null 2>&1; then
      echo "JSON syntax error in $FILE_PATH" >&2
    fi
  fi
fi

# Prettier for other supported files (css, html, json, md, yaml, vue, svelte)
if [[ "$FILE_PATH" == *.css || "$FILE_PATH" == *.html || "$FILE_PATH" == *.json || "$FILE_PATH" == *.md || "$FILE_PATH" == *.yaml || "$FILE_PATH" == *.yml || "$FILE_PATH" == *.vue || "$FILE_PATH" == *.svelte ]]; then
  if [ -x "node_modules/.bin/prettier" ]; then
    ./node_modules/.bin/prettier --write "$FILE_PATH" 2>/dev/null
  fi
fi

exit 0
