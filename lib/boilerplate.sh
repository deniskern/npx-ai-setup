#!/bin/bash
# Boilerplate pull: fetch system-specific config from canonical boilerplate repos via gh CLI
# Requires: $SCRIPT_DIR, _json_merge(), _json_valid(), skill_matches_profile() (skill-filter.sh)

# Org that hosts all boilerplate repos
BOILERPLATE_ORG="onedot-digital-crew"

# Check if gh CLI is available and authenticated
_gh_available() {
  command -v gh >/dev/null 2>&1 || return 1
  gh auth status >/dev/null 2>&1 || return 1
  return 0
}

# Return 0 when the current repository already is the canonical boilerplate repo
# for the given system. This avoids pointless self-pulls inside boilerplates.
_is_current_repo_boilerplate() {
  local system="$1"
  local repo_name
  repo_name=$(get_boilerplate_repo "$system" 2>/dev/null) || return 1

  local repo_root=""
  local current_dir=""
  local origin_url=""

  if command -v git >/dev/null 2>&1; then
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null || true)
    origin_url=$(git remote get-url origin 2>/dev/null || true)
  fi

  if [ -n "$repo_root" ]; then
    current_dir=$(basename "$repo_root")
  else
    current_dir=$(basename "$PWD")
  fi

  [ "$current_dir" = "$repo_name" ] && return 0

  case "$origin_url" in
    *"${BOILERPLATE_ORG}/${repo_name}" | *"${BOILERPLATE_ORG}/${repo_name}.git")
      return 0
      ;;
  esac

  return 1
}

# Fetch a single file from a GitHub repo via gh API.
# Decodes base64 content and writes to target path.
# Usage: _gh_fetch_file <org>/<repo> <remote_path> <local_target>
_gh_fetch_file() {
  local repo="$1"
  local remote_path="$2"
  local local_target="$3"
  local content

  content=$(gh api "repos/${repo}/contents/${remote_path}" --jq '.content' 2>/dev/null) || return 1
  [ -z "$content" ] && return 1

  mkdir -p "$(dirname "$local_target")"

  # Decode base64 (macOS: base64 -D, GNU: base64 -d) into temp file
  local tmp
  tmp=$(mktemp)
  if echo "$content" | base64 -D > "$tmp" 2>/dev/null || echo "$content" | base64 -d > "$tmp" 2>/dev/null; then
    # Skip if identical to existing file
    if [ -f "$local_target" ] && diff -q "$tmp" "$local_target" >/dev/null 2>&1; then
      rm -f "$tmp"
      return 2  # unchanged
    fi
    mv "$tmp" "$local_target"
    return 0
  fi

  rm -f "$tmp" "$local_target"
  return 1
}

# Fetch a directory listing from a GitHub repo via gh API.
# Returns newline-separated list of file paths.
# Usage: _gh_list_dir <org>/<repo> <remote_path>
_gh_list_dir() {
  local repo="$1"
  local remote_path="$2"
  gh api "repos/${repo}/contents/${remote_path}" --jq '.[] | select(.type=="dir") | .path' 2>/dev/null || true
}

# Merge a remote .mcp.json into the local .mcp.json.
# Never overwrites — always merges via _json_merge().
_merge_mcp_json() {
  local repo="$1"
  local tmp_mcp
  tmp_mcp=$(mktemp)

  if _gh_fetch_file "$repo" ".mcp.json" "$tmp_mcp"; then
    if _json_valid "$tmp_mcp"; then
      if [ -f .mcp.json ] && _json_valid .mcp.json; then
        local remote_content
        remote_content=$(cat "$tmp_mcp")
        _json_merge .mcp.json "$remote_content"
        echo "  📦 .mcp.json merged from boilerplate"
      else
        mv "$tmp_mcp" .mcp.json
        echo "  📦 .mcp.json copied from boilerplate"
        return 0
      fi
    else
      echo "  ⚠️  .mcp.json from boilerplate is invalid JSON, skipping" >&2
      rm -f "$tmp_mcp"
      return 1
    fi
  else
    rm -f "$tmp_mcp"
    return 1
  fi

  rm -f "$tmp_mcp"
}

# Pass FORCE_ALL_SKILLS=1 (env) to bypass the stack profile filter.
# Pull all boilerplate files for a given system from the canonical repo.
# Fresh installs pull skills, rules, agents, and .mcp.json by default.
# Update syncs can pass --skip-skills to avoid overwriting project-local skills.
# Usage: pull_boilerplate_files <system> [--skip-skills]
pull_boilerplate_files() {
  local system="$1"
  local skip_skills="${2:-}"
  local repo_name
  repo_name=$(get_boilerplate_repo "$system") || return 1
  local repo="${BOILERPLATE_ORG}/${repo_name}"

  tui_section "Boilerplate Pull" "Pulling ${system} config from ${repo}"

  local pulled=0
  local failed=0
  local skipped=0

  # Detect stack profile for skill filtering (empty = filter disabled)
  local _stack_profile=""
  if [ "${FORCE_ALL_SKILLS:-0}" != "1" ] && [ -n "${SCRIPT_DIR:-}" ] && \
     [ -f "${SCRIPT_DIR}/lib/detect-stack.sh" ]; then
    _stack_profile=$(bash "${SCRIPT_DIR}/lib/detect-stack.sh" "$PWD" 2>/dev/null \
      | grep '^stack_profile=' | cut -d= -f2 || true)
  fi

  if [ "$skip_skills" != "--skip-skills" ]; then
    # --- Skills: .claude/skills/*/SKILL.md ---
    local skill_dirs
    skill_dirs=$(_gh_list_dir "$repo" ".claude/skills" 2>/dev/null | grep -v '^$' || true)

    if [ -n "$skill_dirs" ]; then
      while IFS= read -r skill_dir; do
        local skill_name
        skill_name=$(basename "$skill_dir")
        local remote_skill="${skill_dir}/SKILL.md"
        local local_skill=".claude/skills/${skill_name}/SKILL.md"

        # Download to temp file first so we can inspect frontmatter before install
        local _tmp_skill
        _tmp_skill=$(mktemp)

        _gh_fetch_file "$repo" "$remote_skill" "$_tmp_skill"
        local _rc=$?

        if [ $_rc -eq 0 ] || [ $_rc -eq 2 ]; then
          # Apply stack profile filter when profile is known and not "default"
          if [ -n "$_stack_profile" ] && [ "$_stack_profile" != "default" ]; then
            if ! skill_matches_profile "$_tmp_skill" "$_stack_profile"; then
              log_skill_skip "$skill_name" "$_tmp_skill" "$_stack_profile"
              rm -f "$_tmp_skill"
              skipped=$((skipped + 1))
              continue
            fi
          fi

          if [ $_rc -eq 0 ]; then
            mkdir -p ".claude/skills/${skill_name}"
            mv "$_tmp_skill" "$local_skill"
            tui_success "Skill: ${skill_name}"
            pulled=$((pulled + 1))
          else
            # rc=2: unchanged — temp file holds the same content, discard
            rm -f "$_tmp_skill"
          fi
        else
          rm -f "$_tmp_skill"
          tui_warn "Skill not found: ${skill_name}/SKILL.md"
          failed=$((failed + 1))
        fi
      done <<< "$skill_dirs"
    fi
  fi

  # --- Rules: .claude/rules/<system>*.md ---
  local rules_listing
  rules_listing=$(gh api "repos/${repo}/contents/.claude/rules" --jq '.[].name' 2>/dev/null || true)

  if [ -n "$rules_listing" ]; then
    while IFS= read -r rule_file; do
      # Only pull rules prefixed with the system name
      if [[ "$rule_file" == "${system}"* ]]; then
        local local_rule=".claude/rules/${rule_file}"
        _gh_fetch_file "$repo" ".claude/rules/${rule_file}" "$local_rule"
        local _rc=$?
        if [ $_rc -eq 0 ]; then
          tui_success "Rule: ${rule_file}"
          pulled=$((pulled + 1))
        elif [ $_rc -eq 1 ]; then
          tui_warn "Rule fetch failed: ${rule_file}"
          failed=$((failed + 1))
        fi
        # rc=2: unchanged — skip silently
      fi
    done <<< "$rules_listing"
  fi

  # --- Agents: .claude/agents/*.md ---
  local agents_listing
  agents_listing=$(gh api "repos/${repo}/contents/.claude/agents" --jq '.[].name' 2>/dev/null || true)

  if [ -n "$agents_listing" ]; then
    mkdir -p .claude/agents
    while IFS= read -r agent_file; do
      [[ "$agent_file" == *.md ]] || continue
      [ "$agent_file" = "README.md" ] && continue
      local local_agent=".claude/agents/${agent_file}"
      _gh_fetch_file "$repo" ".claude/agents/${agent_file}" "$local_agent"
      local _rc=$?
      if [ $_rc -eq 0 ]; then
        tui_success "Agent: ${agent_file%.md}"
        pulled=$((pulled + 1))
      elif [ $_rc -eq 1 ]; then
        tui_warn "Agent fetch failed: ${agent_file}"
        failed=$((failed + 1))
      fi
      # rc=2: unchanged — skip silently
    done <<< "$agents_listing"
  fi

  # --- MCP config: merge .mcp.json ---
  _merge_mcp_json "$repo"

  echo ""
  if [ "$skipped" -gt 0 ]; then
    tui_info "Done: ${pulled} file(s) pulled, ${skipped} skipped (profile filter), ${failed} failed"
  else
    tui_info "Done: ${pulled} file(s) pulled, ${failed} failed"
  fi
  echo ""
}

# Show manual pull instructions when gh CLI is not available.
_show_manual_instructions() {
  local system="$1"
  local repo_name
  repo_name=$(get_boilerplate_repo "$system") || repo_name="<repo-name>"

  echo ""
  tui_hint \
    "gh CLI not available — manual pull required:" \
    "  Option A — Clone and copy:" \
    "    git clone --depth=1 https://github.com/${BOILERPLATE_ORG}/${repo_name}.git /tmp/${repo_name}" \
    "    cp -r /tmp/${repo_name}/.claude/skills/* .claude/skills/" \
    "    cp /tmp/${repo_name}/.claude/rules/${system}*.md .claude/rules/" \
    "    cp /tmp/${repo_name}/.claude/agents/*.md .claude/agents/ 2>/dev/null" \
    "  Option B — Install gh CLI:" \
    "    brew install gh && gh auth login" \
    "    Then run the setup command again: npx @onedot/ai-setup"
}

# Detect the installed boilerplate system for an existing project.
# Reads from .ai-setup.json first, falls back to rule-file pattern matching.
# Prints the system name (shopify/shopware/nuxt/next/storyblok) or empty string.
detect_installed_system() {
  # Primary: read from metadata
  if [ -f .ai-setup.json ] && command -v jq >/dev/null 2>&1; then
    local sys
    sys=$(jq -r '.system // empty' .ai-setup.json 2>/dev/null)
    if [ -n "$sys" ] && [ "$sys" != "null" ]; then
      echo "$sys"
      return 0
    fi
  fi

  # Fallback: detect from rule files
  local rules_dir=".claude/rules"
  if [ -d "$rules_dir" ]; then
    for system_key in shopify shopware nuxt-storyblok nuxt next storyblok; do
      if ls "${rules_dir}/${system_key}"*.md 2>/dev/null | grep -q .; then
        echo "$system_key"
        return 0
      fi
    done
  fi

  echo ""
  return 1
}

# Sync boilerplate files for the detected system.
# Called during updates to re-pull latest rules/agents from boilerplate repos
# without overwriting project-local skills.
sync_boilerplate() {
  local system
  system=$(detect_installed_system) || true

  if [ -z "$system" ]; then
    # No system recorded in .ai-setup.json — skip silently during updates.
    # select_boilerplate_system is for fresh installs only; triggering it during
    # an update can pull an unexpected boilerplate based on project files in the
    # current working directory.
    return 0
  fi

  if ! _gh_available; then
    tui_info "Skipping boilerplate sync (gh CLI not available)"
    return 0
  fi

  if ! get_boilerplate_repo "$system" >/dev/null 2>&1; then
    return 0
  fi

  if _is_current_repo_boilerplate "$system"; then
    tui_info "Skipping boilerplate sync (already inside ${system} boilerplate repo)"
    SELECTED_SYSTEM="$system"
    return 0
  fi

  tui_step "Syncing boilerplate for $system"
  pull_boilerplate_files "$system" --skip-skills

  # Persist system in SELECTED_SYSTEM for metadata write
  SELECTED_SYSTEM="$system"
}

# Detect whether any system-specific config is already present.
# Returns 0 if system config found (skip selector), 1 if fresh project.
has_system_config() {
  # Check for system-specific rule files (any non-generic rule file)
  local rules_dir=".claude/rules"
  if [ -d "$rules_dir" ]; then
    for system_key in shopify shopware nuxt-storyblok nuxt next storyblok; do
      ls "${rules_dir}/${system_key}"*.md 2>/dev/null | grep -q . && return 0
    done
  fi
  return 1
}

# Auto-detect framework from project config files and pull boilerplate.
# Sets SELECTED_SYSTEM based on detected config files.
# Skips silently if no framework detected or system config already present.
select_boilerplate_system() {
  SELECTED_SYSTEM=""

  # Skip if system config already present
  if has_system_config; then
    return 0
  fi

  # Auto-detect framework from config files
  if ls nuxt.config.* 1>/dev/null 2>&1; then
    # Nuxt + Storyblok → combined boilerplate; Nuxt-only → no boilerplate repo yet
    if [ -f "package.json" ] && grep -q '"@storyblok/' package.json 2>/dev/null; then
      SELECTED_SYSTEM="nuxt-storyblok"
    else
      SELECTED_SYSTEM="nuxt"
      tui_info "Detected framework: nuxt (no boilerplate pull — nuxt-only repo not yet available)"
      return 0
    fi
  elif ls next.config.* 1>/dev/null 2>&1; then
    SELECTED_SYSTEM="next"
  elif [ -f "theme.liquid" ] || ls shopify.* 1>/dev/null 2>&1 || { [ -d "sections" ] && [ -d "snippets" ]; }; then
    SELECTED_SYSTEM="shopify"
  elif [ -f "shopware.yaml" ] || [ -f "config/packages/shopware.yaml" ] || \
       ([ -f "composer.json" ] && grep -q '"shopware/' composer.json 2>/dev/null) || \
       ([ -f "bin/console" ] && [ -d "src" ]); then
    SELECTED_SYSTEM="shopware"
  fi

  if [ -z "$SELECTED_SYSTEM" ]; then
    return 0
  fi

  tui_info "Detected framework: $SELECTED_SYSTEM"

  if _is_current_repo_boilerplate "$SELECTED_SYSTEM"; then
    tui_info "Skipping boilerplate pull (already inside ${SELECTED_SYSTEM} boilerplate repo)"
    return 0
  fi

  if _gh_available; then
    pull_boilerplate_files "$SELECTED_SYSTEM"
  else
    tui_info "Skipping boilerplate pull (gh CLI not available)"
  fi
}
