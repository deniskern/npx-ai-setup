#!/bin/bash
# Core utilities: template map, version management, checksums, backup
# Requires: SCRIPT_DIR, TPL

# Files with special handling excluded from generic TEMPLATE_MAP (e.g. mcp.json uses merge logic)
TEMPLATE_EXCLUDES=("mcp.json")

# Build TEMPLATE_MAP dynamically from templates/ directory.
# Applies consistent prefix rules:
#   claude/  -> .claude/
#   github/  -> .github/
#   agents/  -> .claude/agents/
#   specs/   -> specs/
#   (root)   -> (root, e.g. CLAUDE.md)
# Note: commands/ is empty (migrated to skills/); skills/ handled by install_skills()
build_template_map() {
  TEMPLATE_MAP=()
  local tpl_dir="$SCRIPT_DIR/templates"

  while IFS= read -r -d '' file; do
    local rel="${file#$tpl_dir/}"
    local filename="${rel##*/}"

    # Skip excluded filenames
    local excluded=false
    for excl in "${TEMPLATE_EXCLUDES[@]}"; do
      [ "$filename" = "$excl" ] && excluded=true && break
    done
    [ "$excluded" = "true" ] && continue

    # Skip skills/ and commands/ — both handled by install_skills()
    [[ "$rel" == skills/* ]] && continue
    [[ "$rel" == commands/* ]] && continue

    # Skip typescript.md — handled conditionally by TS_RULES_MAP in install_rules()
    [[ "$rel" == "claude/rules/typescript.md" ]] && continue

    # Map source path to install target path
    local target
    case "$rel" in
      claude/*)   target=".${rel}" ;;
      github/*)   target=".${rel}" ;;
      agents/*)   target=".claude/${rel}" ;;
      scripts/*)  target=".claude/${rel}" ;;
      specs/*)    target="${rel}" ;;
      *)          target="${rel}" ;;
    esac

    TEMPLATE_MAP+=("templates/${rel}:${target}")
  done < <(find "$tpl_dir" -type f -print0 | sort -z)
}

# Populate TEMPLATE_MAP at startup
build_template_map

# Legacy: explicit skill mappings used by install_spec_skills() — kept for compat.
# Superseded by install_skills() which installs all templates/skills/ generically.
SPEC_SKILLS_MAP=(
  "templates/skills/spec-board/SKILL.template.md:.claude/skills/spec-board/SKILL.md"
  "templates/skills/spec/SKILL.template.md:.claude/skills/spec/SKILL.md"
  "templates/skills/spec-review/SKILL.template.md:.claude/skills/spec-review/SKILL.md"
  "templates/skills/spec-validate/SKILL.template.md:.claude/skills/spec-validate/SKILL.md"
  "templates/skills/spec-work/SKILL.template.md:.claude/skills/spec-work/SKILL.md"
  "templates/skills/spec-work-all/SKILL.template.md:.claude/skills/spec-work-all/SKILL.md"
  "templates/skills/orchestrate/SKILL.template.md:.claude/skills/orchestrate/SKILL.md"
)

# System-to-boilerplate-repo mapping (org: onedot-digital-crew)
# Uses a function instead of declare -A for bash 3.2 compatibility (macOS)
get_boilerplate_repo() {
  case "$1" in
    shopify)        echo "sp-shopify-boilerplate" ;;
    shopware)       echo "sw-shop-boilerplate" ;;
    nuxt-storyblok) echo "sb-nuxt-boilerplate" ;;
    next)           echo "sb-next-boilerplate" ;;
    storyblok)      echo "sb-storyblok-boilerplate" ;;
    *)         return 1 ;;
  esac
}

# TypeScript-specific rules (only added when *.ts or *.tsx files are detected)
TS_RULES_MAP=(
  "templates/claude/rules/typescript.md:.claude/rules/typescript.md"
)

# Return 0 if $1 > $2 in semver (major.minor.patch, ignores pre-release)
_semver_gt() {
  local -a a b
  IFS=. read -ra a <<< "$1"
  IFS=. read -ra b <<< "$2"
  for i in 0 1 2; do
    local ai=${a[$i]:-0} bi=${b[$i]:-0}
    [ "$ai" -gt "$bi" ] 2>/dev/null && return 0
    [ "$ai" -lt "$bi" ] 2>/dev/null && return 1
  done
  return 1  # equal
}

# Get package version from package.json
get_package_version() {
  _json_read "$SCRIPT_DIR/package.json" '.version' 2>/dev/null || echo "unknown"
}

# Get installed version from .ai-setup.json
get_installed_version() {
  if [ -f .ai-setup.json ] && _json_valid .ai-setup.json; then
    _json_read .ai-setup.json '.version' || echo ""
  else
    echo ""
  fi
}

# Compute checksum for a file (sha256sum on Linux/macOS, fallback to shasum)
compute_checksum() {
  if [ -f "$1" ]; then
    if command -v sha256sum >/dev/null 2>&1; then
      sha256sum "$1" 2>/dev/null | awk '{print $1}' || echo ""
    else
      shasum -a 256 "$1" 2>/dev/null | awk '{print $1}' || echo ""
    fi
  else
    echo ""
  fi
}

# Write .ai-setup.json with current version and checksums
write_metadata() {
  local version
  version=$(get_package_version)
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Preserve original install time if updating
  local install_time="$timestamp"
  if [ -f .ai-setup.json ] && _json_valid .ai-setup.json; then
    local prev
    prev=$(_json_read .ai-setup.json '.installed_at')
    [ -n "$prev" ] && install_time="$prev"
  fi

  # Build JSON
  local json
  json=$(_json_build_metadata "$version" "$install_time" "$timestamp")

  # Persist boilerplate system if detected
  if [ -n "${SELECTED_SYSTEM:-}" ]; then
    json=$(echo "$json" | jq --arg sys "$SELECTED_SYSTEM" '. + {system: $sys}')
  elif [ -f .ai-setup.json ] && command -v jq >/dev/null 2>&1; then
    # Preserve existing system field on updates
    local prev_sys
    prev_sys=$(jq -r '.system // empty' .ai-setup.json 2>/dev/null)
    if [ -n "$prev_sys" ] && [ "$prev_sys" != "null" ]; then
      json=$(echo "$json" | jq --arg sys "$prev_sys" '. + {system: $sys}')
    fi
  fi

  for mapping in "${TEMPLATE_MAP[@]}"; do
    local tpl="${mapping%%:*}"
    local target="${mapping#*:}"
    if [ -f "$target" ]; then
      local cs
      cs=$(compute_checksum "$target")
      json=$(echo "$json" | _json_set_file "$target" "$cs")
    fi
  done

  # Include TypeScript rules if installed
  for mapping in "${TS_RULES_MAP[@]}"; do
    local tpl="${mapping%%:*}"
    local target="${mapping#*:}"
    if [ -f "$target" ]; then
      local cs
      cs=$(compute_checksum "$target")
      json=$(echo "$json" | _json_set_file "$target" "$cs")
    fi
  done

  # Include scripts installed via install_claude_scripts
  if [ -d ".claude/scripts" ]; then
    while IFS= read -r -d '' _script; do
      local _target="${_script#./}"
      local cs
      cs=$(compute_checksum "$_target")
      json=$(echo "$json" | _json_set_file "$_target" "$cs")
    done < <(find .claude/scripts -type f -print0 | sort -z)
  fi

  # Include only template-managed skills (skip custom skills without a template source)
  if [ -d ".claude/skills" ]; then
    while IFS= read -r -d '' _skill; do
      local _target="${_skill#./}"
      local _sname
      _sname=$(echo "$_target" | sed 's|.claude/skills/\([^/]*\)/SKILL.md|\1|')
      [ -f "$SCRIPT_DIR/templates/skills/$_sname/SKILL.template.md" ] || continue
      local cs
      cs=$(compute_checksum "$_target")
      json=$(echo "$json" | _json_set_file "$_target" "$cs")
    done < <(find .claude/skills -name "SKILL.md" -print0 | sort -z)

    while IFS= read -r -d '' _ref; do
      local _target="${_ref#./}"
      local _sname
      local _rname
      _sname=$(echo "$_target" | sed 's|.claude/skills/\([^/]*\)/references/.*|\1|')
      _rname="${_target##*/}"
      [ -f "$SCRIPT_DIR/templates/skills/$_sname/references/$_rname" ] || continue
      local cs
      cs=$(compute_checksum "$_target")
      json=$(echo "$json" | _json_set_file "$_target" "$cs")
    done < <(find .claude/skills -path "*/references/*.md" -print0 | sort -z)
  fi

  echo "$json" > .ai-setup.json
}

# Returns 0 when the target path is still managed by the current installer config.
# Includes conditional maps that may or may not apply in the current project.
is_current_managed_target() {
  local target="$1"
  local mapping

  for mapping in "${TEMPLATE_MAP[@]}"; do
    [ "${mapping#*:}" = "$target" ] && return 0
  done

  for mapping in "${TS_RULES_MAP[@]}"; do
    [ "${mapping#*:}" = "$target" ] && return 0
  done

  # Scripts are managed via install_claude_scripts
  [[ "$target" == .claude/scripts/* ]] && return 0

  # Skills: only protect if a matching template exists (custom skills are not tracked)
  if [[ "$target" == .claude/skills/*/SKILL.md ]]; then
    local _skill_name
    _skill_name=$(echo "$target" | sed 's|.claude/skills/\([^/]*\)/SKILL.md|\1|')
    [ -f "$SCRIPT_DIR/templates/skills/$_skill_name/SKILL.template.md" ] && return 0
  fi

  if [[ "$target" == .claude/skills/*/references/*.md ]]; then
    local _skill_name
    local _ref_name
    _skill_name=$(echo "$target" | sed 's|.claude/skills/\([^/]*\)/references/.*|\1|')
    _ref_name="${target##*/}"
    [ -f "$SCRIPT_DIR/templates/skills/$_skill_name/references/$_ref_name" ] && return 0
  fi

  return 1
}

# Backup a file to .ai-setup-backup/ with timestamp
backup_file() {
  local file="$1"
  local ts
  ts=$(date +"%Y%m%d_%H%M%S")
  mkdir -p .ai-setup-backup

  # Use flat filename with path separators replaced
  local safe_name
  safe_name=$(echo "$file" | tr '/' '_')
  local backup_path=".ai-setup-backup/${safe_name}.${ts}"
  cp "$file" "$backup_path"
  echo "$backup_path"
}

# Efficiently collect project files (git-aware with fallback)
collect_project_files() {
  local max_files=${1:-80}

  # Try git first (10x faster)
  if git rev-parse --git-dir >/dev/null 2>&1; then
    git ls-files -z '*.js' '*.ts' '*.jsx' '*.tsx' '*.vue' '*.svelte' \
      '*.css' '*.scss' '*.liquid' '*.php' '*.html' '*.twig' \
      '*.blade.php' '*.erb' '*.py' '*.rb' '*.go' '*.rs' '*.astro' \
      2>/dev/null | tr '\0' '\n' | head -n "$max_files"
  else
    # Fallback: optimized find with early pruning
    find . -maxdepth 4 \
      \( -name node_modules -o -name .git -o -name dist -o -name build \
         -o -name assets -o -name .next -o -name vendor -o -name .nuxt \) -prune -o \
      -type f \( \
        -iname '*.js' -o -iname '*.ts' -o -iname '*.jsx' -o -iname '*.tsx' \
        -o -iname '*.vue' -o -iname '*.svelte' -o -iname '*.css' -o -iname '*.scss' \
        -o -iname '*.liquid' -o -iname '*.php' -o -iname '*.html' -o -iname '*.twig' \
        -o -iname '*.blade.php' -o -iname '*.erb' -o -iname '*.py' -o -iname '*.rb' \
        -o -iname '*.go' -o -iname '*.rs' -o -iname '*.astro' \
      \) -print | head -n "$max_files"
  fi
}
