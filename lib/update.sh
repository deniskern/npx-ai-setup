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

  [ -n "$latest" ] || return 0
  # Only show notice when registry version is strictly newer (semver compare)
  if [ "$latest" != "$current" ] && _semver_gt "$latest" "$current"; then
    echo ""
    echo "ℹ️  New version available: @onedot/ai-setup v${latest} (current: v${current})"
    echo "   Update command: npx github:onedot-digital-crew/npx-ai-setup"
    echo ""
  fi
}

# Handle version check and route to update, reinstall, or exit
# Called when .ai-setup.json exists. May exit the script.
handle_version_check() {
  INSTALLED_VERSION=$(get_installed_version)
  PACKAGE_VERSION=$(get_package_version)
  local update_rc=0

  if [ -n "$INSTALLED_VERSION" ] && [ "$INSTALLED_VERSION" = "$PACKAGE_VERSION" ]; then
    # Same version — pre-scan to check if templates actually differ
    restore_system_from_metadata --quiet
    scan_template_changes

    echo ""
    if [ "$SCAN_TOTAL_CHANGES" -eq 0 ]; then
      echo "✅ Already up to date (v${PACKAGE_VERSION}) — all files match templates."
    else
      echo "✅ Already up to date (v${PACKAGE_VERSION}) — ${SCAN_TOTAL_CHANGES} file(s) differ from templates."
    fi
    echo ""
    echo "   1) Update files  — review template files, ask about user-modified ones"
    echo "   2) Regenerate    — choose exactly what to regenerate (docs/context/commands/agents/skills)"
    echo "   3) Skip          — exit without changes"
    echo ""
    read -p "   Choose [1/2/3]: " UPTODATE_CHOICE

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
            restore_system_from_metadata
            if [ -z "$SYSTEM" ]; then
              select_system
            fi
            detect_system
            run_generation || regen_ok=$?
            write_metadata
            echo ""
            if [ "$regen_ok" -eq 0 ]; then
              echo "✅ Regeneration complete!"
            else
              echo "⚠️  Regeneration finished with warnings. Review output above."
            fi
          fi
        else
          echo ""
          echo "  ⚠️  Claude CLI not found. Regeneration requires Claude Code."
          echo "  Install: npm i -g @anthropic-ai/claude-code"
          regen_ok=1
        fi
        exit "$regen_ok"
        ;;
      *)
        echo "   Skipped. No changes made."
        exit 0
        ;;
    esac

  elif [ -n "$INSTALLED_VERSION" ]; then
    # Different version — pre-scan to show change count
    restore_system_from_metadata --quiet
    scan_template_changes

    echo ""
    echo "🔄 Update available: v${INSTALLED_VERSION} → v${PACKAGE_VERSION} (${SCAN_TOTAL_CHANGES} file(s) changed)"
    echo ""
    echo "   1) Update       — smart update (backup modified files, update templates)"
    echo "   2) Reinstall    — delete managed files, fresh install from scratch"
    echo "   3) Skip         — exit without changes"
    echo ""
    read -p "   Choose [1/2/3]: " UPDATE_CHOICE

    case "$UPDATE_CHOICE" in
      1)
        update_rc=0
        run_smart_update || update_rc=$?
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
  if [[ "${SYSTEM:-}" == *shopify* ]]; then
    all_mappings+=("${SHOPIFY_SKILLS_MAP[@]}")
  fi

  for mapping in "${all_mappings[@]}"; do
    local tpl="${mapping%%:*}"
    local target="${mapping#*:}"
    local cat
    cat=$(get_template_category "$mapping")

    if [ ! -f "$target" ]; then
      # New file
      if [ -f "$SCRIPT_DIR/$tpl" ]; then
        local var_new="SCAN_${cat^^}_NEW"
        eval "$var_new=\$(( ${!var_new} + 1 ))"
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
      local var_changed="SCAN_${cat^^}_CHANGED"
      eval "$var_changed=\$(( ${!var_changed} + 1 ))"
      SCAN_TOTAL_CHANGES=$((SCAN_TOTAL_CHANGES + 1))
    fi
  done
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
      # User modified — ask before overwriting
      if ask_overwrite_modified "$target"; then
        local bp
        bp=$(backup_file "$target")
        cp "$SCRIPT_DIR/$tpl" "$target"
        [[ "$target" == *.sh ]] && chmod +x "$target"
        echo "  ✅ $target (updated — backed up to $bp)"
        UPD_BACKED_UP=$((UPD_BACKED_UP + 1))
      else
        echo "  ⏭️  $target (kept — user version preserved)"
        UPD_SKIPPED=$((UPD_SKIPPED + 1))
        continue
      fi
    else
      # Not modified by user — update
      cp "$SCRIPT_DIR/$tpl" "$target"
      [[ "$target" == *.sh ]] && chmod +x "$target"
      echo "  ✅ $target (updated)"
    fi
    UPD_UPDATED=$((UPD_UPDATED + 1))
  done
}

# Smart update: checksum diffing, selective category update, backup user-modified files
# Usage: run_smart_update [--skip-regen]
run_smart_update() {
  local skip_regen=0
  local regen_failed=0
  [ "${1:-}" = "--skip-regen" ] && skip_regen=1
  echo ""
  echo "🔍 Analyzing templates..."

  # Restore SYSTEM from metadata if not set via --system flag
  restore_system_from_metadata

  # Normalize legacy skills layout in existing projects.
  if command -v ensure_skills_alias >/dev/null 2>&1; then
    ensure_skills_alias
  fi

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
    echo "  ✅ All template files are up to date — nothing to update."
    # Still check for obsolete files
    cleanup_obsolete_managed_files
    write_metadata
  else
    # Ask which template categories to update (with change counts)
    ask_update_parts || echo "  ⏭️  No categories selected — skipping template updates"
  fi
  echo ""

  # Skip template processing when pre-scan found no changes
  if [ "$SCAN_TOTAL_CHANGES" -gt 0 ]; then
    _process_update_mappings "${TEMPLATE_MAP[@]}"

    # Also update Shopify-specific skills if system includes shopify
    if [[ "${SYSTEM:-}" == *shopify* ]]; then
      _process_update_mappings "${SHOPIFY_SKILLS_MAP[@]}"
    fi

    cleanup_obsolete_managed_files
  fi

  # Only show summary when there was work to do
  if [ "$UPD_UPDATED" -gt 0 ] || [ "$UPD_NEW" -gt 0 ] || [ "$UPD_REMOVED" -gt 0 ] || [ "$UPD_BACKED_UP" -gt 0 ]; then
    echo ""
    echo "📊 Update summary:"
    [ $UPD_UPDATED -gt 0 ] && echo "   Updated:   $UPD_UPDATED"
    [ $UPD_NEW -gt 0 ] && echo "   New:       $UPD_NEW"
    [ $UPD_REMOVED -gt 0 ] && echo "   Removed:   $UPD_REMOVED"
    [ $UPD_SKIPPED -gt 0 ] && echo "   Unchanged: $UPD_SKIPPED"
    [ $UPD_BACKED_UP -gt 0 ] && echo "   Backed up: $UPD_BACKED_UP (see .ai-setup-backup/)"
    [ $UPD_REMOVED_BACKED_UP -gt 0 ] && echo "   Backed up before removal: $UPD_REMOVED_BACKED_UP"
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
        if [ -z "$SYSTEM" ]; then
          select_system
        fi
        detect_system
        regen_ok=0
        run_generation || regen_ok=$?
        write_metadata
        echo ""
        if [ "$regen_ok" -eq 0 ]; then
          echo "✅ Regeneration complete!"
        else
          regen_failed=1
          echo "⚠️  Regeneration finished with warnings. Review output above."
        fi
      fi
    else
      echo ""
      echo "  ⚠️  Skipping regeneration (claude CLI not found)."
      echo "  Install: npm i -g @anthropic-ai/claude-code"
    fi
  fi

  update_gitignore
  generate_repomix_snapshot

  echo ""
  local _version_info="v${PACKAGE_VERSION}"
  [ "$INSTALLED_VERSION" != "$PACKAGE_VERSION" ] && _version_info="v${INSTALLED_VERSION} → v${PACKAGE_VERSION}"
  if [ "$regen_failed" -eq 0 ]; then
    echo "✅ Update complete! (${_version_info})"
    return 0
  fi
  echo "⚠️  Update complete with warnings (${_version_info})"
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

  # Also remove Shopify-specific skills
  for mapping in "${SHOPIFY_SKILLS_MAP[@]}"; do
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
