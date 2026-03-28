#!/bin/bash
# context-nuxt.sh — Nuxt project context scanner
# Generates .agents/context/NUXT.md with zero LLM tokens.
# Run: bash .claude/scripts/context-nuxt.sh
# Triggered by: /context-refresh skill when nuxt.config.* is detected

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
OUTPUT="$PROJECT_DIR/.agents/context/NUXT.md"

# Support both classic (pages/) and Nuxt app/ directory structure
PAGES_DIR="$PROJECT_DIR/pages"
[ -d "$PROJECT_DIR/app/pages" ] && PAGES_DIR="$PROJECT_DIR/app/pages"
COMPONENTS_DIR="$PROJECT_DIR/components"
[ -d "$PROJECT_DIR/app/components" ] && COMPONENTS_DIR="$PROJECT_DIR/app/components"
COMPOSABLES_DIR="$PROJECT_DIR/composables"
[ -d "$PROJECT_DIR/app/composables" ] && COMPOSABLES_DIR="$PROJECT_DIR/app/composables"
LAYOUTS_DIR="$PROJECT_DIR/layouts"
[ -d "$PROJECT_DIR/app/layouts" ] && LAYOUTS_DIR="$PROJECT_DIR/app/layouts"
STORYBLOK_DIR="$PROJECT_DIR/app/storyblok"
[ -d "$PROJECT_DIR/storyblok" ] && STORYBLOK_DIR="$PROJECT_DIR/storyblok"

# --- Pages ---
page_count=$(find "$PAGES_DIR" -name "*.vue" 2>/dev/null | wc -l | tr -d ' ')
pages=$(find "$PAGES_DIR" -name "*.vue" 2>/dev/null \
  | sed "s|$PAGES_DIR/||" | sed 's/\.vue$//' | sort | tr '\n' ',' | sed 's/,$//')

# --- Components ---
component_count=$(find "$COMPONENTS_DIR" -name "*.vue" 2>/dev/null | wc -l | tr -d ' ')
component_dirs=$(find "$COMPONENTS_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null \
  | xargs -I{} basename {} | sort | tr '\n' ',' | sed 's/,$//')

# --- Composables ---
composables=$(find "$COMPOSABLES_DIR" \( -name "use*.ts" -o -name "use*.js" \) 2>/dev/null \
  | xargs -I{} basename {} | sed 's/\.\(ts\|js\)$//' | sort | tr '\n' ',' | sed 's/,$//')

# --- Stores ---
stores=""
for store_dir in "$PROJECT_DIR/stores" "$PROJECT_DIR/app/stores"; do
  [ -d "$store_dir" ] && stores=$(find "$store_dir" \( -name "*.ts" -o -name "*.js" \) 2>/dev/null \
    | xargs -I{} basename {} | sed 's/\.\(ts\|js\)$//' | sort | tr '\n' ',' | sed 's/,$//')
done

# --- Layouts ---
layouts=$(find "$LAYOUTS_DIR" -name "*.vue" 2>/dev/null \
  | xargs -I{} basename {} .vue | sort | tr '\n' ',' | sed 's/,$//')

# --- Middleware ---
middleware=""
for mw_dir in "$PROJECT_DIR/middleware" "$PROJECT_DIR/app/middleware"; do
  [ -d "$mw_dir" ] && middleware=$(find "$mw_dir" \( -name "*.ts" -o -name "*.js" \) 2>/dev/null \
    | xargs -I{} basename {} | sed 's/\.\(ts\|js\)$//' | sort | tr '\n' ',' | sed 's/,$//')
done

# --- Server routes ---
server_routes=$(find "$PROJECT_DIR/server/api" \( -name "*.ts" -o -name "*.js" \) 2>/dev/null \
  | sed "s|$PROJECT_DIR/server/api/||" | sed 's/\.\(ts\|js\)$//' | sort | tr '\n' ',' | sed 's/,$//')

# --- Storyblok components ---
storyblok_count=$(find "$STORYBLOK_DIR" -name "*.vue" 2>/dev/null | wc -l | tr -d ' ')

# --- Nuxt modules (from nuxt.config) ---
nuxt_modules=""
nuxt_config=$(find "$PROJECT_DIR" -maxdepth 1 -name "nuxt.config.*" 2>/dev/null | head -1)
if [ -n "$nuxt_config" ]; then
  nuxt_modules=$(grep -oE "'@[^']+'" "$nuxt_config" 2>/dev/null \
    | tr -d "'" | sort -u | tr '\n' ',' | sed 's/,$//' || echo "")
fi

# --- Build abstract ---
store_count=$(echo "$stores" | tr ',' '\n' | grep -c . 2>/dev/null || echo 0)
abstract="Nuxt: ${page_count} pages | ${component_count} components${component_dirs:+ (${component_dirs})}${store_count:+ | ${store_count} stores}${storyblok_count:+ | ${storyblok_count} storyblok components}${server_routes:+ | server/api}"

# --- Write output ---
mkdir -p "$(dirname "$OUTPUT")"
cat > "$OUTPUT" << NUXT_EOF
---
abstract: "${abstract}"
---

# Nuxt Project Context

## Pages (${page_count})
${pages:-none}

## Components (${component_count})
${component_dirs:+Dirs: ${component_dirs}}
${composables:+
## Composables
${composables}}
${stores:+
## Stores (Pinia)
${stores}}
${layouts:+
## Layouts
${layouts}}
${middleware:+
## Middleware
${middleware}}
${server_routes:+
## Server API Routes
${server_routes}}
${storyblok_count:+
## Storyblok Components (${storyblok_count})
See ${STORYBLOK_DIR##*/}/ — use /context-load for details}
${nuxt_modules:+
## Key Nuxt Modules
${nuxt_modules}}
NUXT_EOF

echo "✓ NUXT.md written to $OUTPUT"
wc -l < "$OUTPUT" | xargs -I{} echo "  {} lines"
