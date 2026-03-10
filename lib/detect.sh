#!/bin/bash
# System detection and template filtering
# Requires: $SYSTEM, $UPD_* flags

# Detect system from codebase signals when SYSTEM="auto"
# Updates SYSTEM in-place if a concrete signal is found
detect_system() {
  [ "$SYSTEM" != "auto" ] && return 0

  if find . -maxdepth 4 -name "theme.liquid" -not -path "*/node_modules/*" 2>/dev/null | grep -q . \
    || [ -f "shopify.app.toml" ] \
    || [ -f "shopify.web.toml" ] \
    || find . -maxdepth 5 -name "shopify.extension.toml" -not -path "*/node_modules/*" 2>/dev/null | grep -q . \
    || { [ -f package.json ] && grep -Eq '"@shopify/(shopify-api|shopify-app-remix|app-bridge|app-bridge-react|polaris)"' package.json 2>/dev/null; }; then
    SYSTEM="shopify"
  elif [ -f composer.json ] && [ -f artisan ]; then
    SYSTEM="laravel"
  elif [ -f composer.json ] && {
    [ -d vendor/shopware ] ||
    grep -Eq '"type"[[:space:]]*:[[:space:]]*"shopware-(platform-plugin|bundle)"' composer.json 2>/dev/null ||
    grep -Eq '"shopware/(core|storefront|administration|elasticsearch|recovery|platform)"' composer.json 2>/dev/null ||
    grep -Eq '"store\.shopware\.com/' composer.json 2>/dev/null ||
    [ -f manifest.xml ] ||
    { [ -d src ] && find src -maxdepth 2 \( -name "*Plugin.php" -o -name "*Bundle.php" \) 2>/dev/null | grep -q .; }
  }; then
    SYSTEM="shopware"
  elif [ -f package.json ] && grep -q '"nuxt"' package.json 2>/dev/null; then
    SYSTEM="nuxt"
  elif [ -f package.json ] && grep -q '"next"' package.json 2>/dev/null; then
    SYSTEM="next"
  elif [ -f package.json ] && grep -q '"@storyblok' package.json 2>/dev/null; then
    SYSTEM="storyblok"
  fi

  if [ "$SYSTEM" != "auto" ]; then
    echo "  🔍 Detected system: $SYSTEM"
  fi
}

# Distinguish Shopware plugin project from full shop repository.
# Sets SHOPWARE_TYPE to "plugin" or "shop".
# Called from run_generation() after SYSTEM is set.
detect_shopware_type() {
  SHOPWARE_TYPE=""
  [ "$SYSTEM" != "shopware" ] && return 0

  # Shop indicator: custom/plugins or custom/static-plugins directory
  if [ -d "custom/plugins" ] || [ -d "custom/static-plugins" ]; then
    SHOPWARE_TYPE="shop"
    return 0
  fi

  # Plugin indicator: composer.json type field
  local ctype
  ctype=$(jq -r '.type // ""' composer.json 2>/dev/null)
  if [ "$ctype" = "shopware-platform-plugin" ] || [ "$ctype" = "shopware-bundle" ]; then
    SHOPWARE_TYPE="plugin"
    return 0
  fi

  # Plugin indicator: bootstrap PHP class in src/
  if find src -maxdepth 2 \( -name "*Plugin.php" -o -name "*Bundle.php" \) 2>/dev/null | grep -q .; then
    SHOPWARE_TYPE="plugin"
    return 0
  fi

  # Plugin indicator: app-system manifest
  if [ -f manifest.xml ]; then
    SHOPWARE_TYPE="plugin"
    return 0
  fi

  # Fallback: assume plugin (smaller scope, safer default)
  SHOPWARE_TYPE="plugin"
}

# Returns the category name for a given template mapping target path.
# Used by scan_template_changes() and should_update_template().
get_template_category() {
  local target="${1#*:}"
  if [[ "$target" == .claude/hooks/* ]] || [[ "$target" == .claude/rules/* ]]; then
    echo "hooks"
  elif [[ "$target" == .claude/settings* ]]; then
    echo "settings"
  elif [[ "$target" == "CLAUDE.md" ]]; then
    echo "claude_md"
  elif [[ "$target" == "AGENTS.md" ]]; then
    echo "agents_md"
  elif [[ "$target" == .claude/commands/* ]]; then
    echo "commands"
  elif [[ "$target" == .claude/agents/* ]]; then
    echo "agents"
  else
    echo "other"
  fi
}

# Returns 0 (true) if the given mapping's target path matches the selected update categories.
# Returns 1 (false) if the category is deselected — caller should skip this file.
# Defaults to "yes" for all categories when UPD_* flags are unset (fresh install / reinstall paths).
should_update_template() {
  local cat
  cat=$(get_template_category "$1")
  case "$cat" in
    hooks)     [ "${UPD_HOOKS:-yes}" = "yes" ] ;;
    settings)  [ "${UPD_SETTINGS:-yes}" = "yes" ] ;;
    claude_md) [ "${UPD_CLAUDE_MD:-yes}" = "yes" ] ;;
    agents_md) [ "${UPD_AGENTS_MD:-yes}" = "yes" ] ;;
    commands)  [ "${UPD_COMMANDS:-yes}" = "yes" ] ;;
    agents)    [ "${UPD_AGENTS:-yes}" = "yes" ] ;;
    *)         [ "${UPD_OTHER:-yes}" = "yes" ] ;;
  esac
}
