#!/bin/bash

# ==============================================================================
# @onedot/ai-setup-global - Global developer workstation setup
# ==============================================================================
# Installs CLI tools, global Claude settings, and developer workstation config.
# Independent of any project — run once per developer machine.
# Usage: npx @onedot/ai-setup-global [--check]
# ==============================================================================

set -euo pipefail

# Package root (one level above bin/)
# Resolve symlinks so npx installs work correctly (macOS-compatible, no readlink -f)
_SCRIPT="${BASH_SOURCE[0]}"
while [ -L "$_SCRIPT" ]; do
  _DIR="$(cd -P "$(dirname "$_SCRIPT")" && pwd)"
  _SCRIPT="$(readlink "$_SCRIPT")"
  [[ "$_SCRIPT" != /* ]] && _SCRIPT="$_DIR/$_SCRIPT"
done
SCRIPT_DIR="$(cd -P "$(dirname "$_SCRIPT")/.." && pwd)"
unset _SCRIPT _DIR

# Parse flags
CHECK_MODE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check) CHECK_MODE="yes"; shift ;;
    *) shift ;;
  esac
done

# Load modules
source "$SCRIPT_DIR/lib/_loader.sh"
source_lib "cli-tools.sh"
source_lib "global-settings.sh"

# ==============================================================================
# COLORS
# ==============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

# ==============================================================================
# PHASE HEADER
# ==============================================================================
_phase() {
  local num="$1"
  local title="$2"
  echo ""
  echo -e "${BOLD}Phase ${num}: ${title}${RESET}"
  echo "   ──────────────────────────────────────────────────────────"
}

# ==============================================================================
# PHASE 1: SYSTEM CHECK
# ==============================================================================
phase_system_check() {
  _phase 1 "System Check"

  local ok=true

  # macOS / Linux
  local platform
  platform="$(uname -s)"
  case "$platform" in
    Darwin) echo "   Platform : macOS ($(sw_vers -productVersion 2>/dev/null || echo 'unknown'))" ;;
    Linux)  echo "   Platform : Linux" ;;
    *)      echo "   Platform : $platform (untested)" ;;
  esac

  # Node.js
  if command -v node &>/dev/null; then
    local node_ver
    node_ver="$(node -v 2>/dev/null)"
    echo -e "   Node.js  : ${GREEN}${node_ver}${RESET}"
  else
    echo -e "   Node.js  : ${RED}not found${RESET} (install from https://nodejs.org)"
    ok=false
  fi

  # npm
  if command -v npm &>/dev/null; then
    echo -e "   npm      : ${GREEN}$(npm -v 2>/dev/null)${RESET}"
  else
    echo -e "   npm      : ${RED}not found${RESET}"
    ok=false
  fi

  # cargo (optional — needed for agent-browser)
  if command -v cargo &>/dev/null; then
    echo -e "   cargo    : ${GREEN}$(cargo -V 2>/dev/null | awk '{print $2}')${RESET}"
  else
    echo -e "   cargo    : ${YELLOW}not found${RESET} (optional — needed for agent-browser)"
  fi

  if [ "$ok" = "false" ]; then
    echo ""
    echo -e "   ${RED}Required tools missing. Install them and re-run.${RESET}"
    exit 1
  fi
}

# ==============================================================================
# PHASE 2: CLI TOOLS
# ==============================================================================
phase_cli_tools() {
  _phase 2 "CLI Tools"
  if [ "$CHECK_MODE" = "yes" ]; then
    check_cli_tools
  else
    install_cli_tools
  fi
}

# ==============================================================================
# PHASE 3: GLOBAL SETTINGS
# ==============================================================================
phase_global_settings() {
  _phase 3 "Global Claude Settings"
  if [ "$CHECK_MODE" = "yes" ]; then
    check_global_settings
  else
    install_global_settings
  fi
}

# ==============================================================================
# PHASE 4: API KEYS CHECK
# ==============================================================================
phase_api_keys() {
  _phase 4 "API Keys"

  local any_missing=false

  _check_key() {
    local name="$1"
    local var="$2"
    local hint="$3"
    if [ -n "${!var:-}" ]; then
      echo -e "   ${GREEN}✔${RESET}  $name ($var)"
    else
      echo -e "   ${YELLOW}✗${RESET}  $name ($var) — not set"
      if [ "$CHECK_MODE" != "yes" ]; then
        echo "      Add to ~/.zshrc:  export ${var}=\"your-key-here\""
        [ -n "$hint" ] && echo "      Get key: $hint"
      fi
      any_missing=true
    fi
  }

  _check_key "Anthropic" "ANTHROPIC_API_KEY" "https://console.anthropic.com/settings/keys"
  _check_key "OpenAI"    "OPENAI_API_KEY"    "https://platform.openai.com/api-keys"
  _check_key "Gemini"    "GEMINI_API_KEY"    "https://aistudio.google.com/app/apikey"

  if [ "$any_missing" = "true" ] && [ "$CHECK_MODE" != "yes" ]; then
    echo ""
    echo "   After adding keys, reload shell:  source ~/.zshrc"
  fi
}

# ==============================================================================
# MAIN
# ==============================================================================
main() {
  if [ "$CHECK_MODE" = "yes" ]; then
    echo -e "${BOLD}@onedot/ai-setup-global — Status Check${RESET}"
    echo "   Dry-run mode: no changes will be made."
  else
    echo -e "${BOLD}@onedot/ai-setup-global — Global Developer Workstation Setup${RESET}"
  fi

  phase_system_check
  phase_cli_tools
  phase_global_settings
  phase_api_keys

  echo ""
  if [ "$CHECK_MODE" = "yes" ]; then
    echo -e "${BOLD}Check complete.${RESET}"
  else
    echo -e "${GREEN}${BOLD}Setup complete!${RESET}"
    echo ""
    echo "   Reload your shell to activate all tools:"
    echo "     source ~/.zshrc"
  fi
  echo ""
}

main
