<!-- bundle: shopify-liquid v1 -->
---
abstract: "Shopify Liquid conventions: snake_case vars, kebab-case filenames, no inline JS, render over include."
---

# Conventions

## Naming
- Liquid variables: `snake_case` (`product_title`, `cart_item_count`)
- Section/snippet filenames: `kebab-case` (`product-card.liquid`, `cart-drawer.liquid`)
- Asset filenames: `kebab-case` (`main-cart.js`, `product-form.css`)
- Schema settings IDs: `snake_case` to match Liquid access pattern

## Liquid Patterns
- Use `{% render 'snippet' %}` — never `{% include %}` (deprecated)
- No inline `<script>` in liquid files — all JS belongs in `assets/`
- Access section settings via `section.settings.field_name`
- Escape output: `{{ var | escape }}` for user-generated content

## JavaScript
- Vanilla JS preferred; no jQuery dependency
- Custom elements or module pattern (`export default class ...`)
- Load via `{{ 'main.js' | asset_url | script_tag }}` in layout

## Definition of Done
- [ ] `shopify theme check` passes (no errors or warnings)
- [ ] No Liquid syntax errors in preview
- [ ] Tested on Dawn base theme or project base
- [ ] Settings schema has labels and defaults for all new fields
