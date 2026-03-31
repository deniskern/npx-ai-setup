#!/bin/bash
# PreToolUse — redirect WebFetch to defuddle when available (~80% token savings)
# Passes through silently when defuddle is not installed.
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

[ "$TOOL_NAME" = "WebFetch" ] || exit 0
command -v defuddle >/dev/null 2>&1 || exit 0

URL=$(echo "$INPUT" | jq -r '.tool_input.url // empty')

cat <<EOF
WebFetch blocked — defuddle is available (saves ~80% tokens).
Use: defuddle parse "$URL" --md
Fallback: https://markdown.new/$URL
Exception: use WebFetch when the page requires JavaScript rendering.
EOF
exit 2
