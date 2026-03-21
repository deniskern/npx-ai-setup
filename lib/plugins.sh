#!/bin/bash
# Plugin & extension installation: Claude-Mem, official plugins, Context7
# Requires: $AI_CLI

PENDING_PLUGINS=""

# Legacy compatibility shim.
# GSD is intentionally optional and no longer auto-installed by ai-setup.
install_gsd() {
  echo "  🧩 GSD integration removed from default setup."
  return 0
}

# Legacy compatibility shim.
# Playwright auto-install was removed; keep function for older callers/tests.
install_playwright() {
  echo "  🎭 Playwright auto-install is deprecated and skipped."
  return 0
}

# Claude-Mem (Marketplace Plugin — persistent memory)
install_claude_mem() {
  CLAUDE_MEM_DIR="${HOME}/.claude/plugins/cache/thedotmack/claude-mem"

  if [ -d "$CLAUDE_MEM_DIR" ]; then
    echo "  🧠 Claude-Mem already installed, skipping."
  else
    # Merge extraKnownMarketplaces + enabledPlugins into .claude/settings.json
    if [ -f .claude/settings.json ]; then
      CLAUDE_MEM_MERGE='{"extraKnownMarketplaces":{"thedotmack":{"source":{"source":"github","repo":"thedotmack/claude-mem"}}},"enabledPlugins":{"claude-mem@thedotmack":true}}'
      _json_merge .claude/settings.json "$CLAUDE_MEM_MERGE"
      echo "  🧠 Claude-Mem marketplace registered in .claude/settings.json"
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

# CodeRabbit Claude Plugin (Marketplace Plugin — PR review companion)
install_coderabbit_plugin() {
  CODERABBIT_DIR="${HOME}/.claude/plugins/cache/coderabbitai/claude-plugin"

  if [ -d "$CODERABBIT_DIR" ]; then
    echo "  🐇 CodeRabbit plugin already installed, skipping."
    return 0
  fi

  # Merge marketplace + enabled plugin hints into project settings.
  if [ -f .claude/settings.json ]; then
    CODERABBIT_MERGE='{"extraKnownMarketplaces":{"coderabbitai":{"source":{"source":"github","repo":"coderabbitai/claude-plugin"}}},"enabledPlugins":{"claude-plugin@coderabbitai":true}}'
    _json_merge .claude/settings.json "$CODERABBIT_MERGE"
    echo "  🐇 CodeRabbit marketplace registered in .claude/settings.json"
  fi

  # Try CLI install (first marketplace id, then full repo fallback).
  if command -v claude &>/dev/null; then
    echo "  🐇 Attempting CodeRabbit plugin install via CLI..."
    if claude plugin install claude-plugin@coderabbitai --scope project 2>/dev/null || \
       claude plugin install coderabbitai/claude-plugin --scope project 2>/dev/null; then
      echo "  ✅ CodeRabbit plugin installed via CLI"
    else
      PENDING_PLUGINS="${PENDING_PLUGINS}coderabbit-plugin "
      echo "  📋 CodeRabbit plugin registered — will be prompted on next Claude Code session"
    fi
  else
    PENDING_PLUGINS="${PENDING_PLUGINS}coderabbit-plugin "
    echo "  📋 CodeRabbit plugin registered — teammates will be prompted to install when they trust this project"
  fi
}

# Official Claude Code Plugins (code-review, feature-dev, etc.)
install_official_plugins() {
  OFFICIAL_PLUGINS=(
    "code-review:Automated PR review with 4 parallel agents + confidence scoring"
    "feature-dev:7-phase feature workflow (discovery → architecture → review)"
    "frontend-design:Anti-generic design guidance for frontend projects"
    "commit-commands:Git workflow slash commands (/commit, /commit-push-pr, /clean_gone)"
  )

  INSTALLED_PLUGINS=""
  for i in "${!OFFICIAL_PLUGINS[@]}"; do
    IFS=':' read -r PNAME PDESC <<< "${OFFICIAL_PLUGINS[$i]}"

    # Skip frontend-design only for known backend-only stacks
    if [ "$PNAME" = "frontend-design" ] && [ -n "$SYSTEM" ] && [ "$SYSTEM" != "auto" ]; then
      local is_backend_only="no"
      for sys in $(echo "$SYSTEM" | tr ',' ' '); do
        case "$sys" in shopware|laravel) is_backend_only="yes" ;; esac
      done
      if [ "$is_backend_only" = "yes" ]; then
        echo "  ⏭️  frontend-design skipped (backend stack: ${SYSTEM})"
        continue
      fi
    fi

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
    echo "  ⚡ Pending plugin installations (run in a Claude Code session):"
    for PP in $PENDING_PLUGINS; do
      case "$PP" in
        claude-mem)
          echo "     /plugin marketplace add thedotmack/claude-mem"
          echo "     /plugin install claude-mem"
          ;;
        coderabbit-plugin)
          echo "     /plugin marketplace add coderabbitai/claude-plugin"
          echo "     /plugin install claude-plugin@coderabbitai"
          echo "     # fallback:"
          echo "     /plugin install coderabbitai/claude-plugin"
          ;;
        *)
          echo "     /plugin install ${PP}"
          ;;
      esac
    done
    echo ""
    echo "  Then restart Claude Code."
  fi
}

# Show installation summary
show_installation_summary() {
  echo ""
  echo "🎉 AI Setup complete! Your project is ready for AI-assisted development."
  echo ""
  echo "📦 Installation Summary"
  echo "   ──────────────────────────────────────────────────────────"
  echo ""
  echo "✅ Files created:"
  [ -f CLAUDE.md ] && echo "   - CLAUDE.md (project rules)"
  [ -f AGENTS.md ] && echo "   - AGENTS.md (universal passive agent context)"
  [ -f .claude/settings.json ] && echo "   - .claude/settings.json (permissions)"
  [ -f .github/copilot-instructions.md ] && echo "   - .github/copilot-instructions.md"
  echo "   - .claude/hooks/ (protect-files, post-edit-lint, circuit-breaker, context-freshness, update-check)"
  [ -f .mcp.json ] && echo "   - .mcp.json (MCP server config)"
  [ -d specs ] && echo "   - specs/ (spec-driven workflow)"
  [ -d .claude/commands ] && echo "   - .claude/commands/ (spec, spec-work, commit, pr, review, test, techdebt, bug, grill)"
  [ -d .claude/agents ] && echo "   - .claude/agents/ (verify-app, build-validator, staff-reviewer, context-refresher, code-reviewer, code-architect, perf-reviewer, test-generator)"

  echo ""
  echo "✅ Tools & Plugins:"
  local CLAUDE_MEM_DIR="${HOME}/.claude/plugins/cache/thedotmack/claude-mem"
  if [ -d "$CLAUDE_MEM_DIR" ]; then
    echo "   - Claude-Mem (persistent memory) ✅"
  else
    echo "   - Claude-Mem (pending — run install commands in Claude Code)"
  fi
  local CODERABBIT_DIR="${HOME}/.claude/plugins/cache/coderabbitai/claude-plugin"
  if [ -d "$CODERABBIT_DIR" ]; then
    echo "   - CodeRabbit plugin ✅"
  else
    echo "   - CodeRabbit plugin (pending — run install commands in Claude Code)"
  fi
  [ -n "${INSTALLED_PLUGINS:-}" ] && echo "   - Plugins: ${INSTALLED_PLUGINS}"
  [ -f .mcp.json ] && echo "   - Context7 MCP server (.mcp.json)"
  if [ -n "$PENDING_PLUGINS" ]; then
    echo "   - ⚠️  Pending plugins: ${PENDING_PLUGINS}(see install commands above)"
  fi

  if [ "$AI_CLI" = "claude" ] && [[ ! "${RUN_INIT:-N}" =~ ^[Nn]$ ]]; then
    echo ""
    if [ "${AUTO_INIT_OK:-yes}" = "yes" ]; then
      echo "✅ Auto-Init completed (System: ${SYSTEM:-not set}):"
      echo "   - CLAUDE.md + AGENTS.md extended with project-specific sections"
      [ -d .agents/context ] && echo "   - .agents/context/ (STACK.md, ARCHITECTURE.md, CONVENTIONS.md)"
      if [ ${INSTALLED:-0} -gt 0 ]; then
        echo "   - ${INSTALLED} skills installed"
      fi
    else
      echo "⚠️  Auto-Init finished with warnings — review output above."
    fi
  fi

  echo ""
  echo "📂 Project structure ready for AI development"
}

# Show next steps and cheat sheet
show_next_steps() {
  echo ""
  echo "🎯 Next Steps"
  echo "   ──────────────────────────────────────────────────────────"
  echo ""
  echo "Start a Claude Code session and begin working."
  echo "Your project context, CLAUDE.md, and AGENTS.md are ready."
  echo ""
  echo "Spec-driven workflow:"
  echo "  /spec \"task description\"    Create a structured spec before coding"
  echo "  /spec-work 001              Execute a spec step by step"
  echo ""
  echo "To regenerate context files later:"
  echo "  npx @onedot/ai-setup --regenerate"

  echo ""
  echo "🔗 Links"
  echo "   ──────────────────────────────────────────────────────────"
  echo ""
  echo "  Skills:   https://skills.sh/"
  echo "  Memory:   https://claude-mem.ai"
  echo "  Claude:   https://docs.anthropic.com/en/docs/claude-code"
  echo "  Hooks:    https://docs.anthropic.com/en/docs/claude-code/hooks"
  echo ""
}
