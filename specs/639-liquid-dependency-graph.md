# Spec: Liquid Dependency Graph für Shopify Themes

> **Spec ID**: 639 | **Created**: 2026-04-19 | **Status**: draft | **Complexity**: medium | **Branch**: —

## Goal
Liquid-spezifischer Dependency-Graph (section→snippet→template→asset) parallel zum bestehenden JS/TS-Import-Graph. Ziel: 10+ sp-* Shopify-Theme-Repos kriegen grep-freie Struktur-Discovery beim Feature-Bau.

## Context
`agents.md` referenziert `.agents/context/graph.json` für JS/TS-Imports. Shopify-Themes haben aber 80% Liquid, und dort ist Cross-File-Discovery grep-schwach: `{% render 'snippet-name' %}`, `{% section 'section-name' %}`, `{% include %}`, `assign template-`. Bei 30-100 Liquid-Files ist das bei jedem neuen Feature eine 10-Grep-Runde.

Ein separater `liquid-graph.json` mit `renders`, `sections`, `includes`, `schema-blocks` Edges löst das — same JSON-Shape wie JS/TS-Graph, andere Edge-Types. Generator ist pure bash + `grep -E` + `jq`, keine neue Dep.

## Steps
- [ ] Step 1: Bash-Generator `lib/build-liquid-graph.sh` — scannt `sections/`, `snippets/`, `templates/`, `layout/`, `blocks/`, extrahiert: `render`/`include`/`section` Calls, `schema > blocks > type` Referenzen, `asset_url` Referenzen, Layout-Verwendung in Templates
- [ ] Step 2: Output nach `.agents/context/liquid-graph.json` mit Shape: `{ nodes: [{file, type, kind}], edges: [{source, target, relation}], stats: {top_hubs, orphans, top_rendered_snippets} }`
- [ ] Step 3: `lib/detect-stack.sh` — wenn `stack_profile=shopify-liquid` → Liquid-Graph-Build in Setup-Phase aufnehmen
- [ ] Step 4: `templates/rules/agents.md` für Shopify-Profil erweitern: jq-Snippets für häufige Queries (wer rendert diesen Snippet? welche Blocks nutzt diese Section? orphan Snippets?)
- [ ] Step 5: Test-Anchor `templates/context-bundles/shopify-liquid/ARCHITECTURE.md` auf Liquid-Graph verweisen
- [ ] Step 6: `.claude/scripts/` neues Script `liquid-graph-refresh.sh` (idempotent, nur Regeneration wenn neuere `.liquid` mtime als graph.json)
- [ ] Step 7: Smoke-Test in `~/Sites/sp-alpensattel`: graph-Generation <2s, `jq '.stats.top_rendered_snippets'` zeigt sinnvolle Top-10
- [ ] Step 8: Edge-Case-Tests: dynamische Render-Namen (`{% render snippet %}` mit Variable), Loop-Renders, schema-blocks mit `@app` Prefix

## Acceptance Criteria
- [ ] `bash lib/build-liquid-graph.sh ~/Sites/sp-alpensattel` erzeugt valides JSON (`jq . liquid-graph.json` ohne Fehler)
- [ ] `jq '.edges | length' liquid-graph.json` >0 in einem realen Shopify-Theme
- [ ] `jq -r --arg s "snippets/product-card.liquid" '.edges[] | select(.target==$s) | .source' liquid-graph.json` listet alle rendernden Files
- [ ] Generator läuft <3s auf sp-alpensattel (whichever Größe dieses Repo hat)
- [ ] Dynamische Render-Namen werden als `{target: "*", relation: "render-dynamic"}` markiert (nicht ignoriert, nicht fälschlich gematcht)
- [ ] `shellcheck lib/build-liquid-graph.sh .claude/scripts/liquid-graph-refresh.sh` passt
- [ ] `bash .claude/scripts/quality-gate.sh` grün

## Files to Modify
- `lib/build-liquid-graph.sh` — NEU
- `lib/detect-stack.sh` — Hook für Liquid-Graph-Trigger
- `.claude/scripts/liquid-graph-refresh.sh` — NEU
- `templates/rules/agents.md` — Shopify jq-Snippets
- `templates/context-bundles/shopify-liquid/ARCHITECTURE.md` — verweist auf Graph (gebündelt mit Spec 638)

## Out of Scope
- Section-Schema-Validierung (separates Thema, kein Graph-Job)
- Theme-Check-Integration (Shopify CLI macht das schon)
- Asset-Size-Tracking (Performance-Thema, nicht Graph-Thema)
- JS/TS-Bundle-Graph im Shopify-Theme (fällt unter existierenden agents.md Graph)
- Liquid-Rendering/Preview (nicht Ziel von Setup-Tool)

## Dependencies
- Profitiert von Spec 638 (Context-Bundles) aber nicht hard-blocked — kann auch ohne Bundle laufen
