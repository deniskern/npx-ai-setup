#!/bin/bash
# transcript-ingest.sh — Stop hook (async)
# Automatically extracts learnings from Claude session transcripts.
# Runs async (fire-and-forget) — does not block Claude's response.
# Supports claude-mem plugin installs with fallback to .agents/memory/.
#
# Requirements: claude CLI (for haiku summarization)
# Token cost: ~500 tokens per invocation (haiku summarization)

set -euo pipefail

# Cache expiry tracking: record stop timestamp for idle detection
CACHE_STAMP_FILE="${TMPDIR:-/tmp}/claude-last-stop-$(echo "${CLAUDE_PROJECT_DIR:-.}" | cksum | cut -d' ' -f1)"
date +%s > "$CACHE_STAMP_FILE" 2>/dev/null || true

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
MEMORY_DIR="$PROJECT_DIR/.agents/memory"
TRANSCRIPT_FILE="${CLAUDE_TRANSCRIPT:-}"
SETTINGS_FILE="$PROJECT_DIR/.claude/settings.json"
CLAUDE_MEM_PLUGIN_DIR="${HOME}/.claude/plugins/cache/thedotmack/claude-mem"
MAX_MEMORY_FILES=50
MAX_MEMORY_SIZE_KB=200

# Guard: only run for substantial sessions
message_count="${CLAUDE_MESSAGE_COUNT:-0}"
if [ "$message_count" -lt 10 ]; then
  exit 0
fi

# Guard: need transcript data
if [ -z "$TRANSCRIPT_FILE" ] || [ ! -f "$TRANSCRIPT_FILE" ]; then
  # Try to read from stdin (Claude passes transcript via Stop hook)
  TRANSCRIPT=$(cat)
  if [ ${#TRANSCRIPT} -lt 200 ]; then
    exit 0
  fi
else
  TRANSCRIPT=$(cat "$TRANSCRIPT_FILE")
fi

# Guard: transcript must be substantial
if [ ${#TRANSCRIPT} -lt 500 ]; then
  exit 0
fi

# Truncate to last 8000 chars to stay within haiku limits
if [ ${#TRANSCRIPT} -gt 8000 ]; then
  TRANSCRIPT="${TRANSCRIPT: -8000}"
fi

# Extract learnings via haiku
PROMPT="Analyze this Claude Code session transcript. Extract ONLY genuinely useful cross-session learnings:
- Architectural decisions made (and why)
- Bugs found and their root causes
- New patterns or conventions established
- Non-obvious technical discoveries

Rules:
- Max 5 bullet points
- Skip trivial observations (file reads, routine commits)
- Skip anything already obvious from the code itself
- Each bullet: what was learned + why it matters
- If nothing worth remembering: respond with just 'NONE'

Transcript (last portion):
$TRANSCRIPT"

LEARNINGS=$(echo "$PROMPT" | claude -p --model haiku --output-format text 2>/dev/null) || exit 0

# Skip if nothing useful
if [ "$LEARNINGS" = "NONE" ] || [ -z "$LEARNINGS" ]; then
  exit 0
fi

DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date +%H%M%S)

# Enforce memory size limits before writing
enforce_memory_limits() {
  [ ! -d "$MEMORY_DIR" ] && return 0

  # Count existing memory files (exclude MEMORY.md index)
  local file_count
  file_count=$(find "$MEMORY_DIR" -name "*.md" ! -name "MEMORY.md" -type f 2>/dev/null | wc -l | tr -d ' ')

  # If over limit, remove oldest files
  if [ "$file_count" -ge "$MAX_MEMORY_FILES" ]; then
    local remove_count=$(( file_count - MAX_MEMORY_FILES + 5 ))
    find "$MEMORY_DIR" -name "*.md" ! -name "MEMORY.md" -type f -print0 2>/dev/null \
      | xargs -0 ls -t 2>/dev/null \
      | tail -n "$remove_count" \
      | xargs rm -f 2>/dev/null || true
  fi

  # Check total size
  local total_size
  total_size=$(du -sk "$MEMORY_DIR" 2>/dev/null | cut -f1)
  if [ "${total_size:-0}" -gt "$MAX_MEMORY_SIZE_KB" ]; then
    # Remove oldest files until under limit
    find "$MEMORY_DIR" -name "*.md" ! -name "MEMORY.md" -type f -print0 2>/dev/null \
      | xargs -0 ls -t 2>/dev/null \
      | tail -n 5 \
      | xargs rm -f 2>/dev/null || true
  fi
}

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

# Try claude-mem first when the supported plugin install path is present.
if command -v claude >/dev/null 2>&1 && claude_mem_available; then
  echo "$LEARNINGS" | claude -p --model haiku --output-format text \
    "Save these session learnings to claude-mem. Use the save_memory MCP tool with type 'session-learning' and today's date $DATE. Content: $LEARNINGS" 2>/dev/null && exit 0
fi

# Fallback: write to .agents/memory/
mkdir -p "$MEMORY_DIR"

enforce_memory_limits

FILENAME="session-learning-${DATE}-${TIMESTAMP}.md"

cat > "$MEMORY_DIR/$FILENAME" << MEMEOF
---
name: session-learning-${DATE}
description: Auto-extracted learnings from session on ${DATE}
type: project
---

# Session Learnings — ${DATE}

$LEARNINGS
MEMEOF

# Update MEMORY.md index if it exists
if [ -f "$MEMORY_DIR/MEMORY.md" ]; then
  # Only add if not already referenced
  if ! grep -q "$FILENAME" "$MEMORY_DIR/MEMORY.md" 2>/dev/null; then
    echo "- [$FILENAME]($FILENAME) — Auto-extracted session learnings ${DATE}" >> "$MEMORY_DIR/MEMORY.md"
  fi
fi

exit 0
