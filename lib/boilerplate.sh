#!/bin/bash
# Boilerplate pull: fetch system-specific config from canonical boilerplate repos via gh CLI
# Requires: $SCRIPT_DIR, _json_merge(), _json_valid()

# Org that hosts all boilerplate repos
BOILERPLATE_ORG="onedot-digital-crew"

# Check if gh CLI is available and authenticated
_gh_available() {
  command -v gh >/dev/null 2>&1 || return 1
  gh auth status >/dev/null 2>&1 || return 1
  return 0
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

  # Decode base64 (macOS: base64 -D, GNU: base64 -d)
  if echo "$content" | base64 -D > "$local_target" 2>/dev/null; then
    return 0
  elif echo "$content" | base64 -d > "$local_target" 2>/dev/null; then
    return 0
  fi

  rm -f "$local_target"
  return 1
}

# Fetch a directory listing from a GitHub repo via gh API.
# Returns newline-separated list of file paths.
# Usage: _gh_list_dir <org>/<repo> <remote_path>
_gh_list_dir() {
  local repo="$1"
  local remote_path="$2"
  gh api "repos/${repo}/contents/${remote_path}" --jq '.[].path' 2>/dev/null || true
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
    fi
  fi

  rm -f "$tmp_mcp"
}

# Pull all boilerplate files for a given system from the canonical repo.
# Fetches: .claude/skills/*/SKILL.md, .claude/rules/<system>*.md, .mcp.json (merged)
# Usage: pull_boilerplate_files <system>
pull_boilerplate_files() {
  local system="$1"
  local repo="${BOILERPLATE_ORG}/${SYSTEM_BOILERPLATES[$system]}"

  echo ""
  echo "📥 Pulling ${system} config from ${repo}..."
  echo "   ──────────────────────────────────────────────────────────"

  local pulled=0
  local failed=0

  # --- Skills: .claude/skills/*/SKILL.md ---
  local skill_dirs
  skill_dirs=$(_gh_list_dir "$repo" ".claude/skills" 2>/dev/null | grep -v '^$' || true)

  if [ -n "$skill_dirs" ]; then
    while IFS= read -r skill_dir; do
      local skill_name
      skill_name=$(basename "$skill_dir")
      local remote_skill="${skill_dir}/SKILL.md"
      local local_skill=".claude/skills/${skill_name}/SKILL.md"

      if _gh_fetch_file "$repo" "$remote_skill" "$local_skill"; then
        echo "  ✅ Skill: ${skill_name}"
        pulled=$((pulled + 1))
      else
        echo "  ⚠️  Skill not found: ${skill_name}/SKILL.md"
        failed=$((failed + 1))
      fi
    done <<< "$skill_dirs"
  fi

  # --- Rules: .claude/rules/<system>*.md ---
  local rules_listing
  rules_listing=$(gh api "repos/${repo}/contents/.claude/rules" --jq '.[].name' 2>/dev/null || true)

  if [ -n "$rules_listing" ]; then
    while IFS= read -r rule_file; do
      # Only pull rules prefixed with the system name
      if [[ "$rule_file" == "${system}"* ]]; then
        local local_rule=".claude/rules/${rule_file}"
        if _gh_fetch_file "$repo" ".claude/rules/${rule_file}" "$local_rule"; then
          echo "  ✅ Rule: ${rule_file}"
          pulled=$((pulled + 1))
        else
          echo "  ⚠️  Rule fetch failed: ${rule_file}"
          failed=$((failed + 1))
        fi
      fi
    done <<< "$rules_listing"
  fi

  # --- MCP config: merge .mcp.json ---
  _merge_mcp_json "$repo"

  echo ""
  echo "  Done: ${pulled} file(s) pulled, ${failed} failed."
  echo ""
}

# Show manual pull instructions when gh CLI is not available.
_show_manual_instructions() {
  local system="$1"
  local repo_name="${SYSTEM_BOILERPLATES[$system]:-<repo-name>}"

  echo ""
  echo "  ℹ️  Manual pull instructions (gh CLI not available):"
  echo ""
  echo "  Option A — Clone and copy:"
  echo "    git clone --depth=1 https://github.com/${BOILERPLATE_ORG}/${repo_name}.git /tmp/${repo_name}"
  echo "    cp -r /tmp/${repo_name}/.claude/skills/* .claude/skills/"
  echo "    cp /tmp/${repo_name}/.claude/rules/${system}*.md .claude/rules/"
  echo ""
  echo "  Option B — Install gh CLI:"
  echo "    brew install gh && gh auth login"
  echo "    Then re-run: npx @onedot/ai-setup"
  echo ""
}

# Detect whether any system-specific config is already present.
# Returns 0 if system config found (skip selector), 1 if fresh project.
has_system_config() {
  # Check for system-specific rule files (any non-generic rule file)
  local rules_dir=".claude/rules"
  if [ -d "$rules_dir" ]; then
    for system_key in shopify shopware nuxt next storyblok; do
      ls "${rules_dir}/${system_key}"*.md 2>/dev/null | grep -q . && return 0
    done
  fi
  return 1
}

# Interactive system selector for fresh installs.
# Prompts user to choose a boilerplate system or skip.
# Sets SELECTED_SYSTEM (or empty string to skip).
select_boilerplate_system() {
  SELECTED_SYSTEM=""

  # Skip if system config already present
  if has_system_config; then
    return 0
  fi

  echo ""
  echo "🏗️  Pull system config from boilerplate?"
  echo "   ──────────────────────────────────────────────────────────"
  echo "   1) Shopify"
  echo "   2) Shopware"
  echo "   3) Nuxt"
  echo "   4) Next.js"
  echo "   5) Storyblok"
  echo "   6) Skip"
  echo ""
  read -rp "   Choose [1-6]: " _choice

  case "$_choice" in
    1) SELECTED_SYSTEM="shopify" ;;
    2) SELECTED_SYSTEM="shopware" ;;
    3) SELECTED_SYSTEM="nuxt" ;;
    4) SELECTED_SYSTEM="next" ;;
    5) SELECTED_SYSTEM="storyblok" ;;
    *) SELECTED_SYSTEM="" ;;
  esac

  if [ -z "$SELECTED_SYSTEM" ]; then
    echo "   Skipping system config pull."
    return 0
  fi

  if _gh_available; then
    pull_boilerplate_files "$SELECTED_SYSTEM"
  else
    echo ""
    echo "  ⚠️  gh CLI not found or not authenticated."
    _show_manual_instructions "$SELECTED_SYSTEM"
  fi
}
