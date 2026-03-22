#!/bin/bash
# Core utilities: template map, version management, checksums, backup
# Requires: SCRIPT_DIR, TPL

# Files with special handling excluded from generic TEMPLATE_MAP (e.g. mcp.json uses merge logic)
TEMPLATE_EXCLUDES=("mcp.json")

# Build TEMPLATE_MAP dynamically from templates/ directory.
# Applies consistent prefix rules:
#   claude/    -> .claude/
#   github/    -> .github/
#   commands/  -> .claude/commands/
#   agents/    -> .claude/agents/
#   specs/     -> specs/
#   (root)     -> (root, e.g. CLAUDE.md)
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

    # Skip skills/ — handled separately via SPEC_SKILLS_MAP
    [[ "$rel" == skills/* ]] && continue

    # Skip scripts/ — not installed by generic base layer
    [[ "$rel" == scripts/* ]] && continue

    # Skip typescript.md — handled conditionally by TS_RULES_MAP in install_rules()
    [[ "$rel" == "claude/rules/typescript.md" ]] && continue

    # Map source path to install target path
    local target
    case "$rel" in
      claude/*)   target=".${rel}" ;;
      github/*)   target=".${rel}" ;;
      commands/*) target=".claude/${rel}" ;;
      agents/*)   target=".claude/${rel}" ;;
      specs/*)    target="${rel}" ;;
      *)          target="${rel}" ;;
    esac

    TEMPLATE_MAP+=("templates/${rel}:${target}")
  done < <(find "$tpl_dir" -type f -print0 | sort -z)
}

# Populate TEMPLATE_MAP at startup
build_template_map

# Workflow skills shipped to every project so Codex can map slash-style spec prompts
# to the existing spec workflow through .codex/skills -> .claude/skills.
SPEC_SKILLS_MAP=(
  "templates/skills/spec-board/SKILL.md:.claude/skills/spec-board/SKILL.md"
  "templates/skills/spec-create/SKILL.md:.claude/skills/spec-create/SKILL.md"
  "templates/skills/spec-review/SKILL.md:.claude/skills/spec-review/SKILL.md"
  "templates/skills/spec-validate/SKILL.md:.claude/skills/spec-validate/SKILL.md"
  "templates/skills/spec-work/SKILL.md:.claude/skills/spec-work/SKILL.md"
  "templates/skills/spec-work-all/SKILL.md:.claude/skills/spec-work-all/SKILL.md"
  "templates/skills/project-audit/SKILL.md:.claude/skills/project-audit/SKILL.md"
)

# System-to-boilerplate-repo mapping (org: onedot-digital-crew)
declare -A SYSTEM_BOILERPLATES=(
  ["shopify"]="sp-shopify-boilerplate"
  ["shopware"]="sw-shopware-boilerplate"
  ["nuxt"]="sb-nuxt-boilerplate"
  ["next"]="sb-next-boilerplate"
  ["storyblok"]="sb-storyblok-boilerplate"
)

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

# Compute checksum for a file (cksum outputs: checksum size filename)
compute_checksum() {
  if [ -f "$1" ]; then
    cksum "$1" 2>/dev/null | awk '{print $1, $2}' || echo ""
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
