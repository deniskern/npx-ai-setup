#!/bin/bash
# Interactive TUI menus: regeneration parts, update parts
# Sets: $REGEN_*, $UPD_*

# ==============================================================================
# REGENERATION PART SELECTOR
# ==============================================================================
# Sets REGEN_CLAUDE_MD, REGEN_AGENTS_MD, REGEN_CONTEXT, REGEN_COMMANDS,
# REGEN_AGENTS, REGEN_SKILLS globals.
# Returns 1 if the user selected nothing (skip).
ask_regen_parts() {
  # Arrow keys + Space to toggle + Enter to confirm
  local options=("CLAUDE.md" "AGENTS.md" "Context" "Commands" "Agents" "Skills")
  local descriptions=("Main instructions + project guardrails" "Agent workflow + role guidelines" ".agents/context/{STACK,ARCHITECTURE,CONVENTIONS}" ".claude/commands/ slash commands" ".claude/agents/ subagent templates" "Global skills (agent-browser, find-skills, gh-cli)")
  local count=6
  local selected=0
  local checked=(1 1 1 1 1 1)  # all pre-selected

  echo ""
  echo "  Select what to regenerate:"
  echo "  (Use ↑↓ arrows, Space to toggle, Enter to confirm)"
  echo ""

  printf '\033[?25l'
  trap 'printf "\033[?25h"' RETURN 2>/dev/null || true

  for ((i=0; i<count; i++)); do
    local checkbox="[ ]"
    [ "${checked[$i]}" -eq 1 ] && checkbox="[✓]"
    if [ $i -eq $selected ]; then
      printf '  \033[7m ▸ %s %-12s %s \033[0m\n' "$checkbox" "${options[$i]}" "${descriptions[$i]}"
    else
      printf '    %s %-12s %s\n' "$checkbox" "${options[$i]}" "${descriptions[$i]}"
    fi
  done

  while true; do
    IFS= read -rsn1 key
    case "$key" in
      $'\x1b')
        read -rsn2 seq
        case "$seq" in
          '[A') selected=$(( (selected - 1 + count) % count )) ;;
          '[B') selected=$(( (selected + 1) % count )) ;;
        esac
        ;;
      " ")
        [ "${checked[$selected]}" -eq 1 ] && checked[$selected]=0 || checked[$selected]=1
        ;;
      "")
        break
        ;;
    esac

    printf "\033[${count}A"
    for ((i=0; i<count; i++)); do
      local checkbox="[ ]"
      [ "${checked[$i]}" -eq 1 ] && checkbox="[✓]"
      if [ $i -eq $selected ]; then
        printf '  \033[7m ▸ %s %-12s %s \033[0m\033[K\n' "$checkbox" "${options[$i]}" "${descriptions[$i]}"
      else
        printf '    %s %-12s %s\033[K\n' "$checkbox" "${options[$i]}" "${descriptions[$i]}"
      fi
    done
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

# Format change count for a category: "2 changed" / "1 new" / "unchanged"
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
  local options=("Hooks" "Settings" "CLAUDE.md" "AGENTS.md" "Commands" "Agents" "Other")
  local base_descriptions=(".claude/hooks + .claude/rules" ".claude/settings.json" "Root CLAUDE.md template" "Root AGENTS.md template" ".claude/commands/" ".claude/agents/" "specs/, .github/, misc")
  local count=7
  local selected=0

  # Build per-category change labels and pre-select only changed categories
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
      descriptions+=("${base_descriptions[$i]} — unchanged")
      checked+=("0")
    else
      descriptions+=("${base_descriptions[$i]} — $label")
      checked+=("1")
    fi
  done

  echo ""
  echo "  Select which categories to update:"
  echo "  (Use ↑↓ arrows, Space to toggle, Enter to confirm)"
  echo ""

  printf '\033[?25l'
  trap 'printf "\033[?25h"' RETURN 2>/dev/null || true

  for ((i=0; i<count; i++)); do
    local checkbox="[ ]"
    [ "${checked[$i]}" -eq 1 ] && checkbox="[✓]"
    if [ $i -eq $selected ]; then
      printf '  \033[7m ▸ %s %-12s %s \033[0m\n' "$checkbox" "${options[$i]}" "${descriptions[$i]}"
    else
      printf '    %s %-12s %s\n' "$checkbox" "${options[$i]}" "${descriptions[$i]}"
    fi
  done

  while true; do
    IFS= read -rsn1 key
    case "$key" in
      $'\x1b')
        read -rsn2 seq
        case "$seq" in
          '[A') selected=$(( (selected - 1 + count) % count )) ;;
          '[B') selected=$(( (selected + 1) % count )) ;;
        esac
        ;;
      " ")
        [ "${checked[$selected]}" -eq 1 ] && checked[$selected]=0 || checked[$selected]=1
        ;;
      "")
        break
        ;;
    esac

    printf "\033[${count}A"
    for ((i=0; i<count; i++)); do
      local checkbox="[ ]"
      [ "${checked[$i]}" -eq 1 ] && checkbox="[✓]"
      if [ $i -eq $selected ]; then
        printf '  \033[7m ▸ %s %-12s %s \033[0m\033[K\n' "$checkbox" "${options[$i]}" "${descriptions[$i]}"
      else
        printf '    %s %-12s %s\033[K\n' "$checkbox" "${options[$i]}" "${descriptions[$i]}"
      fi
    done
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
  printf "  ⚠️  %s (user-modified) — Overwrite with template? [y/N]: " "$file"
  local answer
  IFS= read -r answer </dev/tty
  case "$answer" in
    y|Y|yes|YES|Yes) return 0 ;;
    *)               return 1 ;;
  esac
}
