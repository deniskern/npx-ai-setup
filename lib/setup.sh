#!/bin/bash
# Fresh install steps: requirements, templates, hooks, commands, agents
# Requires: core.sh ($TPL, $TEMPLATE_MAP, $SHOPIFY_SKILLS_MAP)

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
  [ "$tpl_cs" = "$cur_cs" ] && return 1

  # Template is newer — check if user modified the installed file
  if [ -f .ai-setup.json ] && command -v jq >/dev/null 2>&1; then
    local stored_cs
    stored_cs=$(jq -r --arg f "$target" '.files[$f] // empty' .ai-setup.json 2>/dev/null)
    if [ -n "$stored_cs" ] && [ "$stored_cs" != "$cur_cs" ]; then
      # User modified this file — don't overwrite
      echo "  ⏭️  $target (user-modified, kept)"
      return 1
    fi
  fi

  # Not user-modified — safe to update
  cp "$src" "$target"
  [[ "$target" == *.sh ]] && chmod +x "$target"
  echo "  ✅ $target (updated)"
  return 0
}

# Check requirements: node >= 18, npm, jq, AI CLI detection
# Sets: $AI_CLI
check_requirements() {
  MISSING=()
  ! command -v node &>/dev/null && MISSING+=("node (>= 18)")
  ! command -v npm &>/dev/null && MISSING+=("npm")
  ! command -v jq &>/dev/null && MISSING+=("jq (brew install jq)")

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

# Install all GitHub templates (copilot instructions + workflows)
install_copilot() {
  mkdir -p .github
  while IFS= read -r -d '' _gh_path; do
    local _rel="${_gh_path#$TPL/github/}"
    local _target=".github/$_rel"
    _install_or_update_file "$_gh_path" "$_target"
  done < <(find "$TPL/github" -type f -print0 | sort -z)
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

# Install Shopify-specific template skills (when system includes shopify)
install_shopify_skills() {
  if [[ "${SYSTEM:-}" == *shopify* ]]; then
    echo "  🛍️  Installing Shopify skills..."
    for mapping in "${SHOPIFY_SKILLS_MAP[@]}"; do
      local local_tpl="${mapping%%:*}"
      local local_target="${mapping#*:}"
      local skill_dir
      skill_dir="$(dirname "$local_target")"
      mkdir -p "$skill_dir"
      # Backwards-compat: rename legacy prompt.md to SKILL.md if present
      if [ -f "$skill_dir/prompt.md" ] && [ ! -f "$skill_dir/SKILL.md" ]; then
        mv "$skill_dir/prompt.md" "$skill_dir/SKILL.md"
      fi
      _install_or_update_file "$TPL/${local_tpl#templates/}" "$local_target"
    done
  fi
}

install_spec_skills() {
  [ "${#SPEC_SKILLS_MAP[@]}" -gt 0 ] || return 0
  echo "  📚 Installing spec workflow skills..."
  for mapping in "${SPEC_SKILLS_MAP[@]}"; do
    local local_tpl="${mapping%%:*}"
    local local_target="${mapping#*:}"
    local skill_dir src_path
    skill_dir="$(dirname "$local_target")"
    src_path="$TPL/${local_tpl#templates/}"
    [ -f "$src_path" ] || continue
    mkdir -p "$skill_dir"
    _install_or_update_file "$src_path" "$local_target"
  done
}

# Install subagent templates
install_agents() {
  echo "🤖 Installing subagent templates..."
  mkdir -p .claude/agents
  while IFS= read -r -d '' _agent_path; do
    _agent_name="${_agent_path##*/}"
    _install_or_update_file "$_agent_path" ".claude/agents/$_agent_name"
  done < <(find "$TPL/agents" -maxdepth 1 -type f -print0 | sort -z)
  _inject_agent_skills
}

# Inject skills: field into agent YAML headers based on detected system.
# Runs after agent templates are copied. Idempotent — skips if skills: already present.
_inject_agent_skills() {
  # Insert a skills block before the closing --- in an agent's YAML frontmatter.
  # Usage: _inject_skill "agent-name.md" "skill1" "skill2" ...
  _inject_skill() {
    local agent_file=".claude/agents/$1"
    shift
    [ -f "$agent_file" ] || return 0
    grep -q '^skills:' "$agent_file" && return 0

    local skills_block="skills:"
    for s in "$@"; do
      skills_block="$skills_block
  - $s"
    done

    # Build new file: insert skills block before closing ---
    local in_front=false
    local done_inject=false
    local tmpfile
    tmpfile=$(mktemp)
    while IFS= read -r line; do
      if [ "$done_inject" = "true" ]; then
        printf '%s\n' "$line" >> "$tmpfile"
      elif [ "$in_front" = "false" ] && [ "$line" = "---" ]; then
        in_front=true
        printf '%s\n' "$line" >> "$tmpfile"
      elif [ "$in_front" = "true" ] && [ "$line" = "---" ]; then
        printf '%s\n' "$skills_block" >> "$tmpfile"
        printf '%s\n' "$line" >> "$tmpfile"
        done_inject=true
      else
        printf '%s\n' "$line" >> "$tmpfile"
      fi
    done < "$agent_file"
    mv "$tmpfile" "$agent_file"
  }

  if [ "$SYSTEM" = "shopify" ]; then
    _inject_skill "liquid-linter.md" "shopify-liquid" "shopify-theme-dev"
    _inject_skill "code-reviewer.md" "shopify-theme-dev"
  fi

  if [ "$SYSTEM" = "shopware" ]; then
    _inject_skill "code-reviewer.md" "shopware6-best-practices"
  fi

  # vitest skill for test-generator (any system, if vitest is installed)
  if [ -d ".claude/skills/vitest" ]; then
    _inject_skill "test-generator.md" "vitest"
  fi
}

# Merge top-level skill items from $1 into $2.
# Non-conflicting items are moved, conflicts are moved to backup dir and counted.
merge_skills_dir_into_canonical() {
  local source_dir="$1"
  local canonical_dir="$2"
  local backup_dir="$3"
  local moved_ref="$4"
  local conflicts_ref="$5"
  local item
  local name
  local target

  [ -d "$source_dir" ] || return 0

  while IFS= read -r -d '' item; do
    name="${item##*/}"
    target="$canonical_dir/$name"
    if [ ! -e "$target" ]; then
      if mv "$item" "$target" 2>/dev/null; then
        eval "$moved_ref=\$(( $moved_ref + 1 ))"
      else
        mkdir -p "$backup_dir"
        mv "$item" "$backup_dir/$name" 2>/dev/null || true
        eval "$conflicts_ref=\$(( $conflicts_ref + 1 ))"
      fi
    else
      mkdir -p "$backup_dir"
      mv "$item" "$backup_dir/$name" 2>/dev/null || true
      eval "$conflicts_ref=\$(( $conflicts_ref + 1 ))"
    fi
  done < <(find "$source_dir" -mindepth 1 -maxdepth 1 -print0)
}

# Repair looping skill symlinks inside canonical dir, e.g.
# .claude/skills/nuxt -> ../../.agents/skills/nuxt while .agents/skills links back.
# Restores from ~/.agents/skills or ~/.claude/skills when available.
repair_canonical_skill_links() {
  local canonical_dir="$1"
  local canonical_abs="$2"
  local repaired=0
  local removed=0
  local link
  local name
  local target_rel
  local target_abs
  local src

  [ -d "$canonical_dir" ] || return 0

  while IFS= read -r -d '' link; do
    name="${link##*/}"
    target_rel=$(readlink "$link" 2>/dev/null || echo "")
    target_abs=$(cd "$(dirname "$link")" 2>/dev/null && cd "$target_rel" 2>/dev/null && pwd -P)

    case "$target_rel" in
      *".agents/skills/$name"|*".claude/skills/$name")
        rm -f "$link" 2>/dev/null || true
        src=""
        [ -d "$HOME/.agents/skills/$name" ] && src="$HOME/.agents/skills/$name"
        [ -z "$src" ] && [ -d "$HOME/.claude/skills/$name" ] && src="$HOME/.claude/skills/$name"
        if [ -n "$src" ]; then
          cp -R "$src" "$canonical_dir/$name" 2>/dev/null || mkdir -p "$canonical_dir/$name"
          repaired=$((repaired + 1))
          echo "  🛠️  Repaired skill link loop: $name (restored from $(basename "$(dirname "$src")"))"
        else
          removed=$((removed + 1))
          echo "  ⚠️  Removed looping skill link: $name (reinstall if needed)"
        fi
        ;;
      *)
        # Self-referential absolute resolution also indicates a loop.
        if [ -n "$target_abs" ] && [ "$target_abs" = "$canonical_abs/$name" ]; then
          rm -f "$link" 2>/dev/null || true
          removed=$((removed + 1))
          echo "  ⚠️  Removed self-referential skill link: $name"
        fi
        ;;
    esac
  done < <(find "$canonical_dir" -mindepth 1 -maxdepth 1 -type l -print0)

  [ "$repaired" -gt 0 ] && echo "  ✅ Repaired $repaired looping skill link(s)"
  [ "$removed" -gt 0 ] && echo "  ℹ️  Removed $removed broken skill link(s)"
  return 0
}

# Keep .claude/skills as canonical and expose .agents/skills as symlink alias.
# Falls back gracefully when symlinks are not available.
ensure_skills_alias() {
  local canonical=".claude/skills"
  local alias=".agents/skills"
  local moved=0
  local conflicts=0
  local ts
  local backup_dir
  local canonical_abs
  local project_abs
  local canonical_target
  local canonical_target_abs
  local alias_target
  local alias_abs

  mkdir -p .claude .agents
  ts=$(date +"%Y%m%d_%H%M%S")
  backup_dir=".ai-setup-backup/skills-migration-$ts"
  project_abs=$(pwd -P 2>/dev/null || pwd)

  # Canonical path must be a real directory (not a symlink), otherwise loops can occur.
  if [ -L "$canonical" ]; then
    canonical_target=$(readlink "$canonical" 2>/dev/null || echo "")
    canonical_target_abs=$(cd "$(dirname "$canonical")" 2>/dev/null && cd "$canonical_target" 2>/dev/null && pwd -P)
    echo "  ♻️  Converting legacy symlink $canonical -> ${canonical_target:-<unresolved>} to canonical directory"
    rm -f "$canonical" 2>/dev/null || true
    mkdir -p "$canonical"

    # Only migrate automatically from in-project targets (e.g. .agents/skills).
    if [ -n "$canonical_target_abs" ] && [ -d "$canonical_target_abs" ]; then
      case "$canonical_target_abs" in
        "$project_abs"/*)
          merge_skills_dir_into_canonical "$canonical_target_abs" "$canonical" "$backup_dir" moved conflicts
          ;;
        *)
          echo "  ℹ️  Skipping auto-migration from external target: $canonical_target_abs"
          ;;
      esac
    fi
  fi

  # Guard against unexpected file at canonical path.
  if [ ! -d "$canonical" ]; then
    if [ -e "$canonical" ]; then
      mkdir -p "$backup_dir"
      mv "$canonical" "$backup_dir/skills-canonical-path-$ts" 2>/dev/null || rm -f "$canonical" 2>/dev/null || true
      conflicts=$((conflicts + 1))
    fi
    mkdir -p "$canonical"
  fi

  canonical_abs=$(cd "$canonical" 2>/dev/null && pwd -P)
  repair_canonical_skill_links "$canonical" "$canonical_abs"

  if [ -L "$alias" ]; then
    alias_target=$(readlink "$alias" 2>/dev/null || echo "")
    alias_abs=$(cd "$(dirname "$alias")" 2>/dev/null && cd "$alias_target" 2>/dev/null && pwd -P)
    if [ -n "$alias_abs" ] && [ -n "$canonical_abs" ] && [ "$alias_abs" = "$canonical_abs" ]; then
      return 0
    fi
    echo "  ♻️  Repointing legacy symlink $alias -> $alias_target to canonical $canonical"
    if [ -n "$alias_abs" ] && [ -d "$alias_abs" ]; then
      merge_skills_dir_into_canonical "$alias_abs" "$canonical" "$backup_dir" moved conflicts
    fi
    rm -f "$alias" 2>/dev/null || true
  fi

  # Migrate legacy non-symlink layout (.agents/skills as real directory).
  if [ -d "$alias" ] && [ -n "$(ls -A "$alias" 2>/dev/null)" ]; then
    echo "  ♻️  Migrating legacy skills layout ($alias -> $canonical)..."
    merge_skills_dir_into_canonical "$alias" "$canonical" "$backup_dir" moved conflicts
  fi

  [ "$moved" -gt 0 ] && echo "  ✅ Migrated $moved skill item(s) into $canonical" || true
  [ "$conflicts" -gt 0 ] && echo "  ⚠️  $conflicts conflicting item(s) backed up to $backup_dir" || true

  if [ -d "$alias" ]; then
    rm -rf "$alias" 2>/dev/null || true
  fi

  if ln -s ../.claude/skills "$alias" 2>/dev/null; then
    echo "  🔗 Linked $alias -> ../.claude/skills"
  else
    echo "  ℹ️  Symlink not available on this system. Using $canonical only."
  fi
}

# Create .codex/skills -> .claude/skills symlink if codex is installed.
ensure_codex_skills_alias() {
  command -v codex >/dev/null 2>&1 || return 0
  local alias=".codex/skills"
  local canonical_abs
  canonical_abs=$(cd .claude/skills 2>/dev/null && pwd -P)
  mkdir -p .codex
  if [ -L "$alias" ]; then
    local alias_abs
    alias_abs=$(cd "$(dirname "$alias")" 2>/dev/null && cd "$(readlink "$alias")" 2>/dev/null && pwd -P)
    [ -n "$alias_abs" ] && [ "$alias_abs" = "$canonical_abs" ] && return 0
    rm -f "$alias" 2>/dev/null || echo "  ⚠️  Could not remove stale symlink $alias"
  elif [ -e "$alias" ]; then
    echo "  ⏭️  $alias already exists as a non-symlink — skipping (Codex)"
    return 0
  fi
  if ln -s ../.claude/skills "$alias" 2>/dev/null; then
    echo "  🔗 Linked $alias -> ../.claude/skills (Codex)"
  fi
}

# Create .opencode/skills -> .claude/skills symlink if opencode is installed.
ensure_opencode_skills_alias() {
  command -v opencode >/dev/null 2>&1 || return 0
  local alias=".opencode/skills"
  local canonical_abs
  canonical_abs=$(cd .claude/skills 2>/dev/null && pwd -P)
  mkdir -p .opencode
  if [ -L "$alias" ]; then
    local alias_abs
    alias_abs=$(cd "$(dirname "$alias")" 2>/dev/null && cd "$(readlink "$alias")" 2>/dev/null && pwd -P)
    [ -n "$alias_abs" ] && [ "$alias_abs" = "$canonical_abs" ] && return 0
    rm -f "$alias" 2>/dev/null || echo "  ⚠️  Could not remove stale symlink $alias"
  elif [ -e "$alias" ]; then
    echo "  ⏭️  $alias already exists as a non-symlink — skipping (OpenCode)"
    return 0
  fi
  if ln -s ../.claude/skills "$alias" 2>/dev/null; then
    echo "  🔗 Linked $alias -> ../.claude/skills (OpenCode)"
  fi
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
      echo ".agents/repomix-snapshot.md" >> .gitignore
      echo "CLAUDE.local.md" >> .gitignore
      echo ".codex/skills" >> .gitignore
      echo ".opencode/skills" >> .gitignore
    else
      # Add new entries if missing from existing block
      grep -q "\.ai-setup\.json" .gitignore 2>/dev/null || echo ".ai-setup.json" >> .gitignore
      grep -q "\.ai-setup-backup" .gitignore 2>/dev/null || echo ".ai-setup-backup/" >> .gitignore
      grep -q "\.agents/context/\.state" .gitignore 2>/dev/null || echo ".agents/context/.state" >> .gitignore
      grep -q "repomix-snapshot" .gitignore 2>/dev/null || echo ".agents/repomix-snapshot.md" >> .gitignore
      grep -q "CLAUDE\.local\.md" .gitignore 2>/dev/null || echo "CLAUDE.local.md" >> .gitignore
      grep -q "\.codex/skills" .gitignore 2>/dev/null || echo ".codex/skills" >> .gitignore
      grep -q "\.opencode/skills" .gitignore 2>/dev/null || echo ".opencode/skills" >> .gitignore
    fi
  else
    echo "# Claude Code / AI Setup" > .gitignore
    echo ".claude/settings.local.json" >> .gitignore
    echo ".ai-setup.json" >> .gitignore
    echo ".ai-setup-backup/" >> .gitignore
    echo ".agents/context/.state" >> .gitignore
    echo ".agents/repomix-snapshot.md" >> .gitignore
    echo "CLAUDE.local.md" >> .gitignore
    echo ".codex/skills" >> .gitignore
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

# Map Claude Code model shorthand to OpenCode provider/model format
_oc_model() {
  case "$1" in
    haiku)  echo "anthropic/claude-haiku-4-5" ;;
    opus)   echo "anthropic/claude-opus-4-6" ;;
    *)      echo "anthropic/claude-sonnet-4-6" ;;
  esac
}

# Generate opencode.json for OpenCode compatibility
# Translates agents, commands, MCP servers from Claude Code format
generate_opencode_config() {
  if [ -f opencode.json ]; then
    echo "  opencode.json already exists, skipping."
    return 0
  fi

  command -v jq &>/dev/null || return 0

  # MCP servers from .mcp.json
  local mcp_block="{}"
  if [ -f .mcp.json ]; then
    mcp_block=$(jq '.mcpServers // {}' .mcp.json 2>/dev/null || echo "{}")
  fi

  # Agents from .claude/agents/*.md
  local agents_json="{}"
  if [ -d .claude/agents ]; then
    for agent_file in .claude/agents/*.md; do
      [ -f "$agent_file" ] || continue
      local aname amodel adesc atools
      aname=$(basename "$agent_file" .md)
      # Extract frontmatter fields (awk for macOS/BSD compat)
      adesc=$(awk '/^---$/{n++; next} n==1 && /^description:/{sub(/^description: */, ""); print}' "$agent_file" | head -1)
      amodel=$(awk '/^---$/{n++; next} n==1 && /^model:/{sub(/^model: */, ""); print}' "$agent_file" | head -1)
      atools=$(awk '/^---$/{n++; next} n==1 && /^tools:/{sub(/^tools: */, ""); print}' "$agent_file" | head -1)

      [ -z "$adesc" ] && adesc="$aname agent"

      # Map tools to OpenCode permissions
      local t_read=false t_write=false t_bash=false
      case "$atools" in *Read*|*Glob*|*Grep*) t_read=true ;; esac
      case "$atools" in *Write*|*Edit*) t_write=true ;; esac
      case "$atools" in *Bash*) t_bash=true ;; esac

      agents_json=$(printf '%s' "$agents_json" | jq -c \
        --arg name "$aname" \
        --arg desc "$adesc" \
        --arg model "$(_oc_model "$amodel")" \
        --arg file "$agent_file" \
        --argjson r "$t_read" --argjson w "$t_write" --argjson b "$t_bash" \
        '.[$name] = {
          "description": $desc,
          "mode": "subagent",
          "model": $model,
          "prompt": ("{file:" + $file + "}"),
          "tools": {"read": $r, "write": $w, "edit": $w, "bash": $b}
        }')
    done
  fi

  # Commands from .claude/commands/*.md
  local commands_json="{}"
  if [ -d .claude/commands ]; then
    for cmd_file in .claude/commands/*.md; do
      [ -f "$cmd_file" ] || continue
      local cname cmodel
      cname=$(basename "$cmd_file" .md)
      cmodel=$(awk '/^---$/{n++; next} n==1 && /^model:/{sub(/^model: */, ""); print}' "$cmd_file" | head -1)

      # Derive description from filename (kebab-case to words)
      local cdesc
      cdesc=$(echo "$cname" | tr '-' ' ')

      commands_json=$(printf '%s' "$commands_json" | jq -c \
        --arg name "$cname" \
        --arg desc "$cdesc" \
        --arg file "$cmd_file" \
        '.[$name] = {"description": $desc, "template": ("{file:" + $file + "}\\n\\n$ARGUMENTS")}')
    done
  fi

  # Assemble final config
  jq -n \
    --arg schema "https://opencode.ai/config.json" \
    --arg model "anthropic/claude-sonnet-4-6" \
    --arg small "anthropic/claude-haiku-4-5" \
    --argjson mcp "$mcp_block" \
    --argjson agents "$agents_json" \
    --argjson commands "$commands_json" \
    '{
      "$schema": $schema,
      "model": $model,
      "small_model": $small,
      "instructions": ["CLAUDE.md"],
      "mcp": $mcp,
      "agent": $agents,
      "command": $commands
    }' > opencode.json 2>/dev/null

  if [ -f opencode.json ]; then
    local ac=0 cc=0
    ac=$(echo "$agents_json" | jq 'keys | length' 2>/dev/null || echo 0)
    cc=$(echo "$commands_json" | jq 'keys | length' 2>/dev/null || echo 0)
    echo "  opencode.json created ($ac agents, $cc commands, OpenCode compatibility)"
  fi
}

# Install repomix.config.json for codebase snapshot configuration
install_repomix_config() {
  if [ ! -f repomix.config.json ]; then
    cp "$TPL/repomix.config.json" repomix.config.json
  else
    echo "  repomix.config.json already exists, skipping."
  fi
}

# Install claude-powerline statusline into project settings.json.
install_statusline_project() {
  # Idempotency: skip if statusLine is already configured
  if [ -f ".claude/settings.json" ] && jq -e '.statusLine' ".claude/settings.json" >/dev/null 2>&1; then
    return 0
  fi
  mkdir -p ".claude"
  # Copy default powerline config (skip if already present)
  if [ ! -f ".claude/claude-powerline.json" ] && [ -f "$SCRIPT_DIR/templates/.claude-powerline.json" ]; then
    cp "$SCRIPT_DIR/templates/.claude-powerline.json" ".claude/claude-powerline.json"
  fi
  local status_cmd="npx -y @owloops/claude-powerline@latest --style=powerline --theme=dark"
  if [ -f ".claude/settings.json" ]; then
    local TMP
    TMP=$(mktemp)
    if jq --arg cmd "$status_cmd" '.statusLine = {"type":"command","command":$cmd,"padding":2}' ".claude/settings.json" > "$TMP"; then
      mv "$TMP" ".claude/settings.json"
    else
      rm -f "$TMP"
      echo "  ⚠️  Failed to update .claude/settings.json (jq error)"
      return 1
    fi
  else
    local TMP2
    TMP2=$(mktemp)
    if jq -n --arg cmd "$status_cmd" '{"statusLine":{"type":"command","command":$cmd,"padding":2}}' > "$TMP2"; then
      mv "$TMP2" ".claude/settings.json"
    else
      rm -f "$TMP2"
      return 1
    fi
  fi
  echo "  Statusline installed -> claude-powerline (@owloops/claude-powerline)"
}

# Generate repomix codebase snapshot in background (once, if not already present)
generate_repomix_snapshot() {
  if [ -f ".agents/repomix-snapshot.md" ]; then
    return 0
  fi
  mkdir -p .agents
  echo "📸 Generating codebase snapshot (repomix)..."

  local _repomix_timeout=""
  command -v timeout &>/dev/null && _repomix_timeout="timeout 120"
  command -v gtimeout &>/dev/null && _repomix_timeout="gtimeout 120"

  # Use repomix.config.json if present (user-customizable), otherwise fall back to defaults
  if [ -f "repomix.config.json" ]; then
    $_repomix_timeout npx -y repomix >/dev/null 2>&1 &
  else
    $_repomix_timeout npx -y repomix --compress --style markdown \
      --ignore "node_modules,dist,.git,.next,.nuxt,coverage,.turbo,*.lock,*.lockb" \
      --output .agents/repomix-snapshot.md >/dev/null 2>&1 &
  fi
  REPOMIX_PID=$!

  SPIN='-\|/'
  i=0
  while kill -0 $REPOMIX_PID 2>/dev/null; do
    i=$(( (i+1) % 4 ))
    printf "\r  ${SPIN:$i:1} Analyzing codebase..."
    sleep 0.2
  done

  REPOMIX_EXIT=0
  wait $REPOMIX_PID 2>/dev/null || REPOMIX_EXIT=$?

  if [ $REPOMIX_EXIT -eq 0 ] && [ -f ".agents/repomix-snapshot.md" ]; then
    LINES=$(wc -l < .agents/repomix-snapshot.md 2>/dev/null || echo "?")
    printf "\r  ✅ Snapshot written to .agents/repomix-snapshot.md (%s lines)%*s\n" "$LINES" 10 ""
  else
    printf "\r  ⏭️  repomix unavailable, skipping snapshot%*s\n" 20 ""
    rm -f .agents/repomix-snapshot.md
  fi
}
