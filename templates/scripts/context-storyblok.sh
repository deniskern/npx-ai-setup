#!/bin/bash
# context-storyblok.sh — Storyblok project context scanner
# Generates .agents/context/STORYBLOK.md with zero LLM tokens.
# Run: bash .claude/scripts/context-storyblok.sh
# Triggered by: /context-refresh skill when @storyblok package is detected

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
OUTPUT="$PROJECT_DIR/.agents/context/STORYBLOK.md"

# --- Storyblok packages ---
sb_packages=""
if [ -f "$PROJECT_DIR/package.json" ] && command -v python3 >/dev/null 2>&1; then
  sb_packages=$(python3 -c "
import json
with open('$PROJECT_DIR/package.json') as f:
  d = json.load(f)
deps = {**d.get('dependencies', {}), **d.get('devDependencies', {})}
sb = [k for k in deps if '@storyblok' in k]
print(', '.join(sorted(sb)))
" 2>/dev/null || echo "")
fi

# --- Storyblok Vue components (app/storyblok/ or storyblok/) ---
SB_DIR="$PROJECT_DIR/app/storyblok"
[ -d "$PROJECT_DIR/storyblok" ] && SB_DIR="$PROJECT_DIR/storyblok"

sb_component_count=$(find "$SB_DIR" -name "*.vue" 2>/dev/null | wc -l | tr -d ' ')
sb_components=$(find "$SB_DIR" -name "*.vue" 2>/dev/null \
  | sed "s|$SB_DIR/||" | sed 's/\.vue$//' | sort | tr '\n' ',' | sed 's/,$//')

# --- .storyblok config dir ---
sb_config_files=$(find "$PROJECT_DIR/.storyblok" -maxdepth 1 -type f 2>/dev/null \
  | xargs -I{} basename {} | sort | tr '\n' ',' | sed 's/,$//')

# --- Component definitions JSON (Storyblok CLI export) ---
sb_def_file=$(find "$PROJECT_DIR" -maxdepth 2 -name "components.*.json" 2>/dev/null | head -1)
sb_def_count=0
if [ -n "$sb_def_file" ] && command -v python3 >/dev/null 2>&1; then
  sb_def_count=$(python3 -c "
import json
with open('$sb_def_file') as f:
  d = json.load(f)
comps = d.get('components', d) if isinstance(d, dict) else d
print(len(comps) if isinstance(comps, list) else len(comps.keys()))
" 2>/dev/null || echo 0)
fi

# --- Space ID from nuxt.config or .env ---
space_id=""
nuxt_config=$(find "$PROJECT_DIR" -maxdepth 1 -name "nuxt.config.*" 2>/dev/null | head -1)
if [ -n "$nuxt_config" ]; then
  space_id=$(grep -oE 'spaceId[: ]+[0-9]+' "$nuxt_config" 2>/dev/null | grep -oE '[0-9]+' | head -1 || echo "")
fi
if [ -z "$space_id" ] && [ -f "$PROJECT_DIR/.env" ]; then
  space_id=$(grep -E "STORYBLOK_SPACE_ID|SB_SPACE_ID" "$PROJECT_DIR/.env" 2>/dev/null | cut -d= -f2 | head -1 || echo "")
fi
if [ -z "$space_id" ] && [ -f "$PROJECT_DIR/.env.example" ]; then
  space_id=$(grep -E "STORYBLOK_SPACE_ID|SB_SPACE_ID" "$PROJECT_DIR/.env.example" 2>/dev/null | cut -d= -f2 | head -1 || echo "")
fi

# --- Build abstract ---
abstract="Storyblok: ${sb_component_count} Vue components${sb_def_count:+ | ${sb_def_count} schema components}${space_id:+ | space ${space_id}}${sb_packages:+ | ${sb_packages}}"

# --- Write output ---
mkdir -p "$(dirname "$OUTPUT")"
cat > "$OUTPUT" << SB_EOF
---
abstract: "${abstract}"
---

# Storyblok Context
${space_id:+Space ID: ${space_id}}
${sb_packages:+Packages: ${sb_packages}}

## Vue Components (${sb_component_count})
${sb_components:-none}
${sb_def_count:+
## Schema Components (Storyblok space)
${sb_def_count} components defined — see ${sb_def_file##*/}}
${sb_config_files:+
## .storyblok Config
${sb_config_files}}
SB_EOF

echo "✓ STORYBLOK.md written to $OUTPUT"
wc -l < "$OUTPUT" | xargs -I{} echo "  {} lines"
