# Context Bundles

Stack-specific starting points for `.agents/context/` files. Installed by `npx ai-setup` when a known stack is detected — zero LLM cost.

## How it works

1. `lib/detect-stack.sh` detects the stack profile (nuxt-storyblok, shopify-liquid, laravel, mcp-server, nextjs, n8n, default)
2. Bundle files are copied to `.agents/context/STACK.md`, `ARCHITECTURE.md`, `CONVENTIONS.md`
3. `lib/generate-summary.sh` creates `SUMMARY.md` from the bundle abstracts
4. LLM generation is skipped for known stacks

## Bundle structure

Each bundle has 3 files:
- `STACK.md` — runtime, deps, build tooling
- `ARCHITECTURE.md` — directory layout, entry points, data flow
- `CONVENTIONS.md` — naming, patterns, Definition of Done

Each file starts with `<!-- bundle: <profile> v1 -->`. Files without this marker are treated as manually edited and will not be overwritten on `--patch`.

## Profiles

| Profile | Trigger |
|---------|---------|
| `nuxt-storyblok` | `nuxt.config.*` + `@storyblok/nuxt` in package.json |
| `shopify-liquid` | ≥5 `.liquid` files in sections/ snippets/ templates/ |
| `laravel` | `artisan` file or `laravel/framework` in composer.json |
| `mcp-server` | `@modelcontextprotocol/sdk` in package.json |
| `nextjs` | `next.config.*` or `next` in package.json |
| `n8n` | `.n8n/` dir or `n8n` in package.json |
| `default` | Fallback — generic placeholders |

## Adding a custom profile

1. Create `templates/context-bundles/<profile>/` with `STACK.md`, `ARCHITECTURE.md`, `CONVENTIONS.md`
2. Add detection logic to `lib/detect-stack.sh` (before the `default` fallback)
3. Add entry to the profiles table above
