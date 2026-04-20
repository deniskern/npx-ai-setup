<!-- bundle: shopify-liquid v1 -->
---
abstract: "Shopify Theme (Liquid 2.x) with optional Vite JS bundle. Shopify CLI 3.x, Dawn/Skeleton base."
---

# Stack

## Runtime & Distribution
- Shopify storefront (CDN-hosted), Shopify CLI 3.x for local dev
- Theme push/pull via `shopify theme push --development`

## Framework & Dependencies
- Liquid 2.x (Shopify flavour): objects, filters, tags
- JavaScript/TypeScript bundled via Vite (optional)
- Dawn or custom Skeleton as base theme
- Shopify Theme Check for linting

## Build & Tooling
- `shopify theme dev` → live reload local preview
- `shopify theme check` → liquid linting
- Vite (if present): `npm run build` → compiled assets into `assets/`
