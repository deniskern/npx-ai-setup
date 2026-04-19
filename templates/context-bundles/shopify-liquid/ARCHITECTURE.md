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
