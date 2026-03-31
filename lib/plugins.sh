#!/bin/bash
# Plugin & extension installation: Claude-Mem, official plugins, Context7
# Requires: $AI_CLI

PENDING_PLUGINS=""

# Claude-Mem (Marketplace Plugin — persistent memory)
install_claude_mem() {
  CLAUDE_MEM_DIR="${HOME}/.claude/plugins/cache/thedotmack/claude-mem"

  if [ -d "$CLAUDE_MEM_DIR" ]; then
    echo "  🧠 Claude-Mem already installed, skipping."
  else
    # Merge extraKnownMarketplaces + enabledPlugins into .claude/settings.json
    if [ -f .claude/settings.json ]; then
      CLAUDE_MEM_MERGE='{"extraKnownMarketplaces":{"thedotmack":{"source":{"source":"github","repo":"thedotmack/claude-mem"}}},"enabledPlugins":{"claude-mem@thedotmack":true}}'
      if _json_merge .claude/settings.json "$CLAUDE_MEM_MERGE"; then
        echo "  🧠 Claude-Mem marketplace registered in .claude/settings.json"
      else
        echo "  ⚠️  Claude-Mem marketplace registration skipped (could not update .claude/settings.json)"
      fi
    fi

    # Try CLI install (works if claude is available)
    if command -v claude &>/dev/null; then
      echo "  🧠 Attempting Claude-Mem install via CLI..."
      if claude plugin install claude-mem@thedotmack --scope project 2>/dev/null; then
        echo "  ✅ Claude-Mem installed via CLI"
      else
        PENDING_PLUGINS="${PENDING_PLUGINS}claude-mem "
        echo "  📋 Claude-Mem registered — will be prompted on next Claude Code session"
      fi
    else
      PENDING_PLUGINS="${PENDING_PLUGINS}claude-mem "
      echo "  📋 Claude-Mem registered — teammates will be prompted to install when they trust this project"
    fi
  fi
}

# Official Claude Code Plugins (code-review, feature-dev, etc.)
install_official_plugins() {
  OFFICIAL_PLUGINS=(
    "code-review:Automated PR review with 4 parallel agents + confidence scoring"
    "feature-dev:7-phase feature workflow (discovery → architecture → review)"
  )

  INSTALLED_PLUGINS=""
  for i in "${!OFFICIAL_PLUGINS[@]}"; do
    IFS=':' read -r PNAME PDESC <<< "${OFFICIAL_PLUGINS[$i]}"

    # Check if already installed (plugin cache or .claude/settings.json)
    if [ -d "${HOME}/.claude/plugins/cache/anthropics/${PNAME}" ] 2>/dev/null; then
      echo "  🔌 ${PNAME} already installed, skipping."
      continue
    fi

    # Try CLI install
    if command -v claude &>/dev/null; then
      echo "  🔌 Installing ${PNAME}..."
      if claude plugin install "${PNAME}" --scope project 2>/dev/null; then
        INSTALLED_PLUGINS="${INSTALLED_PLUGINS}${PNAME} "
        echo "  ✅ ${PNAME} installed"
      else
        PENDING_PLUGINS="${PENDING_PLUGINS}${PNAME} "
        echo "  📋 ${PNAME} — install manually: /plugin install ${PNAME}"
      fi
    else
      PENDING_PLUGINS="${PENDING_PLUGINS}${PNAME} "
      echo "  📋 ${PNAME} — install manually: /plugin install ${PNAME}"
    fi
  done
}

# Context7 MCP Server (up-to-date library docs)
install_context7() {
  # Create or merge .mcp.json
  CTX7_CONFIG='{"mcpServers":{"context7":{"command":"npx","args":["-y","@upstash/context7-mcp"]}}}'

  if [ -f .mcp.json ]; then
    if grep -q '"context7"' .mcp.json 2>/dev/null; then
      echo "  📚 Context7 already configured in .mcp.json, skipping."
    else
      _json_merge .mcp.json "$CTX7_CONFIG"
      echo "  📚 Context7 MCP server added to .mcp.json"
    fi
  else
    echo "$CTX7_CONFIG" > .mcp.json
    echo "  📚 Context7 MCP server configured in .mcp.json"
  fi

  # Add Context7 rule to CLAUDE.md
  if [ -f CLAUDE.md ] && ! grep -q "context7" CLAUDE.md 2>/dev/null; then
    cat >> CLAUDE.md << 'CTX7EOF'

## Documentation Lookup
Always use Context7 MCP when you need library/API documentation, code generation,
setup or configuration steps. Add "use context7" to prompts or it will be auto-invoked.
CTX7EOF
    echo "  📚 Context7 rule added to CLAUDE.md"
  fi
}

# Show pending plugin install instructions
show_plugin_summary() {
  if [ -n "$PENDING_PLUGINS" ]; then
    echo ""
    tui_warn "Pending plugin installations (run in a Claude Code session)"
    for PP in $PENDING_PLUGINS; do
      case "$PP" in
        claude-mem)
          echo "     /plugin marketplace add thedotmack/claude-mem"
          echo "     /plugin install claude-mem"
          ;;
*)
          echo "     /plugin install ${PP}"
          ;;
      esac
    done
    echo ""
    tui_hint "Restart Claude Code afterwards to activate the new plugins."
  fi
}

# Show installation summary
show_installation_summary() {
  tui_section "Setup Summary" "Project files, plugins, and optional follow-up tasks"
  tui_success "Setup complete. Core project files are ready."
  echo ""
  local docs_status hooks_status workflow_status mcp_status skills_status context_status plugin_status
  docs_status="CLAUDE.md"
  [ -f AGENTS.md ] && docs_status="${docs_status}, AGENTS.md"
  hooks_status="missing"
  [ -d .claude/hooks ] && hooks_status="installed"
  workflow_status="basic"
  [ -d .claude/commands ] && workflow_status="commands"
  [ -d .claude/agents ] && workflow_status="${workflow_status} + agents"
  [ -d specs ] && workflow_status="${workflow_status} + specs"
  mcp_status="not configured"
  [ -f .mcp.json ] && mcp_status="configured"
  skills_status="none"
  [ ${INSTALLED:-0} -gt 0 ] && skills_status="${INSTALLED} installed"
  context_status="not generated"
  if [ "$AI_CLI" = "claude" ] && [[ ! "${RUN_INIT:-N}" =~ ^[Nn]$ ]]; then
    if [ "${AUTO_INIT_OK:-yes}" = "yes" ]; then
      context_status="generated"
    else
      context_status="generated with warnings"
    fi
  fi

  local CLAUDE_MEM_DIR="${HOME}/.claude/plugins/cache/thedotmack/claude-mem"
  local mem_status="pending"
  if [ -d "$CLAUDE_MEM_DIR" ]; then
    mem_status="installed"
  fi
  plugin_status="Claude-Mem ${mem_status}"
  [ -n "${INSTALLED_PLUGINS:-}" ] && plugin_status="${plugin_status}, extras ${INSTALLED_PLUGINS}"
  if [ -n "$PENDING_PLUGINS" ]; then
    plugin_status="${plugin_status}, pending ${PENDING_PLUGINS}"
  fi

  tui_key_value "Docs" "$docs_status"
  tui_key_value "Hooks" "$hooks_status"
  tui_key_value "Workflow" "$workflow_status"
  tui_key_value "MCP" "$mcp_status"
  tui_key_value "Skills" "$skills_status"
  tui_key_value "Context" "$context_status"
  tui_key_value "Plugins" "$plugin_status"

  echo ""
  tui_success "Project structure is ready"
}

# Full onboarding tips for fresh installs
show_next_steps() {
  tui_section "Get Started"

  printf '  Open Claude Code in this project and you are ready to go.\n'
  printf '  Run %b/analyze%b first to let Claude learn your codebase,\n' "$TUI_CYAN" "$TUI_RESET"
  printf '  then use %b/spec "your task"%b to plan before coding.\n' "$TUI_CYAN" "$TUI_RESET"
  echo ""

  printf '  %bSpec-Driven Development%b\n' "$TUI_BOLD" "$TUI_RESET"
  echo ""
  printf '  %b  /spec "add auth"%b\n' "$TUI_CYAN" "$TUI_RESET"
  printf '       %b│%b  Claude writes a structured plan\n' "$TUI_DIM" "$TUI_RESET"
  printf '       %b▼%b\n' "$TUI_DIM" "$TUI_RESET"
  printf '  %b  /spec-validate 171%b\n' "$TUI_CYAN" "$TUI_RESET"
  printf '       %b│%b  Check the plan before executing\n' "$TUI_DIM" "$TUI_RESET"
  printf '       %b▼%b\n' "$TUI_DIM" "$TUI_RESET"
  printf '  %b  /spec-work 171%b\n' "$TUI_CYAN" "$TUI_RESET"
  printf '       %b│%b  Claude implements step by step\n' "$TUI_DIM" "$TUI_RESET"
  printf '       %b▼%b\n' "$TUI_DIM" "$TUI_RESET"
  printf '  %b  /spec-review 171%b\n' "$TUI_CYAN" "$TUI_RESET"
  printf '       %b│%b  Verify against acceptance criteria\n' "$TUI_DIM" "$TUI_RESET"
  printf '       %b▼%b\n' "$TUI_DIM" "$TUI_RESET"
  printf '  %b  /commit%b\n' "$TUI_CYAN" "$TUI_RESET"
  echo ""

  printf '  %bEssential Commands%b\n' "$TUI_BOLD" "$TUI_RESET"
  printf '  %b/analyze%b           Deep codebase analysis → PATTERNS.md + AUDIT.md\n' "$TUI_CYAN" "$TUI_RESET"
  printf '  %b/review%b            Code review before committing\n' "$TUI_CYAN" "$TUI_RESET"
  printf '  %b/find-skills%b       Discover new skills from skills.sh\n' "$TUI_CYAN" "$TUI_RESET"
  printf '  %b/pause + /resume%b   Save and restore session state\n' "$TUI_CYAN" "$TUI_RESET"
  if [ -f .mcp.json ] && grep -q '"context7"' .mcp.json 2>/dev/null; then
    printf '  %buse context7%b       Add to any prompt for up-to-date docs\n' "$TUI_CYAN" "$TUI_RESET"
  fi
  echo ""

  printf '  %bReference%b\n' "$TUI_BOLD" "$TUI_RESET"
  printf '   %b%-12s%b ' "$TUI_DIM" "Guide:" "$TUI_RESET"
  tui_file_link "templates/WORKFLOW-GUIDE.md" "WORKFLOW-GUIDE.md"
  printf '\n'
  printf '   %b%-12s%b %s\n' "$TUI_DIM" "Skills:" "$TUI_RESET" "https://skills.sh/"
  printf '   %b%-12s%b %s\n' "$TUI_DIM" "Docs:" "$TUI_RESET" "https://docs.anthropic.com/en/docs/claude-code"
  printf '   %b%-12s%b %b%s%b\n' "$TUI_DIM" "Refresh:" "$TUI_RESET" "$TUI_CYAN" "npx @onedot/ai-setup" "$TUI_RESET"
  echo ""
}

# Compact reference for updates (no onboarding tips)
show_update_next_steps() {
  echo ""
  printf '  %bReference%b\n' "$TUI_BOLD" "$TUI_RESET"
  printf '   %b%-12s%b ' "$TUI_DIM" "Commands:" "$TUI_RESET"
  tui_file_link "templates/WORKFLOW-GUIDE.md" "WORKFLOW-GUIDE.md"
  printf '\n'
  printf '   %b%-12s%b ' "$TUI_DIM" "Changelog:" "$TUI_RESET"
  tui_file_link "CHANGELOG.md"
  printf '\n'
  printf '   %b%-12s%b %b%s%b\n' "$TUI_DIM" "Refresh:" "$TUI_RESET" "$TUI_CYAN" "npx @onedot/ai-setup" "$TUI_RESET"
  echo ""
}
