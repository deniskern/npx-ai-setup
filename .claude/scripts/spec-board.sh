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
    # Title from heading (supports "# Spec: ..." and "# Brainstorm: ...")
    if [ -z "$title" ]; then
      case "$line" in
        "# Spec: "*)       title="${line#\# Spec: }" ;;
        "# Brainstorm: "*) title="${line#\# Brainstorm: }" ;;
      esac
    fi
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

# ── Kanban rendering ────────────────────────────────────────────
# Compact side-by-side layout using temp files (no eval).
# Only non-empty columns are rendered; empty ones show in the footer.

TERM_WIDTH="${COLUMNS:-$(tput cols 2>/dev/null || echo 120)}"
TMPBASE="${TMPDIR:-/tmp}/specboard.$$"
trap 'rm -f "${TMPBASE}".col_* 2>/dev/null' EXIT

strip_ansi() { sed $'s/\033\\[[0-9;]*m//g'; }

# Write one column to a temp file. Each line is padded to COL_W visible chars.
# Usage: write_col FILENAME LABEL COLOR GLYPH COL_W row1 row2 ...
write_col() {
  local outfile="$1" label="$2" color="$3" glyph="$4" col_w="$5"
  shift 5
  local count=$# inner=$((col_w - 4))
  [ "$inner" -lt 10 ] && inner=10

  # Helper: write a padded line (content + right-fill to col_w visible chars)
  _wline() {
    local text="$1"
    local vis
    vis="$(printf '%s' "$text" | strip_ansi)"
    local pad=$((col_w - ${#vis}))
    [ "$pad" -lt 0 ] && pad=0
    printf '%s%*s\n' "$text" "$pad" "" >> "$outfile"
  }

  : > "$outfile"
  # Header (no separator line — keeps output compact)
  _wline "${color}${glyph} ${label} (${count})${C_RESET}"

  for row in "$@"; do
    local id title status branch done_n total marker="" mc=""
    IFS='|' read -r id title status branch done_n total <<< "$row"
    case "$status" in
      draft)       marker="◻"; mc="$C_BACKLOG" ;;
      in-progress) marker="▶"; mc="$C_PROGRESS" ;;
      in-review)   marker="●"; mc="$C_REVIEW" ;;
      blocked)     marker="✖"; mc="$C_BLOCKED" ;;
      completed)   marker="✓"; mc="$C_DONE" ;;
    esac
    local max_t=$((inner - 2))
    [ "$max_t" -lt 4 ] && max_t=4
    if [ ${#title} -gt "$max_t" ]; then
      title="${title:0:$((max_t - 2))}.."
    fi
    _wline " ${mc}${marker} #${id}${C_RESET} ${title}"
    if [ "$status" = "in-progress" ] || [ "$status" = "in-review" ]; then
      _wline "   ${C_DIM}$(progress_bar "$done_n" "$total") ${done_n}/${total}${C_RESET}"
    fi
  done
}

# Determine which columns have items
declare -a COL_FILES=()
declare -a EMPTY_NAMES=()

maybe_col() {
  local name="$1" label="$2" color="$3" glyph="$4"
  shift 4
  if [ $# -gt 0 ]; then
    local f="${TMPBASE}.col_${name}"
    COL_FILES+=("$f")
    write_col "$f" "$label" "$color" "$glyph" "0" "$@"  # col_w set after count
  else
    EMPTY_NAMES+=("${glyph} ${label}")
  fi
}

# Count non-empty columns first
n_active=0
[ ${#BACKLOG[@]} -gt 0 ] && n_active=$((n_active + 1))
[ ${#INPROG[@]}  -gt 0 ] && n_active=$((n_active + 1))
[ ${#REVIEW[@]}  -gt 0 ] && n_active=$((n_active + 1))
[ ${#BLOCKED[@]} -gt 0 ] && n_active=$((n_active + 1))
[ ${#DONE[@]}    -gt 0 ] && n_active=$((n_active + 1))

if [ "$n_active" -eq 0 ]; then
  printf '%sSpec Board%s  —  no specs\n' "$C_HEAD" "$C_RESET"
  exit 0
fi

# Column width: divide terminal by active columns, with 2-char gap
COL_W=$(( (TERM_WIDTH - (n_active - 1) * 2) / n_active ))
[ "$COL_W" -lt 26 ] && COL_W=26

# Now build columns with correct width
COL_FILES=()
EMPTY_NAMES=()

_build_if() {
  local name="$1" label="$2" color="$3" glyph="$4"
  shift 4
  if [ $# -gt 0 ]; then
    local f="${TMPBASE}.col_${name}"
    COL_FILES+=("$f")
    write_col "$f" "$label" "$color" "$glyph" "$COL_W" "$@"
  else
    EMPTY_NAMES+=("${glyph} ${label}")
  fi
}

_build_if backlog  "BACKLOG"     "$C_BACKLOG"  "◻" ${BACKLOG[@]+"${BACKLOG[@]}"}
_build_if progress "IN PROGRESS" "$C_PROGRESS" "▶" ${INPROG[@]+"${INPROG[@]}"}
_build_if review   "REVIEW"      "$C_REVIEW"   "●" ${REVIEW[@]+"${REVIEW[@]}"}
_build_if blocked  "BLOCKED"     "$C_BLOCKED"  "✖" ${BLOCKED[@]+"${BLOCKED[@]}"}
_build_if done     "DONE"        "$C_DONE"     "✓" ${DONE[@]+"${DONE[@]}"}

# Find max line count across column files
max_lines=0
for cf in "${COL_FILES[@]}"; do
  n="$(wc -l < "$cf")"
  [ "$n" -gt "$max_lines" ] && max_lines="$n"
done

# Pad all files to same line count
for cf in "${COL_FILES[@]}"; do
  n="$(wc -l < "$cf")"
  while [ "$n" -lt "$max_lines" ]; do
    printf '%*s\n' "$COL_W" "" >> "$cf"
    n=$((n + 1))
  done
done

# Merge columns side by side using paste
if [ ${#COL_FILES[@]} -eq 1 ]; then
  cat "${COL_FILES[0]}"
else
  paste -d$'\t' "${COL_FILES[@]}" | while IFS=$'\t' read -r line; do
    printf '%s\n' "$line"
  done
fi

# Footer (no blank line — keeps output compact for CLI collapse threshold)
open_count=$(( ${#BACKLOG[@]} + ${#INPROG[@]} + ${#REVIEW[@]} + ${#BLOCKED[@]} ))
printf '%s' "Open: ${open_count} | Done: ${#DONE[@]}"
if [ ${#EMPTY_NAMES[@]} -gt 0 ]; then
  printf '  %s(' "$C_DIM"
  first=1
  for el in "${EMPTY_NAMES[@]}"; do
    [ "$first" -eq 1 ] || printf '  '
    printf '%s 0' "$el"
    first=0
  done
  printf ')%s' "$C_RESET"
fi
echo ""
