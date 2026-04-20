# Spec: Curated Standard MCPs

> **Spec ID**: 640 | **Created**: 2026-04-19 | **Status**: in-review | **Complexity**: small | **Branch**: —

## Goal
Kuratiertes, kleines Set an Standard-MCP-Servern automatisch in Zielprojekt-`.mcp.json` vorschlagen: `context7` global (Library-Docs), `@shopify/dev-mcp` nur bei Shopify-Stack. User kann per Prompt opt-out. Kein Slug-Raten, keine Auth-Magie.

## Context
Ersatz für den aus Scope genommenen mcp-platform Auto-Suggest (siehe Brainstorm `specs/brainstorms/640b-mcp-platform-discovery.md` — deferred bis Platform einen `/api/projects` Discovery-Endpoint exposed).

Beobachtung: in ~70 Repos wiederholt sich "Claude muss Library-Docs nachschlagen" → `context7` wäre überall nützlich, ist aber nur auf Dev-Machines global installiert. Neue Team-Devs bekommen es nicht automatisch. Bei Shopify-Themes ist `@shopify/dev-mcp` das offizielle MCP für Liquid/GraphQL-Schema-Referenzen — ebenfalls kein Auth, ebenfalls pure Docs.

Bewusste Beschränkung auf 2 Tools:
- Token-Impact hoch, Wartung niedrig
- Keine Auth, keine Secrets, keine Slug-Matching-Probleme
- Stack-agnostisch (context7) oder klar gated (shopify-dev-mcp bei `stack_profile=shopify-liquid`)
- Alles andere (Browser-Automation, DB-MCPs, mcp-platform) bleibt explizit opt-in außerhalb dieses Specs

## Steps
- [x] Step 1: `lib/data/mcp-defaults.json` anlegen — Mapping `{global: [context7], profiles: {shopify-liquid: [shopify-dev-mcp]}}` inkl. Install-Command und kurzer Beschreibung je MCP
- [x] Step 2: `lib/mcp-suggest.sh` — liest defaults-JSON, gibt basierend auf `stack_profile` (aus Spec 638) die passende Liste zurück
- [x] Step 3: `ai-setup.sh` nach Stack-Detect: Liste als AskUserQuestion-Prompt, pro MCP Y/N. Default=Y für alle, User kann einzelne abwählen
- [x] Step 4: `.mcp.json` Generator (oder `claude mcp add --scope project` Aufrufe) — idempotent, existierende Einträge bleiben, managed block via Kommentar-Marker falls JSON das erlaubt (sonst jq-merge + Log-Eintrag)
- [x] Step 5: `.claude/rules/mcp.md` Template erweitern: Abschnitt "Default MCPs" mit Kurzbeschreibung was context7 und shopify-dev-mcp tun und wann sie auslassen
- [x] Step 6: `doctor.sh` Check: wenn MCP in `.mcp.json` steht aber `claude mcp list` das nicht anzeigt → Warning (Typischer Fail: npm/npx nicht installiert, Node fehlt)
- [x] Step 7: `README.md` Section "Default MCPs" mit Install-Commands für manuelles Nachholen
- [ ] Step 8: Smoke-Test: ai-setup in sp-alpensattel (Shopify) → Prompt zeigt context7 + shopify-dev-mcp; in nuxt-onedot → nur context7; in crewbuddy (Laravel) → nur context7

## Acceptance Criteria
- [x] `bash lib/mcp-suggest.sh` mit `stack_profile=shopify-liquid` gibt JSON-Array mit `context7` und `shopify-dev-mcp` zurück
- [x] `bash lib/mcp-suggest.sh` mit `stack_profile=nuxt-storyblok` gibt nur `context7` zurück
- [ ] Nach `ai-setup` (Y zu allen) in Shopify-Repo: `jq -e '.mcpServers.context7' .mcp.json` valide, `jq -e '.mcpServers."shopify-dev-mcp"' .mcp.json` valide
- [x] Keine Bearer-Token/Secrets in `.mcp.json` — `grep -iE "token|secret|bearer" .mcp.json` liefert nichts
- [ ] `ai-setup --patch` in Repo mit manuell hinzugefügtem Custom-MCP-Eintrag lässt diesen intakt
- [x] `bash .claude/scripts/doctor.sh` warnt wenn `context7` in `.mcp.json` aber `claude mcp list` zeigt ihn nicht
- [x] `shellcheck lib/mcp-suggest.sh` passt
- [ ] `bash .claude/scripts/quality-gate.sh` grün

## Files to Modify
- `lib/mcp-suggest.sh` — NEU
- `lib/data/mcp-defaults.json` — NEU, kuratierte Liste
- `bin/ai-setup.sh` — MCP-Suggest-Phase (install_context7 → install_mcp_suggestions)
- `lib/plugins.sh` — _mcp_add_entry + install_mcp_suggestions + install_context7 refactor
- `templates/claude/rules/mcp.md` — NEU, "Default MCPs" Section
- `templates/scripts/doctor.sh` — MCP-Install-Sanity-Check
- `README.md` — Section "Default MCPs"

## Out of Scope
- mcp-platform Integration (storyblok/shopify/klaviyo Endpoints) → Brainstorm 640b
- Playwright/Puppeteer/Chrome-DevTools-MCPs (opt-in, kein Default)
- Database-MCPs (postgres, sqlite) — projekt-spezifisch
- Auto-Install von npm/npx-Deps (User-Verantwortung, doctor zeigt nur Hinweis)
- OAuth-Flows, Token-Management
- Globale vs. Projekt-Scope Entscheidung pro MCP — hier fix Projekt-Scope, global-Install ist User-eigene Sache

## Dependencies
- Profitiert von Spec 638 (`stack_profile`) — zwingend danach
