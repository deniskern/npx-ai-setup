# Spec: Subagent-Optimierung — Globale Agents, Model-Routing, Stack-Coverage

> **Spec ID**: 593 | **Created**: 2026-03-26 | **Status**: completed | **Complexity**: medium | **Branch**: spec/593-subagent-optimization

## Goal
Universelle Agents global deployen, Model-Routing korrigieren, Stack-spezifische Agents konditionell deployen, und neue Shopware- und Storyblok-Agents hinzufügen.

## Context
11 Agents werden aktuell alle in `.claude/agents/` des Zielprojekts installiert — egal ob relevant. Universelle Agents (code-reviewer, security-reviewer etc.) gehören nach `~/.claude/agents/` für projektübergreifende Verfügbarkeit. `liquid-linter` wird ohne Shopify-Check deployed, `verify-app` läuft unnötig auf Sonnet, und es fehlt ein Shopware-Agent.

### Verified Assumptions
- `install_agents()` in `lib/setup-skills.sh:21` steuert Agent-Deployment — Evidence: `lib/setup-skills.sh` | Confidence: High
- `_install_or_update_file()` handled Copy + Checksum — Evidence: `lib/setup.sh:68` | Confidence: High
- Nur `frontend-developer` hat konditionelle Logik — Evidence: `lib/setup-skills.sh:34` | Confidence: High
- `~/.claude/agents/` existiert aber ist leer — Evidence: ls check | Confidence: High

## Steps
- [x] Step 1: `templates/agents/perf-reviewer.md` → `performance-reviewer.md` umbenennen
- [x] Step 2: `templates/agents/verify-app.md` — model von `sonnet` auf `haiku` ändern
- [x] Step 3: Stack-spezifische Agents (shopware, storyblok) → Boilerplate-Repos (separater Task)
- [x] Step 4: `liquid-linter` aus Templates entfernt, `pull_boilerplate_files()` um Agent-Pull erweitert
- [x] Step 5: `lib/setup-skills.sh` — `install_global_agents()` Funktion + in Setup-Flow eingebunden
- [x] Step 6: Agent-Dispatch-Docs + README aktualisiert (universal/conditional/boilerplate Scopes)
- [x] Step 7: Skills → Agent Mappings: /review, /test, /scan, /build-fix dispatchen jetzt relevante Agents
- [x] Step 8: Migration `2.1.0.sh` für Rename + liquid-linter Removal
- [x] Step 9: Alle `perf-reviewer` Referenzen in Agent-Templates aktualisiert

## Acceptance Criteria

### Truths
- [ ] `ls templates/agents/performance-reviewer.md` existiert, `perf-reviewer.md` nicht mehr
- [ ] `grep 'model: haiku' templates/agents/verify-app.md` matcht
- [ ] `templates/agents/shopware-reviewer.md` existiert mit PHP/Twig-Fokus
- [ ] `templates/agents/storyblok-reviewer.md` existiert mit Schema+Vue-Fokus

### Artifacts
- [ ] `templates/agents/shopware-reviewer.md` — Shopware-spezifischer Review-Agent
- [ ] `templates/agents/storyblok-reviewer.md` — Storyblok Schema + Vue-Integration Review
- [ ] `templates/agents/performance-reviewer.md` — umbenannt von perf-reviewer

### Key Links
- [ ] `bin/ai-setup.sh` → `lib/setup-skills.sh` via `install_global_agents`
- [ ] `lib/setup-skills.sh` → `lib/setup.sh` via `_install_or_update_file`

## Files to Modify
- `templates/agents/perf-reviewer.md` — rename zu performance-reviewer.md
- `templates/agents/verify-app.md` — model downgrade
- `templates/agents/shopware-reviewer.md` — neu
- `templates/agents/storyblok-reviewer.md` — neu
- `lib/setup-skills.sh` — konditionelle Logik + globale Install-Funktion
- `bin/ai-setup.sh` — globale Agents einbinden
- `lib/migrations/` — Migration für Rename

## Out of Scope
- Docs-reviewer Agent oder Skill
- Änderungen an Skills oder Hooks
- Agents für dieses Repo selbst (nur Templates)
