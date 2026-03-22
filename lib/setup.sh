#!/bin/bash
# Fresh install steps: requirements, templates, hooks, commands
# Requires: core.sh ($TPL, $TEMPLATE_MAP)

# Install a template file, updating it if the template is newer.
# Skips if installed file matches template checksum.
# Updates silently if user hasn't modified the file (checksum matches .ai-setup.json).
# Skips with notice if user has modified the file (preserves user changes).
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
      stored_cs=$(node -e "
        try{const d=JSON.parse(require('fs').readFileSync('.ai-setup.json','utf8'));
        const v=(d.files||{})['$target'];if(v)process.stdout.write(v);}catch(e){}
      " 2>/dev/null)
    fi
    if [ -n "$stored_cs" ] && [ "$stored_cs" != "$cur_cs" ]; then
      # User modified this file — don't overwrite
      echo "  ⏭️  $target (user-modified, kept)"
      return 0
    fi
  fi

  # Not user-modified — safe to update
  cp "$src" "$target"
  [[ "$target" == *.sh ]] && chmod +x "$target"
  echo "  ✅ $target (updated)"
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
    echo "  ℹ️  jq not found — Node.js JSON fallback active (install jq for better performance)"
  fi

  if [ ${#MISSING[@]} -gt 0 ]; then
    echo "❌ Missing requirements:"
    for m in "${MISSING[@]}"; do echo "   - $m"; done
    echo ""
    echo "Install the missing tools and try again."
    exit 1
  fi

  # Node.js version check (>= 18)
  NODE_VERSION=$(node -v 2>/dev/null | sed 's/v//' | cut -d. -f1)
  if [ -n "$NODE_VERSION" ] && [ "$NODE_VERSION" -lt 18 ]; then
    echo "❌ Node.js >= 18 required (found v$NODE_VERSION)"
    exit 1
  fi

  # Template directory validation
  if [ ! -d "$TPL" ]; then
    echo "❌ Template directory not found: $TPL"
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
  echo "✅ Requirements OK (AI CLI: ${AI_CLI:-none detected})"
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
    echo "⚠️  Legacy AI structures found:"
    for f in "${FOUND[@]}"; do echo "   - $f"; done
    echo ""
    read -p "Delete? (Y/n) " CLEANUP
    if [[ ! "$CLEANUP" =~ ^[Nn]$ ]]; then
      for f in "${FOUND[@]}"; do rm -rf "$f"; done
      echo "✅ Cleanup done."
    else
      echo "⏭️  Cleanup skipped."
    fi
  else
    echo "✅ No legacy structures found."
  fi
}

# Copy CLAUDE.md template
install_claude_md() {
  echo "📝 Writing CLAUDE.md..."
  if [ ! -f CLAUDE.md ]; then
    cp "$TPL/CLAUDE.md" CLAUDE.md
    echo "  CLAUDE.md created (template — customize as needed)."
  else
    echo "  CLAUDE.md already exists, skipping."
  fi
}

# Copy AGENTS.md template
install_agents_md() {
  echo "📝 Writing AGENTS.md..."
  if [ ! -f AGENTS.md ]; then
    cp "$TPL/AGENTS.md" AGENTS.md
    echo "  AGENTS.md created (template — customize as needed)."
  else
    echo "  AGENTS.md already exists, skipping."
  fi
}

# Create .claude/settings.json
install_settings() {
  echo "⚙️  Writing .claude/settings.json..."
  mkdir -p .claude
  _install_or_update_file "$TPL/claude/settings.json" .claude/settings.json
}

# Install hook scripts
install_hooks() {
  echo "🛡️  Creating hooks..."
  mkdir -p .claude/hooks

  while IFS= read -r -d '' _hook_path; do
    _hook_name="${_hook_path##*/}"
    _install_or_update_file "$_hook_path" ".claude/hooks/$_hook_name"
  done < <(find "$TPL/claude/hooks" -maxdepth 1 -type f -print0 | sort -z)
}

# Install rule templates
install_rules() {
  echo "📐 Installing rules..."
  mkdir -p .claude/rules

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
    echo "  TypeScript detected — installing typescript.md rules..."
    for _ts_mapping in "${TS_RULES_MAP[@]}"; do
      local _ts_tpl="${_ts_mapping%%:*}"
      local _ts_target="${_ts_mapping#*:}"
      _install_or_update_file "$SCRIPT_DIR/$_ts_tpl" "$_ts_target"
    done
  fi
}

# Create specs/ directory structure
install_specs() {
  echo "📋 Setting up spec-driven workflow..."
  mkdir -p specs/completed
  _install_or_update_file "$TPL/specs/TEMPLATE.md" specs/TEMPLATE.md
  _install_or_update_file "$TPL/specs/README.md" specs/README.md
  if [ ! -f specs/completed/.gitkeep ]; then
    touch specs/completed/.gitkeep
  fi
}

# Install developer workflow guide
install_workflow_guide() {
  echo "📖 Installing developer workflow guide..."
  _install_or_update_file "$TPL/claude/WORKFLOW-GUIDE.md" .claude/WORKFLOW-GUIDE.md
}

# Install slash commands
install_commands() {
  echo "⚡ Installing slash commands..."
  mkdir -p .claude/commands
  while IFS= read -r -d '' _cmd_path; do
    _cmd_name="${_cmd_path##*/}"
    _install_or_update_file "$_cmd_path" ".claude/commands/$_cmd_name"
  done < <(find "$TPL/commands" -maxdepth 1 -type f -print0 | sort -z)
}

# Install Claude scripts (pure Bash, zero-token alternatives to Claude-driven commands)
install_claude_scripts() {
  if [ ! -d "$TPL/scripts" ]; then return 0; fi
  local _count=0
  echo "📜 Installing Claude scripts..."
  mkdir -p .claude/scripts
  while IFS= read -r -d '' _script_path; do
    _script_name="${_script_path##*/}"
    # Only install .sh files
    case "$_script_name" in *.sh) ;; *) continue ;; esac
    _install_or_update_file "$_script_path" ".claude/scripts/$_script_name"
    chmod +x ".claude/scripts/$_script_name" 2>/dev/null || true
    _count=$((_count + 1))
  done < <(find "$TPL/scripts" -maxdepth 1 -name "*.sh" -print0 | sort -z)
  [ "$_count" -gt 0 ] && echo "  ✅ ${_count} script(s) installed to .claude/scripts/"
}

# Heuristic module detection from repository name.
_detect_repo_module() {
  local _name
  _name=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
  case "$_name" in
    *sub-theme*) echo "sub-theme" ;;
    *theme*) echo "theme" ;;
    *plugin*) echo "plugin" ;;
    *shop*) echo "shop" ;;
    *frontend*|*front-end*|*client*|*ui*) echo "frontend" ;;
    *backend*|*back-end*|*api*|*server*) echo "backend" ;;
    *core*) echo "core" ;;
    *) echo "app" ;;
  esac
}

# Optional wizard: creates .agents/context/repo-group.json for cross-repo context.
setup_repo_group_context() {
  local group_file=".agents/context/repo-group.json"
  mkdir -p .agents/context

  if [ -f "$group_file" ]; then
    echo "🔗 Multi-repo context map already exists, skipping."
    return 0
  fi

  echo ""
  echo "🔗 Multi-Repo Context (optional)"
  read -p "   Setup shared repo map (.agents/context/repo-group.json)? (y/N) " SETUP_MULTI_REPO
  [[ "$SETUP_MULTI_REPO" =~ ^[Yy]$ ]] || return 0

  local current_repo parent_dir default_group group_name
  current_repo="$(basename "$PWD")"
  parent_dir="$(cd .. && pwd)"
  default_group="$current_repo"
  if [[ "$current_repo" == *-* ]]; then
    default_group="${current_repo##*-}"
  fi

  read -p "   Group name [${default_group}]: " group_name
  [ -n "$group_name" ] || group_name="$default_group"

  local repos_json
  repos_json=$(jq -n --arg g "$group_name" '{group:$g,repos:[]}')

  local selected=0
  local dir repo_name include_ans module module_default rel_path
  while IFS= read -r dir; do
    [ -d "$dir" ] || continue
    repo_name="$(basename "$dir")"

    # Filter obvious non-project directories.
    if [ ! -d "$dir/.git" ] && [ ! -f "$dir/package.json" ] && [ ! -f "$dir/composer.json" ]; then
      continue
    fi

    if [ "$repo_name" = "$current_repo" ]; then
      read -p "   Include ${repo_name} (current repo)? (Y/n) " include_ans
      [[ "$include_ans" =~ ^[Nn]$ ]] && continue
    else
      read -p "   Include ${repo_name}? (y/N) " include_ans
      [[ "$include_ans" =~ ^[Yy]$ ]] || continue
    fi

    module_default="$(_detect_repo_module "$repo_name")"
    read -p "      Module for ${repo_name} [${module_default}]: " module
    [ -n "$module" ] || module="$module_default"

    if [ "$repo_name" = "$current_repo" ]; then
      rel_path="."
    else
      rel_path="../${repo_name}"
    fi

    repos_json=$(printf '%s' "$repos_json" \
      | jq --arg n "$repo_name" --arg m "$module" --arg p "$rel_path" '.repos += [{name:$n,module:$m,path:$p}]')
    selected=$((selected + 1))
  done < <(find "$parent_dir" -maxdepth 1 -mindepth 1 -type d ! -name ".*" | sort)

  # Ensure current repo is present.
  if ! printf '%s' "$repos_json" | jq -e --arg n "$current_repo" '.repos[]? | select(.name == $n)' >/dev/null 2>&1; then
    module_default="$(_detect_repo_module "$current_repo")"
    repos_json=$(printf '%s' "$repos_json" \
      | jq --arg n "$current_repo" --arg m "$module_default" --arg p "." '.repos += [{name:$n,module:$m,path:$p}]')
    selected=$((selected + 1))
  fi

  if [ "$selected" -lt 2 ]; then
    echo "   ⏭️  Skipping map (need at least 2 repos in group)."
    return 0
  fi

  printf '%s\n' "$repos_json" | jq '.' > "$group_file"
  echo "   ✅ Created $group_file (${selected} repos)"
}

# Update .gitignore with AI setup entries
# Team-vs-local boundary:
#   GITIGNORED (machine-local): .state, repomix snapshot, skill cache, memory, dump outputs
#   COMMITTED  (team-shared):   .agents/context/*.md (STACK, ARCHITECTURE, CONVENTIONS, PATTERNS, AUDIT)
#   Never add .agents/context/*.md files to gitignore — they are shared team knowledge.
update_gitignore() {
  echo "🚫 Updating .gitignore..."
  if [ -f .gitignore ]; then
    if ! grep -q "claude/settings.local" .gitignore 2>/dev/null; then
      echo "" >> .gitignore
      echo "# Claude Code / AI Setup" >> .gitignore
      echo ".claude/settings.local.json" >> .gitignore
      echo ".ai-setup.json" >> .gitignore
      echo ".ai-setup-backup/" >> .gitignore
      echo ".agents/context/.state" >> .gitignore
      echo ".agents/memory/" >> .gitignore
      echo ".agents/repomix-snapshot.xml" >> .gitignore
      echo ".agents/.skill-cache.json" >> .gitignore
      echo "scripts/storyblok-dump.json" >> .gitignore
      echo "CLAUDE.local.md" >> .gitignore
      echo ".codex/skills" >> .gitignore
      echo ".opencode/skills" >> .gitignore
      echo ".repomixignore" >> .gitignore
    else
      # Add new entries if missing from existing block
      grep -q "\.ai-setup\.json" .gitignore 2>/dev/null || echo ".ai-setup.json" >> .gitignore
      grep -q "\.ai-setup-backup" .gitignore 2>/dev/null || echo ".ai-setup-backup/" >> .gitignore
      grep -q "\.agents/context/\.state" .gitignore 2>/dev/null || echo ".agents/context/.state" >> .gitignore
      grep -q "\.agents/memory" .gitignore 2>/dev/null || echo ".agents/memory/" >> .gitignore
      grep -q "repomix-snapshot" .gitignore 2>/dev/null || echo ".agents/repomix-snapshot.xml" >> .gitignore
      grep -q "skill-cache" .gitignore 2>/dev/null || echo ".agents/.skill-cache.json" >> .gitignore
      grep -q "storyblok-dump\.json" .gitignore 2>/dev/null || echo "scripts/storyblok-dump.json" >> .gitignore
      grep -q "CLAUDE\.local\.md" .gitignore 2>/dev/null || echo "CLAUDE.local.md" >> .gitignore
      grep -q "\.codex/skills" .gitignore 2>/dev/null || echo ".codex/skills" >> .gitignore
      grep -q "\.opencode/skills" .gitignore 2>/dev/null || echo ".opencode/skills" >> .gitignore
      grep -q "\.repomixignore" .gitignore 2>/dev/null || echo ".repomixignore" >> .gitignore
    fi
  else
    echo "# Claude Code / AI Setup" > .gitignore
    echo ".claude/settings.local.json" >> .gitignore
    echo ".ai-setup.json" >> .gitignore
    echo ".ai-setup-backup/" >> .gitignore
    echo ".agents/context/.state" >> .gitignore
    echo ".agents/repomix-snapshot.xml" >> .gitignore
    echo ".agents/.skill-cache.json" >> .gitignore
    echo "scripts/storyblok-dump.json" >> .gitignore
    echo "CLAUDE.local.md" >> .gitignore
    echo ".codex/skills" >> .gitignore
    echo ".opencode/skills" >> .gitignore
    echo ".repomixignore" >> .gitignore
  fi

  # AGENTS.md should be tracked like CLAUDE.md (never ignored)
  if grep -Eq '^[[:space:]]*/?AGENTS\.md[[:space:]]*$' .gitignore 2>/dev/null; then
    local tmp_gitignore
    tmp_gitignore=$(mktemp)
    awk '!/^[[:space:]]*\/?AGENTS\.md[[:space:]]*$/' .gitignore > "$tmp_gitignore" && mv "$tmp_gitignore" .gitignore
    echo "  Removed AGENTS.md from .gitignore (must be committed)."
  fi
}
