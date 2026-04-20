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
FORCE_SKIP_GRAPHIFY=false
INSTALL_GRAPHIFY=no
FORCE_ALL_SKILLS=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --patch)
      if [[ $# -lt 2 ]]; then
        echo "❌ --patch requires a pattern (e.g. --patch spec-work)"
        exit 1
      fi
      PATCH_PATTERN="$2"; shift 2 ;;
    --force-skip-graphify)
      FORCE_SKIP_GRAPHIFY=true; shift ;;
    --force-all-skills)
      FORCE_ALL_SKILLS=1; shift ;;
    --relax-context-caps)
      export CONTEXT_CAPS_RELAX=1; shift ;;
    --reset|--system|--regenerate|--audit|--force-skills)
      echo "❌ Flag '$1' is not supported. Use the interactive setup/update flow instead."
      exit 1
      ;;
    --*)
      echo "❌ Unsupported flag '$1'. Supported flags: --patch <pattern> | --force-skip-graphify | --force-all-skills | --relax-context-caps"
      exit 1
      ;;
    *)
      echo "❌ Unexpected argument '$1'. Supported flags: --patch <pattern> | --force-skip-graphify | --force-all-skills | --relax-context-caps"
      exit 1
      ;;
  esac
done
export FORCE_ALL_SKILLS

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
source_lib "skill-filter.sh"
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
if [ -f .ai-setup.json ] && _json_valid .ai-setup.json; then
  handle_version_check
fi

# ==============================================================================
# PROJECT CONFIG: read aiSetup flags from package.json
# ==============================================================================
SKIP_SKILLS=false
if [ -f package.json ]; then
  _skip_val=$(_json_read package.json '.aiSetup.skipSkills' 2>/dev/null || true)
  [ "$_skip_val" = "true" ] && SKIP_SKILLS=true
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
if [ "$SKIP_SKILLS" = "true" ]; then
  tui_info "Skills skipped (aiSetup.skipSkills: true in package.json)"
else
  install_skills
fi
install_claude_scripts
install_agents
tui_section "Global Convenience" "Optional cross-project agents and statusline"
install_global_agents
cleanup_orphans
select_boilerplate_system
customize_settings_for_stack
tui_step "Writing installation metadata"
write_metadata
update_gitignore

# Detect stack profile + graphify candidate (used for claudeignore + graphify prompt)
STACK_PROFILE="default"
GRAPHIFY_CANDIDATE="false"
if [ -f "$SCRIPT_DIR/lib/detect-stack.sh" ]; then
  _detect_out=$(bash "$SCRIPT_DIR/lib/detect-stack.sh" "$PWD" 2>/dev/null || true)
  STACK_PROFILE=$(printf '%s\n' "$_detect_out" | grep '^stack_profile=' | cut -d= -f2 || echo "default")
  GRAPHIFY_CANDIDATE=$(printf '%s\n' "$_detect_out" | grep '^graphify_candidate=' | cut -d= -f2 || echo "false")
fi
export STACK_PROFILE
install_claudeignore

# Graphify opt-in (only when candidate, not skipped, and terminal is interactive)
if [ "$GRAPHIFY_CANDIDATE" = "true" ] && [ "$FORCE_SKIP_GRAPHIFY" = "false" ] && [ -t 0 ]; then
  if [ -f ".claude/skills/graphify/SKILL.md" ] || [ -f ".claude/skills/graphify.md" ]; then
    tui_info "Graphify skill already installed — skipping prompt"
    INSTALL_GRAPHIFY=yes
  else
    tui_section "Knowledge Graph" "Optional: Graphify semantic knowledge graph (opt-in)"
    if ask_yes_no_menu \
      "Activate Graphify knowledge graph for this project?" \
      "Yes" "Install graphify skill now (requires: pipx install graphifyy)" \
      "No" "Skip — can be added later via --patch graphify" \
      "yes"; then
      INSTALL_GRAPHIFY=yes
    fi
  fi
fi
export INSTALL_GRAPHIFY

# Plugins & extensions
tui_section "Plugins & Extensions" "Marketplace plugins, MCP servers, and editor-side helpers"

install_claude_mem
install_official_plugins
install_mcp_suggestions
show_plugin_summary

# Global skills (stack-specific skills come from boilerplate or /find-skills)
if [ "$SKIP_SKILLS" != "true" ]; then
  if ! run_skill_installation; then
    tui_warn "Shared skill installation completed with warnings"
  fi
fi

# Graphify skill install (opt-in, only when user confirmed above)
if [ "${INSTALL_GRAPHIFY:-no}" = "yes" ]; then
  install_graphify_skill
fi

# OpenCode compatibility (generates opencode.json from .mcp.json)
generate_opencode_config

# Statusline (global install — only if not already configured in ~/.claude/settings.json)
statusline_settings="$HOME/.claude/settings.json"
statusline_configured=false
if [ -f "$statusline_settings" ] && _json_valid "$statusline_settings"; then
  if [ -n "$(_json_read "$statusline_settings" '.statusLine' 2>/dev/null)" ]; then
    statusline_configured=true
  fi
fi
if [ "$statusline_configured" = "false" ] && [ -t 0 ]; then
  tui_section "Statusline" "Optional global Claude Code status line"
  if ask_yes_no_menu \
    "Install the optional Claude Code statusline?" \
    "Yes" "Install it now" \
    "No" "Skip this step" \
    "no"; then
    install_statusline_project
  fi
fi
unset _statusline_config

# Install context bundle for detected stack profile (STACK_PROFILE set above)
# Must run BEFORE any LLM call so bundle files are present and REGEN_CONTEXT can be suppressed.
BUNDLE_DIR="$SCRIPT_DIR/templates/context-bundles/${STACK_PROFILE}"
CONTEXT_DIR=".agents/context"
_BUNDLE_INSTALLED=0

if [ "$STACK_PROFILE" != "default" ] && [ -d "$BUNDLE_DIR" ]; then
  tui_section "Project Context" "Installing $STACK_PROFILE context bundle (zero LLM cost)"
  mkdir -p "$CONTEXT_DIR"
  _bundle_skip=0
  for _f in STACK.md ARCHITECTURE.md CONVENTIONS.md; do
    if [ -f "$CONTEXT_DIR/$_f" ] && ! grep -q "<!-- bundle:" "$CONTEXT_DIR/$_f" 2>/dev/null; then
      # File exists and was manually edited (no bundle marker) — don't overwrite
      tui_warn "$_f already exists (custom). Saving bundle as ${_f}.new"
      cp "$BUNDLE_DIR/$_f" "$CONTEXT_DIR/${_f}.new"
      _bundle_skip=$((_bundle_skip + 1))
    else
      cp "$BUNDLE_DIR/$_f" "$CONTEXT_DIR/$_f"
    fi
  done
  if [ -f "$SCRIPT_DIR/lib/generate-summary.sh" ]; then
    bash "$SCRIPT_DIR/lib/generate-summary.sh" "$BUNDLE_DIR" "$CONTEXT_DIR" 2>/dev/null || true
  fi
  _BUNDLE_INSTALLED=1
  if [ "$_bundle_skip" -gt 0 ]; then
    tui_warn "Bundle installed. $_bundle_skip file(s) saved as .new (review and rename if wanted)"
  else
    tui_success "Context bundle installed (${STACK_PROFILE})"
  fi
  tui_hint "Edit .agents/context/*.md to add project-specific details. Remove <!-- bundle: --> marker to prevent future overwrites."
  # Context files come from the bundle — skip LLM context generation
  REGEN_CONTEXT=no
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

# Liquid dependency graph for shopify-liquid profile
if [ "$STACK_PROFILE" = "shopify-liquid" ] && [ -f "$SCRIPT_DIR/lib/build-liquid-graph.sh" ]; then
  tui_step "Building Liquid dependency graph"
  if bash "$SCRIPT_DIR/lib/build-liquid-graph.sh" "$PWD" 2>/dev/null; then
    tui_success "Liquid graph built (.agents/context/liquid-graph.json)"
  else
    tui_warn "Liquid graph skipped (non-fatal)"
  fi
fi

if [ "$AI_CLI" = "claude" ]; then
  tui_hint "Run /analyze to generate PATTERNS.md and AUDIT.md for this project."
fi
