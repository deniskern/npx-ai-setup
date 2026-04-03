#!/usr/bin/env bash
# spec-board.sh — Kanban overview of all specs/*.md
# Usage: bash .claude/scripts/spec-board.sh
# Requires: bash 3.2+, no external dependencies
set -euo pipefail

SPECS_DIR="${1:-specs}"
COMPLETED_LIMIT=10

if [ ! -d "$SPECS_DIR" ]; then
  echo "No specs directory found at: $SPECS_DIR"
  exit 0
fi

# Parse a single spec file, outputs: ID|TITLE|STATUS|BRANCH|DONE|TOTAL
parse_spec() {
  local file="$1"
  local id="" title="" status="draft" branch="" done=0 total=0
  local in_steps=0

  while IFS= read -r line; do
    # Metadata row: Spec ID, Status, Branch
    case "$line" in
      "> **Spec ID**:"*)
        id="$(printf '%s\n' "$line" | sed -n 's/^> \*\*Spec ID\*\*: \([^|]*\).*/\1/p' | tr -d ' ')"
        status="$(printf '%s\n' "$line" | sed -n 's/.*\*\*Status\*\*: \([^|]*\).*/\1/p' | tr -d ' ')"
        branch="$(printf '%s\n' "$line" | sed -n 's/.*\*\*Branch\*\*: \(.*\)$/\1/p' | sed 's/[[:space:]]*$//')"
        ;;
    esac
    # Title from heading
    case "$line" in
      "# Spec: "*) title="${line#\# Spec: }" ;;
    esac
    # Steps section toggle
    case "$line" in
      "## Steps"*) in_steps=1 ;;
      "## "*) [ "$in_steps" = "1" ] && in_steps=0 ;;
    esac
    # Count checkboxes only in Steps section
    if [ "$in_steps" = "1" ]; then
      case "$line" in
        *"- [x]"*) done=$((done + 1)) ; total=$((total + 1)) ;;
        *"- [ ]"*) total=$((total + 1)) ;;
      esac
    fi
  done < "$file"

  # Fallback: extract ID from filename (e.g. specs/116-foo.md -> 116)
  if [ -z "$id" ]; then
    local base
    base="$(basename "$file" .md)"
    id="${base%%-*}"
  fi
  # Truncate title to 30 chars
  if [ ${#title} -gt 30 ]; then
    title="${title:0:28}.."
  fi
  echo "${id}|${title}|${status}|${branch}|${done}|${total}"
}

# Collect files for the board.
collect_open_specs() {
  find "$SPECS_DIR" -maxdepth 1 -name "*.md" | sort
}

collect_recent_completed_specs() {
  local completed_dir="${SPECS_DIR}/completed"

  if [ ! -d "$completed_dir" ]; then
    return 0
  fi

  find "$completed_dir" -maxdepth 1 -name "*.md" \
    | awk -F/ '
        {
          file=$NF
          id=file
          sub(/-.*/, "", id)
          if (id ~ /^[0-9]+$/) {
            printf "%09d %s\n", id, $0
          }
        }
      ' \
    | sort \
    | tail -n "$COMPLETED_LIMIT" \
    | sed 's/^[0-9][0-9]* //'
}

# Bucket arrays
declare -a BACKLOG=() INPROG=() REVIEW=() BLOCKED=() DONE=()

process_spec_file() {
  local f="$1"
  local base row status_field
  base="$(basename "$f")"
  # Skip non-spec files
  case "$base" in README.md|TEMPLATE.md|template.md) return 0 ;; esac
  row="$(parse_spec "$f")"
  status_field="$(echo "$row" | cut -d'|' -f3)"
  case "$status_field" in
    draft)       BACKLOG+=("$row") ;;
    in-progress) INPROG+=("$row") ;;
    in-review)   REVIEW+=("$row") ;;
    blocked)     BLOCKED+=("$row") ;;
    completed)   DONE+=("$row") ;;
  esac
}

while IFS= read -r f; do
  [ -n "$f" ] || continue
  process_spec_file "$f"
done < <(collect_open_specs)

while IFS= read -r f; do
  [ -n "$f" ] || continue
  process_spec_file "$f"
done < <(collect_recent_completed_specs)

# Formatting helpers
fmt_entry() {
  local row="$1"
  local id title status branch done total
  IFS='|' read -r id title status branch done total <<< "$row"
  local line="#${id} ${title}"
  # Show progress for in-progress / in-review
  case "$status" in
    in-progress|in-review)
      [ "$total" -gt 0 ] && line="$line [${done}/${total}]"
      [ -n "$branch" ] && [ "$branch" != "—" ] && line="$line (${branch})"
      ;;
  esac
  echo "  $line"
}

print_column() {
  local label="$1"; shift
  local count=$#
  echo ""
  printf "%-20s(%d)\n" "$label" "$count"
  echo "  ────────────────────"
  for row in "$@"; do
    fmt_entry "$row"
  done
}

echo "# Spec Board"
echo ""
print_column "BACKLOG"     "${BACKLOG[@]+"${BACKLOG[@]}"}"
print_column "IN PROGRESS" "${INPROG[@]+"${INPROG[@]}"}"
print_column "REVIEW"      "${REVIEW[@]+"${REVIEW[@]}"}"
print_column "BLOCKED"     "${BLOCKED[@]+"${BLOCKED[@]}"}"
print_column "DONE (latest 10)" "${DONE[@]+"${DONE[@]}"}"

# Summary
total_all=$(( ${#BACKLOG[@]} + ${#INPROG[@]} + ${#REVIEW[@]} + ${#BLOCKED[@]} + ${#DONE[@]} ))
echo ""
echo "---"
echo "Total shown: ${total_all} specs | ${#BACKLOG[@]} backlog, ${#INPROG[@]} in-progress, ${#REVIEW[@]} in-review, ${#BLOCKED[@]} blocked, ${#DONE[@]} done (latest ${COMPLETED_LIMIT})"
