#!/bin/bash
# context-shopify.sh — Shopify theme context scanner
# Generates .agents/context/SHOPIFY.md with zero LLM tokens.
# Run: bash .claude/scripts/context-shopify.sh
# Triggered by: /context-refresh skill when theme.liquid is detected

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
OUTPUT="$PROJECT_DIR/.agents/context/SHOPIFY.md"

# --- Sections ---
sections=$(find "$PROJECT_DIR/sections" -maxdepth 1 -name "*.liquid" 2>/dev/null \
  | xargs -I{} basename {} .liquid | grep -v "^gp-" | sort | tr '\n' ',' | sed 's/,$//')
section_count=$(echo "$sections" | tr ',' '\n' | grep -c . 2>/dev/null || echo 0)
gp_section_count=$(find "$PROJECT_DIR/sections" -maxdepth 1 -name "gp-*.liquid" 2>/dev/null | wc -l | tr -d ' ')

# --- Blocks ---
blocks=$(find "$PROJECT_DIR/blocks" -maxdepth 1 -name "*.liquid" 2>/dev/null \
  | xargs -I{} basename {} .liquid | sort | tr '\n' ',' | sed 's/,$//')
block_count=$(echo "$blocks" | tr ',' '\n' | grep -c . 2>/dev/null || echo 0)

# --- Snippets ---
alp_snippets=$(find "$PROJECT_DIR/snippets" -maxdepth 1 -name "alp-*.liquid" 2>/dev/null \
  | xargs -I{} basename {} .liquid | sort | tr '\n' ',' | sed 's/,$//')
alp_count=$(echo "$alp_snippets" | tr ',' '\n' | grep -c . 2>/dev/null || echo 0)

# --- Templates (categorized) ---
_tpl_names() {
  find "$PROJECT_DIR/templates" -maxdepth 1 -name "$1" 2>/dev/null \
    | xargs -I{} basename {} | sed 's/\.json$//' | grep -v "^gp-\|\.gem-\|\.gp-template" | sort
}
standard_tpls=$(for t in 404 article blog cart collection gift_card index page product search; do
  [ -f "$PROJECT_DIR/templates/${t}.json" ] || [ -f "$PROJECT_DIR/templates/${t}.liquid" ] && echo -n "$t," || true
done | sed 's/,$//')

custom_article=$(_tpl_names "article.*.json" | grep -v "^article$" | tr '\n' ',' | sed 's/,$//')
custom_page=$(_tpl_names "page.*.json" | grep -v "^page$" | tr '\n' ',' | sed 's/,$//')
custom_product=$(_tpl_names "product.*.json" | grep -v "^product$" | tr '\n' ',' | sed 's/,$//')
gp_tpl_count=$(find "$PROJECT_DIR/templates" -maxdepth 1 \( -name "*.gp-template*" -o -name "gp-template*" -o -name "*.gem-*" \) 2>/dev/null | wc -l | tr -d ' ')

# --- Layout ---
layouts=$(find "$PROJECT_DIR/layout" -maxdepth 1 -name "*.liquid" 2>/dev/null \
  | xargs -I{} basename {} .liquid | sort | tr '\n' ',' | sed 's/,$//')

# --- JS Components ---
js_components=$(find "$PROJECT_DIR/src/js/components" -maxdepth 1 -name "*.js" 2>/dev/null \
  | xargs -I{} basename {} .js | sort | tr '\n' ',' | sed 's/,$//')

# --- Locales ---
locales=$(find "$PROJECT_DIR/locales" -maxdepth 1 -name "*.json" 2>/dev/null \
  | xargs -I{} basename {} .json | sed 's/\.default$//' | sort | tr '\n' ',' | sed 's/,$//')

# --- Settings schema ---
settings_groups=""
if [ -f "$PROJECT_DIR/config/settings_schema.json" ] && command -v python3 >/dev/null 2>&1; then
  settings_groups=$(python3 -c "
import json, sys
with open('$PROJECT_DIR/config/settings_schema.json') as f:
  data = json.load(f)
groups = [s.get('name','') for s in data if isinstance(s, dict) and 'settings' in s and s.get('name')]
print(', '.join(groups))
" 2>/dev/null || echo "")
fi

# --- Store URL ---
store=$(find "$PROJECT_DIR/.shopify" -name "*.json" 2>/dev/null \
  | xargs grep -h "myshopify" 2>/dev/null \
  | grep -o '[a-z0-9-]*\.myshopify\.com' | head -1 || echo "")

# --- Build abstract ---
abstract="Shopify: ${section_count} sections | ${block_count} blocks | ${alp_count} alp-* snippets | GP-*: ${gp_section_count} sections + ${gp_tpl_count} templates — NEVER TOUCH"

# --- Write output ---
mkdir -p "$(dirname "$OUTPUT")"
cat > "$OUTPUT" << SHOPIFY_EOF
---
abstract: "${abstract}"
---

# Shopify Theme Context
${store:+Store: $store}

## Sections — editable (${section_count})
${sections}

## GP-* Sections (${gp_section_count} files — NEVER MODIFY)
GemPages generated. Pattern: sections/gp-*.liquid

## Blocks (${block_count})
${blocks}

## Custom Snippets alp-* (${alp_count})
${alp_snippets}

## Templates
Standard: ${standard_tpls}
$([ -n "$custom_article" ] && echo "Custom article: ${custom_article}" || true)
$([ -n "$custom_page" ] && echo "Custom page: ${custom_page}" || true)
$([ -n "$custom_product" ] && echo "Custom product: ${custom_product}" || true)
GP/GemPages templates (${gp_tpl_count}): NEVER TOUCH — pattern: *.gp-template* / *.gem-*

## Layout
${layouts}

## JS Components (src/js/components/)
${js_components}

## Locales
${locales}
${settings_groups:+
## Theme Settings Groups
${settings_groups}}
SHOPIFY_EOF

echo "✓ SHOPIFY.md written to $OUTPUT"
wc -l < "$OUTPUT" | xargs -I{} echo "  {} lines"
