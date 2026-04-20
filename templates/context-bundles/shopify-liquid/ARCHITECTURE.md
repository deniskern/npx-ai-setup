<!-- bundle: shopify-liquid v1 -->
---
abstract: "Shopify theme directory layout. Liquid objects flow from section schema to render; settings via settings_schema.json."
---

# Architecture

## Directory Structure
- `sections/` — top-level page sections (each has schema block)
- `snippets/` — reusable partials, no schema, included via `{% render %}`
- `templates/` — page type JSON templates (product, collection, page, etc.)
- `layout/` — `theme.liquid` wraps all pages; `checkout.liquid` for checkout
- `assets/` — JS, CSS, image files served from Shopify CDN
- `config/` — `settings_schema.json` (theme editor), `settings_data.json`
- `locales/` — translation JSON files

## Data Flow
1. Liquid objects (`product`, `cart`, `customer`, `shop`) injected by Shopify
2. Section schema defines blocks and settings → accessible via `section.settings`
3. `{% render 'snippet-name', param: value %}` passes data to snippets
4. JS in `assets/` loaded via `{{ 'main.js' | asset_url | script_tag }}`

## Key Patterns
- Theme settings: read via `settings.color_accent` (from settings_data.json)
- Metafields: `product.metafields.custom.field_name`
- Sections everywhere: JSON template references section handles

## Liquid Dependency Graph

`.agents/context/liquid-graph.json` maps render/include/section/schema-block edges across all Liquid files.
Build: `bash lib/build-liquid-graph.sh $PWD` — writes `.agents/context/liquid-graph.json` (<2s).
Refresh: `bash .claude/scripts/liquid-graph-refresh.sh` — no-op if graph is up to date.

```bash
# Top rendered snippets
jq -r '.stats.top_rendered_snippets[] | "\(.count)x \(.file)"' .agents/context/liquid-graph.json | head -10

# Who renders snippets/product-card.liquid?
jq -r --arg s "snippets/product-card.liquid" '.edges[] | select(.target==$s) | .source' .agents/context/liquid-graph.json

# Orphan snippets (unreferenced)
jq -r '.stats.orphans[]' .agents/context/liquid-graph.json
```
