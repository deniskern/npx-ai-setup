# Spec: Routing Consistency Check Script

> **Spec ID**: 602 | **Created**: 2026-03-31 | **Status**: completed | **Complexity**: low | **Branch**: —

## Goal
Erstelle `tests/routing-check.sh` — ein lokales Pre-Release-Script das Routing-Regeln über alle relevanten Dateien auf Konsistenz prüft und bei Widersprüchen mit Exit-Code 1 abbricht.

## Context
Routing-Regeln stehen in 4+ Dateien (CLAUDE.md, agents.md, spec-work SKILL.md, templates). Diese Session hat gezeigt, dass Widersprüche entstehen, die erst im Staff-Review auffallen. Ein deterministisches Check-Script macht Drift vor dem Release sichtbar. Relevant: `tests/smoke.sh` für Vorbildstruktur.

### Verified Assumptions
- Routing-Invarianten sind grep-prüfbar — Evidence: Smoke-Tests in `tests/smoke.sh` Zeile 143–430 belegen das | Confidence: High | If Wrong: Script kann nur Anwesenheit, nicht Semantik prüfen — dokumentieren
- Template-Parität ist testbar via `cmp` oder grep-Vergleich — Evidence: `tests/smoke.sh` Zeile 426 nutzt bereits Template-Parität | Confidence: High | If Wrong: diff-basierter Ansatz als Fallback

## Steps
- [x] Step 1: Erstelle `tests/routing-check.sh` mit Pass/Fail-Struktur analog zu `tests/smoke.sh`, prüft folgende Invarianten: (a) agents.md kein Selbstwiderspruch Haiku/Sonnet-Default, (b) spec-work medium→sonnet in repo und template, (c) kein `git add -u` in template spec-work, (d) CLAUDE.md enthält Haiku-Scope-Beschränkung
- [x] Step 2: Cross-file-Check: `diff`-basierter Vergleich der medium-Routing-Zeile zwischen `.claude/skills/spec-work/SKILL.md` und `templates/skills/spec-work/SKILL.md`
- [x] Step 3: Wire in `package.json` als `"routing-check": "bash tests/routing-check.sh"` und in Release-Skill-Dokumentation als Pre-Release-Gate erwähnen
- [x] Step 4: Smoke-Test-Assertion ergänzen die sicherstellt dass `tests/routing-check.sh` existiert und syntaktisch valide ist

## Acceptance Criteria

### Truths
- [ ] `bash tests/routing-check.sh` gibt Exit 0 auf aktuellem Stand
- [ ] Nach künstlichem Einbau eines Widerspruchs in agents.md gibt das Script Exit 1 mit lesbarer Fehlermeldung
- [ ] `npm run routing-check` funktioniert

### Artifacts
- [ ] `tests/routing-check.sh` — ausführbares Bash-Script mit mindestens 8 Assertions (40+ Zeilen)

## Files to Modify
- `tests/routing-check.sh` - neu erstellen
- `package.json` - Script-Eintrag ergänzen
- `tests/smoke.sh` - Existenz-Assertion für routing-check.sh

## Out of Scope
- Semantische/LLM-basierte Routing-Validierung
- Automatisches Fixing von Widersprüchen
- Integration in CI/CD
