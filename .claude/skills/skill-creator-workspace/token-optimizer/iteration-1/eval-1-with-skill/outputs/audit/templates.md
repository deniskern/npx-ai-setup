# Template Quality Audit

## Installations-Footprint (was Nutzer nach Installation laden)

| Komponente | Größe | ~Tokens/Nachricht |
|------------|-------|-------------------|
| CLAUDE.md Template | 123 Zeilen | ~1,845 |
| Rules (9 unscoped, immer geladen) | 238 Zeilen | ~3,570 |
| Rules (testing.md, scoped) | 37 Zeilen | — |
| Skills-Menü (26 Skills) | 26 Skills | ~4,340 |

**Gesamt: ~9,755 Tokens/Nachricht für Nutzer**

Hinweis: Skills werden in ~/.claude/skills/ installiert und erscheinen im globalen Menü.
Das bedeutet: ALLE 26 Skills laden bei JEDEM Projekt, nicht nur bei npx-ai-setup Projekten.

## Kritische Probleme

| Problem | Impact | Fix |
|---------|--------|-----|
| 11 von 21 Skills haben Descriptions >200 Zeichen | ~1,100 Tokens Overhead im Menü | Kürzen auf ≤200 Zeichen |
| 5 Skills ohne SKILL.md (drizzle, pinia, tailwind, tanstack, vitest) | Unklar ob/wie geladen | Prüfen und dokumentieren oder entfernen |
| 9 von 10 Rules ohne paths: Frontmatter | ~3,570 Tokens immer geladen | paths: hinzufügen wo sinnvoll |
| Shopify/Shopware Skills für alle Nutzer (11 Skills) | ~2,200 Tokens Overhead für Non-Shopify Nutzer | Optional installieren |
| typescript.md Rule immer geladen (kein paths: scope) | ~600 Tokens für Projekte ohne TypeScript | paths: ["**/*.ts","**/*.tsx"] |

## Verbose Skill Descriptions (>200 Zeichen)

| Skill | Länge | ~Tokens | Vorschlag |
|-------|-------|---------|-----------|
| release | 616 | 154 | "Release & Changelog — Version bumping, CHANGELOG generation, tagging." (~60 chars) |
| explore | 600 | 150 | "Read-only thinking partner for exploring options, tradeoffs, and design decisions before committing." (~100 chars) |
| context-load | 581 | 145 | "Load tiered project context (STACK.md, ARCHITECTURE.md, CONVENTIONS.md) on demand." (~82 chars) |
| spec-board | 520 | 130 | "Manage spec backlog — list, prioritize, and pick next spec to work on." (~70 chars) |
| spec-work-all | 513 | 128 | "Work all pending specs sequentially to completion." (~50 chars) |
| spec-create | 497 | 124 | "Create a structured spec (plan) for a feature or task before implementation." (~76 chars) |
| spec-validate | 469 | 117 | "Validate a spec for completeness and clarity before implementation begins." (~73 chars) |
| spec-review | 457 | 114 | "Review a spec and provide feedback on scope, risks, and missing details." (~71 chars) |
| spec-work | 444 | 111 | "Implement the next pending spec step-by-step." (~46 chars) |
| orchestrate | 241 | 60 | "Coordinate parallel subagent tasks for complex multi-file work." (~63 chars) |
| shopify-new-block | 207 | 52 | "Scaffold a new Shopify theme block with schema and Liquid." (~57 chars) |

**Einsparpotenzial durch Kürzen: ~1,100 Tokens/Nachricht für alle Nutzer**

## Nicht-gescopte Rules

| Datei | Lines | paths: vorhanden? | Problem |
|-------|-------|-------------------|---------|
| agents.md | 35 | Nein | Immer geladen, auch ohne Subagenten |
| code-review-reception.md | 28 | Nein | Nur relevant beim Code-Review |
| general.md | 38 | Nein | Allgemein — OK, immer laden |
| git.md | 23 | Nein | OK, immer laden |
| quality-general.md | 18 | Nein | OK, immer laden |
| quality-maintainability.md | 20 | Nein | OK, immer laden |
| quality-performance.md | 19 | Nein | OK, immer laden |
| quality-security.md | 17 | Nein | OK, immer laden |
| testing.md | 37 | JA | Korrekt gescoped |
| typescript.md | 40 | Nein | Sollte auf *.ts/*.tsx gescoped werden |

**Kandidaten für paths: Scope:** code-review-reception.md, typescript.md, agents.md

## Geschätzte Nutzer-Einsparung wenn behoben: ~3,000 Tokens/Nachricht

- Skill Descriptions kürzen: ~1,100 Tokens
- Shopify-Skills optional (11 Skills): ~2,200 Tokens (für Non-Shopify Nutzer)
- typescript.md scopen: ~600 Tokens (für Non-TS Projekte)
- code-review-reception.md scopen: ~420 Tokens
