#!/bin/bash
# install-claudeignore.sh — install stack-specific .claudeignore in target project
# Usage: install-claudeignore.sh <target-dir> <stack-profile> <templates-dir>
# Profiles: nuxt-storyblok | shopify-liquid | laravel | nextjs | mcp-server | n8n | default
#
# Idempotent: managed block between markers is re-synced; user lines outside are preserved.
# Markers:
#   # --- ai-setup managed (profile: <profile>) ---
#   # --- end ai-setup ---

set -euo pipefail

TARGET_DIR="${1:?Usage: install-claudeignore.sh <target-dir> <stack-profile> <templates-dir>}"
STACK_PROFILE="${2:-default}"
TEMPLATES_DIR="${3:?Usage: install-claudeignore.sh <target-dir> <stack-profile> <templates-dir>}"

CLAUDEIGNORE="${TARGET_DIR}/.claudeignore"
CLAUDEIGNORE_TPL_DIR="${TEMPLATES_DIR}/claudeignore"
BASE_TPL="${CLAUDEIGNORE_TPL_DIR}/base.claudeignore"
PROFILE_TPL="${CLAUDEIGNORE_TPL_DIR}/${STACK_PROFILE}.claudeignore"

MARKER_START="# --- ai-setup managed (profile: ${STACK_PROFILE}) ---"
MARKER_END="# --- end ai-setup ---"

# Verify templates exist
if [ ! -f "$BASE_TPL" ]; then
  echo "install-claudeignore: base template not found: $BASE_TPL" >&2
  exit 1
fi

# Build merged content: base + profile (deduped, sorted)
_build_managed_block() {
  local tmp_combined
  tmp_combined=$(mktemp)
  cat "$BASE_TPL" >> "$tmp_combined"
  if [ -f "$PROFILE_TPL" ] && [ "$STACK_PROFILE" != "default" ]; then
    cat "$PROFILE_TPL" >> "$tmp_combined"
  fi
  # Dedup: strip blank lines and comments, then sort -u
  grep -v '^[[:space:]]*$' "$tmp_combined" | grep -v '^#' | sort -u
  rm -f "$tmp_combined"
}

# First install: no .claudeignore exists
if [ ! -f "$CLAUDEIGNORE" ]; then
  {
    printf '%s\n' "$MARKER_START"
    _build_managed_block
    printf '%s\n' "$MARKER_END"
  } > "$CLAUDEIGNORE"
  count=$(grep -c '' "$CLAUDEIGNORE" 2>/dev/null || echo 0)
  echo "  .claudeignore installed (profile: ${STACK_PROFILE}, ${count} lines)"
  exit 0
fi

# File exists: detect orphan state (start marker present, end marker absent)
if grep -qF "# --- ai-setup managed" "$CLAUDEIGNORE" 2>/dev/null && \
   ! grep -qF "$MARKER_END" "$CLAUDEIGNORE" 2>/dev/null; then
  echo "ai-setup: .claudeignore has orphan managed block (start marker without end)." >&2
  echo "         Review and fix the file manually, or delete .claudeignore and re-run." >&2
  echo "         Expected end marker: ${MARKER_END}" >&2
  exit 2
fi

# File exists: check for existing managed block
if grep -qF "$MARKER_END" "$CLAUDEIGNORE" 2>/dev/null; then
  # Re-sync managed block; preserve user lines outside markers
  local_before=$(mktemp)
  tmp_new=$(mktemp)

  # Extract user lines (all lines outside any ai-setup managed block)
  # Then strip trailing blank lines to prevent blank-line drift on re-runs
  awk '
    /^# --- ai-setup managed/ { found=1; next }
    /^# --- end ai-setup ---/  { found=0; next }
    !found { print }
  ' "$CLAUDEIGNORE" | awk 'NF{p=NR} {lines[NR]=$0} END{for(i=1;i<=p;i++) print lines[i]}' > "$local_before"

  # Build new file: user content + fresh managed block
  {
    cat "$local_before"
    # Add blank line separator when user content is non-empty
    if [ -s "$local_before" ]; then
      printf '\n'
    fi
    printf '%s\n' "$MARKER_START"
    _build_managed_block
    printf '%s\n' "$MARKER_END"
  } > "$tmp_new"

  mv "$tmp_new" "$CLAUDEIGNORE"
  rm -f "$local_before"
  echo "  .claudeignore synced (profile: ${STACK_PROFILE})"
else
  # No managed block yet: append to existing file
  {
    printf '\n%s\n' "$MARKER_START"
    _build_managed_block
    printf '%s\n' "$MARKER_END"
  } >> "$CLAUDEIGNORE"
  echo "  .claudeignore updated (+managed block, profile: ${STACK_PROFILE})"
fi
