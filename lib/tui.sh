#!/bin/bash
# Terminal UI helpers: colors, banners, prompts, spinners, and interactive menus
# Sets: $REGEN_*, $UPD_*

_tui_init() {
  [ "${_TUI_READY:-0}" = "1" ] && return 0

  TUI_IS_TTY="no"
  [ -t 1 ] && TUI_IS_TTY="yes"

  TUI_PLAIN="no"
  [ -n "${NO_COLOR:-}" ] && TUI_PLAIN="yes"
  [ -n "${AI_SETUP_PLAIN:-}" ] && TUI_PLAIN="yes"

  TUI_HAS_COLOR="no"
  if [ "$TUI_IS_TTY" = "yes" ] && [ "$TUI_PLAIN" = "no" ]; then
    case "${TERM:-}" in
      dumb|"") ;;
      *) TUI_HAS_COLOR="yes" ;;
    esac
  fi

  TUI_HAS_UNICODE="yes"
  case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in
    C|POSIX|"") TUI_HAS_UNICODE="no" ;;
  esac
  [ "$TUI_PLAIN" = "yes" ] && TUI_HAS_UNICODE="no"

  if [ "$TUI_HAS_COLOR" = "yes" ]; then
    TUI_RESET=$'\033[0m'
    TUI_BOLD=$'\033[1m'
    TUI_DIM=$'\033[2m'
    TUI_INVERSE=$'\033[7m'
    TUI_RED=$'\033[31m'
    TUI_GREEN=$'\033[32m'
    TUI_YELLOW=$'\033[33m'
    TUI_BLUE=$'\033[34m'
    TUI_MAGENTA=$'\033[35m'
    TUI_CYAN=$'\033[36m'
    TUI_WHITE=$'\033[37m'
  else
    TUI_RESET=""
    TUI_BOLD=""
    TUI_DIM=""
    TUI_INVERSE=""
    TUI_RED=""
    TUI_GREEN=""
    TUI_YELLOW=""
    TUI_BLUE=""
    TUI_MAGENTA=""
    TUI_CYAN=""
    TUI_WHITE=""
  fi

  if [ "$TUI_HAS_UNICODE" = "yes" ]; then
    TUI_TL="┌"
    TUI_TR="┐"
    TUI_BL="└"
    TUI_BR="┘"
    TUI_H="─"
    TUI_V="│"
    TUI_BAR_FILL="█"
    TUI_BAR_EMPTY="░"
    TUI_OK="✓"
    TUI_WARN="!"
    TUI_ERR="✕"
    TUI_INFO="i"
    TUI_ARROW="▸"
    TUI_BULLET="•"
    TUI_BRAND_ICON="◈"
  else
    TUI_TL="+"
    TUI_TR="+"
    TUI_BL="+"
    TUI_BR="+"
    TUI_H="-"
    TUI_V="|"
    TUI_BAR_FILL="#"
    TUI_BAR_EMPTY="-"
    TUI_OK="OK"
    TUI_WARN="WARN"
    TUI_ERR="ERR"
    TUI_INFO="INFO"
    TUI_ARROW=">"
    TUI_BULLET="*"
    TUI_BRAND_ICON="<>"
  fi

  TUI_SPINNER_FRAMES='-\|/'
  _TUI_READY=1
}

tui_repeat_char() {
  local char="$1"
  local count="${2:-0}"
  local out=""

  while [ "$count" -gt 0 ]; do
    out="${out}${char}"
    count=$((count - 1))
  done

  printf '%s' "$out"
}

tui_cols() {
  _tui_init
  local cols=80

  if [ "$TUI_IS_TTY" = "yes" ] && command -v tput >/dev/null 2>&1; then
    cols=$(tput cols 2>/dev/null || echo 80)
  fi

  [ -z "$cols" ] && cols=80
  [ "$cols" -lt 48 ] && cols=48
  printf '%s\n' "$cols"
}

tui_rows() {
  _tui_init
  local rows=24

  if [ "$TUI_IS_TTY" = "yes" ] && command -v tput >/dev/null 2>&1; then
    rows=$(tput lines 2>/dev/null || echo 24)
  fi

  [ -z "$rows" ] && rows=24
  [ "$rows" -lt 16 ] && rows=16
  printf '%s\n' "$rows"
}

_tui_box_width() {
  local cols
  cols=$(tui_cols)
  local inner=$((cols - 8))
  [ "$inner" -gt 72 ] && inner=72
  [ "$inner" -lt 28 ] && inner=28
  printf '%s\n' "$inner"
}

tui_pad_right() {
  local text="$1"
  local width="${2:-0}"
  local len=${#text}

  if [ "$len" -ge "$width" ]; then
    printf '%s' "$text"
    return 0
  fi

  printf '%s%s' "$text" "$(tui_repeat_char " " $((width - len)))"
}

tui_divider() {
  _tui_init
  local width="${1:-$(_tui_box_width)}"
  printf '   %s\n' "$(tui_repeat_char "$TUI_H" "$width")"
}

tui_center_line() {
  _tui_init
  local text="$1"
  local style="${2:-}"
  local cols
  cols=$(tui_cols)
  local pad=$(((cols - ${#text}) / 2))
  [ "$pad" -lt 0 ] && pad=0
  printf '%*s%b%s%b\n' "$pad" '' "$style" "$text" "$TUI_RESET"
}

tui_truncate() {
  _tui_init
  local text="$1"
  local max="${2:-0}"
  local ellipsis="..."

  [ "$TUI_HAS_UNICODE" = "yes" ] && ellipsis="…"
  [ "$max" -le 0 ] && { printf ''; return 0; }
  [ "${#text}" -le "$max" ] && { printf '%s' "$text"; return 0; }
  [ "$max" -le "${#ellipsis}" ] && { printf '%s' "${text:0:$max}"; return 0; }
  printf '%s%s' "${text:0:$((max - ${#ellipsis}))}" "$ellipsis"
}

tui_center_block() {
  _tui_init
  local style="${1:-}"
  local line

  while IFS= read -r line; do
    [ -z "$line" ] && { echo ""; continue; }
    tui_center_line "$line" "$style"
  done
}

tui_banner() {
  _tui_init
  local title="$1"
  local subtitle="${2:-}"
  local inner
  inner=$(_tui_box_width)

  echo ""
  printf '   %b%s%s%s%b\n' "$TUI_CYAN" "$TUI_TL" "$(tui_repeat_char "$TUI_H" "$inner")" "$TUI_TR" "$TUI_RESET"
  printf '   %b%s%b %b%s%b %b%s%b\n' "$TUI_CYAN" "$TUI_V" "$TUI_RESET" "$TUI_BOLD" "$(tui_pad_right "$title" "$((inner - 2))")" "$TUI_RESET" "$TUI_CYAN" "$TUI_V" "$TUI_RESET"
  if [ -n "$subtitle" ]; then
    printf '   %b%s%b %s %b%s%b\n' "$TUI_CYAN" "$TUI_V" "$TUI_RESET" "$(tui_pad_right "$subtitle" "$((inner - 2))")" "$TUI_CYAN" "$TUI_V" "$TUI_RESET"
  fi
  printf '   %b%s%s%s%b\n' "$TUI_CYAN" "$TUI_BL" "$(tui_repeat_char "$TUI_H" "$inner")" "$TUI_BR" "$TUI_RESET"
}

tui_brand_banner() {
  _tui_init
  local subtitle="${1:-}"
  local cols
  local rows
  cols=$(tui_cols)
  rows=$(tui_rows)
  echo ""

  if [ "$TUI_PLAIN" = "yes" ] || [ "$TUI_IS_TTY" != "yes" ]; then
    tui_center_line "ONEDOT" "${TUI_CYAN}${TUI_BOLD}"
    tui_center_line "AI Setup" "$TUI_DIM"
    [ -n "$subtitle" ] && tui_center_line "$subtitle" "$TUI_DIM"
    echo ""
    return 0
  fi

  if [ "$cols" -ge 44 ] && [ "$rows" -ge 28 ]; then
    tui_center_block "${TUI_CYAN}" <<'EOF'
###################################
###################################
###################################
###################################
###################################
################-.-################
###############.      +############
####################.  +###########
############-  .#####   ###########
###########    .#####.  ###########
#############  .#####   ###########
#############  .####.  +###########
#############         +############
#############......+###############
###################################
###################################
###################################
###################################
###################################
EOF
    echo ""
    tui_center_line "ONEDOT" "${TUI_CYAN}${TUI_BOLD}"
    tui_center_line "AI Setup" "$TUI_DIM"
    [ -n "$subtitle" ] && tui_center_line "$subtitle" "$TUI_DIM"
    echo ""
    return 0
  fi

  tui_center_line "${TUI_BRAND_ICON} ONEDOT" "${TUI_CYAN}${TUI_BOLD}"
  tui_center_line "AI Setup" "$TUI_DIM"
  [ -n "$subtitle" ] && tui_center_line "$subtitle" "$TUI_DIM"
  echo ""
  return 0
}

tui_brand_banner_once() {
  [ "${TUI_BRAND_SHOWN:-0}" = "1" ] && return 0
  tui_brand_banner "$@"
  TUI_BRAND_SHOWN=1
}

tui_section() {
  _tui_init
  local title="$1"
  local subtitle="${2:-}"
  local accent="${3:-$TUI_CYAN}"

  echo ""
  printf ' %b%s%b %b%s%b\n' "$accent" "$TUI_ARROW" "$TUI_RESET" "$TUI_BOLD" "$title" "$TUI_RESET"
  tui_divider
  if [ -n "$subtitle" ]; then
    printf '   %s\n' "$subtitle"
  fi
  return 0
}

tui_step() {
  _tui_init
  printf '  %b%s%b %s\n' "$TUI_CYAN" "$TUI_BULLET" "$TUI_RESET" "$1"
}

tui_info() {
  _tui_init
  printf '  %b%s%b %s\n' "$TUI_BLUE" "$TUI_INFO" "$TUI_RESET" "$1"
}

tui_success() {
  _tui_init
  printf '  %b%s%b %s\n' "$TUI_GREEN" "$TUI_OK" "$TUI_RESET" "$1"
}

# tui_hint "line1" ["line2" ...]  — visually distinct callout for tips/next steps
tui_hint() {
  _tui_init
  printf '\n  %b%s%s Tip%b\n' "$TUI_YELLOW" "$TUI_TL" "$TUI_H$TUI_H" "$TUI_RESET"
  local line
  for line in "$@"; do
    printf '  %b%s%b  %s\n' "$TUI_YELLOW" "$TUI_V" "$TUI_RESET" "$line"
  done
  printf '\n'
}

tui_warn() {
  _tui_init
  printf '  %b%s%b %s\n' "$TUI_YELLOW" "$TUI_WARN" "$TUI_RESET" "$1"
}

tui_error() {
  _tui_init
  printf '  %b%s%b %s\n' "$TUI_RED" "$TUI_ERR" "$TUI_RESET" "$1"
}

tui_key_value() {
  _tui_init
  local key="$1"
  local value="$2"
  printf '   %b%-12s%b %s\n' "$TUI_DIM" "${key}:" "$TUI_RESET" "$value"
}

# Print a clickable OSC 8 terminal hyperlink pointing to the ai-setup GitHub repo.
# Usage: tui_file_link <github_path> [label]
# Example: tui_file_link "CHANGELOG.md" → links to github.com/onedot-digital-crew/npx-ai-setup/blob/main/CHANGELOG.md
_TUI_GH_REPO="https://github.com/onedot-digital-crew/npx-ai-setup/blob/main"

tui_file_link() {
  _tui_init
  local gh_path="$1"
  local label="${2:-$gh_path}"
  if [ "$TUI_HAS_COLOR" = "yes" ]; then
    printf '\033]8;;%s/%s\033\\%b%s%b\033]8;;\033\\' "$_TUI_GH_REPO" "$gh_path" '\033[4m' "$label" "$TUI_RESET"
  else
    printf '%s' "$label"
  fi
}

tui_prompt_text() {
  _tui_init
  printf '  %b%s%b %s' "$TUI_CYAN" "$TUI_ARROW" "$TUI_RESET" "$1"
}

_tui_spinner_loop() {
  _tui_init
  local label="$1"
  local frames="$TUI_SPINNER_FRAMES"
  local i=0
  local frame_count=${#frames}

  while true; do
    local frame="${frames:i:1}"
    printf '\r  %b%s%b %s' "$TUI_CYAN" "$frame" "$TUI_RESET" "$label"
    sleep 0.1
    i=$(((i + 1) % frame_count))
  done
}

tui_spinner_start() {
  _tui_init
  TUI_SPINNER_LABEL="$1"
  TUI_SPINNER_PID=""

  if [ "$TUI_IS_TTY" = "yes" ] && [ "$TUI_PLAIN" = "no" ]; then
    _tui_spinner_loop "$TUI_SPINNER_LABEL" &
    TUI_SPINNER_PID=$!
  else
    printf '  %s %s...\n' "$TUI_INFO" "$TUI_SPINNER_LABEL"
  fi
}

tui_spinner_stop() {
  _tui_init
  local status="${1:-ok}"
  local message="${2:-${TUI_SPINNER_LABEL:-Done}}"

  if [ -n "${TUI_SPINNER_PID:-}" ]; then
    kill "$TUI_SPINNER_PID" 2>/dev/null || true
    wait "$TUI_SPINNER_PID" 2>/dev/null || true
    TUI_SPINNER_PID=""
    printf '\r\033[K'
  fi

  case "$status" in
    ok) tui_success "$message" ;;
    warn) tui_warn "$message" ;;
    error) tui_error "$message" ;;
    *) tui_info "$message" ;;
  esac
}

tui_cleanup() {
  if [ -n "${TUI_SPINNER_PID:-}" ]; then
    kill "$TUI_SPINNER_PID" 2>/dev/null || true
    wait "$TUI_SPINNER_PID" 2>/dev/null || true
    TUI_SPINNER_PID=""
    printf '\r\033[K'
  fi
  printf '\033[?25h' 2>/dev/null || true
}

tui_abort_setup() {
  tui_cleanup
  echo ""
  tui_warn "Setup aborted"
  echo "   Pressed Esc to cancel the current setup run."
  exit 130
}

_tui_read_escape_sequence() {
  local first="" second=""

  if ! IFS= read -rsn1 -t 1 first </dev/tty; then
    return 1
  fi

  if ! IFS= read -rsn1 -t 1 second </dev/tty; then
    printf '%s' "$first"
    return 0
  fi

  printf '%s%s' "$first" "$second"
  return 0
}

tui_read_line() {
  _tui_init
  local prompt="$1"
  local buffer=""
  local key=""

  if [ "$TUI_IS_TTY" != "yes" ]; then
    read -r -p "$prompt" buffer
    printf '%s' "$buffer"
    return 0
  fi

  printf '%s' "$prompt"
  while true; do
    IFS= read -rsn1 key </dev/tty
    case "$key" in
      $'\x1b')
        tui_abort_setup
        ;;
      "")
        printf '\n'
        printf '%s' "$buffer"
        return 0
        ;;
      $'\177'|$'\010')
        if [ -n "$buffer" ]; then
          buffer="${buffer%?}"
          printf '\b \b'
        fi
        ;;
      *)
        buffer="${buffer}${key}"
        printf '%s' "$key"
        ;;
    esac
  done
}

ensure_valid_working_directory() {
  if pwd -P >/dev/null 2>&1; then
    return 0
  fi

  echo ""
  tui_error "Current working directory is no longer available."
  echo "   The shell is currently attached to a deleted or moved directory."
  echo "   cd into an existing project directory, then run the setup again."
  return 1
}

_tui_menu_row() {
  _tui_init
  local is_selected="$1"
  local checkbox="$2"
  local option="$3"
  local description="$4"
  local cols desc_max rendered row_lines
  cols=$(tui_cols)
  row_lines=$(_tui_menu_row_lines)
  desc_max=$((cols - 24))
  [ "$desc_max" -lt 12 ] && desc_max=12
  rendered="$(tui_truncate "$description" "$desc_max")"

  if [ "$row_lines" -gt 1 ]; then
    if [ "$is_selected" -eq 1 ]; then
      if [ "$TUI_HAS_COLOR" = "yes" ]; then
        printf '\033[2K\r  %b %s %-12s%b\n' "$TUI_INVERSE" "$checkbox" "$option" "$TUI_RESET"
      else
        printf '\033[2K\r  %s %s %-12s\n' "$TUI_ARROW" "$checkbox" "$option"
      fi
    else
      printf '\033[2K\r    %s %-12s\n' "$checkbox" "$option"
    fi
    printf '\033[2K\r      %b%s%b\n' "$TUI_DIM" "$rendered" "$TUI_RESET"
    return 0
  fi

  if [ "$is_selected" -eq 1 ]; then
    if [ "$TUI_HAS_COLOR" = "yes" ]; then
      printf '\033[2K\r  %b %s %-12s %s %b\n' "$TUI_INVERSE" "$checkbox" "$option" "$rendered" "$TUI_RESET"
    else
      printf '\033[2K\r  %s %s %-12s %s\n' "$TUI_ARROW" "$checkbox" "$option" "$rendered"
    fi
  else
    printf '\033[2K\r    %s %-12s %s\n' "$checkbox" "$option" "$rendered"
  fi
}

_tui_badge_style() {
  local badge="$1"
  case "$badge" in
    Recommended) printf '%s' "$TUI_GREEN" ;;
    Default) printf '%s' "$TUI_DIM" ;;
    Destructive) printf '%s' "$TUI_RED" ;;
    *) printf '%s' "$TUI_YELLOW" ;;
  esac
}

_tui_choice_row_lines() {
  local cols
  cols=$(tui_cols)
  [ "$cols" -lt 86 ] && echo 2 || echo 1
}

_tui_menu_row_lines() {
  local cols
  cols=$(tui_cols)
  [ "$cols" -lt 78 ] && echo 2 || echo 1
}

_tui_choice_row() {
  _tui_init
  local is_selected="$1"
  local index="$2"
  local label="$3"
  local description="$4"
  local badge="$5"
  local prefix="${index})"
  local badge_text=""
  local badge_plain=""
  local cols desc_max rendered row_lines badge_color

  row_lines=$(_tui_choice_row_lines)

  if [ -n "$badge" ]; then
    badge_plain=" [${badge}]"
    if [ "$TUI_HAS_COLOR" = "yes" ]; then
      badge_color="$(_tui_badge_style "$badge")"
      badge_text=" ${badge_color}[${badge}]${TUI_RESET}"
    else
      badge_text="$badge_plain"
    fi
  fi

  cols=$(tui_cols)
  desc_max=$((cols - 31 - ${#badge_plain}))
  [ "$desc_max" -lt 12 ] && desc_max=12
  rendered="$(tui_truncate "$description" "$desc_max")"

  if [ "$row_lines" -gt 1 ]; then
    local line1_badge=""
    line1_badge="$badge_text"
    if [ "$is_selected" -eq 1 ]; then
      if [ "$TUI_HAS_COLOR" = "yes" ]; then
        printf '\033[2K\r  %b %-3s %-14s%b%b\n' "$TUI_INVERSE" "$prefix" "$label" "$line1_badge" "$TUI_RESET"
      else
        printf '\033[2K\r  %s %-3s %-14s%s\n' "$TUI_ARROW" "$prefix" "$label" "$line1_badge"
      fi
    else
      printf '\033[2K\r    %-3s %-14s%s\n' "$prefix" "$label" "$line1_badge"
    fi
    local detail_max=$((cols - 10))
    [ "$detail_max" -lt 12 ] && detail_max=12
    printf '\033[2K\r      %b%s%b\n' "$TUI_DIM" "$(tui_truncate "$description" "$detail_max")" "$TUI_RESET"
    return 0
  fi

  if [ "$is_selected" -eq 1 ]; then
    if [ "$TUI_HAS_COLOR" = "yes" ]; then
      printf '\033[2K\r  %b %-3s %-14s %s%b%b\n' "$TUI_INVERSE" "$prefix" "$label" "$rendered" "$badge_text" "$TUI_RESET"
    else
      printf '\033[2K\r  %s %-3s %-14s %s%s\n' "$TUI_ARROW" "$prefix" "$label" "$rendered" "$badge_text"
    fi
  else
    printf '\033[2K\r    %-3s %-14s %s%s\n' "$prefix" "$label" "$rendered" "$badge_text"
  fi
}

tui_menu_footer() {
  _tui_init
  local kind="${1:-single}"
  local text=""
  if [ "$kind" = "multi" ]; then
    if [ "$TUI_HAS_UNICODE" = "yes" ]; then
      text="↑↓ move  Space toggle  Enter confirm  Esc cancel"
    else
      text="up/down move  Space toggle  Enter confirm  Esc cancel"
    fi
  else
    if [ "$TUI_HAS_UNICODE" = "yes" ]; then
      text="↑↓ move  Enter select  Esc cancel  1-9 jump"
    else
      text="up/down move  Enter select  Esc cancel  1-9 jump"
    fi
  fi
  printf '\033[2K\r  %b%s%b\n' "$TUI_DIM" "$text" "$TUI_RESET"
}

# Single-choice menu with arrow-key navigation.
# Usage: ask_single_choice_menu "Title" [--default N] "Label|Description|Badge" ...
# Returns 0 and sets TUI_MENU_INDEX (1-based), TUI_MENU_LABEL on selection.
ask_single_choice_menu() {
  _tui_init
  local title="$1"
  shift
  local default_index=1

  if [ "${1:-}" = "--default" ]; then
    shift
    default_index="${1:-1}"
    shift
  fi

  local items=("$@")
  local count=${#items[@]}
  local selected=$((default_index - 1))

  TUI_MENU_INDEX=""
  TUI_MENU_LABEL=""

  [ "$count" -eq 0 ] && return 1
  [ "$selected" -lt 0 ] && selected=0
  [ "$selected" -ge "$count" ] && selected=0

  echo ""
  printf '  %b%s%b\n' "$TUI_BOLD" "$title" "$TUI_RESET"

  if [ "$TUI_IS_TTY" != "yes" ]; then
    local i
    for ((i=0; i<count; i++)); do
      local label="${items[$i]%%|*}"
      local rest="${items[$i]#*|}"
      local description="${rest%%|*}"
      local badge=""
      [ "$rest" != "$description" ] && badge="${rest#*|}"
      if [ -n "$badge" ]; then
        printf '   %d) %-14s %s [%s]\n' "$((i + 1))" "$label" "$description" "$badge"
      else
        printf '   %d) %-14s %s\n' "$((i + 1))" "$label" "$description"
      fi
    done
    echo ""
    local answer
    read -r -p "$(tui_prompt_text "Choose [1-${count}] [default: ${default_index}]: ")" answer
    [ "$answer" = $'\x1b' ] && tui_abort_setup
    case "$answer" in
      '') answer="$default_index" ;;
      *[!0-9]*) return 1 ;;
    esac
    [ "$answer" -lt 1 ] || [ "$answer" -gt "$count" ] && return 1
    TUI_MENU_INDEX="$answer"
    TUI_MENU_LABEL="${items[$((answer - 1))]%%|*}"
    return 0
  fi

  printf '\033[?25l'
  trap 'printf "\033[?25h"' RETURN 2>/dev/null || true

  local i row_lines total_lines
  row_lines=$(_tui_choice_row_lines)
  total_lines=$((count * row_lines + 1))
  for ((i=0; i<count; i++)); do
    local label="${items[$i]%%|*}"
    local rest="${items[$i]#*|}"
    local description="${rest%%|*}"
    local badge=""
    [ "$rest" != "$description" ] && badge="${rest#*|}"
    if [ $i -eq $selected ]; then
      _tui_choice_row 1 "$((i + 1))" "$label" "$description" "$badge"
    else
      _tui_choice_row 0 "$((i + 1))" "$label" "$description" "$badge"
    fi
  done
  tui_menu_footer "single"

  while true; do
    IFS= read -rsn1 key
    case "$key" in
      $'\x1b')
        local seq=""
        if seq="$(_tui_read_escape_sequence)"; then
          case "$seq" in
            '[A') selected=$(((selected - 1 + count) % count)) ;;
            '[B') selected=$(((selected + 1) % count)) ;;
            *) tui_abort_setup ;;
          esac
        else
          tui_abort_setup
        fi
        ;;
      "")
        break
        ;;
      [1-9])
        local idx=$((key - 1))
        if [ "$idx" -ge 0 ] && [ "$idx" -lt "$count" ]; then
          selected="$idx"
          break
        fi
        ;;
    esac

    printf "\033[${total_lines}A"
    for ((i=0; i<count; i++)); do
      local label="${items[$i]%%|*}"
      local rest="${items[$i]#*|}"
      local description="${rest%%|*}"
      local badge=""
      [ "$rest" != "$description" ] && badge="${rest#*|}"
      if [ $i -eq $selected ]; then
        _tui_choice_row 1 "$((i + 1))" "$label" "$description" "$badge"
      else
        _tui_choice_row 0 "$((i + 1))" "$label" "$description" "$badge"
      fi
    done
    tui_menu_footer "single"
  done

  printf '\033[?25h'
  TUI_MENU_INDEX=$((selected + 1))
  TUI_MENU_LABEL="${items[$selected]%%|*}"
  tui_info "Selected: ${TUI_MENU_LABEL}"
  return 0
}

# Yes/no menu built on top of ask_single_choice_menu.
# Usage: ask_yes_no_menu "Title" "Yes label" "Yes desc" "No label" "No desc" [default]
# default: yes | no (defaults to no)
# Returns 0 for yes, 1 for no. Sets TUI_MENU_BOOL=yes|no.
ask_yes_no_menu() {
  local title="$1"
  local yes_label="$2"
  local yes_desc="$3"
  local no_label="$4"
  local no_desc="$5"
  local default_choice="${6:-no}"

  TUI_MENU_BOOL="no"

  if [ "$default_choice" = "yes" ]; then
    ask_single_choice_menu "$title" --default 1 \
      "${yes_label}|${yes_desc}|Default" \
      "${no_label}|${no_desc}" || return 1
    if [ "${TUI_MENU_INDEX:-2}" = "1" ]; then
      TUI_MENU_BOOL="yes"
      return 0
    fi
    return 1
  fi

  ask_single_choice_menu "$title" --default 1 \
    "${no_label}|${no_desc}|Default" \
    "${yes_label}|${yes_desc}" || return 1
  if [ "${TUI_MENU_INDEX:-1}" = "2" ]; then
    TUI_MENU_BOOL="yes"
    return 0
  fi
  return 1
}

# ==============================================================================
# REGENERATION PART SELECTOR
# ==============================================================================
# Sets REGEN_CLAUDE_MD, REGEN_AGENTS_MD, REGEN_CONTEXT, REGEN_COMMANDS,
# REGEN_AGENTS, REGEN_SKILLS globals.
# Returns 1 if the user selected nothing (skip).
ask_regen_parts() {
  _tui_init
  local options=("CLAUDE.md" "AGENTS.md" "Context" "Commands" "Agents" "Skills")
  local descriptions=("Main project instructions" "Agent workflow guidelines" ".agents/context files" ".claude/commands files" ".claude/agents files" ".claude/skills files")
  local count=6
  local selected=0
  local checked=(1 1 1 1 1 1)

  echo ""
  printf '  %bSelect what to regenerate%b\n' "$TUI_BOLD" "$TUI_RESET"

  printf '\033[?25l'
  trap 'printf "\033[?25h"' RETURN 2>/dev/null || true

  local row_lines total_lines
  row_lines=$(_tui_menu_row_lines)
  total_lines=$((count * row_lines + 1))

  for ((i=0; i<count; i++)); do
    local checkbox="[ ]"
    [ "${checked[$i]}" -eq 1 ] && checkbox="[x]"
    if [ $i -eq $selected ]; then
      _tui_menu_row 1 "$checkbox" "${options[$i]}" "${descriptions[$i]}"
    else
      _tui_menu_row 0 "$checkbox" "${options[$i]}" "${descriptions[$i]}"
    fi
  done
  tui_menu_footer "multi"

  while true; do
    IFS= read -rsn1 key
    case "$key" in
      $'\x1b')
        local seq=""
        if seq="$(_tui_read_escape_sequence)"; then
          case "$seq" in
            '[A') selected=$(((selected - 1 + count) % count)) ;;
            '[B') selected=$(((selected + 1) % count)) ;;
            *) tui_abort_setup ;;
          esac
        else
          tui_abort_setup
        fi
        ;;
      " ")
        [ "${checked[$selected]}" -eq 1 ] && checked[$selected]=0 || checked[$selected]=1
        ;;
      "")
        break
        ;;
    esac

    printf "\033[${total_lines}A"
    for ((i=0; i<count; i++)); do
      local checkbox="[ ]"
      [ "${checked[$i]}" -eq 1 ] && checkbox="[x]"
      if [ $i -eq $selected ]; then
        _tui_menu_row 1 "$checkbox" "${options[$i]}" "${descriptions[$i]}"
      else
        _tui_menu_row 0 "$checkbox" "${options[$i]}" "${descriptions[$i]}"
      fi
    done
    tui_menu_footer "multi"
  done

  printf '\033[?25h'

  REGEN_CLAUDE_MD="no"; REGEN_AGENTS_MD="no"; REGEN_CONTEXT="no"; REGEN_COMMANDS="no"; REGEN_AGENTS="no"; REGEN_SKILLS="no"
  [ "${checked[0]}" -eq 1 ] && REGEN_CLAUDE_MD="yes"
  [ "${checked[1]}" -eq 1 ] && REGEN_AGENTS_MD="yes"
  [ "${checked[2]}" -eq 1 ] && REGEN_CONTEXT="yes"
  [ "${checked[3]}" -eq 1 ] && REGEN_COMMANDS="yes"
  [ "${checked[4]}" -eq 1 ] && REGEN_AGENTS="yes"
  [ "${checked[5]}" -eq 1 ] && REGEN_SKILLS="yes"

  if [ "$REGEN_CLAUDE_MD" = "no" ] && [ "$REGEN_AGENTS_MD" = "no" ] && [ "$REGEN_CONTEXT" = "no" ] && [ "$REGEN_COMMANDS" = "no" ] && [ "$REGEN_AGENTS" = "no" ] && [ "$REGEN_SKILLS" = "no" ]; then
    echo ""
    return 1
  fi
  return 0
}

_scan_category_label() {
  local changed="$1" new="$2"
  local parts=()
  [ "$changed" -gt 0 ] && parts+=("${changed} changed")
  [ "$new" -gt 0 ] && parts+=("${new} new")
  if [ ${#parts[@]} -eq 0 ]; then
    echo "unchanged"
  else
    local IFS=", "
    echo "${parts[*]}"
  fi
}

# ==============================================================================
# UPDATE PART SELECTOR
# ==============================================================================
# Sets UPD_HOOKS, UPD_SETTINGS, UPD_CLAUDE_MD, UPD_AGENTS_MD, UPD_COMMANDS,
# UPD_AGENTS, UPD_OTHER globals.
# Requires: SCAN_*_CHANGED and SCAN_*_NEW globals from scan_template_changes().
# Pre-selects only categories with actual changes. Shows change counts per category.
# Returns 1 if the user selected nothing (skip template update).
ask_update_parts() {
  _tui_init
  local options=("Hooks" "Settings" "CLAUDE.md" "AGENTS.md" "Commands" "Agents" "Other")
  local base_descriptions=("Hooks and rules" ".claude/settings.json" "Root CLAUDE.md" "Root AGENTS.md" ".claude/commands" ".claude/agents" "Specs and misc files")
  local count=7
  local selected=0
  local -a descriptions=()
  local -a checked=()
  local -a cat_changes=()
  local -a cat_news=()

  cat_changes=("${SCAN_HOOKS_CHANGED:-0}" "${SCAN_SETTINGS_CHANGED:-0}" "${SCAN_CLAUDE_MD_CHANGED:-0}" "${SCAN_AGENTS_MD_CHANGED:-0}" "${SCAN_COMMANDS_CHANGED:-0}" "${SCAN_AGENTS_CHANGED:-0}" "${SCAN_OTHER_CHANGED:-0}")
  cat_news=("${SCAN_HOOKS_NEW:-0}" "${SCAN_SETTINGS_NEW:-0}" "${SCAN_CLAUDE_MD_NEW:-0}" "${SCAN_AGENTS_MD_NEW:-0}" "${SCAN_COMMANDS_NEW:-0}" "${SCAN_AGENTS_NEW:-0}" "${SCAN_OTHER_NEW:-0}")

  for ((i=0; i<count; i++)); do
    local label
    label=$(_scan_category_label "${cat_changes[$i]}" "${cat_news[$i]}")
    if [ "$label" = "unchanged" ]; then
      descriptions+=("${base_descriptions[$i]} - unchanged")
      checked+=("0")
    else
      descriptions+=("${base_descriptions[$i]} - $label")
      checked+=("1")
    fi
  done

  echo ""
  printf '  %bSelect which categories to update%b\n' "$TUI_BOLD" "$TUI_RESET"

  printf '\033[?25l'
  trap 'printf "\033[?25h"' RETURN 2>/dev/null || true

  local row_lines total_lines
  row_lines=$(_tui_menu_row_lines)
  total_lines=$((count * row_lines + 1))

  for ((i=0; i<count; i++)); do
    local checkbox="[ ]"
    [ "${checked[$i]}" -eq 1 ] && checkbox="[x]"
    if [ $i -eq $selected ]; then
      _tui_menu_row 1 "$checkbox" "${options[$i]}" "${descriptions[$i]}"
    else
      _tui_menu_row 0 "$checkbox" "${options[$i]}" "${descriptions[$i]}"
    fi
  done
  tui_menu_footer "multi"

  while true; do
    IFS= read -rsn1 key
    case "$key" in
      $'\x1b')
        local seq=""
        if seq="$(_tui_read_escape_sequence)"; then
          case "$seq" in
            '[A') selected=$(((selected - 1 + count) % count)) ;;
            '[B') selected=$(((selected + 1) % count)) ;;
            *) tui_abort_setup ;;
          esac
        else
          tui_abort_setup
        fi
        ;;
      " ")
        [ "${checked[$selected]}" -eq 1 ] && checked[$selected]=0 || checked[$selected]=1
        ;;
      "")
        break
        ;;
    esac

    printf "\033[${total_lines}A"
    for ((i=0; i<count; i++)); do
      local checkbox="[ ]"
      [ "${checked[$i]}" -eq 1 ] && checkbox="[x]"
      if [ $i -eq $selected ]; then
        _tui_menu_row 1 "$checkbox" "${options[$i]}" "${descriptions[$i]}"
      else
        _tui_menu_row 0 "$checkbox" "${options[$i]}" "${descriptions[$i]}"
      fi
    done
    tui_menu_footer "multi"
  done

  printf '\033[?25h'

  UPD_HOOKS="no"; UPD_SETTINGS="no"; UPD_CLAUDE_MD="no"; UPD_AGENTS_MD="no"; UPD_COMMANDS="no"; UPD_AGENTS="no"; UPD_OTHER="no"
  [ "${checked[0]}" -eq 1 ] && UPD_HOOKS="yes"
  [ "${checked[1]}" -eq 1 ] && UPD_SETTINGS="yes"
  [ "${checked[2]}" -eq 1 ] && UPD_CLAUDE_MD="yes"
  [ "${checked[3]}" -eq 1 ] && UPD_AGENTS_MD="yes"
  [ "${checked[4]}" -eq 1 ] && UPD_COMMANDS="yes"
  [ "${checked[5]}" -eq 1 ] && UPD_AGENTS="yes"
  [ "${checked[6]}" -eq 1 ] && UPD_OTHER="yes"

  if [ "$UPD_HOOKS" = "no" ] && [ "$UPD_SETTINGS" = "no" ] && [ "$UPD_CLAUDE_MD" = "no" ] && [ "$UPD_AGENTS_MD" = "no" ] && [ "$UPD_COMMANDS" = "no" ] && [ "$UPD_AGENTS" = "no" ] && [ "$UPD_OTHER" = "no" ]; then
    echo ""
    return 1
  fi
  return 0
}

# ==============================================================================
# OVERWRITE CONFIRMATION
# ==============================================================================
# Prompts user to confirm overwriting a user-modified file.
# Returns 0 if user confirms overwrite, 1 to keep user's version.
ask_overwrite_modified() {
  local file="$1"
  local prompt
  prompt="$(tui_prompt_text "${file} (user-modified) - overwrite with template? [y/N, Esc cancels]: ")"
  if [ "$TUI_IS_TTY" = "yes" ]; then
    printf '%s' "$prompt"
    local answer=""
    IFS= read -rsn1 answer </dev/tty
    case "$answer" in
      $'\x1b') tui_abort_setup ;;
      y|Y)
        printf '%s\n' "$answer"
        return 0
        ;;
      "")
        printf '\n'
        return 1
        ;;
      *)
        printf '%s\n' "$answer"
        return 1
        ;;
    esac
  fi

  local answer
  IFS= read -r answer </dev/tty
  [ "$answer" = $'\x1b' ] && tui_abort_setup
  case "$answer" in
    y|Y|yes|YES|Yes) return 0 ;;
    *)               return 1 ;;
  esac
}
