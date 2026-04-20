# Spec: Stack-spezifische .claudeignore Templates

> **Spec ID**: 641 | **Created**: 2026-04-19 | **Status**: in-review | **Complexity**: small | **Branch**: —

## Goal
Pro Stack-Profil eine passende `.claudeignore` mitliefern, die Noise aus Build-Artefakten, Vendor-Verzeichnissen und Stack-spezifischen Generated-Files ausblendet. Senkt Token-Last bei Read/Grep/Glob in Zielprojekten.

## Context
Aktuell existiert eine `permissions.deny` Liste in `.claude/settings.json` für dist/.nuxt/.next etc. Das blockt nur Bash-Pfade, nicht aber LLM-Context-Injection via `@file` oder Repomix/Glob-Ergebnisse. `.claudeignore` (analog `.gitignore`) filtert auf Harness-Ebene Files bevor sie in Context kommen.

Stack-spezifische Noise-Quellen aus Repo-Scan:
- **Nuxt**: `.nuxt/`, `.output/`, `dist/`, `node_modules/`, `*.log`, Storyblok-Cache `storyblok-cli-*.json`
- **Shopify Themes**: `assets/*.js.map`, `assets/*.min.js`, `config/settings_data.json` (auto-generated vom Theme-Editor, riesig und ändert sich ständig), `locales/*.default.json` nur bei Bedarf, `.shopifyignore`
- **Laravel**: `vendor/`, `storage/logs/`, `storage/framework/cache/`, `bootstrap/cache/`, `public/build/`, `public/hot`
- **Next**: `.next/`, `out/`, `.vercel/`, `tsconfig.tsbuildinfo`
- **MCP-Server**: `.next/` (wenn Next-basiert), `skills-lock.json` (generated)
- **N8N**: `.n8n/`, node_modules, compiled workflows
- **Alle**: `*.log`, `.DS_Store`, `coverage/`, `.turbo/`

## Steps
- [x] Step 1: `templates/claudeignore/` Verzeichnis mit Stack-Profil-Files: `nuxt-storyblok.claudeignore`, `shopify-liquid.claudeignore`, `laravel.claudeignore`, `nextjs.claudeignore`, `mcp-server.claudeignore`, `n8n.claudeignore`, `base.claudeignore` (common für alle)
- [x] Step 2: `lib/install-claudeignore.sh` — merged `base.claudeignore` + `<profile>.claudeignore` in `.claudeignore` im Zielprojekt; dedupliziert Zeilen
- [x] Step 3: `ai-setup.sh` ruft Installer nach Stack-Detection auf, nutzt `stack_profile` aus Spec 638
- [x] Step 4: Idempotenz: existierende `.claudeignore` wird NICHT überschrieben — Vorschläge die fehlen werden unter Kommentar-Marker `# --- ai-setup managed ---` / `# --- end ai-setup ---` angehängt/aktualisiert, manuelle User-Zeilen außerhalb bleiben intakt
- [x] Step 5: `--patch` Flow re-syncs nur den managed-Block
- [x] Step 6: Prüfen ob `permissions.deny` in `.claude/settings.json` weiterhin nötig — wenn `.claudeignore` reicht (Claude Code liest `.claudeignore`) entweder konsolidieren oder beides parallel (Bash-Block vs. LLM-Read-Block) klar dokumentieren
- [x] Step 7: `doctor.sh` Check: warn wenn `.claudeignore` älter als passendes Template (mtime-Diff)
- [x] Step 8: Smoke-Test: ai-setup in sp-alpensattel + nuxt-onedot + crewbuddy, `.claudeignore` enthält jeweils die Stack-Patterns, aber nicht falsche (Nuxt-Patterns nicht in Laravel-Repo)

## Acceptance Criteria
- [x] `.claudeignore` in Shopify-Target enthält `config/settings_data.json`, `assets/*.js.map`
- [x] `.claudeignore` in Nuxt-Target enthält `.nuxt/`, `.output/`
- [x] `.claudeignore` in Laravel-Target enthält `vendor/`, `storage/logs/`
- [x] Manuell hinzugefügte Zeile außerhalb des managed-Blocks bleibt nach `ai-setup --patch` erhalten
- [x] Managed-Block kann bei Template-Update komplett ersetzt werden ohne User-Zeilen zu verlieren
- [x] `bash .claude/scripts/doctor.sh` erkennt veraltetes `.claudeignore` (mtime-based)
- [x] `shellcheck lib/install-claudeignore.sh` passt
- [x] `bash .claude/scripts/quality-gate.sh` grün

## Files to Modify
- `templates/claudeignore/base.claudeignore` — NEU
- `templates/claudeignore/nuxt-storyblok.claudeignore` — NEU
- `templates/claudeignore/shopify-liquid.claudeignore` — NEU
- `templates/claudeignore/laravel.claudeignore` — NEU
- `templates/claudeignore/nextjs.claudeignore` — NEU
- `templates/claudeignore/mcp-server.claudeignore` — NEU
- `templates/claudeignore/n8n.claudeignore` — NEU
- `lib/install-claudeignore.sh` — NEU
- `ai-setup.sh` — Install-Hook
- `.claude/scripts/doctor.sh` — mtime-Check
- `README.md` — Section "Claude Ignore Patterns"

## Out of Scope
- `.gitignore` Management (separates Tool)
- `.repomixignore` (existiert schon separat, nicht doppelt pflegen — ggf. späterer Spec: konsolidieren)
- Entfernen der existierenden `permissions.deny` — nur dokumentativ klären warum beides
- User-Prompt "welche Ignores willst du" — default sinnvolle Bundle anwenden, User darf danach editieren

## Dependencies
- Profitiert von Spec 638 (stack_profile) — Reihenfolge: 638 → (639 + 640 + 641 parallel)
