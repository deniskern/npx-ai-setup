# Spec: Boilerplate-Sync bei ai-setup Update

> **Spec ID**: 594 | **Created**: 2026-03-27 | **Status**: draft | **Complexity**: medium | **Branch**: —

## Goal
Boilerplate-Skills/Agents/Rules werden bei `ai-setup update` automatisch re-synced, nicht nur bei Erstinstallation.

## Context
`pull_boilerplate_files()` läuft nur bei Erstinstallation via `select_boilerplate_system`. Bei Updates (`run_smart_update`, `run_migrations`) werden nur ai-setup Templates gesynced. Wenn ein Boilerplate-Repo aktualisiert wird (z.B. neuer Skill in sb-nuxt-boilerplate), bekommen existierende Projekte das nie.

`.ai-setup.json` speichert aktuell kein Boilerplate-System — es gibt keinen Weg zu wissen, welches Boilerplate beim Setup gewählt wurde.

### Verified Assumptions
- `select_boilerplate_system` läuft nur bei Erstinstallation — Evidence: `bin/ai-setup.sh:110` | Confidence: High
- `.ai-setup.json` hat kein `system` Feld — Evidence: `lib/core.sh:123` write_metadata | Confidence: High
- `pull_boilerplate_files()` nutzt gh API zum Fetchen — Evidence: `lib/boilerplate.sh` | Confidence: High
- `run_smart_update()` ruft nie boilerplate auf — Evidence: `lib/update.sh` | Confidence: High

## Steps
- [ ] Step 1: `.ai-setup.json` Schema erweitern — `system` Feld hinzufügen (shopify/shopware/nuxt/next/storyblok/none)
- [ ] Step 2: `write_metadata()` in `lib/core.sh` — `system` Feld schreiben (aus `SELECTED_SYSTEM` Variable)
- [ ] Step 3: `select_boilerplate_system()` — gewähltes System in `SELECTED_SYSTEM` speichern
- [ ] Step 4: `sync_boilerplate()` Funktion in `lib/boilerplate.sh` — re-pull wenn System gesetzt, Checksum-Diff für existierende Files
- [ ] Step 5: `run_smart_update()` in `lib/update.sh` — `sync_boilerplate` nach Template-Sync aufrufen
- [ ] Step 6: Bestehende Projekte: System aus vorhandenen Boilerplate-Files erkennen (Fallback wenn kein `system` in Metadata)

## Acceptance Criteria

### Truths
- [ ] `jq .system .ai-setup.json` gibt das gewählte System zurück nach Neuinstallation
- [ ] `ai-setup update` auf einem Projekt mit Boilerplate synced Boilerplate-Files automatisch
- [ ] Bestehende Projekte ohne `system` Feld werden korrekt erkannt (Shopify-Rules → shopify, etc.)

### Artifacts
- [ ] `lib/boilerplate.sh` — `sync_boilerplate()` Funktion
- [ ] `lib/core.sh` — `system` Feld in Metadata

### Key Links
- [ ] `lib/update.sh:run_smart_update` → `lib/boilerplate.sh:sync_boilerplate`
- [ ] `lib/core.sh:write_metadata` → `SELECTED_SYSTEM` Variable

## Files to Modify
- `lib/core.sh` — write_metadata() + SELECTED_SYSTEM
- `lib/boilerplate.sh` — sync_boilerplate() + System-Detection Fallback
- `lib/update.sh` — run_smart_update() Boilerplate-Sync einbinden
- `bin/ai-setup.sh` — SELECTED_SYSTEM setzen nach select_boilerplate_system

## Out of Scope
- Manueller `--sync-boilerplate` Flag (kann später dazu)
- Multi-System Support (ein Projekt = ein Boilerplate)
- Boilerplate-Versioning (immer latest aus dem Repo)
