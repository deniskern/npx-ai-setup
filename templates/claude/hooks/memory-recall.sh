#!/bin/bash
# memory-recall.sh — UserPromptSubmit hook
# Searches relevant memories and injects them as additionalContext.
# Supports claude-mem (semantic search) with fallback to .agents/memory/ (grep).
# Target: <2s execution, max 500 tokens injected.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
MEMORY_DIR="$PROJECT_DIR/.agents/memory"
PROMPT="${CLAUDE_USER_PROMPT:-}"
SETTINGS_FILE="$PROJECT_DIR/.claude/settings.json"
CLAUDE_MEM_PLUGIN_DIR="${HOME}/.claude/plugins/cache/thedotmack/claude-mem"
MAX_CONTEXT_CHARS=2000  # ~500 tokens

# Cache expiry warning: if idle >5min, prompt cache is gone (10x cost on next turn)
CACHE_STAMP_FILE="${TMPDIR:-/tmp}/claude-last-stop-$(echo "${CLAUDE_PROJECT_DIR:-.}" | cksum | cut -d' ' -f1)"
if [ -f "$CACHE_STAMP_FILE" ]; then
  LAST_STOP=$(cat "$CACHE_STAMP_FILE" 2>/dev/null || echo 0)
  NOW=$(date +%s)
  IDLE_SECS=$(( NOW - LAST_STOP ))
  if [ "$IDLE_SECS" -gt 300 ]; then
    IDLE_MIN=$(( IDLE_SECS / 60 ))
    printf '{"additionalContext": "[CACHE EXPIRED] %dmin idle — prompt cache abgelaufen. Dieser Turn kostet 10x mehr. Erwaege /compact vor dem Fortfahren."}\n' "$IDLE_MIN"
    exit 0
  fi
fi

# Guard: skip short prompts
if [ ${#PROMPT} -lt 15 ]; then
  exit 0
fi

# Guard: skip slash commands
case "$PROMPT" in
  /*) exit 0 ;;
esac

# Guard: skip common non-searchable prompts
case "$PROMPT" in
  y|n|yes|no|ok|done|fix*|commit*|push*|"git "*) exit 0 ;;
esac

# Extract keywords: take words >3 chars, deduplicate, max 5
extract_keywords() {
  echo "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | tr -cs '[:alnum:]' '\n' \
    | awk 'length > 3' \
    | sort -u \
    | head -5 \
    | tr '\n' '|' \
    | sed 's/|$//'
}

KEYWORDS=$(extract_keywords "$PROMPT")
[ -z "$KEYWORDS" ] && exit 0

claude_mem_enabled_in_settings() {
  [ -f "$SETTINGS_FILE" ] || return 1

  if command -v jq >/dev/null 2>&1; then
    jq -e '.enabledPlugins["claude-mem@thedotmack"] == true' "$SETTINGS_FILE" >/dev/null 2>&1
    return $?
  fi

  grep -q '"claude-mem@thedotmack"[[:space:]]*:[[:space:]]*true' "$SETTINGS_FILE" 2>/dev/null
}

claude_mem_available() {
  [ -d "$CLAUDE_MEM_PLUGIN_DIR" ] && return 0
  claude_mem_enabled_in_settings && return 0
  return 1
}

# claude-mem active — Claude sees MCP tools directly, no hint needed
if claude_mem_available; then
  exit 0
fi

# Fallback: grep through .agents/memory/ files
if [ ! -d "$MEMORY_DIR" ]; then
  exit 0
fi

# Count memory files
file_count=$(find "$MEMORY_DIR" -name "*.md" ! -name "MEMORY.md" -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$file_count" -eq 0 ]; then
  exit 0
fi

# Search memory files for keyword matches
MATCHES=""
TOTAL_LEN=0

while IFS= read -r file; do
  [ ! -f "$file" ] && continue

  # Check if file contains any keyword
  if grep -qiE "$KEYWORDS" "$file" 2>/dev/null; then
    # Extract the abstract/description from frontmatter
    abstract=""
    name=""
    while IFS= read -r line; do
      case "$line" in
        "---") [ -n "$name" ] && break ;;
        name:*) name="${line#name: }" ;;
        description:*) abstract="${line#description: }" ;;
      esac
    done < "$file"

    if [ -n "$abstract" ]; then
      entry="- $name: $abstract"
    else
      # No frontmatter — use first non-empty, non-header line
      entry=$(grep -v '^#' "$file" | grep -v '^---' | grep -v '^$' | head -1)
      [ -z "$entry" ] && continue
      entry="- $(basename "$file" .md): $entry"
    fi

    entry_len=${#entry}
    new_total=$((TOTAL_LEN + entry_len + 1))

    # Respect token budget
    if [ "$new_total" -gt "$MAX_CONTEXT_CHARS" ]; then
      break
    fi

    MATCHES="${MATCHES:+$MATCHES\n}$entry"
    TOTAL_LEN=$new_total
  fi
done < <(find "$MEMORY_DIR" -name "*.md" ! -name "MEMORY.md" -type f 2>/dev/null | sort -r | head -20)

if [ -n "$MATCHES" ]; then
  escaped=$(printf '%s' "$MATCHES" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g')
  printf '{"additionalContext": "Relevant memories:\\n%s"}\n' "$escaped"
fi

exit 0
