# Spec: Bundle-zu-path-scoped-Rules Refactor

> **Spec ID**: 647 | **Created**: 2026-04-25 | **Status**: draft | **Complexity**: medium | **Branch**: —

## Goal
Context-Bundles liefern zusätzlich stack-spezifische `.claude/rules/*.md` mit `paths:` YAML-Frontmatter — lazy-load via Claude Code path-scoped rule mechanism statt eager-import.

## Context
Anthropic-Doku (`code.claude.com/memory`): Rules mit `paths:` frontmatter laden nur wenn Claude an matching files arbeitet. Aktuell kopieren Bundles nur 3 generic Files (STACK/ARCH/CONV) nach `.agents/context/` — immer on-demand via @. Stack-spezifisches Wissen (Liquid-Patterns, Vue-Conventions, PHP-Idiome) hat keinen lazy-load Pfad. path-scoped rules lösen das: "Shopify-Liquid-rules" laden nur wenn Claude `.liquid` Files bearbeitet.

### Verified Assumptions
- Claude Code unterstützt `paths:` YAML-Frontmatter in `.claude/rules/*.md` — Evidence: `code.claude.com/memory` + `templates/claude/rules/testing.md` (hat YAML frontmatter) | Confidence: High | If Wrong: Feature nicht verfügbar, Spec hinfällig
- `build_template_map` skip `context-bundles/*` bereits (unser Fix) — Evidence: `lib/core.sh:35` | Confidence: High | If Wrong: Bundle-rules landen per TEMPLATE_MAP, nicht via Bundle-Install
- Bundle-Install-Loop in `bin/ai-setup.sh:222-252` kopiert Files direkt aus `$BUNDLE_DIR` — Evidence: `bin/ai-setup.sh:232` `cp "$BUNDLE_DIR/$_f" "$CONTEXT_DIR/$_f"` | Confidence: High | If Wrong: Anderer Install-Pfad nötig

## Stack Coverage
- **Profiles affected**: alle 6 (nuxt-storyblok, shopify-liquid, laravel, nextjs, nuxtjs, default)
- **Per-stack difference**: rules-Inhalt komplett verschieden (Liquid-Patterns ≠ Vue-Patterns ≠ PHP-Patterns). Install-Logik identisch für alle profiles.

## Steps
- [ ] Step 1: `templates/context-bundles/<profile>/rules/` Subdirs anlegen (6 profiles), je 2-3 rules-Files mit `paths:` frontmatter — nuxt-storyblok: `vue-components.md` (paths: app/**/*.vue), `composables.md` (paths: composables/*.ts), `storyblok.md` (paths: app/storyblok/**); shopify-liquid: `liquid.md` (paths: **/*.liquid), `theme-js.md` (paths: assets/*.{js,ts}); laravel: `blade.md` (paths: resources/views/**), `php.md` (paths: app/**/*.php); nextjs: `components.md` (paths: src/**/*.{tsx,jsx}), `api.md` (paths: pages/api/**); nuxtjs ähnlich; default: leer
- [ ] Step 2: `bin/ai-setup.sh` Bundle-Install-Loop erweitern: wenn `$BUNDLE_DIR/rules/` existiert → copy nach `.claude/rules/` (prefix `<profile>-` auf Filename um Konflikte zu vermeiden, z.B. `nuxt-storyblok-vue-components.md`)
- [ ] Step 3: `lib/update.sh:apply_template_updates` — bundle-rules-Files via `is_current_managed_target` schützbar machen: `.claude/rules/<profile>-*.md` als managed tracken
- [ ] Step 4: `lib/core.sh:write_metadata` — bundle-rules-Files in `.ai-setup.json` checksummen (analog zu STACK/ARCH/CONV bundle-files)
- [ ] Step 5: `lib/update.sh:cleanup_obsolete_managed_files` — bundle-rules-Files bei Profile-Wechsel aufräumen (alter Profile rules → obsolete)
- [ ] Step 6: `templates/context-bundles/README.md` updaten: Bundle-Struktur mit `rules/` Subdir dokumentieren
- [ ] Step 7: Smoke-Test in `tests/smoke.sh` ergänzen: check ob bundle-rules-Files mit `paths:` frontmatter valides YAML haben (`bash -c "grep -q 'paths:'" file`)
- [ ] Step 8: `templates/scripts/doctor.sh` + `.claude/scripts/doctor.sh` — check ob bundle-installed rules `paths:` frontmatter haben (WARN wenn nicht)

## Acceptance Criteria
- [ ] `npx ai-setup` in nuxt-storyblok-Projekt installiert `.claude/rules/nuxt-storyblok-vue-components.md` mit `paths: app/**/*.vue` frontmatter
- [ ] `npx ai-setup` in shopify-liquid-Projekt installiert `.claude/rules/shopify-liquid-liquid.md` mit `paths: **/*.liquid`
- [ ] Re-run `npx ai-setup` ist idempotent — rules-Files nicht doppelt
- [ ] Profil-Wechsel (nuxt-storyblok → default): alte rules werden als obsolete erkannt und entfernt
- [ ] `bash .claude/scripts/quality-gate.sh` grün
- [ ] `bash tests/smoke.sh` — neue smoke-checks für rules-frontmatter passen

## Files to Modify
- `templates/context-bundles/*/rules/*.md` — NEU (je Profile 2-3 Files)
- `bin/ai-setup.sh` — Bundle-Install-Loop für rules/ Subdir erweitern
- `lib/update.sh` — bundle-rules als managed tracken + cleanup bei Profile-Wechsel
- `lib/core.sh` — write_metadata checksummt bundle-rules-Files
- `templates/context-bundles/README.md` — Bundle-Struktur dokumentieren
- `tests/smoke.sh` — frontmatter-check für bundle-rules
- `templates/scripts/doctor.sh` + `.claude/scripts/doctor.sh` — doctor-check

## Out of Scope
- SUMMARY.md eager-import aus CLAUDE.md entfernen (eigene Spec)
- analyze-skill project-additions in STACK.md (eigene Spec)
- Neue Stack-Profiles hinzufügen (eigene Spec)
