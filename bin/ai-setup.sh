#!/bin/bash

# ==============================================================================
# @onedot/ai-setup - AI infrastructure for projects
# ==============================================================================
# Installs Claude Code hooks, project context, and AI-curated skills
# Usage: npx @onedot/ai-setup [--force-skills] [--audit] [--patch <pattern>]
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
FORCE_SKILLS=""
RUN_AUDIT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --force-skills) FORCE_SKILLS="yes"; shift ;;
    --audit) RUN_AUDIT="yes"; shift ;;
    --patch)
      if [[ $# -lt 2 ]]; then
        echo "❌ --patch requires a pattern (e.g. --patch spec-work)"
        exit 1
      fi
      PATCH_PATTERN="$2"; shift 2 ;;
    --system|--regenerate)
      echo "❌ Flag '$1' has been removed. ai-setup is now a generic base layer."
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

# Fast patch mode — copy specific template files without full update flow
if [ -n "$PATCH_PATTERN" ]; then
  run_patch "$PATCH_PATTERN"
  exit $?
fi

# Lightweight registry check (cached) to hint when a newer ai-setup is available.
show_cli_update_notice

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
install_commands
install_claude_scripts
install_spec_skills
install_agents
select_boilerplate_system
echo "📋 Writing installation metadata..."
write_metadata
update_gitignore
install_claudeignore

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

# Statusline (global install — only if not already configured in ~/.claude/settings.json)
if ! jq -e '.statusLine' "$HOME/.claude/settings.json" >/dev/null 2>&1; then
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

# Generate project context files (.agents/context/STACK.md, ARCHITECTURE.md, CONVENTIONS.md)
if [ "$AI_CLI" = "claude" ]; then
  echo ""
  echo "📚 Generating project context files..."
  claude --agent context-refresher "Analyze this project and generate .agents/context/STACK.md, .agents/context/ARCHITECTURE.md, and .agents/context/CONVENTIONS.md." 2>/dev/null || \
    echo "⚠️  Context generation skipped (claude CLI unavailable or agent failed)"
fi

# --audit flag: run project onboarding audit after setup
if [ "${RUN_AUDIT:-}" = "yes" ] && [ "$AI_CLI" = "claude" ]; then
  echo ""
  echo "🔍 Running project onboarding audit..."
  claude --agent project-auditor "Analyze this project and produce .agents/context/PATTERNS.md and .agents/context/AUDIT.md. Follow the efficient reading strategy in your instructions. When done, ask the user if specs should be created for the top findings." 2>/dev/null || \
    echo "⚠️  Audit skipped (claude CLI unavailable or agent failed)"
fi
