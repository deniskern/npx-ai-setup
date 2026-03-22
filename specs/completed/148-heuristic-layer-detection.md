# Spec 148: Heuristische Layer-Erkennung fuer ARCHITECTURE.md

> **Status**: completed
> **Source**: specs/145-evaluate-understand-anything.md (Kandidat #8)
> **Goal**: Automatische Architektur-Layer-Erkennung via Directory-Patterns in context-refresher einbauen
> **Depends on**: None. **Must run before**: Spec 149 (both modify context-refresher.md)

## Context

Understand-Anything erkennt Architektur-Layer zweistufig: erst heuristische Pattern-Erkennung (12 Kategorien), dann LLM-Verfeinerung. Aktuell generiert unser context-refresher ARCHITECTURE.md rein LLM-basiert ohne systematische Vorab-Analyse der Directory-Struktur und Import-Patterns.

## Steps

- [x] 1. Read `.claude/agents/context-refresher.md` and template version to understand current ARCHITECTURE.md generation
- [x] 2. Define 12 heuristic directory-pattern categories: API (routes/, api/, endpoints/), Service (services/, providers/), Data (models/, entities/, db/, prisma/), UI (components/, pages/, views/, layouts/), Middleware (middleware/), Utility (utils/, helpers/, lib/), Config (config/, .env*), Test (test/, __tests__, *.test.*, *.spec.*), Types (types/, interfaces/), Hooks (hooks/, composables/), State (store/, stores/, state/), Assets (assets/, public/, static/)
- [x] 3. Add pre-processing step to context-refresher: scan directory structure, classify files into layers, compute file counts per layer
- [x] 4. Pass heuristic layer classification as structured input to LLM step for ARCHITECTURE.md generation
- [x] 5. LLM refines/adjusts layers based on actual code content (may merge or split heuristic layers)
- [x] 6. Mirror changes to template version
- [x] 7. Test: run context-refresher on npx-ai-setup — layer detection script works, detects lib/ (Utility), tests/ (Test), lib/migrations/ (Data) and verify ARCHITECTURE.md includes layer information

## Acceptance Criteria

- Directory patterns correctly classify common project structures (Next.js, Nuxt, Express, Django)
- Heuristic results passed to LLM as structured context, not replacing LLM judgment
- ARCHITECTURE.md includes a "Layers" section with file counts and descriptions
- Non-standard directory structures: if no patterns match, "Layers" section is omitted (not empty/broken)
- context-refresher max_turns remains sufficient (verify during implementation, raise if needed)

## Files to Modify

- `.claude/agents/context-refresher.md`
- `templates/agents/context-refresher.md`
