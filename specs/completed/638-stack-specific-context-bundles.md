# Spec: Stack-spezifische Context-Bundles

> **Spec ID**: 638 | **Created**: 2026-04-19 | **Status**: completed | **Complexity**: medium | **Branch**: spec/638-stack-specific-context-bundles

## Goal
Templates um stack-spezifische Context-Bundles erweitern (Nuxt+Storyblok, Shopify Liquid, Laravel, MCP-Server). Zielprojekte bekommen beim `npx ai-setup` sofort passenden `STACK.md`/`ARCHITECTURE.md`/`CONVENTIONS.md` statt generischer Platzhalter — spart LLM-Roundtrip für Context-Generation und liefert bewährte Patterns.

## Context
Aktueller Flow: Skills werden aus Boilerplates geholt, Context-Files (`.agents/context/*.md`) werden zur Laufzeit per LLM-Call generiert. Das ist teuer + inkonsistent. Bei den ~70 internen Projekten wiederholen sich Stack-Patterns:
- Nuxt+Storyblok (10+ Repos: nuxt-onedot, sb-nuxt-*, nuxt-crew_buddy_*) — gleiche Verzeichnisstruktur, gleiche Storyblok-Bridge, Tailwind
- Shopify Themes (10+ sp-* Repos) — Liquid + Vite + TS-bundle, sections/snippets/templates
- Laravel/PHP (crewbuddy, laravel-overhub) — gleiche Directory-Layouts
- MCP-Server (mcp-*) — Node/TS, Tool-Registry-Pattern

Ein vorgefertigtes Bundle als Starting-Point spart je Projekt ~2-3k Tokens beim Initial-Generate und liefert direkt brauchbare Conventions statt generischer "describe your stack".

## Steps
- [x] Step 1: Verzeichnis `templates/context-bundles/` anlegen mit Subfoldern je Stack-Profil: `nuxt-storyblok/`, `shopify-liquid/`, `laravel/`, `mcp-server/`, `nextjs/`, `n8n/`, `default/`
- [x] Step 2: Je Bundle 3 Dateien: `STACK.md` (runtime, deps, build), `ARCHITECTURE.md` (entry points, data flow, folders), `CONVENTIONS.md` (naming, patterns, anti-patterns). Inhalte aus Pattern-Analyse der bestehenden ~70 Repos extrahiert (nuxt-onedot, sp-alpensattel, crewbuddy als Referenzen)
- [x] Step 3: `SUMMARY.md` Generator-Skript `lib/generate-summary.sh` — merged Bundle-Snippets in eine tiered-loading `SUMMARY.md`
- [x] Step 4: `lib/detect-stack.sh` neu erstellt mit `stack_profile` Output — 7 Profile, POSIX-kompatibel, nur grep/find
- [x] Step 5: `ai-setup.sh` Context-Install-Phase: wenn `stack_profile != default` → Bundle kopieren statt LLM-Call; sonst Fallback auf bestehenden LLM-Generator
- [x] Step 6: Bundle-Update via `--patch`: Dateien ohne bundle-Marker → `.new`-Suffix, kein silent-Overwrite
- [x] Step 7: `lib/generate.sh` CONTEXT_PROMPT erweitert: respektiert `<!-- bundle: -->` Marker, überschreibt markierte Dateien nicht
- [x] Step 8: Smoke-Test: detect-stack.sh in nuxt-onedot → nuxt-storyblok ✓, sp-alpensattel → shopify-liquid ✓, crewbuddy/crew_buddy → laravel ✓; Bundle-Inhalte enthalten "Storyblok" und "Nuxt"
- [x] Step 9: Dokumentation in `README.md` (Section "Context Bundles") + `templates/context-bundles/README.md`

## Acceptance Criteria
- [ ] `bash lib/detect-stack.sh` in `nuxt-onedot` gibt `stack_profile=nuxt-storyblok` aus
- [ ] `bash lib/detect-stack.sh` in `sp-alpensattel` gibt `stack_profile=shopify-liquid` aus
- [ ] `bash lib/detect-stack.sh` in `crewbuddy` gibt `stack_profile=laravel` aus
- [ ] Nach `ai-setup` in einem Nuxt+Storyblok Target enthält `.agents/context/STACK.md` die Strings `Storyblok` und `Nuxt` ohne LLM-Call-Trace im Log
- [ ] `ai-setup --patch` überschreibt manuell editiertes `CONVENTIONS.md` NICHT ohne User-Confirmation
- [ ] `shellcheck lib/detect-stack.sh lib/generate-summary.sh` passt
- [ ] `bash .claude/scripts/quality-gate.sh` grün

## Files to Modify
- `lib/detect-stack.sh` — `stack_profile` Logik
- `lib/generate-summary.sh` — NEU
- `ai-setup.sh` — Context-Install-Phase routet auf Bundle vs. LLM
- `templates/context-bundles/nuxt-storyblok/{STACK,ARCHITECTURE,CONVENTIONS}.md` — NEU
- `templates/context-bundles/shopify-liquid/{STACK,ARCHITECTURE,CONVENTIONS}.md` — NEU
- `templates/context-bundles/laravel/{STACK,ARCHITECTURE,CONVENTIONS}.md` — NEU
- `templates/context-bundles/mcp-server/{STACK,ARCHITECTURE,CONVENTIONS}.md` — NEU
- `templates/context-bundles/nextjs/{STACK,ARCHITECTURE,CONVENTIONS}.md` — NEU
- `templates/context-bundles/n8n/{STACK,ARCHITECTURE,CONVENTIONS}.md` — NEU
- `templates/context-bundles/default/{STACK,ARCHITECTURE,CONVENTIONS}.md` — Fallback
- `templates/context-bundles/README.md` — Bundle-Format-Doku
- `.claude/agents/context-refresher.md` — Bundle-aware Merge
- `README.md` — Section "Context Bundles"

## Out of Scope
- Storyblok-Component-spezifische Generation (das macht MCP im Zielprojekt, nicht Setup)
- Auto-Update von Bundles via Remote-Fetch (Bundles sind Repo-bundled, versionieren via git tag)
- Sprach-Bundles (i18n der Context-Files) — alles Englisch, konsistent mit bestehendem Repo
