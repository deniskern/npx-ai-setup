#!/bin/bash
# memory-recall.sh — UserPromptSubmit hook
# Searches relevant memories and injects them as additionalContext.
# Supports claude-mem (semantic search) with fallback to .agents/memory/ (grep).
# Target: <2s execution, max 500 tokens injected.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
MEMORY_DIR="$PROJECT_DIR/.agents/memory"
PROMPT="${CLAUDE_USER_PROMPT:-}"
MAX_CONTEXT_CHARS=2000  # ~500 tokens

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

# Try claude-mem first (semantic search — best results)
if [ -f "$PROJECT_DIR/.mcp.json" ] && grep -q "claude-mem" "$PROJECT_DIR/.mcp.json" 2>/dev/null; then
  # claude-mem is configured — Claude will use MCP tools directly
  # We just hint that memory search is available
  printf '{"additionalContext": "Memory search available: claude-mem MCP is active. Consider searching for relevant past observations if this prompt relates to prior work."}\n'
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
