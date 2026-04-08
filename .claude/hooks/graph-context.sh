#!/bin/bash
# graph-context.sh — PreToolUse hook for Read and Edit
# Surfaces direct import neighbors from graph.json when Claude opens a file.
# Output: additionalContext with 1-line summary of imports + imported-by.
# Performance budget: <50ms (jq query, no LLM).

set -euo pipefail

GRAPH_FILE="${CLAUDE_PROJECT_DIR:-.}/.agents/context/graph.json"

[ -f "$GRAPH_FILE" ] || exit 0

# Extract file path from tool input (Read: file_path, Edit: file_path)
FILE_PATH="${CLAUDE_TOOL_INPUT_FILE_PATH:-}"
[ -z "$FILE_PATH" ] && exit 0

# Make relative to project root
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
REL_PATH=$(python3 -c "
import os, sys
try:
    print(os.path.relpath('$FILE_PATH', '$PROJECT_DIR'))
except Exception:
    print('')
" 2>/dev/null || true)

[ -z "$REL_PATH" ] && exit 0
# Skip if path starts with ../ (outside project)
case "$REL_PATH" in
  ../*) exit 0 ;;
esac

# Query graph.json for neighbors (explicit + auto-import edges)
RESULT=$(jq -r --arg file "$REL_PATH" '
  (.edges // []) as $edges |

  ($edges | map(select(.source == $file and .kind == "explicit")) | map(.target)) as $explicit_imports |
  ($edges | map(select(.source == $file and .kind == "auto-import")) | map(.target)) as $auto_imports |
  ($edges | map(select(.source == $file and (.kind == null))) | map(.target)) as $legacy_imports |
  ([$explicit_imports[], $legacy_imports[]] | unique) as $all_explicit |
  ($edges | map(select(.target == $file)) | map(.source) | unique) as $imported_by |

  if ($all_explicit | length) == 0 and ($auto_imports | length) == 0 and ($imported_by | length) == 0 then
    ""
  else
    "[GRAPH] " + ($file | split("/") | last) +
    if ($all_explicit | length) > 0 then
      " imports: " + ($all_explicit | map(split("/") | last) | join(", "))
    else "" end +
    if ($auto_imports | length) > 0 then
      " uses (auto): " + ($auto_imports | map(split("/") | last) | join(", "))
    else "" end +
    if ($imported_by | length) > 0 then
      ". Imported by: " + ($imported_by | map(split("/") | last) | join(", "))
    else "" end
  end
' "$GRAPH_FILE" 2>/dev/null || true)

[ -z "$RESULT" ] && exit 0

jq -n --arg ctx "$RESULT" '{"additionalContext": $ctx}'
