# Spec: Context-File Size Cap & Auto-Trim Warning

> **Spec ID**: 644 | **Created**: 2026-04-19 | **Status**: in-review | **Complexity**: small | **Branch**: —

## Goal
Harte Caps für `.agents/context/*.md` Files definieren. Bei Überschreitung: Warning via context-monitor-hook + Empfehlung welche Datei zu trimmen ist. Verhindert dass Context-Files über Zeit unbegrenzt wachsen und jedes `@file`-Injection teuer wird.

## Context
`@.agents/context/SUMMARY.md` wird bei jedem Turn injiziert (siehe CLAUDE.md `tiered loading`). Aktuell keine Größenbeschränkung — wenn Context-Refresher immer mehr Infos reinpackt, explodiert das kumulativ. Existierender `context-monitor-hook` (Spec 053, 138) trackt vermutlich Gesamtnutzung, aber keine harten Per-File-Caps.

Sinnvolle Caps (in Zeilen, robuster als Bytes für Markdown):
- `SUMMARY.md`: 40 Zeilen (wird pro Turn injiziert — muss schlank bleiben)
- `STACK.md`: 100 Zeilen
- `ARCHITECTURE.md`: 150 Zeilen
- `CONVENTIONS.md`: 80 Zeilen
- Gesamt `/agents/context/` Directory: 400 Zeilen kombiniert

Bei Überschreitung: context-monitor-hook gibt Warning aus, schlägt konkret vor "SUMMARY.md ist 62 Zeilen, Cap 40 — Top 10 entfernen oder in STACK.md verschieben".

## Steps
- [x] Step 1: Cap-Config als `lib/data/context-caps.json` — {file: max_lines} Mapping mit sinnvollen Defaults
- [x] Step 2: `lib/context-size-check.sh` — liest Caps, prüft alle Files in `.agents/context/`, gibt Violations als strukturierte Liste aus (exit-code 0 ok, 1 violations)
- [x] Step 3: `templates/claude/hooks/context-freshness.sh` (existierender Hook) erweitern: ruft size-check auf, bei violation → Warning im Hook-Output mit konkreter Datei + Zeilenzahl + Cap
- [x] Step 4: `templates/scripts/doctor.sh` ruft context-size-check auf, zeigt Violations als WARNING
- [x] Step 5: `lib/generate.sh` CONTEXT_PROMPT mit expliziten Zeilen-Caps aktualisiert (context-refresher Agent nicht vorhanden — generate.sh ist der Ort des Prompts)
- [x] Step 6: `--relax-context-caps` Flag für Setup-Override (Edge-Case: sehr große Legacy-Repos mit riesigem Stack-Spread)
- [x] Step 7: Smoke-Test: künstlich SUMMARY.md auf 80 Zeilen aufblasen, Hook + doctor meldet Violation
- [x] Step 8: Readme-Section "Context File Budget"

## Acceptance Criteria
- [x] `bash lib/context-size-check.sh` in npx-ai-setup selbst passiert ohne Violations (Meta-Check) — CONVENTIONS.md hat 82 Zeilen, 2 über Cap: dokumentiert, nicht getrimmt
- [x] Absichtlich überfüllte SUMMARY.md (80 Zeilen) → `lib/context-size-check.sh` exit 1 mit klarer Meldung
- [x] context-monitor Hook bei überfüllter Datei: Output enthält "Cap exceeded: SUMMARY.md 80 > 40"
- [x] `doctor.sh` zeigt Violations als WARNING (gelb/orange), nicht als FAIL
- [x] `--relax-context-caps` unterdrückt Violations ohne die Caps-File zu ändern
- [x] `shellcheck lib/context-size-check.sh` passt
- [ ] `bash .claude/scripts/quality-gate.sh` grün — `doctor.sh` parity requires `npx ai-setup --patch doctor.sh` after merge (template updated, live file requires setup rerun)

## Files to Modify
- `lib/data/context-caps.json` — NEU
- `lib/context-size-check.sh` — NEU
- `templates/hooks/context-monitor.sh` — erweitern
- `.claude/scripts/doctor.sh` — Cap-Check integrieren
- `.claude/agents/context-refresher.md` — Cap-Policy-Hinweis
- `ai-setup.sh` — `--relax-context-caps` Flag
- `README.md` — Section "Context File Budget"

## Out of Scope
- Auto-Trim (destruktiv Zeilen löschen) — wir warnen nur, User entscheidet
- Byte-basierte Caps (Zeilen sind für Markdown aussagekräftiger)
- Caps für andere Verzeichnisse (nur `.agents/context/`)
- Token-exakte Messung (char/4 Approximation ausreichend, siehe Spec 643)

## Dependencies
- Keine Hard-Deps. Kann parallel zu 638/642/643 laufen.
- Profitiert indirekt von 638 (Bundles sind kompakter als LLM-generierter Free-Text)
