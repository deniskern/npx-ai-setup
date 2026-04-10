#!/bin/bash
# Update/reinstall logic: version detection, smart update, clean reinstall
# Requires: core.sh, detect.sh, tui.sh, generate.sh

# Show a lightweight CLI notice when a newer ai-setup version exists.
# Uses a cached npm registry lookup to avoid slowing normal runs.
show_cli_update_notice() {
  local current latest cache age ttl
  current=$(get_package_version)
  [ -n "$current" ] || return 0
  [ "$current" = "unknown" ] && return 0

  cache="/tmp/ai-setup-cli-latest-version.txt"
  ttl=21600 # 6h cache
  latest=""

  if [ -f "$cache" ]; then
    if [ "$(uname -s)" = "Darwin" ]; then
      age=$(( $(date +%s) - $(stat -f %m "$cache" 2>/dev/null || echo 0) ))
    else
      age=$(( $(date +%s) - $(stat -c %Y "$cache" 2>/dev/null || echo 0) ))
    fi
    if [ "$age" -lt "$ttl" ]; then
      latest=$(tr -d '[:space:]' < "$cache")
    fi
  fi

  if [ -z "$latest" ] && command -v npm >/dev/null 2>&1; then
    local timeout_cmd=""
    if command -v timeout >/dev/null 2>&1; then
      timeout_cmd="timeout 3"
    elif command -v gtimeout >/dev/null 2>&1; then
      timeout_cmd="gtimeout 3"
    fi
    if [ -n "$timeout_cmd" ]; then
      latest=$($timeout_cmd npm view @onedot/ai-setup version 2>/dev/null | head -n1 | tr -d '[:space:]')
    else
      latest=$(npm view @onedot/ai-setup version 2>/dev/null | head -n1 | tr -d '[:space:]')
    fi
    [ -n "$latest" ] && printf '%s\n' "$latest" > "$cache"
  fi

  # GitHub fallback for environments using github: installs without npm publish.
  if [ -z "$latest" ] && command -v curl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    latest=$(curl -fsSL --max-time 4 "https://api.github.com/repos/onedot-digital-crew/npx-ai-setup/releases/latest" 2>/dev/null \
      | jq -r '.tag_name // empty' \
      | head -n1 \
      | tr -d '[:space:]' \
      | sed 's/^v//')
    if [ -z "$latest" ]; then
      latest=$(curl -fsSL --max-time 4 "https://api.github.com/repos/onedot-digital-crew/npx-ai-setup/tags?per_page=1" 2>/dev/null \
        | jq -r '.[0].name // empty' \
        | head -n1 \
        | tr -d '[:space:]' \
        | sed 's/^v//')
    fi
    [ -n "$latest" ] && printf '%s\n' "$latest" > "$cache"
  fi

  if [ -z "$latest" ]; then
    tui_hint "Version check unavailable — npm registry and GitHub API both unreachable" || true
    return 0
  fi
  # Only show notice when registry version is strictly newer (semver compare)
  if [ "$latest" != "$current" ] && _semver_gt "$latest" "$current"; then
    echo ""
    tui_hint \
      "New version available: @onedot/ai-setup v${latest} (current: v${current})" \
      "Update: npx github:onedot-digital-crew/npx-ai-setup"
  fi
}

# Handle version check and route to update, reinstall, or exit
# Called when .ai-setup.json exists. May exit the script.
handle_version_check() {
  # Run Claude Code install method and version checks (same as fresh install)
  if command -v claude &>/dev/null; then
    _check_claude_code_install_method
    _check_claude_code_version
  fi

  INSTALLED_VERSION=$(get_installed_version)
  PACKAGE_VERSION=$(get_package_version)
  local update_rc=0

  if [ -n "$INSTALLED_VERSION" ] && [ "$INSTALLED_VERSION" = "$PACKAGE_VERSION" ]; then
    # Same version — pre-scan to check if templates actually differ
    scan_template_changes

    echo ""
    if [ "$SCAN_TOTAL_CHANGES" -eq 0 ]; then
      tui_success "Already up to date (v${PACKAGE_VERSION}) - all files match templates"
    else
      tui_success "Already up to date (v${PACKAGE_VERSION}) - ${SCAN_TOTAL_CHANGES} file(s) differ from templates"
    fi
    ask_single_choice_menu "What should happen next?" --default 1 \
      "Update files|Sync changed template files|Recommended" \
      "Regenerate|Rebuild docs, context, commands, and skills" \
      "Reset|Remove all managed files and reinstall from scratch|Destructive" \
      "Skip|Exit without changes|Default"
    UPTODATE_CHOICE="${TUI_MENU_INDEX:-1}"

    case "$UPTODATE_CHOICE" in
      1)
        update_rc=0
        run_smart_update --skip-regen || update_rc=$?
        exit "$update_rc"
        ;;
      2)
        regen_ok=0
        if command -v claude &>/dev/null; then
          if ask_regen_parts; then
            [ "${REGEN_SKILLS:-no}" = "yes" ] && run_skill_installation
            run_generation || regen_ok=$?
            write_metadata
            echo ""
            if [ "$regen_ok" -eq 0 ]; then
              tui_success "Regeneration complete"
            else
              tui_warn "Regeneration finished with warnings. Review output above."
            fi
          fi
        else
          echo ""
          tui_warn "Claude CLI not found. Regeneration requires Claude Code."
          echo "  Install: npm i -g @anthropic-ai/claude-code"
          regen_ok=1
        fi
        show_update_next_steps
        exit "$regen_ok"
        ;;
      3)
        run_reset
        ;;
      *)
        echo "   Skipped. No changes made."
        exit 0
        ;;
    esac

  elif [ -n "$INSTALLED_VERSION" ]; then
    # Different version — check for major version jump (fallback to smart update)
    local inst_major pkg_major
    inst_major="${INSTALLED_VERSION%%.*}"
    pkg_major="${PACKAGE_VERSION%%.*}"

    echo ""
    tui_section "Project Update" "v${INSTALLED_VERSION} -> v${PACKAGE_VERSION}"
    ask_single_choice_menu "How should this project be updated?" --default 1 \
      "Update|Run migrations and preserve project files|Recommended" \
      "Reinstall|Replace managed files with a clean install|Destructive" \
      "Skip|Exit without changes|Default"
    UPDATE_CHOICE="${TUI_MENU_INDEX:-1}"

    case "$UPDATE_CHOICE" in
      1)
        update_rc=0
        # Major version jump: fall back to smart update (migrations may not cover it)
        if [ "$inst_major" != "$pkg_major" ]; then
          tui_warn "Major version jump detected - using full template update instead of migrations"
          scan_template_changes
          run_smart_update || update_rc=$?
        else
          run_migrations "$INSTALLED_VERSION" "$PACKAGE_VERSION" || update_rc=$?
          if [ "$update_rc" -eq 0 ]; then
            # After migrations, sync templates that changed between versions
            scan_template_changes
            if [ "$SCAN_TOTAL_CHANGES" -gt 0 ]; then
              run_smart_update --skip-regen || update_rc=$?
            else
              write_metadata
              update_gitignore
              echo ""
              tui_success "Migration complete (v${INSTALLED_VERSION} -> v${PACKAGE_VERSION})"
              show_update_next_steps
            fi
          else
            tui_warn "Migration finished with errors - run again or choose Reinstall."
            show_update_next_steps
          fi
        fi
        exit "$update_rc"
        ;;
      2)
        run_clean_reinstall
        # Fall through to normal setup below (caller continues)
        ;;
      *)
        echo "   Skipped. No changes made."
        exit 0
        ;;
    esac
  fi
}

# Pre-scan all templates and count changes per category.
# Sets SCAN_* globals (changed/new/total counts per category) and SCAN_TOTAL_CHANGES.
# Must be called before ask_update_parts() to provide change counts.
scan_template_changes() {
  SCAN_HOOKS_CHANGED=0; SCAN_HOOKS_NEW=0
  SCAN_SETTINGS_CHANGED=0; SCAN_SETTINGS_NEW=0
  SCAN_CLAUDE_MD_CHANGED=0; SCAN_CLAUDE_MD_NEW=0
  SCAN_AGENTS_MD_CHANGED=0; SCAN_AGENTS_MD_NEW=0
  SCAN_COMMANDS_CHANGED=0; SCAN_COMMANDS_NEW=0
  SCAN_AGENTS_CHANGED=0; SCAN_AGENTS_NEW=0
  SCAN_OTHER_CHANGED=0; SCAN_OTHER_NEW=0
  SCAN_TOTAL_CHANGES=0

  local all_mappings=("${TEMPLATE_MAP[@]}")

  for mapping in "${all_mappings[@]}"; do
    local tpl="${mapping%%:*}"
    local target="${mapping#*:}"
    local cat
    cat=$(get_template_category "$mapping")

    if [ ! -f "$target" ]; then
      # New file
      if [ -f "$SCRIPT_DIR/$tpl" ]; then
        case "$cat" in
          hooks) SCAN_HOOKS_NEW=$((SCAN_HOOKS_NEW + 1)) ;;
          settings) SCAN_SETTINGS_NEW=$((SCAN_SETTINGS_NEW + 1)) ;;
          claude_md) SCAN_CLAUDE_MD_NEW=$((SCAN_CLAUDE_MD_NEW + 1)) ;;
          agents_md) SCAN_AGENTS_MD_NEW=$((SCAN_AGENTS_MD_NEW + 1)) ;;
          commands) SCAN_COMMANDS_NEW=$((SCAN_COMMANDS_NEW + 1)) ;;
          agents) SCAN_AGENTS_NEW=$((SCAN_AGENTS_NEW + 1)) ;;
          *) SCAN_OTHER_NEW=$((SCAN_OTHER_NEW + 1)) ;;
        esac
        SCAN_TOTAL_CHANGES=$((SCAN_TOTAL_CHANGES + 1))
      fi
      continue
    fi

    if [ ! -f "$SCRIPT_DIR/$tpl" ]; then
      continue
    fi

    local tpl_cs cur_cs
    tpl_cs=$(compute_checksum "$SCRIPT_DIR/$tpl")
    cur_cs=$(compute_checksum "$target")

    if [ "$tpl_cs" != "$cur_cs" ]; then
      case "$cat" in
        hooks) SCAN_HOOKS_CHANGED=$((SCAN_HOOKS_CHANGED + 1)) ;;
        settings) SCAN_SETTINGS_CHANGED=$((SCAN_SETTINGS_CHANGED + 1)) ;;
        claude_md) SCAN_CLAUDE_MD_CHANGED=$((SCAN_CLAUDE_MD_CHANGED + 1)) ;;
        agents_md) SCAN_AGENTS_MD_CHANGED=$((SCAN_AGENTS_MD_CHANGED + 1)) ;;
        commands) SCAN_COMMANDS_CHANGED=$((SCAN_COMMANDS_CHANGED + 1)) ;;
        agents) SCAN_AGENTS_CHANGED=$((SCAN_AGENTS_CHANGED + 1)) ;;
        *) SCAN_OTHER_CHANGED=$((SCAN_OTHER_CHANGED + 1)) ;;
      esac
      SCAN_TOTAL_CHANGES=$((SCAN_TOTAL_CHANGES + 1))
    fi
  done

  # Scan skills separately (excluded from TEMPLATE_MAP but still managed)
  if [ -d "$SCRIPT_DIR/templates/skills" ]; then
    while IFS= read -r -d '' skill_dir; do
      local skill_file="$skill_dir/SKILL.template.md"
      [ -f "$skill_file" ] || continue
      local name="${skill_dir##*/}"
      local target=".claude/skills/$name/SKILL.md"
      if [ ! -f "$target" ]; then
        SCAN_OTHER_NEW=$((SCAN_OTHER_NEW + 1))
        SCAN_TOTAL_CHANGES=$((SCAN_TOTAL_CHANGES + 1))
      else
        local tpl_cs cur_cs
        tpl_cs=$(compute_checksum "$skill_file")
        cur_cs=$(compute_checksum "$target")
        if [ "$tpl_cs" != "$cur_cs" ]; then
          SCAN_OTHER_CHANGED=$((SCAN_OTHER_CHANGED + 1))
          SCAN_TOTAL_CHANGES=$((SCAN_TOTAL_CHANGES + 1))
        fi
      fi
      # Check supporting reference files
      if [ -d "$skill_dir/references" ]; then
        while IFS= read -r -d '' ref; do
          local ref_name="${ref##*/}"
          local ref_target=".claude/skills/$name/references/$ref_name"
          if [ ! -f "$ref_target" ]; then
            SCAN_OTHER_NEW=$((SCAN_OTHER_NEW + 1))
            SCAN_TOTAL_CHANGES=$((SCAN_TOTAL_CHANGES + 1))
          else
            local ref_tpl_cs ref_cur_cs
            ref_tpl_cs=$(compute_checksum "$ref")
            ref_cur_cs=$(compute_checksum "$ref_target")
            if [ "$ref_tpl_cs" != "$ref_cur_cs" ]; then
              SCAN_OTHER_CHANGED=$((SCAN_OTHER_CHANGED + 1))
              SCAN_TOTAL_CHANGES=$((SCAN_TOTAL_CHANGES + 1))
            fi
          fi
        done < <(find "$skill_dir/references" -type f -name "*.md" -print0 | sort -z)
      fi
    done < <(find "$SCRIPT_DIR/templates/skills" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
  fi
}

# Process a set of template mappings: install new, update changed, skip unchanged (silently).
# Usage: _process_update_mappings "${TEMPLATE_MAP[@]}"
_process_update_mappings() {
  local mappings=("$@")
  for mapping in "${mappings[@]}"; do
    should_update_template "$mapping" || continue
    local tpl="${mapping%%:*}"
    local target="${mapping#*:}"

    # Target doesn't exist — install as new
    if [ ! -f "$target" ]; then
      if [ -f "$SCRIPT_DIR/$tpl" ]; then
        mkdir -p "$(dirname "$target")"
        cp "$SCRIPT_DIR/$tpl" "$target"
        [[ "$target" == *.sh ]] && chmod +x "$target"
        echo "  ✨ $target (new)"
        UPD_NEW=$((UPD_NEW + 1))
      fi
      continue
    fi

    # Compare template to installed file
    local tpl_cs cur_cs
    tpl_cs=$(compute_checksum "$SCRIPT_DIR/$tpl")
    cur_cs=$(compute_checksum "$target")

    if [ "$tpl_cs" = "$cur_cs" ]; then
      # Identical — skip silently (no output for unchanged files)
      UPD_SKIPPED=$((UPD_SKIPPED + 1))
      continue
    fi

    # Template differs — check if user modified the file
    local stored_cs
    stored_cs=$(jq -r --arg f "$target" '.files[$f] // empty' .ai-setup.json 2>/dev/null)

    if [ -n "$stored_cs" ] && [ "$stored_cs" != "$cur_cs" ]; then
      # User modified — auto-overwrite with backup
      local bp
      bp=$(backup_file "$target")
      cp "$SCRIPT_DIR/$tpl" "$target"
      [[ "$target" == *.sh ]] && chmod +x "$target"
      echo "  ✅ $target (updated — backed up to $bp)"
      UPD_BACKED_UP=$((UPD_BACKED_UP + 1))
    else
      # Not modified by user — update
      cp "$SCRIPT_DIR/$tpl" "$target"
      [[ "$target" == *.sh ]] && chmod +x "$target"
      echo "  ✅ $target (updated)"
    fi
    UPD_UPDATED=$((UPD_UPDATED + 1))
  done
}

# Fast patch: copy only template files matching a filename pattern, no prompts or scanning.
# Usage: run_patch <pattern>
# Example: run_patch "spec-work"  →  copies all templates whose path contains "spec-work"
run_patch() {
  local pattern="${1:-}"
  if [ -z "$pattern" ]; then
    echo "❌ --patch requires a pattern (e.g. --patch spec-work)"
    exit 1
  fi

  if [ ! -f ".ai-setup.json" ]; then
    echo "❌ No .ai-setup.json found — run the setup command first to initialize this project"
    exit 1
  fi

  local all_mappings=("${TEMPLATE_MAP[@]}" "${SPEC_SKILLS_MAP[@]}")

  local copied=0
  for mapping in "${all_mappings[@]}"; do
    local tpl="${mapping%%:*}"
    local target="${mapping#*:}"
    # Match pattern against template path (filename or directory segment)
    [[ "$tpl" == *"$pattern"* ]] || continue
    if [ ! -f "$SCRIPT_DIR/$tpl" ]; then
      echo "  ⚠️  source not found: $tpl"
      continue
    fi
    mkdir -p "$(dirname "$target")"
    cp "$SCRIPT_DIR/$tpl" "$target"
    [[ "$target" == *.sh ]] && chmod +x "$target"
    echo "  ✅ $target"
    copied=$((copied + 1))
  done

  if [ "$copied" -eq 0 ]; then
    echo "  ⚠️  No templates matched pattern: $pattern"
    exit 1
  fi
  echo ""
  echo "Patched $copied file(s) matching '$pattern'."
}

# Smart update: checksum diffing, selective category update, backup user-modified files
# Usage: run_smart_update [--skip-regen]
run_smart_update() {
  local skip_regen=0
  local regen_failed=0
  [ "${1:-}" = "--skip-regen" ] && skip_regen=1
  echo ""
  tui_section "Template Analysis" "Scanning installed files against the current template set"

  # Normalize legacy skills layout in existing projects.
  if command -v ensure_skills_alias >/dev/null 2>&1; then
    ensure_skills_alias
  fi
  command -v ensure_codex_skills_alias >/dev/null 2>&1 && ensure_codex_skills_alias
  command -v ensure_gemini_skills_alias >/dev/null 2>&1 && ensure_gemini_skills_alias
  command -v ensure_opencode_skills_alias >/dev/null 2>&1 && ensure_opencode_skills_alias
  command -v install_skills >/dev/null 2>&1 && install_skills

  # Pre-scan templates to detect actual changes per category (skip if already scanned)
  if [ -z "${SCAN_TOTAL_CHANGES+x}" ]; then
    scan_template_changes
  fi

  UPD_UPDATED=0
  UPD_SKIPPED=0
  UPD_NEW=0
  UPD_BACKED_UP=0
  UPD_REMOVED=0
  UPD_REMOVED_BACKED_UP=0

  if [ "$SCAN_TOTAL_CHANGES" -eq 0 ]; then
    echo ""
    tui_success "All template files are up to date - nothing to update"
    # Still check for obsolete files
    cleanup_obsolete_managed_files
    cleanup_known_orphans
    write_metadata
  else
    # Ask which template categories to update (with change counts)
    ask_update_parts || echo "  ⏭️  No categories selected — skipping template updates"
  fi
  echo ""

  # Skip template processing when pre-scan found no changes
  if [ "$SCAN_TOTAL_CHANGES" -gt 0 ]; then
    _process_update_mappings "${TEMPLATE_MAP[@]}"

    cleanup_obsolete_managed_files
  fi

  # Always remove known obsolete files regardless of version or template changes
  cleanup_known_orphans

  # Sync boilerplate files from stack-specific repos (if system detected)
  sync_boilerplate

  # Merge MCP servers — adds new entries without overwriting existing config
  install_context7

  # Only show summary when there was work to do
  if [ "$UPD_UPDATED" -gt 0 ] || [ "$UPD_NEW" -gt 0 ] || [ "$UPD_REMOVED" -gt 0 ] || [ "$UPD_BACKED_UP" -gt 0 ]; then
    echo ""
    tui_section "Update Summary"
    [ $UPD_UPDATED -gt 0 ] && printf '   %b%-12s%b %b%s%b\n' "$TUI_DIM" "Updated:" "$TUI_RESET" "$TUI_GREEN" "$UPD_UPDATED" "$TUI_RESET"
    [ $UPD_NEW -gt 0 ] && printf '   %b%-12s%b %b%s%b\n' "$TUI_DIM" "New:" "$TUI_RESET" "$TUI_GREEN" "$UPD_NEW" "$TUI_RESET"
    [ $UPD_REMOVED -gt 0 ] && printf '   %b%-12s%b %b%s%b\n' "$TUI_DIM" "Removed:" "$TUI_RESET" "$TUI_YELLOW" "$UPD_REMOVED" "$TUI_RESET"
    [ $UPD_SKIPPED -gt 0 ] && printf '   %b%-12s%b %b%s%b\n' "$TUI_DIM" "Unchanged:" "$TUI_RESET" "$TUI_DIM" "$UPD_SKIPPED" "$TUI_RESET"
    [ $UPD_BACKED_UP -gt 0 ] && printf '   %b%-12s%b %b%s%b %b(see .ai-setup-backup/)%b\n' "$TUI_DIM" "Backed up:" "$TUI_RESET" "$TUI_CYAN" "$UPD_BACKED_UP" "$TUI_RESET" "$TUI_DIM" "$TUI_RESET"
    [ $UPD_REMOVED_BACKED_UP -gt 0 ] && printf '   %b%-12s%b %b%s%b\n' "$TUI_DIM" "Backed up:" "$TUI_RESET" "$TUI_CYAN" "$UPD_REMOVED_BACKED_UP (before removal)" "$TUI_RESET"
  fi

  # Update metadata
  write_metadata

  # Check context files and offer AI regeneration (skipped when called from same-version menu)
  if [ "$skip_regen" -eq 0 ]; then
    if command -v claude &>/dev/null; then
      echo ""
      # Count existing .agents/context/ files (Steps 1-2)
      CTX_EXISTING=0
      [ -f ".agents/context/STACK.md" ] && CTX_EXISTING=$((CTX_EXISTING + 1))
      [ -f ".agents/context/ARCHITECTURE.md" ] && CTX_EXISTING=$((CTX_EXISTING + 1))
      [ -f ".agents/context/CONVENTIONS.md" ] && CTX_EXISTING=$((CTX_EXISTING + 1))
      CTX_MISSING=$((3 - CTX_EXISTING))
      if [ "$CTX_MISSING" -gt 0 ]; then
        echo "  ⚠️  $CTX_MISSING of 3 context files missing in .agents/context/ — regeneration recommended"
        echo ""
      fi
      # Use granular selector instead of binary y/N (Steps 3-4)
      if ask_regen_parts; then
        regen_ok=0
        [ "${REGEN_SKILLS:-no}" = "yes" ] && run_skill_installation
        run_generation || regen_ok=$?
        write_metadata
        echo ""
        if [ "$regen_ok" -eq 0 ]; then
          tui_success "Regeneration complete"
        else
          regen_failed=1
          tui_warn "Regeneration finished with warnings. Review output above."
        fi
      fi
    else
      echo ""
      tui_hint \
        "Skipping regeneration — claude CLI not found." \
        "Install: npm i -g @anthropic-ai/claude-code"
    fi
  fi

  update_gitignore

  echo ""
  local _version_info="v${PACKAGE_VERSION}"
  [ "$INSTALLED_VERSION" != "$PACKAGE_VERSION" ] && _version_info="v${INSTALLED_VERSION} → v${PACKAGE_VERSION}"
  if [ "$regen_failed" -eq 0 ]; then
    tui_success "Update complete (${_version_info})"
  else
    tui_warn "Update complete with warnings (${_version_info})"
  fi

  show_update_next_steps

  [ "$regen_failed" -eq 0 ] && return 0
  return 1
}

# Clean reinstall: remove all managed files, reset metadata
run_clean_reinstall() {
  echo ""
  echo "🗑️  Removing managed files..."

  cleanup_obsolete_managed_files reinstall

  for mapping in "${TEMPLATE_MAP[@]}"; do
    target="${mapping#*:}"
    if [ -f "$target" ]; then
      rm -f "$target"
      echo "   Removed: $target"
    fi
  done

  # Remove metadata and backup dir
  rm -f .ai-setup.json
  echo ""
  echo "   Clean slate ready. Running fresh install..."
  echo ""
  # Caller continues to normal setup
}

# Remove files that are known to be obsolete across all projects regardless of
# their managed status. Called on every update — no version gating.
cleanup_known_orphans() {
  local -a orphans=(
    ".agents/repomix-snapshot.xml"
    ".agents/repomix-snapshot.md"
    "repomix.config.json"
    ".repomixignore"
    ".claude/scripts/delegate-codex.sh"
    ".claude/scripts/delegate-gemini.sh"
    ".claude/hooks/cli-health.sh"
    ".claude/hooks/config-change-audit.sh"
    ".claude/hooks/context-monitor.sh"
    ".claude/hooks/context-reinforcement.sh"
    ".claude/hooks/file-index.sh"
    ".claude/hooks/mcp-health.sh"
    ".claude/hooks/permission-denied-log.sh"
    ".claude/hooks/post-tool-failure-log.sh"
    ".claude/hooks/session-length.sh"
    ".claude/hooks/subagent-start.sh"
    ".claude/hooks/subagent-stop.sh"
    ".claude/hooks/task-created-log.sh"
    ".claude/hooks/tdd-checker.sh"
    ".claude/agents/backend-developer.md"
    ".claude/agents/build-validator.md"
    ".claude/agents/code-architect.md"
    ".claude/agents/context-refresher.md"
    ".claude/agents/frontend-developer.md"
    ".claude/agents/performance-reviewer.md"
    ".claude/agents/staff-reviewer.md"
    ".claude/agents/test-generator.md"
    ".claude/agents/verify-app.md"
    ".claude/hooks/post-compact-restore.sh"
    ".claude/hooks/pre-compact-state.sh"
    ".claude/skills/pause/SKILL.md"
    ".claude/skills/resume/SKILL.md"
    ".claude/commands/pause.md"
    ".claude/commands/resume.md"
    ".continue-here.md"
  )
  for target in "${orphans[@]}"; do
    [ -f "$target" ] || continue
    rm -f "$target"
    echo "  🧹 $target (obsolete — removed)"
    UPD_REMOVED=$((UPD_REMOVED + 1))
  done
}

# Remove files that were managed by an older ai-setup version but are no longer
# part of the current template maps. Smart update backs up user-modified files
# first; reinstall removes all historical managed files outright.
cleanup_obsolete_managed_files() {
  local mode="${1:-smart}"
  local target stored_cs cur_cs bp
  local -a old_targets=()

  [ -f .ai-setup.json ] || return 0
  command -v jq >/dev/null 2>&1 || return 0
  jq -e . .ai-setup.json >/dev/null 2>&1 || return 0

  while IFS= read -r target; do
    [ -n "$target" ] && old_targets+=("$target")
  done < <(jq -r '.files | keys[]?' .ai-setup.json 2>/dev/null)

  [ "${#old_targets[@]}" -gt 0 ] || return 0

  for target in "${old_targets[@]}"; do
    is_current_managed_target "$target" && continue

    # Skills without a current template are project-specific (installed via
    # /find-skills, boilerplate, or manually) — never delete them.  They ended
    # up in .ai-setup.json because older write_metadata() tracked all skills.
    if [[ "$target" == .claude/skills/*/SKILL.md ]]; then
      local _sname
      _sname=$(echo "$target" | sed 's|.claude/skills/\([^/]*\)/SKILL.md|\1|')
      if [ ! -f "$SCRIPT_DIR/templates/skills/$_sname/SKILL.template.md" ]; then
        # Clean the stale entry from .ai-setup.json so it won't be checked again
        if command -v jq >/dev/null 2>&1; then
          local _tmp
          _tmp=$(jq --arg f "$target" 'del(.files[$f])' .ai-setup.json 2>/dev/null) \
            && echo "$_tmp" > .ai-setup.json
        fi
        continue
      fi
    fi

    should_update_template "_:$target" || continue
    [ -f "$target" ] || continue

    if [ "$mode" = "reinstall" ]; then
      rm -f "$target"
      echo "   Removed obsolete: $target"
      continue
    fi

    stored_cs=$(jq -r --arg f "$target" '.files[$f] // empty' .ai-setup.json 2>/dev/null)
    cur_cs=$(compute_checksum "$target")

    if [ -n "$stored_cs" ] && [ "$stored_cs" != "$cur_cs" ]; then
      bp=$(backup_file "$target")
      rm -f "$target"
      echo "  🧹 $target (obsolete — backed up to $bp, then removed)"
      UPD_BACKED_UP=$((UPD_BACKED_UP + 1))
      UPD_REMOVED_BACKED_UP=$((UPD_REMOVED_BACKED_UP + 1))
    else
      rm -f "$target"
      echo "  🧹 $target (obsolete — removed)"
    fi
    UPD_REMOVED=$((UPD_REMOVED + 1))
  done
}
