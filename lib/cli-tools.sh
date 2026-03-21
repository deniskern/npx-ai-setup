#!/bin/bash
# cli-tools.sh — Tool registry with auto-detect + install logic
# Requires: SCRIPT_DIR

# ==============================================================================
# TOOL REGISTRY
# Format: name:pm:package:tier:description
#   pm    = npm | cargo | brew
#   tier  = required | optional
# ==============================================================================
CLI_TOOL_REGISTRY=(
  "rtk:npm:@onedot/rtk:required:Rust Token Killer — token-optimized Claude Code proxy"
  "defuddle:npm:defuddle:required:Web content parser (strips noise, 80% token savings)"
  "repomix:npm:repomix:required:Pack repo into AI-readable format for Claude context"
  "codex:npm:@openai/codex:optional:OpenAI Codex CLI (needs OPENAI_API_KEY)"
  "gemini:npm:@google/gemini-cli:optional:Google Gemini CLI (needs GEMINI_API_KEY)"
  "agent-browser:cargo:agent-browser:optional:Persistent browser daemon for Claude automation (needs cargo)"
)

# Colors (safe to re-define — idempotent)
_CT_GREEN='\033[0;32m'
_CT_YELLOW='\033[1;33m'
_CT_RED='\033[0;31m'
_CT_RESET='\033[0m'

# ==============================================================================
# INTERNAL HELPERS
# ==============================================================================

# Returns 0 if a CLI tool is installed
_tool_installed() {
  command -v "$1" &>/dev/null
}

# Returns 0 if tool can be installed (prerequisites met)
_tool_prereqs_met() {
  local name="$1"
  local pm="$2"
  local tier="$3"

  # cargo tools require cargo
  if [ "$pm" = "cargo" ]; then
    command -v cargo &>/dev/null || return 1
  fi

  # Optional npm tools with API key guard
  if [ "$tier" = "optional" ] && [ "$pm" = "npm" ]; then
    case "$name" in
      codex)  [ -n "${OPENAI_API_KEY:-}" ]  || return 1 ;;
      gemini) [ -n "${GEMINI_API_KEY:-}" ]  || return 1 ;;
    esac
  fi

  return 0
}

# Install a single tool via its package manager
_install_tool() {
  local name="$1"
  local pm="$2"
  local package="$3"

  case "$pm" in
    npm)
      npm install -g "$package" --quiet 2>/dev/null && return 0 || return 1
      ;;
    cargo)
      cargo install "$package" 2>/dev/null && return 0 || return 1
      ;;
    brew)
      if command -v brew &>/dev/null; then
        brew install "$package" &>/dev/null && return 0 || return 1
      fi
      return 1
      ;;
    *)
      return 1
      ;;
  esac
}

# ==============================================================================
# PUBLIC: check_cli_tools (--check mode, no installs)
# ==============================================================================
check_cli_tools() {
  local missing_required=0

  for entry in "${CLI_TOOL_REGISTRY[@]}"; do
    IFS=: read -r name pm package tier description <<< "$entry"

    if _tool_installed "$name"; then
      echo -e "   ${_CT_GREEN}✔${_CT_RESET}  $name"
    else
      if [ "$tier" = "required" ]; then
        echo -e "   ${_CT_RED}✗${_CT_RESET}  $name (MISSING — required)"
        missing_required=$((missing_required + 1))
      else
        # Check if prereqs are even possible
        if _tool_prereqs_met "$name" "$pm" "$tier" 2>/dev/null; then
          echo -e "   ${_CT_YELLOW}✗${_CT_RESET}  $name (not installed — optional)"
        else
          echo -e "   ${_CT_YELLOW}-${_CT_RESET}  $name (skipped — prereqs missing)"
        fi
      fi
    fi
  done

  if [ "$missing_required" -gt 0 ]; then
    echo ""
    echo "   $missing_required required tool(s) not installed."
    echo "   Run without --check to install."
  fi
}

# ==============================================================================
# PUBLIC: install_cli_tools
# ==============================================================================
install_cli_tools() {
  local installed=0
  local skipped=0
  local failed=0

  for entry in "${CLI_TOOL_REGISTRY[@]}"; do
    IFS=: read -r name pm package tier description <<< "$entry"

    # Already installed — skip
    if _tool_installed "$name"; then
      echo -e "   ${_CT_GREEN}✔${_CT_RESET}  $name (already installed)"
      continue
    fi

    # Check prerequisites
    if ! _tool_prereqs_met "$name" "$pm" "$tier" 2>/dev/null; then
      echo -e "   ${_CT_YELLOW}-${_CT_RESET}  $name (skipped — prereqs missing)"
      skipped=$((skipped + 1))
      continue
    fi

    # Attempt install
    echo -n "   Installing $name ... "
    if _install_tool "$name" "$pm" "$package"; then
      echo -e "${_CT_GREEN}done${_CT_RESET}"
      installed=$((installed + 1))
    else
      if [ "$tier" = "required" ]; then
        echo -e "${_CT_RED}FAILED${_CT_RESET}"
        failed=$((failed + 1))
      else
        echo -e "${_CT_YELLOW}failed (optional, skipping)${_CT_RESET}"
        skipped=$((skipped + 1))
      fi
    fi
  done

  echo ""
  echo "   Installed: $installed | Skipped: $skipped | Failed: $failed"

  if [ "$failed" -gt 0 ]; then
    echo ""
    echo -e "   ${_CT_RED}Required tool installation failed. Check npm permissions.${_CT_RESET}"
    return 1
  fi
}
