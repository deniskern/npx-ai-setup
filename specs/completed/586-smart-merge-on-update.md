# Spec: Smart Merge für user-modifizierte Template-Dateien

> **Spec ID**: 586 | **Created**: 2026-03-25 | **Status**: completed | **Complexity**: medium | **Branch**: —

## Goal

Wenn `ai-setup` eine user-modifizierte Datei erkennt, wird sie nicht mehr geskippt sondern via `claude -p` mit Haiku intelligent gemergt — Template-Updates landen im Projekt, lokale Ergänzungen (z.B. via `/apply-learnings`) bleiben erhalten.

## Context

`lib/setup.sh:_install_or_update_file` erkennt bereits user-modifizierte Dateien via Checksum-Vergleich gegen `.ai-setup.json`. Das aktuelle Verhalten: `tui_warn "$target kept (user-modified)"` — Datei wird geskippt, Template-Update geht verloren.

Problem: `/apply-learnings` schreibt Learnings in `rules/general.md`, `rules/agents.md` etc. (Template-Dateien). Nach einem `ai-setup`-Update werden diese Einträge geskippt — aber der Template-Inhalt wird auch nicht aktualisiert. Beides verliert.

Lösung: Statt Skip → `claude -p "Merge these two versions..."` mit `--model claude-haiku-4-5`. Haiku ist ausreichend für Merge-Aufgaben und läuft non-interaktiv. Fallback auf Skip wenn `claude` nicht im PATH.

## Steps

- [x] Step 1: `_install_or_update_file` in `lib/setup.sh` erweitern — nach Zeile 44 (`tui_warn "kept"`) die merge-Logik einbauen
- [x] Step 2: `_smart_merge_file` Hilfsfunktion schreiben:
  ```bash
  # Inputs: src (template), target (user-modified)
  # Calls: claude -p with --model claude-haiku-4-5 --output-format text
  # Returns: merged content → overwrites target
  # Fallback: if claude not in PATH → skip (current behavior)
  ```
- [x] Step 3: Merge-Prompt definieren — präzise Instruktion damit Haiku nur mergt und keine Inhalte erfindet:
  - Template-Inhalt = neue Quelle der Wahrheit für bestehende Sections
  - Lokale Ergänzungen (neue Sections, neue Bullets) erhalten
  - Keine Duplikate
  - Output: nur Dateiinhalt, kein Preamble
- [x] Step 4: Nach erfolgreichem Merge — Checksum in `.ai-setup.json` aktualisieren (write_metadata() am Setup-Ende erledigt das automatisch)
- [x] Step 5: Ausgabe — `tui_success "$target merged (template + local)"` statt `tui_warn "kept"`
- [x] Step 6: Smoke-Test — Funktionen geladen, Fallbacks für .sh und fehlendes claude CLI verifiziert

## Acceptance Criteria

- [x] User-modifizierte Dateien werden nicht mehr geskippt sondern gemergt
- [x] Lokale Ergänzungen (neue Sections, neue Bullets) überleben den Merge
- [x] Template-Updates (neue Inhalte, geänderte bestehende Sections) landen im Merge-Ergebnis
- [x] Fallback auf Skip-Verhalten wenn `claude` nicht im PATH
- [x] Checksum in `.ai-setup.json` wird nach Merge aktualisiert (via write_metadata am Ende)
- [x] Kein interaktiver Input nötig — läuft vollautomatisch durch

## Files to Modify

- `lib/setup.sh` — `_install_or_update_file` + neue `_smart_merge_file` Funktion

## Out of Scope

- Merge für binäre Dateien oder `.sh`-Scripts (nur `.md` und `.json` Template-Dateien)
- Konflikt-Handling wenn Haiku nicht eindeutig entscheiden kann (Fallback: Skip mit Warnung)
- Interaktiver Merge-Editor
