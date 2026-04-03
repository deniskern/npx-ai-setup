#!/bin/bash
# cli-tools.sh — Tool registry with auto-detect + install logic
# Requires: SCRIPT_DIR

# ==============================================================================
# TOOL REGISTRY
# Format: name:pm:package:tier:description
#   pm    = npm | cargo | brew
#   tier  = required | optional
# NOTE: descriptions must NOT contain colons — IFS=: parsing will truncate them
# ==============================================================================
CLI_TOOL_REGISTRY=(
  "rtk:npm:@onedot/rtk:required:Rust Token Killer — token-optimized Claude Code proxy"
  "defuddle:npm:defuddle:required:Web content parser (strips noise, 80% token savings)"
  "codex:npm:@openai/codex:optional:OpenAI Codex CLI (needs OPENAI_API_KEY)"
  "gemini:npm:@google/gemini-cli:optional:Google Gemini CLI (needs GEMINI_API_KEY)"
  "agent-browser:npm:agent-browser:required:Persistent browser daemon for Claude automation"
)

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

# Returns 0 if an npm package has a newer version available
_tool_outdated() {
  local package="$1"
  local pm="$2"

  [ "$pm" = "npm" ] || return 1

  # npm outdated -g returns non-zero if package is outdated
  local outdated_output
  outdated_output=$(npm outdated -g "$package" 2>/dev/null)
  [ -n "$outdated_output" ] && return 0
  return 1
}

# Install a single tool via its package manager
_install_tool() {
  local name="$1"
  local pm="$2"
  local package="$3"

  case "$pm" in
    npm)
      npm install -g "$package@latest" --quiet 2>&1 | tail -5 >&2
      [ "${PIPESTATUS[0]}" -eq 0 ] && return 0 || return 1
      ;;
    cargo)
      cargo install "$package" 2>&1 | tail -5 >&2
      [ "${PIPESTATUS[0]}" -eq 0 ] && return 0 || return 1
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
      if _tool_outdated "$package" "$pm"; then
        tui_warn "$name (update available)"
      else
        tui_success "$name"
      fi
    else
      if [ "$tier" = "required" ]; then
        tui_error "$name (missing - required)"
        missing_required=$((missing_required + 1))
      else
        # Check if prereqs are even possible
        if _tool_prereqs_met "$name" "$pm" "$tier" 2>/dev/null; then
          tui_warn "$name (not installed - optional)"
        else
          tui_info "$name (skipped - prerequisites missing)"
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
  local updated=0
  local skipped=0
  local failed=0

  for entry in "${CLI_TOOL_REGISTRY[@]}"; do
    IFS=: read -r name pm package tier description <<< "$entry"

    # Already installed — check for updates
    if _tool_installed "$name"; then
      if _tool_outdated "$package" "$pm"; then
        tui_spinner_start "Updating ${name}"
        if _install_tool "$name" "$pm" "$package"; then
          tui_spinner_stop ok "${name} updated to latest"
          updated=$((updated + 1))
        else
          tui_spinner_stop warn "${name} update failed (keeping current)"
        fi
      else
        tui_success "$name (up to date)"
      fi
      continue
    fi

    # Check prerequisites
    if ! _tool_prereqs_met "$name" "$pm" "$tier" 2>/dev/null; then
      tui_info "$name (skipped - prerequisites missing)"
      skipped=$((skipped + 1))
      continue
    fi

    # Attempt install
    tui_spinner_start "Installing ${name}"
    if _install_tool "$name" "$pm" "$package"; then
      tui_spinner_stop ok "${name} installed"
      installed=$((installed + 1))
      # Post-install: agent-browser needs Chrome for Testing downloaded once
      if [ "$name" = "agent-browser" ] && command -v agent-browser &>/dev/null; then
        tui_spinner_start "Downloading Chrome for Testing"
        if agent-browser install &>/dev/null; then
          tui_spinner_stop ok "Chrome for Testing ready"
        else
          tui_spinner_stop warn "Chrome for Testing skipped (non-fatal)"
        fi
      fi
    else
      if [ "$tier" = "required" ]; then
        tui_spinner_stop error "${name} install failed"
        failed=$((failed + 1))
      else
        tui_spinner_stop warn "${name} install failed (optional, skipping)"
        skipped=$((skipped + 1))
      fi
    fi
  done

  echo ""
  tui_info "Installed: $installed | Updated: $updated | Skipped: $skipped | Failed: $failed"

  # Ensure RTK hooks are active (idempotent — safe to re-run)
  if command -v rtk &>/dev/null; then
    if ! rtk gain &>/dev/null 2>&1; then
      tui_spinner_start "Activating RTK hooks"
      if rtk init --global &>/dev/null; then
        tui_spinner_stop ok "RTK hooks activated"
      else
        tui_spinner_stop warn "RTK hooks skipped (non-fatal)"
      fi
    fi
  fi

  if [ "$failed" -gt 0 ]; then
    echo ""
    tui_error "Required tool installation failed. Check npm permissions."
    return 1
  fi
}
