#!/bin/bash
# context-shopware.sh — Shopware project context scanner
# Generates .agents/context/SHOPWARE.md with zero LLM tokens.
# Run: bash .claude/scripts/context-shopware.sh
# Triggered by: /context-refresh skill when composer.json has shopware/core

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
OUTPUT="$PROJECT_DIR/.agents/context/SHOPWARE.md"

# --- Shopware version ---
sw_version=""
if [ -f "$PROJECT_DIR/composer.json" ] && command -v python3 >/dev/null 2>&1; then
  sw_version=$(python3 -c "
import json
with open('$PROJECT_DIR/composer.json') as f:
  d = json.load(f)
req = d.get('require', {})
print(req.get('shopware/core', req.get('shopware/platform', '')))
" 2>/dev/null || echo "")
fi

# --- Custom plugins ---
plugin_dirs=$(find "$PROJECT_DIR/custom/plugins" -maxdepth 1 -mindepth 1 -type d 2>/dev/null \
  | xargs -I{} basename {} | sort | tr '\n' ',' | sed 's/,$//')
plugin_count=$(echo "$plugin_dirs" | tr ',' '\n' | grep -c . 2>/dev/null || echo 0)

# --- Storefront theme ---
theme_name=""
theme_config=$(find "$PROJECT_DIR" -path "*/src/Resources/theme.json" 2>/dev/null | head -1)
if [ -n "$theme_config" ] && command -v python3 >/dev/null 2>&1; then
  theme_name=$(python3 -c "
import json
with open('$theme_config') as f:
  d = json.load(f)
print(d.get('name', ''))
" 2>/dev/null || echo "")
fi

# --- Storefront templates ---
twig_count=$(find "$PROJECT_DIR" -path "*/Resources/views/*.html.twig" 2>/dev/null | wc -l | tr -d ' ')

# --- Admin components (Vue) ---
admin_count=$(find "$PROJECT_DIR" -path "*/app/administration*" \( -name "*.js" -o -name "*.vue" \) 2>/dev/null | wc -l | tr -d ' ')

# --- Migrations ---
migration_count=$(find "$PROJECT_DIR" -path "*/Migration/Migration*.php" 2>/dev/null | wc -l | tr -d ' ')

# --- Entities ---
entity_count=$(find "$PROJECT_DIR" -name "*Definition.php" \
  -not -path "*/vendor/*" -not -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')

# --- Key services (Controllers + Subscribers) ---
controller_count=$(find "$PROJECT_DIR" -name "*Controller.php" \
  -not -path "*/vendor/*" -not -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')
subscriber_count=$(find "$PROJECT_DIR" -name "*Subscriber.php" \
  -not -path "*/vendor/*" -not -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')

# --- Build abstract ---
abstract="Shopware${sw_version:+ ${sw_version}}: ${plugin_count} plugins${theme_name:+ | theme: ${theme_name}} | ${twig_count} twig templates | ${entity_count} entities | ${controller_count} controllers"

# --- Write output ---
mkdir -p "$(dirname "$OUTPUT")"
cat > "$OUTPUT" << SW_EOF
---
abstract: "${abstract}"
---

# Shopware Project Context
${sw_version:+Version: ${sw_version}}
${theme_name:+Theme: ${theme_name}}

## Custom Plugins (${plugin_count})
${plugin_dirs:-none}

## Storefront
Twig templates: ${twig_count} | see src/Resources/views/ and custom/plugins/*/views/
${admin_count:+Admin components: ${admin_count} (JS/Vue)}

## Domain
Entities (Definitions): ${entity_count}
Migrations: ${migration_count}
Controllers: ${controller_count}
${subscriber_count:+Event subscribers: ${subscriber_count}}
SW_EOF

echo "✓ SHOPWARE.md written to $OUTPUT"
wc -l < "$OUTPUT" | xargs -I{} echo "  {} lines"
