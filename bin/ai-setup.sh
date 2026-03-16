#!/bin/bash

# ==============================================================================
# @onedot/ai-setup - AI infrastructure for projects
# ==============================================================================
# Installs Claude Code hooks, project context, and AI-curated skills
# Usage: npx @onedot/ai-setup [--system <name>] [--regenerate]
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
SYSTEM=""
REGENERATE=""
PATCH_PATTERN=""
FORCE_SKILLS=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --regenerate) REGENERATE="yes"; shift ;;
    --force-skills) FORCE_SKILLS="yes"; shift ;;
    --patch)
      if [[ $# -lt 2 ]]; then
        echo "❌ --patch requires a pattern (e.g. --patch spec-work)"
        exit 1
      fi
      PATCH_PATTERN="$2"; shift 2 ;;
    --system)
      if [[ $# -lt 2 ]]; then
        echo "❌ --system requires a value (auto|shopify|nuxt|next|laravel|shopware|storyblok)"
        exit 1
      fi
      SYSTEM="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# Load modules
source "$SCRIPT_DIR/lib/_loader.sh"
source_lib "core.sh"
source_lib "process.sh"
source_lib "detect.sh"
source_lib "tui.sh"
source_lib "skills.sh"
source_lib "generate.sh"
source_lib "update.sh"
source_lib "setup.sh"
source_lib "plugins.sh"

# Validate --system value (supports comma-separated list)
if [ -n "$SYSTEM" ]; then
  IFS=',' read -ra SYSTEMS_TO_VALIDATE <<< "$SYSTEM"
  for sys in "${SYSTEMS_TO_VALIDATE[@]}"; do
    VALID=false
    for s in "${VALID_SYSTEMS[@]}"; do
      [ "$sys" = "$s" ] && VALID=true
    done
    if [ "$VALID" = false ]; then
      echo "❌ Unknown system: $sys"
      echo "   Valid options: ${VALID_SYSTEMS[*]}"
      exit 1
    fi
  done
  # Ensure "auto" is not combined with other systems
  if [[ "$SYSTEM" == *"auto"* ]] && [[ "$SYSTEM" == *","* ]]; then
    echo "❌ 'auto' cannot be combined with other systems"
    exit 1
  fi
fi

# Fast patch mode — copy specific template files without full update flow
if [ -n "$PATCH_PATTERN" ]; then
  run_patch "$PATCH_PATTERN"
  exit $?
fi

# Lightweight registry check (cached) to hint when a newer ai-setup is available.
show_cli_update_notice

# ==============================================================================
# REGENERATE MODE (--regenerate flag)
# ==============================================================================
if [ "$REGENERATE" = "yes" ]; then
  if ! command -v claude &>/dev/null; then
    echo "❌ Claude CLI required for regeneration."
    echo "   Install: npm i -g @anthropic-ai/claude-code"
    exit 1
  fi

  # Select system if not provided via --system flag
  if [ -z "$SYSTEM" ]; then
    # Try to restore from previous run stored in .ai-setup.json
    if [ -f .ai-setup.json ] && jq -e . .ai-setup.json >/dev/null 2>&1; then
      STORED_SYSTEM=$(jq -r '.system // empty' .ai-setup.json 2>/dev/null)
      if [ -n "$STORED_SYSTEM" ] && [ "$STORED_SYSTEM" != "auto" ]; then
        SYSTEM="$STORED_SYSTEM"
        echo "  🔍 Restored system from previous run: $SYSTEM"
      fi
    fi
  fi
  if [ -z "$SYSTEM" ]; then
    select_system
  fi
  detect_system

  if run_generation; then
    echo ""
    echo "✅ Regeneration complete! (System: $SYSTEM)"
    echo "   - CLAUDE.md + AGENTS.md updated"
    [ -d .agents/context ] && echo "   - .agents/context/ regenerated"
    [ ${INSTALLED:-0} -gt 0 ] && echo "   - $INSTALLED skills installed"
    exit 0
  fi
  echo ""
  echo "⚠️  Regeneration finished with warnings (System: $SYSTEM)."
  echo "   Review the warnings above and re-run after fixing the underlying issue."
  exit 1
fi

# ==============================================================================
# AUTO-DETECT: UPDATE / REINSTALL / FRESH INSTALL
# ==============================================================================
if [ -f .ai-setup.json ] && jq -e . .ai-setup.json >/dev/null 2>&1; then
  handle_version_check
fi

# ==============================================================================
# NORMAL SETUP MODE
# ==============================================================================
echo "🚀 Starting AI Setup (Claude Code + Skills)..."

check_requirements
cleanup_legacy
install_claude_md
install_agents_md
install_settings
install_hooks
install_rules
install_copilot
mkdir -p .agents
ensure_skills_alias
ensure_codex_skills_alias
ensure_opencode_skills_alias
install_specs
install_workflow_guide
install_commands
install_spec_skills
install_shopify_skills
install_storyblok_scripts
install_agents
setup_repo_group_context
echo "📋 Writing installation metadata..."
write_metadata
update_gitignore
install_repomix_config
generate_repomix_snapshot

# Plugins & extensions
echo ""
echo "🔌 Plugins & Extensions"
echo "   ──────────────────────────────────────────────────────────"

install_claude_mem
install_coderabbit_plugin
install_official_plugins
install_context7
show_plugin_summary

# OpenCode compatibility (generates opencode.json from .mcp.json)
generate_opencode_config

# Statusline (project-level — only in fresh install mode, skip if already configured)
if ! jq -e '.statusLine' ".claude/settings.json" >/dev/null 2>&1; then
  echo ""
  echo "Statusline"
  echo "   ──────────────────────────────────────────────────────────"
  read -p "   Install statusline for Claude Code? (y/N) " INSTALL_STATUSLINE
  if [[ "$INSTALL_STATUSLINE" =~ ^[Yy]$ ]]; then
    install_statusline_project
  fi
fi

# Auto-Init
echo ""
echo "✅ Setup complete!"
echo ""

if [ "$AI_CLI" = "claude" ]; then
  read -p "🤖 Run Auto-Init now? (Y/n) " RUN_INIT
  if [[ ! "$RUN_INIT" =~ ^[Nn]$ ]]; then
    # Select system if not provided via --system flag
    if [ -z "$SYSTEM" ]; then
      select_system
    fi
    detect_system

    AUTO_INIT_OK="no"
    if run_generation; then
      AUTO_INIT_OK="yes"
      echo ""
      echo "✅ Auto-Init complete!"
      _NOTIFY_MSG="Auto-Init complete!"
    else
      echo ""
      echo "⚠️  Auto-Init finished with warnings. Review output above."
      _NOTIFY_MSG="Auto-Init finished with warnings"
    fi
    case "$(uname -s)" in
      Darwin) osascript -e "display notification \"$_NOTIFY_MSG\" with title \"AI Setup\" sound name \"Glass\"" 2>/dev/null || true ;;
      Linux) command -v notify-send >/dev/null 2>&1 && notify-send "AI Setup" "$_NOTIFY_MSG" 2>/dev/null || true ;;
    esac
  fi
elif [ "$AI_CLI" = "copilot" ]; then
  echo "💡 GitHub Copilot detected (no claude CLI)."
  echo "   Manual steps required:"
  echo ""
  echo "   1. Open VS Code / GitHub Copilot Chat"
  echo "   2. Ask Copilot to extend CLAUDE.md and AGENTS.md with project-specific sections"
else
  echo "⚠️  No AI CLI detected (neither claude nor gh copilot)."
  echo "   Install Claude Code: npm i -g @anthropic-ai/claude-code"
  echo "   Then run the setup steps in NEXT STEPS below"
fi

show_installation_summary
show_next_steps
