#!/bin/bash
# Fresh install steps: requirements, templates, hooks, commands
# Requires: core.sh ($TPL, $TEMPLATE_MAP)

# Smart-merge a user-modified .md file with its upstream template via claude -p (Haiku).
# Keeps local additions (learnings, custom rules) while applying template updates.
# Usage: _smart_merge_file <template_src> <target>
# Returns: 0 on success (target updated), 1 on failure (caller falls back to skip)
_smart_merge_file() {
  local src="$1"
  local target="$2"

  # Only merge markdown files — skip scripts and JSON (risk of invalid output)
  case "$target" in
    *.md) ;;
    *) return 1 ;;
  esac

  # Require claude CLI
  command -v claude >/dev/null 2>&1 || return 1

  local tmp_prompt tmp_out tmp_target
  tmp_prompt=$(mktemp)
  tmp_out=$(mktemp)
  tmp_target="${target}.merge-tmp"

  # Ensure cleanup on all exit paths (signals, set -e, normal return)
  trap 'rm -f "$tmp_prompt" "$tmp_out"' RETURN

  cat > "$tmp_prompt" << 'MERGE_PROMPT_EOF'
Merge two versions of a configuration file. Output ONLY the merged file content — no explanation, no preamble, no code fences.

Rules:
- Keep all content from TEMPLATE that has not been intentionally removed in LOCAL
- Preserve all LOCAL additions not present in TEMPLATE (custom rules, learnings, extra sections)
- For existing sections present in both: TEMPLATE content takes precedence
- No duplicate entries or sections
- Preserve file structure, formatting, and comments exactly
MERGE_PROMPT_EOF

  printf '\n=== TEMPLATE (upstream update) ===\n' >> "$tmp_prompt"
  cat "$src" >> "$tmp_prompt"
  printf '\n=== LOCAL (user-modified) ===\n' >> "$tmp_prompt"
  cat "$target" >> "$tmp_prompt"

  # Note: "$(cat file)" command substitution is safe here — the result is a single
  # string argument; shell metacharacters in file content are NOT re-evaluated.
  if claude -p "$(cat "$tmp_prompt")" --model claude-haiku-4-5 --output-format text > "$tmp_out" 2>/dev/null; then
    if [ -s "$tmp_out" ]; then
      # Atomic write: cp to .merge-tmp then mv (mv is atomic on same filesystem)
      cp "$tmp_out" "$tmp_target" && mv "$tmp_target" "$target" || {
        rm -f "$tmp_target"
        return 1
      }
      return 0
    fi
  fi

  rm -f "$tmp_target"
  return 1
}

# Install a template file, updating it if the template is newer.
# Skips if installed file matches template checksum.
# Updates silently if user hasn't modified the file (checksum matches .ai-setup.json).
# Smart-merges via Haiku if user has modified the file (preserves local additions).
# Usage: _install_or_update_file <template_path> <target_path>
_install_or_update_file() {
  local src="$1"
  local target="$2"
  local name="${target##*/}"

  if [ ! -f "$target" ]; then
    mkdir -p "$(dirname "$target")"
    cp "$src" "$target"
    [[ "$target" == *.sh ]] && chmod +x "$target"
    return 0
  fi

  # File exists — compare checksums
  local tpl_cs cur_cs
  tpl_cs=$(compute_checksum "$src")
  cur_cs=$(compute_checksum "$target")

  # Already identical — skip silently
  [ "$tpl_cs" = "$cur_cs" ] && return 0

  # Template is newer — check if user modified the installed file
  if [ -f .ai-setup.json ] && _json_valid .ai-setup.json; then
    local stored_cs
    if [ "$_JSON_CMD" = "jq" ]; then
      stored_cs=$(jq -r --arg f "$target" '.files[$f] // empty' .ai-setup.json 2>/dev/null)
    else
      stored_cs=$(node - "$target" <<'NODESCRIPT' 2>/dev/null
        try{const d=JSON.parse(require('fs').readFileSync('.ai-setup.json','utf8'));
        const v=(d.files||{})[process.argv[2]];if(v)process.stdout.write(v);}catch(e){}
NODESCRIPT
      )
    fi
    if [ -n "$stored_cs" ] && [ "$stored_cs" != "$cur_cs" ]; then
      # User modified this file — attempt smart merge, fall back to skip
      if _smart_merge_file "$src" "$target"; then
        tui_success "$target merged (template + local)"
      else
        tui_warn "$target kept (user-modified, merge unavailable)"
      fi
      return 0
    fi
  fi

  # Not user-modified — safe to update
  cp "$src" "$target"
  [[ "$target" == *.sh ]] && chmod +x "$target"
  tui_success "$target updated"
  return 0
}
# Install all files from a template directory into a target directory.
# Usage: _install_template_dir <src_dir> <target_dir> [glob] [executable]
#   src_dir    — source template directory (must exist)
#   target_dir — destination directory (created with mkdir -p)
#   glob       — optional find -name pattern, e.g. "*.sh" (default: all files)
#   executable — pass "executable" to chmod +x each installed file
# Returns: count of processed files via stdout (last line "COUNT:<n>")
_install_template_dir() {
  local src_dir="$1"
  local target_dir="$2"
  local glob="${3:-}"
  local executable="${4:-}"

  [ -d "$src_dir" ] || return 0
  mkdir -p "$target_dir"

  local _count=0
  local _find_args
  if [ -n "$glob" ]; then
    while IFS= read -r -d '' _f; do
      local _name="${_f##*/}"
      _install_or_update_file "$_f" "$target_dir/$_name"
      [ "$executable" = "executable" ] && chmod +x "$target_dir/$_name" 2>/dev/null || true
      _count=$((_count + 1))
    done < <(find "$src_dir" -maxdepth 1 -name "$glob" -type f -print0 | sort -z)
  else
    while IFS= read -r -d '' _f; do
      local _name="${_f##*/}"
      _install_or_update_file "$_f" "$target_dir/$_name"
      [ "$executable" = "executable" ] && chmod +x "$target_dir/$_name" 2>/dev/null || true
      _count=$((_count + 1))
    done < <(find "$src_dir" -maxdepth 1 -type f -print0 | sort -z)
  fi

  echo "COUNT:${_count}"
}

# Check requirements: node >= 18, npm, jq, AI CLI detection
# Sets: $AI_CLI
check_requirements() {
  MISSING=()
  ! command -v node &>/dev/null && MISSING+=("node (>= 18)")
  ! command -v npm &>/dev/null && MISSING+=("npm")
  if ! command -v jq &>/dev/null && ! command -v node &>/dev/null; then
    MISSING+=("jq or node (brew install jq, or install Node.js >= 18)")
  elif ! command -v jq &>/dev/null; then
    tui_info "jq not found - Node.js JSON fallback active"
  fi

  if [ ${#MISSING[@]} -gt 0 ]; then
    tui_error "Missing requirements"
    for m in "${MISSING[@]}"; do echo "   - $m"; done
    echo ""
    echo "Install the missing tools and try again."
    exit 1
  fi

  # Node.js version check (>= 18)
  NODE_VERSION=$(node -v 2>/dev/null | sed 's/v//' | cut -d. -f1)
  if [ -n "$NODE_VERSION" ] && [ "$NODE_VERSION" -lt 18 ]; then
    tui_error "Node.js >= 18 required (found v$NODE_VERSION)"
    exit 1
  fi

  # npm cache permission check (root-owned files block npx)
  local npm_cache
  npm_cache="$(npm config get cache 2>/dev/null || echo "$HOME/.npm")"
  if [ -d "$npm_cache" ] && find "$npm_cache" -maxdepth 1 -not -user "$(id -u)" -print -quit 2>/dev/null | grep -q .; then
    tui_hint \
      "npm cache contains root-owned files — this can break npx" \
      "Fix: sudo chown -R \$(id -u):\$(id -g) \"$npm_cache\""
  fi

  # Template directory validation
  if [ ! -d "$TPL" ]; then
    tui_error "Template directory not found: $TPL"
    echo "   The package may be corrupted. Try: npm cache clean --force && npx @onedot/ai-setup"
    exit 1
  fi

  # AI CLI detection (optional, for Auto-Init)
  AI_CLI=""
  if command -v claude &>/dev/null; then
    AI_CLI="claude"
  elif command -v gh &>/dev/null && gh copilot --version &>/dev/null 2>&1; then
    AI_CLI="copilot"
  fi
  tui_success "Requirements OK (AI CLI: ${AI_CLI:-none detected})"
}

# Detect and remove legacy AI structures
cleanup_legacy() {
  FOUND=()
  [ -d ".ai" ] && FOUND+=(".ai/")
  [ -d ".claude/skills/create-spec" ] && FOUND+=(".claude/skills/create-spec/")
  [ -d ".claude/skills/spec-work" ] && FOUND+=(".claude/skills/spec-work/")
  [ -d ".claude/skills/template-skill" ] && FOUND+=(".claude/skills/template-skill/")
  [ -d ".claude/skills/learn" ] && FOUND+=(".claude/skills/learn/")
  [ -f ".claude/INIT.md" ] && FOUND+=(".claude/INIT.md")
  [ -d "skills/" ] && FOUND+=("skills/")
  [ -d ".skillkit/" ] && FOUND+=(".skillkit/")
  [ -f "skillkit.yaml" ] && FOUND+=("skillkit.yaml")

  if [ ${#FOUND[@]} -gt 0 ]; then
    tui_warn "Legacy AI structures found"
    for f in "${FOUND[@]}"; do echo "   - $f"; done
    echo ""
    if ask_yes_no_menu \
      "Remove old AI setup files before continuing?" \
      "Yes" "Delete them now" \
      "No" "Keep them and continue" \
      "yes"; then
      for f in "${FOUND[@]}"; do rm -rf "$f"; done
      tui_success "Legacy cleanup complete"
    else
      tui_info "Legacy cleanup skipped"
    fi
  else
    tui_success "No legacy structures found"
  fi
}

# Diff-based orphan cleanup: remove managed files/dirs that no longer exist in their template source.
# Covers commands, rules, scripts, hooks, and skills directories.
# Runs AFTER all installs so comparisons reflect the current template state.
cleanup_orphans() {
  local ORPHANS=()

  # Helper: find files in $target_dir not present in $src_dir (flat, maxdepth 1)
  _find_orphan_files() {
    local src="$1" target="$2" glob="${3:-*}"
    [ -d "$src" ] && [ -d "$target" ] || return 0
    while IFS= read -r -d '' f; do
      local name="${f##*/}"
      [ -f "$src/$name" ] || ORPHANS+=("$target/$name")
    done < <(find "$target" -maxdepth 1 -type f -name "$glob" -print0 2>/dev/null)
  }

  # Helper: find subdirs in $target_dir not present in $src_dir (flat, maxdepth 1)
  _find_orphan_dirs() {
    local src="$1" target="$2"
    [ -d "$src" ] && [ -d "$target" ] || return 0
    while IFS= read -r -d '' d; do
      local name="${d##*/}"
      [ -d "$src/$name" ] || ORPHANS+=("$target/$name/")
    done < <(find "$target" -maxdepth 1 -mindepth 1 -type d -print0 2>/dev/null)
  }

  # Helper: find files installed recursively from $src_dir that no longer exist there
  _find_orphan_files_recursive() {
    local src="$1" target="$2"
    [ -d "$src" ] && [ -d "$target" ] || return 0
    while IFS= read -r -d '' f; do
      local rel="${f#$target/}"
      [ -f "$src/$rel" ] || ORPHANS+=("$target/$rel")
    done < <(find "$target" -type f -print0 2>/dev/null)
  }

  _find_orphan_files "$TPL/commands"      ".claude/commands"  "*.md"
  _find_orphan_files "$TPL/claude/rules"  ".claude/rules"     "*.md"
  _find_orphan_files "$TPL/scripts"       ".claude/scripts"   "*.sh"
  _find_orphan_files "$TPL/claude/hooks"  ".claude/hooks"
  _find_orphan_files "$TPL/agents"        ".claude/agents"    "*.md"
  _find_orphan_dirs  "$TPL/skills"        ".claude/skills"
  _find_orphan_files_recursive "$TPL/github" ".github"

  if [ ${#ORPHANS[@]} -eq 0 ]; then
    tui_success "No orphaned managed files found"
    return 0
  fi

  tui_warn "Orphaned files found (no longer in templates)"
  for f in "${ORPHANS[@]}"; do echo "   - $f"; done
  echo ""
  if ask_yes_no_menu \
    "Remove orphaned files?" \
    "Yes" "Delete them now" \
    "No" "Keep them and continue" \
    "yes"; then
    for f in "${ORPHANS[@]}"; do rm -rf "$f"; done
    tui_success "Orphan cleanup complete (${#ORPHANS[@]} items removed)"
  else
    tui_info "Orphan cleanup skipped"
  fi
}

# Reset: delete all setup-managed files so the next install runs completely fresh.
# CLAUDE.md, specs/, memory/, and .claude/settings.local.json are intentionally excluded.
run_reset() {
  local TARGETS=()

  # Managed directories (fully owned by setup)
  [ -d ".claude/commands" ]  && TARGETS+=(".claude/commands/")
  [ -d ".claude/rules" ]     && TARGETS+=(".claude/rules/")
  [ -d ".claude/scripts" ]   && TARGETS+=(".claude/scripts/")
  [ -d ".claude/hooks" ]     && TARGETS+=(".claude/hooks/")

  # Template-managed skills only (leave custom skills untouched)
  if [ -d ".claude/skills" ] && [ -d "$TPL/skills" ]; then
    while IFS= read -r -d '' d; do
      local name="${d##*/}"
      [ -d "$TPL/skills/$name" ] && TARGETS+=(".claude/skills/$name/")
    done < <(find ".claude/skills" -maxdepth 1 -mindepth 1 -type d -print0 2>/dev/null)
  fi

  # Template-managed agents only (leave custom agents untouched)
  if [ -d ".claude/agents" ] && [ -d "$TPL/agents" ]; then
    while IFS= read -r -d '' f; do
      local name="${f##*/}"
      [ -f "$TPL/agents/$name" ] && TARGETS+=(".claude/agents/$name")
    done < <(find ".claude/agents" -maxdepth 1 -type f -print0 2>/dev/null)
  fi

  # Managed single files
  [ -f ".claude/settings.json" ]      && TARGETS+=(".claude/settings.json")
  [ -f "WORKFLOW-GUIDE.md" ]           && TARGETS+=("WORKFLOW-GUIDE.md")
  [ -f ".ai-setup.json" ]             && TARGETS+=(".ai-setup.json")
  [ -f ".claudeignore" ]              && TARGETS+=(".claudeignore")
  [ -f "AGENTS.md" ]                  && TARGETS+=("AGENTS.md")
  [ -f "opencode.json" ]              && TARGETS+=("opencode.json")

  # Conditional installs (only if they exist)
  [ -f ".gemini/settings.json" ]  && TARGETS+=(".gemini/settings.json")
  [ -f ".codex/config.toml" ]     && TARGETS+=(".codex/config.toml")

  # GitHub templates (copilot instructions + workflows)
  if [ -d ".github" ] && [ -d "$TPL/github" ]; then
    while IFS= read -r -d '' f; do
      local rel="${f#$TPL/github/}"
      [ -f ".github/$rel" ] && TARGETS+=(".github/$rel")
    done < <(find "$TPL/github" -type f -print0 2>/dev/null)
  fi

  if [ ${#TARGETS[@]} -eq 0 ]; then
    tui_info "Nothing to reset — no managed files found"
    return 0
  fi

  tui_warn "RESET: The following setup-managed files will be deleted"
  for t in "${TARGETS[@]}"; do echo "   - $t"; done
  tui_info "Excluded: CLAUDE.md, specs/, .agents/memory/, .claude/settings.local.json"
  echo ""

  if ask_yes_no_menu \
    "Delete all managed files and reinstall from scratch?" \
    "Yes" "Reset now — fresh install follows" \
    "No" "Cancel" \
    "no"; then
    for t in "${TARGETS[@]}"; do rm -rf "$t"; done
    tui_success "Reset complete (${#TARGETS[@]} items removed) — starting fresh install"
    echo ""
    tui_hint \
      "For a complete wipe, delete these manually before continuing:" \
      "  rm CLAUDE.md  |  rm .claude/settings.local.json" \
      "  rm -rf .agents/memory/  |  rm -rf specs/"
  else
    tui_info "Reset cancelled"
    exit 0
  fi
}

# Copy CLAUDE.md template
install_claude_md() {
  tui_step "Writing CLAUDE.md"
  if [ ! -f CLAUDE.md ]; then
    cp "$TPL/CLAUDE.md" CLAUDE.md
    tui_success "CLAUDE.md created"
  else
    tui_info "CLAUDE.md already exists, kept"
  fi
}

# Copy AGENTS.md template
install_agents_md() {
  tui_step "Writing AGENTS.md"
  if [ ! -f AGENTS.md ]; then
    cp "$TPL/AGENTS.md" AGENTS.md
    tui_success "AGENTS.md created"
  else
    tui_info "AGENTS.md already exists, kept"
  fi
}

# Create .claude/settings.json
install_settings() {
  tui_step "Writing .claude/settings.json"
  mkdir -p .claude
  _install_or_update_file "$TPL/claude/settings.json" .claude/settings.json
}

# Customize .claude/settings.json deny list for the detected framework.
# Removes framework-specific deny entries that block pre-commit hooks
# (e.g. Nuxt ESLint imports from .nuxt/eslint.config.mjs).
# Idempotent — safe to run multiple times.
customize_settings_for_stack() {
  local settings=".claude/settings.json"
  [ -f "$settings" ] || return 0

  local framework="${SELECTED_SYSTEM:-}"

  # Auto-detect framework from config files when SELECTED_SYSTEM is empty
  # (e.g. update runs where user skips framework selection)
  if [ -z "$framework" ]; then
    if ls nuxt.config.* 1>/dev/null 2>&1; then
      framework="nuxt"
    elif ls next.config.* 1>/dev/null 2>&1; then
      framework="next"
    fi
  fi

  [ -z "$framework" ] && return 0

  # Build pipe-separated list of deny patterns to remove
  local remove_patterns=""
  case "$framework" in
    nuxt)
      remove_patterns='Read(.nuxt/**)|Read(.output/**)'
      ;;
    next)
      remove_patterns='Read(.next/**)'
      ;;
    *)
      return 0
      ;;
  esac

  tui_step "Customizing sandbox permissions for $framework"

  local tmp
  tmp=$(mktemp)
  if [ "$_JSON_CMD" = "jq" ]; then
    jq --arg patterns "$remove_patterns" '
      .permissions.deny |= map(
        select(. as $d | ($patterns | split("|")) | index($d) | not)
      )
    ' "$settings" > "$tmp" && mv "$tmp" "$settings" || { rm -f "$tmp"; return 1; }
  else
    node - "$settings" "$remove_patterns" <<'NODESCRIPT' 2>/dev/null || { rm -f "$tmp"; return 1; }
      const fs = require('fs');
      const settings = process.argv[2];
      const patterns = process.argv[3].split('|');
      const cfg = JSON.parse(fs.readFileSync(settings, 'utf8'));
      if (cfg.permissions && cfg.permissions.deny) {
        cfg.permissions.deny = cfg.permissions.deny.filter(d => !patterns.includes(d));
      }
      fs.writeFileSync(settings, JSON.stringify(cfg, null, 2));
NODESCRIPT
  fi
  rm -f "$tmp"

  tui_success "Sandbox deny list adjusted for $framework"
}

# Install .gemini/settings.json if gemini CLI is available
install_gemini_config() {
  command -v gemini >/dev/null 2>&1 || return 0
  tui_step "Writing .gemini/settings.json"
  mkdir -p .gemini
  _install_or_update_file "$TPL/gemini/settings.json" .gemini/settings.json
}

# Install .codex/config.toml if codex CLI is available
install_codex_config() {
  command -v codex >/dev/null 2>&1 || return 0
  tui_step "Writing .codex/config.toml"
  mkdir -p .codex
  _install_or_update_file "$TPL/codex/config.toml" .codex/config.toml
}

# Install hook scripts
install_hooks() {
  tui_step "Installing hooks"
  _install_template_dir "$TPL/claude/hooks" ".claude/hooks" "" "executable" >/dev/null
}

# Install rule templates
install_rules() {
  tui_step "Installing rules"
  mkdir -p .claude/rules

  # Install all rules except typescript.md (handled conditionally below)
  while IFS= read -r -d '' _rule_path; do
    _rule_name="${_rule_path##*/}"
    # Skip typescript.md — handled conditionally below via TS_RULES_MAP
    [ "$_rule_name" = "typescript.md" ] && continue
    _install_or_update_file "$_rule_path" ".claude/rules/$_rule_name"
  done < <(find "$TPL/claude/rules" -maxdepth 1 -type f -print0 | sort -z)

  # Conditional: install TypeScript rules only when TS files are detected
  local _ts_found
  _ts_found=$(find . \( -name "*.ts" -o -name "*.tsx" \) -not -path "*/node_modules/*" 2>/dev/null | head -1)
  if [ -n "$_ts_found" ]; then
    tui_info "TypeScript detected - installing typescript.md rules"
    for _ts_mapping in "${TS_RULES_MAP[@]}"; do
      local _ts_tpl="${_ts_mapping%%:*}"
      local _ts_target="${_ts_mapping#*:}"
      _install_or_update_file "$SCRIPT_DIR/$_ts_tpl" "$_ts_target"
    done
  fi
}

# Create specs/ directory structure
install_specs() {
  tui_step "Setting up spec workflow"
  mkdir -p specs/completed
  _install_or_update_file "$TPL/specs/TEMPLATE.md" specs/TEMPLATE.md
  _install_or_update_file "$TPL/specs/README.md" specs/README.md
  if [ ! -f specs/completed/.gitkeep ]; then
    touch specs/completed/.gitkeep
  fi
}

# Install developer workflow guide
install_workflow_guide() {
  tui_step "Installing workflow guide"
  _install_or_update_file "$TPL/WORKFLOW-GUIDE.md" WORKFLOW-GUIDE.md
}

# Install all template skills (commands + spec workflow) to .claude/skills/
install_skills() {
  tui_step "Installing skills"
  [ -d "$TPL/skills" ] || return 0
  local _count=0
  while IFS= read -r -d '' skill_dir; do
    local name="${skill_dir##*/}"
    local skill_file="$skill_dir/SKILL.md"
    [ -f "$skill_file" ] || continue
    mkdir -p ".claude/skills/$name"
    _install_or_update_file "$skill_file" ".claude/skills/$name/SKILL.md"
    _count=$(( _count + 1 ))
  done < <(find "$TPL/skills" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
  [ "$_count" -gt 0 ] && tui_success "$_count skill(s) installed to .claude/skills/"
  return 0
}

# Install tracked repo-local Claude scripts by copying canonical templates/scripts/*.sh
# into .claude/scripts/ during setup.
install_claude_scripts() {
  if [ ! -d "$TPL/scripts" ]; then return 0; fi
  tui_step "Installing Claude scripts"
  local _result
  _result=$(_install_template_dir "$TPL/scripts" ".claude/scripts" "*.sh" "executable")
  local _count="${_result##*COUNT:}"
  [ "$_count" -gt 0 ] && tui_success "${_count} script(s) installed to .claude/scripts/"
}

# Update .gitignore with AI setup entries
# Team-vs-local boundary:
#   GITIGNORED (machine-local): .state, skill cache, memory, dump outputs
#   COMMITTED  (team-shared):   .agents/context/*.md (STACK, ARCHITECTURE, CONVENTIONS, PATTERNS, AUDIT)
#   Never add .agents/context/*.md files to gitignore — they are shared team knowledge.
update_gitignore() {
  tui_step "Updating .gitignore"
  if [ -f .gitignore ]; then
    if ! grep -q "claude/settings.local" .gitignore 2>/dev/null; then
      echo "" >> .gitignore
      echo "# Claude Code / Project setup" >> .gitignore
      echo ".claude/settings.local.json" >> .gitignore
      echo ".ai-setup.json" >> .gitignore
      echo ".ai-setup-backup/" >> .gitignore
      echo ".agents/context/.state" >> .gitignore
      echo ".agents/memory/" >> .gitignore
      echo ".agents/.skill-cache.json" >> .gitignore
      echo "scripts/storyblok-dump.json" >> .gitignore
      echo "CLAUDE.local.md" >> .gitignore
      echo ".codex/skills" >> .gitignore
      echo ".gemini/agents" >> .gitignore
      echo ".opencode/skills" >> .gitignore
    else
      # Add new entries if missing from existing block
      grep -q "\.ai-setup\.json" .gitignore 2>/dev/null || echo ".ai-setup.json" >> .gitignore
      grep -q "\.ai-setup-backup" .gitignore 2>/dev/null || echo ".ai-setup-backup/" >> .gitignore
      grep -q "\.agents/context/\.state" .gitignore 2>/dev/null || echo ".agents/context/.state" >> .gitignore
      grep -q "\.agents/memory" .gitignore 2>/dev/null || echo ".agents/memory/" >> .gitignore
      grep -q "skill-cache" .gitignore 2>/dev/null || echo ".agents/.skill-cache.json" >> .gitignore
      grep -q "storyblok-dump\.json" .gitignore 2>/dev/null || echo "scripts/storyblok-dump.json" >> .gitignore
      grep -q "CLAUDE\.local\.md" .gitignore 2>/dev/null || echo "CLAUDE.local.md" >> .gitignore
      grep -q "\.codex/skills" .gitignore 2>/dev/null || echo ".codex/skills" >> .gitignore
      grep -q "\.gemini/agents" .gitignore 2>/dev/null || echo ".gemini/agents" >> .gitignore
      grep -q "\.opencode/skills" .gitignore 2>/dev/null || echo ".opencode/skills" >> .gitignore
    fi
  else
    echo "# Claude Code / Project setup" > .gitignore
    echo ".claude/settings.local.json" >> .gitignore
    echo ".ai-setup.json" >> .gitignore
    echo ".ai-setup-backup/" >> .gitignore
    echo ".agents/context/.state" >> .gitignore
    echo ".agents/.skill-cache.json" >> .gitignore
    echo "scripts/storyblok-dump.json" >> .gitignore
    echo "CLAUDE.local.md" >> .gitignore
    echo ".codex/skills" >> .gitignore
    echo ".gemini/agents" >> .gitignore
    echo ".opencode/skills" >> .gitignore
  fi

  # AGENTS.md should be tracked like CLAUDE.md (never ignored)
  if grep -Eq '^[[:space:]]*/?AGENTS\.md[[:space:]]*$' .gitignore 2>/dev/null; then
    local tmp_gitignore
    tmp_gitignore=$(mktemp)
    awk '!/^[[:space:]]*\/?AGENTS\.md[[:space:]]*$/' .gitignore > "$tmp_gitignore" && mv "$tmp_gitignore" .gitignore
    echo "  Removed AGENTS.md from .gitignore (must be committed)."
  fi
}
