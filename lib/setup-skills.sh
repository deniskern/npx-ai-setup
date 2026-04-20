#!/bin/bash
# Skills and agents installation: spec skills, agent templates, skill aliases
# Requires: core.sh ($TPL, $TEMPLATE_MAP, $SPEC_SKILLS_MAP), setup.sh (_install_or_update_file)

install_spec_skills() {
  [ "${#SPEC_SKILLS_MAP[@]}" -gt 0 ] || return 0
  tui_step "Installing spec workflow skills"

  # Detect stack profile for filtering (empty = no filter)
  local _profile=""
  if [ "${FORCE_ALL_SKILLS:-0}" != "1" ] && [ -n "${SCRIPT_DIR:-}" ] && \
     [ -f "${SCRIPT_DIR}/lib/detect-stack.sh" ]; then
    _profile=$(bash "${SCRIPT_DIR}/lib/detect-stack.sh" "$PWD" 2>/dev/null \
      | grep '^stack_profile=' | cut -d= -f2 || true)
  fi

  for mapping in "${SPEC_SKILLS_MAP[@]}"; do
    local local_tpl="${mapping%%:*}"
    local local_target="${mapping#*:}"
    local skill_dir src_path skill_name
    skill_dir="$(dirname "$local_target")"
    src_path="$TPL/${local_tpl#templates/}"
    skill_name="$(basename "$skill_dir")"
    [ -f "$src_path" ] || continue

    # Apply stack profile filter when profile is known and not "default"
    if [ -n "$_profile" ] && [ "$_profile" != "default" ]; then
      if ! skill_matches_profile "$src_path" "$_profile"; then
        log_skill_skip "$skill_name" "$src_path" "$_profile"
        continue
      fi
    fi

    mkdir -p "$skill_dir"
    _install_or_update_file "$src_path" "$local_target"
  done
}

# Install subagent templates
install_agents() {
  tui_step "Installing subagent templates"
  mkdir -p .claude/agents

  # Detect stack from project config for conditional agent install
  local _has_frontend=false
  local _has_backend=false
  if [ -f "package.json" ]; then
    grep -qE '"(react|vue|nuxt|next|svelte|astro)"' package.json 2>/dev/null && _has_frontend=true
    # Backend: Nuxt/Next server, express, fastify, nitro, or server/ directory
    if grep -qE '"(express|fastify|@hono|h3|nitro)"' package.json 2>/dev/null \
       || [ -d "server" ] || ls nuxt.config.* 1>/dev/null 2>&1 || ls next.config.* 1>/dev/null 2>&1; then
      _has_backend=true
    fi
  fi

  while IFS= read -r -d '' _agent_path; do
    _agent_name="${_agent_path##*/}"
    # frontend-developer: only when frontend framework detected
    if [ "$_agent_name" = "frontend-developer.md" ] && [ "$_has_frontend" = "false" ]; then
      tui_info "frontend-developer agent skipped (no frontend stack detected)"
      continue
    fi
    # backend-developer: only when backend/API framework detected
    if [ "$_agent_name" = "backend-developer.md" ] && [ "$_has_backend" = "false" ]; then
      tui_info "backend-developer agent skipped (no backend stack detected)"
      continue
    fi
    _install_or_update_file "$_agent_path" ".claude/agents/$_agent_name"
  done < <(find "$TPL/agents" -maxdepth 1 -type f -print0 | sort -z)
  _inject_agent_skills
}

# Install universal agents to ~/.claude/agents/ for cross-project availability.
# Only copies agents that are NOT stack-specific (those come from boilerplate repos).
install_global_agents() {
  local global_dir="$HOME/.claude/agents"
  local warned=false
  local skipped="no"
  local _count=0

  if ! mkdir -p "$global_dir" 2>/dev/null; then
    tui_warn "Global agents skipped: cannot create $global_dir"
    return 0
  fi

  tui_step "Installing global agents to ~/.claude/agents/"

  while IFS= read -r -d '' _agent_path; do
    _agent_name="${_agent_path##*/}"
    [ "$_agent_name" = "README.md" ] && continue
    # Conditional agents are project-specific, not global
    [ "$_agent_name" = "frontend-developer.md" ] && continue
    [ "$_agent_name" = "backend-developer.md" ] && continue

    if [ ! -f "$global_dir/$_agent_name" ] || ! cmp -s "$_agent_path" "$global_dir/$_agent_name"; then
      if cp "$_agent_path" "$global_dir/$_agent_name" 2>/dev/null; then
        _count=$((_count + 1))
      else
        if [ "$warned" = "false" ]; then
          tui_warn "Global agents skipped: cannot write to $global_dir"
          warned=true
        fi
        skipped="yes"
      fi
    fi
  done < <(find "$TPL/agents" -maxdepth 1 -type f -name '*.md' -print0 | sort -z)

  if [ "$warned" = "true" ] && [ "$_count" -eq 0 ]; then
    return 0
  fi

  if [ "$_count" -gt 0 ]; then
    tui_success "$_count global agent(s) installed/updated"
  elif [ "$skipped" = "yes" ]; then
    tui_warn "Global agents skipped (unable to write to ${global_dir})"
  else
    tui_info "Global agents already up to date"
  fi

  return 0
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

# Create .gemini/agents -> .claude/skills symlink if gemini is installed.
ensure_gemini_skills_alias() {
  command -v gemini >/dev/null 2>&1 || return 0
  local alias=".gemini/agents"
  local canonical_abs
  canonical_abs=$(cd .claude/skills 2>/dev/null && pwd -P)
  mkdir -p .gemini
  if [ -L "$alias" ]; then
    local alias_abs
    alias_abs=$(cd "$(dirname "$alias")" 2>/dev/null && cd "$(readlink "$alias")" 2>/dev/null && pwd -P)
    [ -n "$alias_abs" ] && [ "$alias_abs" = "$canonical_abs" ] && return 0
    rm -f "$alias" 2>/dev/null || echo "  ⚠️  Could not remove stale symlink $alias"
  elif [ -e "$alias" ]; then
    echo "  ⏭️  $alias already exists as a non-symlink — skipping (Gemini)"
    return 0
  fi
  if ln -s ../.claude/skills "$alias" 2>/dev/null; then
    echo "  🔗 Linked $alias -> ../.claude/skills (Gemini)"
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

# Install graphify skill when INSTALL_GRAPHIFY=yes and not already present.
# Idempotent: skips silently if .claude/skills/graphify.md already exists.
# Called from ai-setup.sh after the user has confirmed the opt-in.
install_graphify_skill() {
  [ "${INSTALL_GRAPHIFY:-no}" = "yes" ] || return 0

  local dst=".claude/skills/graphify.md"
  if [ -f "$dst" ]; then
    tui_info "Graphify skill already installed — skipping"
    return 0
  fi

  local src="$TPL/skills/graphify/SKILL.template.md"
  if [ ! -f "$src" ]; then
    tui_warn "Graphify skill template missing: $src"
    return 1
  fi

  mkdir -p .claude/skills
  cp "$src" "$dst"
  tui_success "Graphify skill installed ($dst)"

  if ! command -v graphify >/dev/null 2>&1; then
    tui_warn "graphify binary not found — run: pipx install graphifyy"
  fi
}
