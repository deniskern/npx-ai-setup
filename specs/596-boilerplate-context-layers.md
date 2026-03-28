# Spec: System-Aware Kontext via Bash-Scanner

> **Spec ID**: 596 | **Created**: 2026-03-28 | **Status**: draft | **Complexity**: medium | **Branch**: spec/596-boilerplate-context-layers

## Goal

Bash-Skripte generieren system-spezifische Kontext-Dateien (z.B. `SHOPIFY.md`) mit zero LLM-Tokens — `context-loader.sh` lädt sie automatisch als L0-Abstract im SessionStart.

## Context

Aktuell ist der Kontext zu generisch — Claude muss bei jeder Session erst `ls sections/` laufen. Bash-Scanner (< 100ms, zero Tokens) extrahieren projektspezifische Fakten direkt aus dem Dateisystem und schreiben eine kompakte Kontext-Datei mit Frontmatter. `context-loader.sh` wird von hardcoded 3 Dateien auf Glob umgestellt, sodass neue System-Dateien ohne Setup-Änderung geladen werden. Haiku-Validierung ist optional.

### Verified Assumptions
- `context-loader.sh:12` iteriert hardcoded — Glob auf `*.md` ist drop-in-replace | Evidence: `.claude/hooks/context-loader.sh:12` | Confidence: High | If Wrong: SessionStart-Output bricht
- `install_claude_scripts()` deployt alles aus `templates/scripts/` nach `.claude/scripts/` | Evidence: `lib/setup.sh:536` | Confidence: High | If Wrong: Scripts landen nicht im Projekt
- Shopify-Projekt hat `sections/`, `snippets/`, `blocks/` | Evidence: sp-alpensattel-next | Confidence: High | If Wrong: Script schreibt leere Listen, SHOPIFY.md trotzdem valide

## Steps

- [ ] Step 1: `templates/scripts/context-shopify.sh` — Bash-Scanner: sections (non-gp Namen), blocks (Namen), alp-* snippets (Namen), templates (product/page/article custom + gp-count), layout-Varianten, src/js/components (Namen), locales, settings_schema summary → schreibt `.agents/context/SHOPIFY.md` mit Frontmatter
- [ ] Step 2: `templates/scripts/context-nuxt.sh` — Stub: pages/, composables/, stores/ → schreibt `.agents/context/NUXT.md`
- [ ] Step 3: `context-loader.sh` — `for f in STACK.md ...` ersetzen durch Glob `"$CONTEXT_DIR"/*.md` (sort, skip .state)
- [ ] Step 4: `templates/claude/hooks/context-loader.sh` — gleiche Änderung
- [ ] Step 5: `context-refresh/SKILL.md` — nach base refresher: System erkennen (`theme.liquid` → shopify, `nuxt.config.*` → nuxt), passendes Script ausführen wenn vorhanden
- [ ] Step 6: `templates/skills/context-refresh/SKILL.md` — gleiche Änderung
- [ ] Step 7: In `sp-alpensattel-next` testen: Script direkt ausführen, `SHOPIFY.md` prüfen, SessionStart-Output validieren

## Acceptance Criteria

### Truths
- [ ] `bash .claude/scripts/context-shopify.sh` in Shopify-Projekt schreibt `SHOPIFY.md` in < 1s ohne LLM-Aufruf
- [ ] SessionStart in Shopify-Projekt zeigt 4 Abstracts (STACK + ARCH + CONV + SHOPIFY)
- [ ] Abstract enthält Section-Count, GP-Count, Custom-Template-Count — präzise Zahlen + Hinweis auf GP-* Tabu
- [ ] In Nicht-Shopify-Projekt läuft `context-loader.sh` ohne Fehler (3 Abstracts)

### Artifacts
- [ ] `templates/scripts/context-shopify.sh` — ausführbar, ≤ 60 Zeilen
- [ ] `.agents/context/SHOPIFY.md` — ≤ 80 Zeilen, valides Frontmatter-Abstract

## Files to Modify
- `templates/scripts/context-shopify.sh` — neu
- `templates/scripts/context-nuxt.sh` — neu (stub)
- `.claude/hooks/context-loader.sh` — Glob
- `templates/claude/hooks/context-loader.sh` — Glob
- `.claude/skills/context-refresh/SKILL.md` — System-Detection
- `templates/skills/context-refresh/SKILL.md` — System-Detection

## Out of Scope
- Haiku-Validierung (eigene Spec wenn Bedarf entsteht)
- Storyblok / Shopware Scanner (separate Specs in jeweiligen Boilerplate-Repos)
- `context-freshness.sh` kennt neue Dateien nicht — GIT_HASH reicht als Trigger
