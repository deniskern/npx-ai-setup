# Spec: /ship — Autonomer Shipping-Flow

> **Spec ID**: 571 | **Created**: 2026-03-24 | **Status**: ✅ completed (cancelled) | **Complexity**: medium | **Branch**: —
> **Source**: [specs/570-research-just-ship.md](570-research-just-ship.md) Kandidat #1

## Goal
Optionaler `/ship` Command für Solo-Projekte ohne Branch Protection: Commit → Push → PR → Squash-Merge → Branch-Cleanup → main in einem autonomen Flow. **Nicht als Default-Template installiert.**

## Context
Aktuell braucht der User 3 separate Commands (`/commit`, `/pr`, manuelles Merge). Just Ship zeigt dass ein Full-Auto-Flow funktioniert wenn er nur nach expliziter Freigabe aufgerufen wird. Aber: `npx-ai-setup` geht in Teams und Agentur-Projekte mit Branch Protection, required Reviews, und CI-Gates — dort würde Auto-Merge fehlschlagen oder Policies umgehen. Daher: opt-in, nicht Default.

## Scope-Einschränkung
**Nur geeignet für**: Solo-Projekte, persönliche Repos, Projekte ohne Branch Protection.
**Nicht geeignet für**: Team-Projekte, Repos mit required reviews/CI, Shopify-Boilerplates, Client-Projekte.

## Steps
- [ ] Step 1: Command-Datei `templates/commands/ship.md` erstellen
  - Frontmatter: name, description + explizite Warnung "requires no branch protection"
  - Flow als reine Markdown-Instruktionen (kein Shell-Aufruf): Uncommitted changes committen → Push → PR via `gh pr create` → Squash-Merge via `gh pr merge --squash --delete-branch` → `git checkout main && git pull`
  - Kein auto-merge bei Konflikten, kein auto-merge wenn CI pending
  - Keine Rückfragen zwischen den Schritten
- [ ] Step 2: `templates/claude/WORKFLOW-GUIDE.md` — `/ship` als optionalen Command dokumentieren mit Warnung
- [ ] Step 3: `.claude/commands/ship.md` für dieses Repo erstellen (eigener Use Case)
- [ ] Step 4: Smoke Test: Feature-Branch mit Changes → `/ship` → PR merged, auf main

## Acceptance Criteria
- [ ] `/ship` führt alle 5 Schritte ohne Rückfragen aus (Commit → Push → PR → Merge → Checkout main)
- [ ] Command prüft vor Start ob auf main: falls ja, Abbruch mit Fehlermeldung
- [ ] Bei Merge-Konflikten oder pending CI stoppt der Command und informiert den User
- [ ] Ohne uncommitted Changes überspringt der Command den Commit-Schritt
- [ ] WORKFLOW-GUIDE.md enthält Warnung "nicht für Projekte mit Branch Protection"
- [ ] `tests/smoke.sh` enthält Smoke Test für `/ship`

## Files to Modify
- `templates/commands/ship.md` — neuer Command (erstellen, aber NICHT auto-installiert)
- `templates/claude/WORKFLOW-GUIDE.md` — Dokumentation mit Opt-In-Hinweis
- `.claude/commands/ship.md` — für dieses Repo

## Out of Scope
- Automatische Installation in Kundenprojekte (immer manuell opt-in)
- Board/Pipeline-Integration
- Konversationelle Trigger ("passt" → auto-ship)
- Vercel Preview URL Fetching
