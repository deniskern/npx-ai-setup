<!-- bundle: nextjs v1 -->
---
abstract: "Next.js App Router: app/ with page.tsx, layout.tsx, Server/Client Component boundary. Fetch in server, SWR in client."
---

# Architecture

## Directory Structure
- `app/` — App Router root: `page.tsx`, `layout.tsx`, `loading.tsx`, `error.tsx`
- `app/api/` — Route Handlers (replaces `pages/api/`)
- `components/` — shared UI; prefix with `"use client"` only when needed
- `lib/` — server utilities, DB clients, helpers (never imported by client components)
- `public/` — static assets served from root

## Server vs Client Components
- Default: Server Component (no interactivity, direct DB/API access)
- Add `"use client"` only for: hooks, event handlers, browser APIs
- Boundary: pass serializable props from Server → Client; never pass functions

## Data Fetching
- Server Components: `fetch()` with `{ cache: 'force-cache' }` or `{ next: { revalidate } }`
- Client Components: SWR or React Query for mutations and real-time
- Mutations: Server Actions (`"use server"`) or Route Handlers

## Key Patterns
- Parallel routes: `@slot/page.tsx` for modal-like layouts
- Intercepting routes: `(.)path` for in-context previews
- Metadata: export `metadata` or `generateMetadata()` from page files
