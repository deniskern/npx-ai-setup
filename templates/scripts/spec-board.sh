#!/usr/bin/env bash
# spec-board.sh — Kanban overview of all specs/*.md
# Usage: bash .claude/scripts/spec-board.sh
# Requires: bash 3.2+, no external dependencies
set -euo pipefail

SPECS_DIR="${1:-specs}"
COMPLETED_LIMIT=10

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_RESET="$(printf '\033[0m')"
  C_HEAD="$(printf '\033[1;36m')"
  C_BACKLOG="$(printf '\033[1;33m')"
  C_PROGRESS="$(printf '\033[1;34m')"
  C_REVIEW="$(printf '\033[1;35m')"
  C_BLOCKED="$(printf '\033[1;31m')"
  C_DONE="$(printf '\033[1;32m')"
  C_DIM="$(printf '\033[2m')"
else
  C_RESET=""
  C_HEAD=""
  C_BACKLOG=""
  C_PROGRESS=""
  C_REVIEW=""
  C_BLOCKED=""
  C_DONE=""
  C_DIM=""
fi

if [ ! -d "$SPECS_DIR" ]; then
  echo "No specs directory found at: $SPECS_DIR"
  exit 0
fi

# Parse a single spec file, outputs: ID|TITLE|STATUS|BRANCH|DONE|TOTAL
parse_spec() {
  local file="$1"
  local id="" title="" status="draft" branch="" done=0 total=0
  local in_steps=0

  case "$file" in
    */completed/*) status="completed" ;;
  esac

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

repeat_char() {
  local char="$1"
  local count="$2"
  local out=""
  local i

  for ((i = 0; i < count; i++)); do
    out="${out}${char}"
  done

  printf '%s' "$out"
}

progress_bar() {
  local done="$1"
  local total="$2"
  local width=14
  local filled=0
  local empty

  if [ "$total" -gt 0 ]; then
    filled=$((done * width / total))
  fi
  empty=$((width - filled))

  printf '[%s%s]' "$(repeat_char '#' "$filled")" "$(repeat_char '.' "$empty")"
}

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

# Process open specs (skip completed — those come from the windowed completed collector)
while IFS= read -r f; do
  [ -n "$f" ] || continue
  local_base="$(basename "$f")"
  case "$local_base" in README.md|TEMPLATE.md|template.md) continue ;; esac
  row="$(parse_spec "$f")"
  status_field="$(echo "$row" | cut -d'|' -f3)"
  [ "$status_field" = "completed" ] && continue
  case "$status_field" in
    draft)       BACKLOG+=("$row") ;;
    in-progress) INPROG+=("$row") ;;
    in-review)   REVIEW+=("$row") ;;
    blocked)     BLOCKED+=("$row") ;;
  esac
done < <(collect_open_specs)

while IFS= read -r f; do
  [ -n "$f" ] || continue
  process_spec_file "$f"
done < <(collect_recent_completed_specs)

# Formatting helpers
fmt_entry() {
  local row="$1"
  local id title status branch done total
  local marker=""
  local color="$C_HEAD"
  IFS='|' read -r id title status branch done total <<< "$row"

  case "$status" in
    draft)
      marker="◻"
      color="$C_BACKLOG"
      printf '  %s%s %-4s%s %s\n' "$color" "$marker" "#${id}" "$C_RESET" "$title"
      ;;
    in-progress)
      marker="▶"
      color="$C_PROGRESS"
      printf '  %s%s %-4s%s %s\n' "$color" "$marker" "#${id}" "$C_RESET" "$title"
      printf '     %s%s %s/%s%s' "$C_DIM" "$(progress_bar "$done" "$total")" "$done" "$total" "$C_RESET"
      if [ -n "$branch" ] && [ "$branch" != "—" ]; then
        printf ' %s(%s)%s' "$C_DIM" "$branch" "$C_RESET"
      fi
      printf '\n'
      ;;
    in-review)
      marker="●"
      color="$C_REVIEW"
      printf '  %s%s %-4s%s %s\n' "$color" "$marker" "#${id}" "$C_RESET" "$title"
      printf '     %s%s %s/%s%s' "$C_DIM" "$(progress_bar "$done" "$total")" "$done" "$total" "$C_RESET"
      if [ -n "$branch" ] && [ "$branch" != "—" ]; then
        printf ' %s(%s)%s' "$C_DIM" "$branch" "$C_RESET"
      fi
      printf '\n'
      ;;
    blocked)
      marker="✖"
      color="$C_BLOCKED"
      printf '  %s%s %-4s%s %s\n' "$color" "$marker" "#${id}" "$C_RESET" "$title"
      ;;
    completed)
      marker="✓"
      color="$C_DONE"
      printf '  %s%s %-4s%s %s\n' "$color" "$marker" "#${id}" "$C_RESET" "$title"
      ;;
  esac
}

print_column() {
  local label="$1"
  local color="$2"
  local glyph="$3"
  shift 3
  local count=$#
  echo ""
  printf '%s%s %s (%d)%s\n' "$color" "$glyph" "$label" "$count" "$C_RESET"
  printf '  %s%s%s\n' "$C_DIM" "$(repeat_char '─' 24)" "$C_RESET"
  for row in "$@"; do
    fmt_entry "$row"
  done
}

echo "${C_HEAD}# Spec Board${C_RESET}"
echo ""
print_column "BACKLOG" "$C_BACKLOG" "◻" "${BACKLOG[@]+"${BACKLOG[@]}"}"
print_column "IN PROGRESS" "$C_PROGRESS" "▶" "${INPROG[@]+"${INPROG[@]}"}"
print_column "REVIEW" "$C_REVIEW" "●" "${REVIEW[@]+"${REVIEW[@]}"}"
print_column "BLOCKED" "$C_BLOCKED" "✖" "${BLOCKED[@]+"${BLOCKED[@]}"}"
print_column "DONE (recent ${COMPLETED_LIMIT})" "$C_DONE" "✓" "${DONE[@]+"${DONE[@]}"}"

# Summary
total_all=$(( ${#BACKLOG[@]} + ${#INPROG[@]} + ${#REVIEW[@]} + ${#BLOCKED[@]} + ${#DONE[@]} ))
echo ""
echo "---"
echo "Open: $(( ${#BACKLOG[@]} + ${#INPROG[@]} + ${#REVIEW[@]} + ${#BLOCKED[@]} )) | Done shown: ${#DONE[@]} | Total shown: ${total_all}"
