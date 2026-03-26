# Spec: QA-Tiering in /review — full/light/skip

> **Spec ID**: 572 | **Created**: 2026-03-24 | **Status**: ✅ completed (cancelled) | **Complexity**: medium | **Branch**: —
> **Source**: [specs/570-research-just-ship.md](570-research-just-ship.md) Kandidat #2

## Goal
~~`/review` erkennt automatisch den Change-Typ und wählt die passende Review-Tiefe (full/light/skip).~~

> **Cancelled**: `/review` hat bereits manuelle Intensitätswahl via `AskUserQuestion` (Step 0). Auto-Detection würde damit kollidieren. Kein echter Pain, kein Mehrwert.

## Context
Just Ship's Triage-Agent kategorisiert Changes in 3 Tiers. Unser `/review` behandelt alles gleich — ein Typo-Fix bekommt denselben Review-Aufwand wie ein neues Feature. Tiering optimiert Token-Verbrauch ohne Qualitätsverlust.

## Steps
- [ ] Step 1: Tiering-Logik in `templates/scripts/review-prep.sh` einbauen
  - `git diff --stat` analysieren: welche Dateien geändert?
  - Heuristik: `.md` only → skip, `*.test.*` + source → light, UI/neue Files → full
  - Tier als Variable an den Review-Command übergeben
- [ ] Step 2: `templates/commands/review.md` um Tier-Awareness erweitern
  - `full`: Kompletter Review (Security, Performance, Architecture, Tests)
  - `light`: Nur Correctness + Style (kein Architecture/Performance Review)
  - `skip`: Nur Format-Check + Commit-Message-Validierung
  - User kann Tier manuell überschreiben: `/review full`, `/review light`
- [ ] Step 3: Tier-Ausgabe im Review-Header anzeigen ("Review Tier: light — Bugfix detected")
- [ ] Step 4: Testen mit 3 Change-Typen: Docs-only, Bugfix, neues Feature

## Acceptance Criteria
- [ ] Docs/Config-only Changes werden automatisch als `skip` erkannt
- [ ] Bugfixes/Minor Changes werden als `light` erkannt
- [ ] UI-Changes/neue Features werden als `full` erkannt
- [ ] User kann Tier manuell überschreiben (`/review full`)
- [ ] Review-Output zeigt erkanntes Tier im Header
- [ ] Token-Verbrauch bei `skip` ist <20% eines `full` Reviews

## Files to Modify
- `templates/scripts/review-prep.sh` — Tiering-Heuristik
- `templates/commands/review.md` — Tier-aware Review-Logik
- `.claude/scripts/review-prep.sh` — eigenes Projekt aktualisieren
- `.claude/commands/review.md` — eigenes Projekt aktualisieren

## Out of Scope
- Separater `/triage` Command
- ML-basierte Klassifizierung (Heuristik reicht)
- Tiering für andere Commands (nur `/review`)
