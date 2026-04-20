#!/bin/bash
# graph-before-read.sh — PreToolUse hint hook for Read/Grep/Glob
# Emits stderr hint when graph.json would be cheaper than a large Read or repeated Grepping.
# Never blocks — always exits 0. Output budget: <400 chars (Spec 643 policy).
#
# Triggers:
#   Read   — file >500 lines AND graph.json present → single hint
#   Grep   — 4th consecutive Grep without a graph query in between → hint
#
# Opt-out: .claude/settings.local.json { "graphBeforeRead": false }

INPUT=$(cat)

# --- Opt-out check ---------------------------------------------------------
LOCAL_SETTINGS="${CLAUDE_PROJECT_DIR:-.}/.claude/settings.local.json"
if [ -f "$LOCAL_SETTINGS" ] && command -v jq >/dev/null 2>&1; then
  opt_out=$(jq -r 'if .graphBeforeRead == false then "false" else "true" end' "$LOCAL_SETTINGS" 2>/dev/null || echo "true")
  [ "$opt_out" = "false" ] && exit 0
fi

# --- Session history helpers -----------------------------------------------
CACHE_DIR="${HOME}/.cache/ai-setup"
SESSION_ID="${CLAUDE_SESSION_ID:-${PPID:-0}}"
HIST_FILE="${CACHE_DIR}/tool-history-${SESSION_ID}.log"

mkdir -p "$CACHE_DIR" 2>/dev/null || true
chmod 700 "$CACHE_DIR" 2>/dev/null || true

# Cleanup logs older than 24h (best-effort)
find "$CACHE_DIR" -name "tool-history-*.log" -mmin +1440 -delete 2>/dev/null || true

# Read tool name from stdin payload
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || true)
[ -z "$TOOL_NAME" ] && exit 0

GRAPH_FILE="${CLAUDE_PROJECT_DIR:-.}/.agents/context/graph.json"

# --- Read hint: large file ------------------------------------------------
if [ "$TOOL_NAME" = "Read" ]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)
  [ -z "$FILE_PATH" ] && exit 0
  [ -f "$GRAPH_FILE" ] || exit 0

  # Count lines with 50ms timeout; skip hint if wc too slow or file unreadable
  line_count=""
  if [ -f "$FILE_PATH" ] && command -v wc >/dev/null 2>&1; then
    # Use perl timeout fallback if GNU timeout not available (macOS ships without it)
    if command -v timeout >/dev/null 2>&1; then
      # shellcheck disable=SC2016
      line_count=$(timeout 0.05 sh -c 'wc -l < "$1"' -- "$FILE_PATH" 2>/dev/null | tr -d ' ' || true)
    else
      line_count=$(wc -l < "$FILE_PATH" 2>/dev/null | tr -d ' ' || true)
    fi
  fi

  if [ -n "$line_count" ] && [ "$line_count" -gt 500 ] 2>/dev/null; then
    echo "Datei hat ${line_count} Zeilen. Prüfe erst: jq '.stats.top_hubs' .agents/context/graph.json" >&2
  fi
  exit 0
fi

# --- Grep/Glob history tracking + hint ------------------------------------
if [ "$TOOL_NAME" = "Grep" ] || [ "$TOOL_NAME" = "Glob" ]; then
  echo "Grep" >> "$HIST_FILE" 2>/dev/null || true

  # Count consecutive Grep entries at end of log (reset on GraphQuery entry)
  consec=0
  if [ -f "$HIST_FILE" ]; then
    while IFS= read -r line; do
      case "$line" in
        Grep) consec=$((consec + 1)) ;;
        *)    consec=0 ;;
      esac
    done < "$HIST_FILE"
  fi

  if [ "$consec" -ge 4 ]; then
    echo "${consec}x Grep in Folge. Graph-Lookup ist billiger: jq '.stats.top_hubs' .agents/context/graph.json" >&2
  fi
  exit 0
fi

# --- Bash with graph query resets the counter -----------------------------
if [ "$TOOL_NAME" = "Bash" ]; then
  CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
  case "$CMD" in
    *graph.json*|*jq*graph*)
      echo "GraphQuery" >> "$HIST_FILE" 2>/dev/null || true
      ;;
  esac
fi

exit 0
