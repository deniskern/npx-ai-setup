#!/bin/bash
# Migration runner and helper functions for versioned incremental updates
# Requires: SCRIPT_DIR, core.sh (get_installed_version, get_package_version, _semver_gt)

# Run all pending migrations between installed_version and target_version.
# Usage: run_migrations <installed_version> <target_version>
# Returns 0 if all migrations applied (or none pending), 1 on failure.
run_migrations() {
  local installed_version="$1"
  local target_version="$2"
  local migrations_dir="$SCRIPT_DIR/lib/migrations"
  local applied=0
  local failed=0

  if [ ! -d "$migrations_dir" ]; then
    return 0
  fi

  # Collect migration files, sorted by version
  local -a pending=()
  while IFS= read -r -d '' mfile; do
    local fname
    fname=$(basename "$mfile" .sh)
    # Only include migrations with version > installed_version
    if _semver_gt "$fname" "$installed_version" && ! _semver_gt "$fname" "$target_version"; then
      pending+=("$mfile")
    fi
  done < <(find "$migrations_dir" -maxdepth 1 -name "*.sh" -print0 | sort -z)

  if [ "${#pending[@]}" -eq 0 ]; then
    return 0
  fi

  echo ""
  echo "🔄 Applying ${#pending[@]} migration(s)..."

  for mfile in "${pending[@]}"; do
    local mver
    mver=$(basename "$mfile" .sh)
    echo "   → $mver"
    if source "$mfile"; then
      applied=$((applied + 1))
    else
      echo "   ❌ Migration $mver failed"
      failed=$((failed + 1))
      break
    fi
  done

  echo ""
  if [ "$failed" -gt 0 ]; then
    echo "⚠️  $applied migration(s) applied, $failed failed."
    return 1
  fi

  echo "✅ $applied migration(s) applied."
  return 0
}

# ---------------------------------------------------------------------------
# Migration helper functions (used inside migration files)
# All functions are idempotent — safe to run twice.
# ---------------------------------------------------------------------------

# Copy a template file to target if the target does not already exist.
# Usage: _add_file <template_rel_path> <target_path>
#   template_rel_path: relative to SCRIPT_DIR (e.g. templates/claude/rules/foo.md)
_add_file() {
  local tpl="$1" target="$2"
  local src="$SCRIPT_DIR/$tpl"
  if [ ! -f "$src" ]; then
    echo "  ⚠️  _add_file: source not found: $tpl" >&2
    return 1
  fi
  if [ -f "$target" ]; then
    return 0  # Already exists — idempotent
  fi
  mkdir -p "$(dirname "$target")"
  cp "$src" "$target"
  [[ "$target" == *.sh ]] && chmod +x "$target"
  echo "  ✨ $target (new)"
}

# Replace target with template content, backing up user modifications first.
# Usage: _update_file <template_rel_path> <target_path>
_update_file() {
  local tpl="$1" target="$2"
  local src="$SCRIPT_DIR/$tpl"
  if [ ! -f "$src" ]; then
    echo "  ⚠️  _update_file: source not found: $tpl" >&2
    return 1
  fi
  if [ ! -f "$target" ]; then
    mkdir -p "$(dirname "$target")"
    cp "$src" "$target"
    [[ "$target" == *.sh ]] && chmod +x "$target"
    echo "  ✨ $target (new)"
    return 0
  fi

  local tpl_cs cur_cs
  tpl_cs=$(compute_checksum "$src")
  cur_cs=$(compute_checksum "$target")
  if [ "$tpl_cs" = "$cur_cs" ]; then
    return 0  # Already up to date
  fi

  # Check for user modifications
  local stored_cs
  stored_cs=$(jq -r --arg f "$target" '.files[$f] // empty' .ai-setup.json 2>/dev/null)
  if [ -n "$stored_cs" ] && [ "$stored_cs" != "$cur_cs" ]; then
    local bp
    bp=$(backup_file "$target")
    cp "$src" "$target"
    [[ "$target" == *.sh ]] && chmod +x "$target"
    echo "  ✅ $target (updated — backed up to $bp)"
  else
    cp "$src" "$target"
    [[ "$target" == *.sh ]] && chmod +x "$target"
    echo "  ✅ $target (updated)"
  fi
}

# Replace or append a line matching a pattern in a file.
# Usage: _patch_line <file> <pattern> <replacement_line>
#   If a line matching <pattern> exists, replace it with <replacement_line>.
#   If no match, append <replacement_line> to the file.
# Idempotent: if replacement line already exists verbatim, skip.
_patch_line() {
  local file="$1" pattern="$2" replacement="$3"
  if [ ! -f "$file" ]; then
    echo "  ⚠️  _patch_line: file not found: $file" >&2
    return 1
  fi
  # Already contains exact replacement line — skip
  if grep -qF "$replacement" "$file" 2>/dev/null; then
    return 0
  fi
  if grep -q "$pattern" "$file" 2>/dev/null; then
    # Replace first matching line
    local tmp
    tmp=$(mktemp)
    awk -v pat="$pattern" -v rep="$replacement" -v done=0 \
      'done==0 && $0 ~ pat { print rep; done=1; next } { print }' \
      "$file" > "$tmp" && mv "$tmp" "$file" || { rm -f "$tmp"; return 1; }
    echo "  ✅ $file (patched line)"
  else
    printf '\n%s\n' "$replacement" >> "$file"
    echo "  ✅ $file (appended line)"
  fi
}

# Add a permission entry to claude settings.json if it is not already present.
# Usage: _settings_add_permission <permission_string>
#   permission_string: e.g. "Bash(git:*)"
_settings_add_permission() {
  local perm="$1"
  local settings_file=".claude/settings.json"
  if [ ! -f "$settings_file" ]; then
    return 0
  fi
  if ! command -v jq >/dev/null 2>&1; then
    echo "  ⚠️  _settings_add_permission: jq required" >&2
    return 1
  fi
  # Idempotent: skip if already present
  if jq -e --arg p "$perm" '.permissions.allow // [] | index($p) != null' "$settings_file" >/dev/null 2>&1; then
    return 0
  fi
  local tmp
  tmp=$(mktemp)
  jq --arg p "$perm" '.permissions.allow = ((.permissions.allow // []) + [$p] | unique)' \
    "$settings_file" > "$tmp" && mv "$tmp" "$settings_file" || { rm -f "$tmp"; return 1; }
  echo "  ✅ $settings_file (added permission: $perm)"
}

# Add a hook entry to claude settings.json if it is not already present.
# Usage: _settings_add_hook <event> <command>
#   event: e.g. "PostToolUse"
_settings_add_hook() {
  local event="$1" cmd="$2"
  local settings_file=".claude/settings.json"
  if [ ! -f "$settings_file" ]; then
    return 0
  fi
  if ! command -v jq >/dev/null 2>&1; then
    echo "  ⚠️  _settings_add_hook: jq required" >&2
    return 1
  fi
  # Idempotent: skip if command already present for this event
  if jq -e --arg e "$event" --arg c "$cmd" \
    '.hooks[$e] // [] | map(.hooks // []) | flatten | index($c) != null' \
    "$settings_file" >/dev/null 2>&1; then
    return 0
  fi
  local tmp
  tmp=$(mktemp)
  jq --arg e "$event" --arg c "$cmd" \
    '.hooks[$e] = ((.hooks[$e] // []) + [{"hooks": [$c]}])' \
    "$settings_file" > "$tmp" && mv "$tmp" "$settings_file" || { rm -f "$tmp"; return 1; }
  echo "  ✅ $settings_file (added hook: $event → $cmd)"
}

# Remove a managed file, backing up user modifications.
# Usage: _remove_file <target_path>
_remove_file() {
  local target="$1"
  if [ ! -f "$target" ]; then
    return 0  # Already gone — idempotent
  fi

  local stored_cs cur_cs
  stored_cs=$(jq -r --arg f "$target" '.files[$f] // empty' .ai-setup.json 2>/dev/null)
  cur_cs=$(compute_checksum "$target")

  if [ -n "$stored_cs" ] && [ "$stored_cs" != "$cur_cs" ]; then
    local bp
    bp=$(backup_file "$target")
    rm -f "$target"
    echo "  🧹 $target (removed — backed up to $bp)"
  else
    rm -f "$target"
    echo "  🧹 $target (removed)"
  fi
}
