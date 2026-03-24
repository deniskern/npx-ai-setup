#!/bin/bash

# ==============================================================================
# @onedot/ai-setup - AI infrastructure for projects
# ==============================================================================
# Installs Claude Code hooks, project context, and AI-curated skills
# Usage: npx @onedot/ai-setup [--patch <pattern>]
# Auto-detects updates: if .ai-setup.json exists with older version, offers update/reinstall
# ==============================================================================

set -e

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
TPL="$SCRIPT_DIR/templates"

# Parse flags
PATCH_PATTERN=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --patch)
      if [[ $# -lt 2 ]]; then
        echo "❌ --patch requires a pattern (e.g. --patch spec-work)"
        exit 1
      fi
      PATCH_PATTERN="$2"; shift 2 ;;
    --reset|--system|--regenerate)
      echo "❌ Flag '$1' has been removed. Use the Reset option in the interactive menu instead."
      exit 1
      ;;
    *) shift ;;
  esac
done

# Load modules
source "$SCRIPT_DIR/lib/_loader.sh"
source_lib "json.sh"
source_lib "core.sh"
source_lib "process.sh"
source_lib "detect.sh"
source_lib "tui.sh"
source_lib "skills.sh"
source_lib "generate.sh"
source_lib "migrate.sh"
source_lib "update.sh"
source_lib "setup.sh"
source_lib "setup-skills.sh"
source_lib "setup-compat.sh"
source_lib "plugins.sh"
source_lib "boilerplate.sh"
trap 'tui_cleanup' EXIT INT TERM

ensure_valid_working_directory || exit 1

# Fast patch mode — copy specific template files without full update flow
if [ -n "$PATCH_PATTERN" ]; then
  run_patch "$PATCH_PATTERN"
  exit $?
fi

# Lightweight registry check (cached) to hint when a newer ai-setup is available.
show_cli_update_notice

# Shared launch banner for fresh install and update flows.
tui_brand_banner_once "Install project rules, workflow files, and helper tools"

# ==============================================================================
# AUTO-DETECT: UPDATE / REINSTALL / FRESH INSTALL
# ==============================================================================
if [ -f .ai-setup.json ] && jq -e . .ai-setup.json >/dev/null 2>&1; then
  handle_version_check
fi

# ==============================================================================
# NORMAL SETUP MODE
# ==============================================================================
tui_brand_banner_once "Install project rules, workflow files, and helper tools"
tui_section "Set Up Project" "Create core instructions, settings, workflow files, and helper tools"

check_requirements
cleanup_legacy
install_claude_md
install_agents_md
install_settings
install_gemini_config
install_codex_config
install_hooks
install_rules
install_copilot
mkdir -p .agents
ensure_skills_alias
ensure_codex_skills_alias
ensure_gemini_skills_alias
ensure_opencode_skills_alias
install_specs
install_workflow_guide
install_skills
install_claude_scripts
install_agents
cleanup_orphans
select_boilerplate_system
customize_settings_for_stack
tui_step "Writing installation metadata"
write_metadata
update_gitignore
install_claudeignore

# Plugins & extensions
tui_section "Plugins & Extensions" "Marketplace plugins, MCP servers, and editor-side helpers"

install_claude_mem
install_official_plugins
install_context7
show_plugin_summary

# Global skills (stack-specific skills come from boilerplate or /find-skills)
run_skill_installation

# OpenCode compatibility (generates opencode.json from .mcp.json)
generate_opencode_config

# Statusline (global install — only if not already configured in ~/.claude/settings.json)
if ! jq -e '.statusLine' "$HOME/.claude/settings.json" >/dev/null 2>&1; then
  tui_section "Statusline" "Optional global Claude Code status line"
  if ask_yes_no_menu \
    "Install the optional Claude Code statusline?" \
    "Yes" "Install it now" \
    "No" "Skip this step" \
    "no"; then
    install_statusline_project
  fi
fi

# Optional context generation
tui_section "Finish Setup" "Optionally generate project-specific docs and context with Claude"
tui_success "Base setup complete"

if [ "$AI_CLI" = "claude" ]; then
  if ask_yes_no_menu \
    "Generate project-specific context now?" \
    "Yes" "Generate docs and context now" \
    "No" "Do this later" \
    "yes"; then
    AUTO_INIT_OK="no"
    if run_generation; then
      AUTO_INIT_OK="yes"
      tui_success "Project context generated"
      _NOTIFY_MSG="Project context generated"
    else
      tui_warn "Project context generated with warnings"
      _NOTIFY_MSG="Project context generated with warnings"
    fi
    case "$(uname -s)" in
      Darwin) osascript -e "display notification \"$_NOTIFY_MSG\" with title \"Project Setup\" sound name \"Glass\"" 2>/dev/null || true ;;
      Linux) command -v notify-send >/dev/null 2>&1 && notify-send "Project Setup" "$_NOTIFY_MSG" 2>/dev/null || true ;;
    esac
  fi
elif [ "$AI_CLI" = "copilot" ]; then
  tui_hint \
    "GitHub Copilot detected (no claude CLI) — manual steps required:" \
    "  1. Open VS Code / GitHub Copilot Chat" \
    "  2. Ask Copilot to extend CLAUDE.md and AGENTS.md with project-specific sections"
else
  tui_hint \
    "No AI CLI detected — install Claude Code to continue:" \
    "  npm i -g @anthropic-ai/claude-code" \
    "  Then follow the next steps shown below."
fi

show_installation_summary
show_next_steps

# Generate project context files (.agents/context/STACK.md, ARCHITECTURE.md, CONVENTIONS.md)
if [ "$AI_CLI" = "claude" ]; then
  tui_section "Project Context" "Refreshing STACK.md, ARCHITECTURE.md, and CONVENTIONS.md"
  tui_spinner_start "Generating project context files"
  if claude --agent context-refresher "Analyze this project and generate .agents/context/STACK.md, .agents/context/ARCHITECTURE.md, and .agents/context/CONVENTIONS.md." >/dev/null 2>&1; then
    tui_spinner_stop ok "Project context files refreshed"
  else
    tui_spinner_stop warn "Project context refresh skipped"
  fi
  tui_hint "Run /analyze to generate PATTERNS.md and AUDIT.md for this project."
fi
