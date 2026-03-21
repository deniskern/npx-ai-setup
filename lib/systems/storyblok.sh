#!/bin/bash
# System plugin: Storyblok
# Requires: core.sh ($TPL), setup.sh (_install_or_update_file), json.sh (_json_merge)

# Install Storyblok dump script and npm entry
install_storyblok_scripts() {
  echo "  📦 Installing Storyblok scripts..."
  local scripts_dir="scripts"
  mkdir -p "$scripts_dir"
  local target="$scripts_dir/storyblok-dump.ts"
  _install_or_update_file "$TPL/scripts/storyblok-dump.ts" "$target"
  # Add npm script entry if package.json present and entry missing
  if [ -f "package.json" ]; then
    if ! grep -q '"storyblok-dump"' package.json 2>/dev/null; then
      _json_merge package.json '{"scripts":{"storyblok-dump":"tsx scripts/storyblok-dump.ts"}}'
      echo "  ✅ Added storyblok-dump script to package.json"
    else
      echo "  ⏭️  storyblok-dump script already in package.json"
    fi
  fi
}

# System plugin interface: default skills for AI-curated installation
system_get_default_skills() {
  SYSTEM_SKILLS+=(
    "bartundmett/skills@storyblok-best-practices"
  )
}
