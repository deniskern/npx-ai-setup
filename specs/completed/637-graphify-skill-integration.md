# Spec: Graphify Knowledge Graph als opt-in Skill

> **Spec ID**: 637 | **Created**: 2026-04-19 | **Status**: completed | **Complexity**: medium | **Branch**: worktree-agent-a1512785

## Goal
Graphify (Karpathy /raw-style Knowledge Graph) als opt-in Skill in npx-ai-setup integrieren, aktiviert via Stack-Detection, genutzt von Claude zur Token-sparenden Code-Navigation in Zielprojekten.

## Context
Graphify baut persistenten Knowledge Graph (`graphify-out/graph.json`) mit Community-Detection, EXTRACTED/INFERRED edge-tagging und MCP-Server. In großen Nuxt-/Shopify-/Laravel-Projekten ersetzt eine `jq`-Query den üblichen 5-10 Grep-Runden-Discovery-Flow.

Python-Dep wird **einmal lokal** via `pipx install graphifyy` auf der Dev-Machine installiert — Zielprojekt bleibt dep-frei. Der Skill wrapped nur den Binary-Aufruf.

Ziel-Primary-Stacks profitieren unterschiedlich:
- Nuxt/Vue (>50 components): hoch — Component-Dependency-Graph ersetzt grep über `components/`, `composables/`, `pages/`
- Shopify Themes (>30 liquid files): sehr hoch — section→snippet→template Graph ist grep-schwach
- Laravel/PHP (>100 PHP files): mittel — Service-Container + Event-Listener-Graph
- MCP/N8N/kleine Repos: skip

## Steps
- [x] Step 1: `lib/detect-stack.sh` um `graphify_candidate` Output erweitern (Stack + file-count thresholds: Nuxt ≥50 `.vue`, Shopify ≥30 `.liquid`, Laravel ≥100 `.php`, JS/TS ≥100 `.ts/.tsx/.js`)
- [x] Step 2: Template `templates/skills/graphify.md` erstellen — how-to-use für Claude: `jq` patterns für Component-Dependencies, `graphify query`/`path`/`explain` Wrapper, MCP-Modus Hinweis
- [x] Step 3: `ai-setup.sh` nach Stack-Detect: wenn `graphify_candidate=true` → `AskUserQuestion`-style Prompt "Graphify Knowledge Graph aktivieren? [Y/n/skip]"; bei Y Skill-Datei kopieren
- [x] Step 4: `lib/install-skills.sh` um Graphify-Skill-Install erweitern (idempotent, respektiert `--patch` flag)
- [x] Step 5: `.claude/rules/agents.md` Template ergänzen: jq-Snippets für graphify graph.json (ergänzend zum existierenden JS/TS-Import-Graph), klare Abgrenzung der beiden Graphen
- [x] Step 6: `.claude/scripts/doctor.sh` Check: wenn `graphify` Skill installiert aber `command -v graphify` fehlt → Warning + Hinweis `pipx install graphifyy`
- [x] Step 7: `README.md` im npx-ai-setup Repo: Abschnitt "Optional: Knowledge Graph via Graphify" mit Install-One-Liner und Stack-Thresholds
- [x] Step 8: Smoke-Test: ai-setup in `~/Sites/sp-alpensattel` (Shopify) laufen lassen, prüfen dass Prompt erscheint, Skill korrekt installiert wird, doctor grünes Licht gibt
- [x] Step 9: Negative-Test: ai-setup in kleinem Repo (<20 files) — Prompt darf NICHT erscheinen

## Acceptance Criteria
- [x] `bash lib/detect-stack.sh` gibt `graphify_candidate=true|false` in einem Nuxt-Projekt mit ≥50 `.vue` zurück (`grep 'graphify_candidate=true'` muss matchen)
- [x] `bash ai-setup.sh --dry-run` in Shopify-Theme mit ≥30 `.liquid` zeigt Graphify-Prompt; in leerem tmp-Repo zeigt ihn nicht
- [x] Nach Skill-Install: `.claude/skills/graphify.md` existiert und enthält `jq` query examples
- [x] `bash .claude/scripts/doctor.sh` ohne installiertes graphify-binary zeigt Warning mit dem pipx-Hinweis
- [x] `shellcheck lib/detect-stack.sh lib/install-skills.sh ai-setup.sh` passt
- [x] `bash .claude/scripts/quality-gate.sh` grün

## Files to Modify
- `lib/detect-stack.sh` — file-count Thresholds + `graphify_candidate` export
- `lib/install-skills.sh` — Graphify-Skill opt-in install
- `ai-setup.sh` — User-Prompt nach Stack-Detection
- `templates/skills/graphify.md` — NEU, Skill template für Zielprojekte
- `templates/rules/agents.md` — jq-Snippets, Graphen-Abgrenzung
- `.claude/scripts/doctor.sh` — graphify binary check
- `README.md` — Optional-Section
- `specs/TEMPLATE.md` — unverändert

## Out of Scope
- Auto-Install von `graphifyy` via pip/pipx (bleibt User-Verantwortung, doctor zeigt nur Hinweis)
- Globales Claude-MCP-Setup für graphify (separate Entscheidung, nicht Teil von npx-ai-setup)
- Ersetzen des existierenden JS/TS-Import-Graphen (`.agents/context/graph.json`) — beide laufen parallel, agents.md grenzt ab
- Python-Version-Management, venv-Handling
- Windows-Support (POSIX/macOS/Linux only, konsistent mit Repo-Status)
