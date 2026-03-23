---
id: 168
title: Migrate project-audit into /analyze
status: in-progress
---

## Goal

`/analyze` übernimmt die Funktion von `project-audit`: produziert PATTERNS.md + AUDIT.md als persistente Artefakte. Wenn die Dateien bereits existieren, wird immer gefragt ob neu generiert werden soll. `project-audit` Skill und `project-auditor` Agent werden entfernt.

## Context

`/analyze` gibt derzeit nur einen Chat-Report aus. `project-audit` schreibt PATTERNS.md + AUDIT.md via `project-auditor` Agent. Die Trennung ist unnötig — `/analyze` hat die bessere Analyse-Logik (3 parallele Agents, Fast/Batch-Mode). `bin/ai-setup.sh` hatte einen `--audit` Flag der den Agent direkt aufrief — das wird nicht mehr automatisch während des Setups ausgeführt, sondern als Post-Install-Empfehlung angezeigt.

## Steps

1. **`templates/commands/analyze.md` + `.claude/commands/analyze.md`** — Step 4 hinzufügen nach dem bestehenden Step 3:
   - Prüfe ob `.agents/context/PATTERNS.md` oder `.agents/context/AUDIT.md` existieren
   - Falls ja: Frage "Dateien existieren bereits. Neu generieren?" (Ja / Nein)
   - Falls Nein: abbrechen
   - Schreibe PATTERNS.md aus dem Architecture-Block des Reports
   - Schreibe AUDIT.md aus Hotspots + Risks + Recommendations des Reports
   - Committe beide Dateien: `chore: update project analysis artifacts`
   - Beide Dateien (template + aktiv) identisch ändern

2. **`lib/core.sh`** — Zeile mit `project-audit/SKILL.md` aus dem `CORE_SKILLS` Array entfernen

3. **`bin/ai-setup.sh`** — `--audit` Flag und den gesamten Audit-Block (Zeilen ~27–203) entfernen; stattdessen in der Post-Install-Erfolgsmeldung einen Hinweis hinzufügen: "Run \`/analyze\` to generate PATTERNS.md and AUDIT.md for this project."

4. **Cleanup** — 4 Dateien löschen:
   - `templates/skills/project-audit/SKILL.md`
   - `.claude/skills/project-audit/SKILL.md`
   - `templates/agents/project-auditor.md`
   - `.claude/agents/project-auditor.md`

5. **Docs** — `project-audit` → `/analyze` ersetzen in:
   - `templates/claude/WORKFLOW-GUIDE.md` + `.claude/WORKFLOW-GUIDE.md`
   - `templates/CLAUDE.md` + `CLAUDE.md`
   - `README.md`

## Acceptance Criteria

### Truths
- `/analyze` schreibt PATTERNS.md + AUDIT.md nach Abschluss der Analyse
- Existierende Dateien → User wird gefragt, kein Auto-Überschreiben
- `project-audit` Skill und `project-auditor` Agent existieren nicht mehr in templates/ und .claude/
- `lib/core.sh` enthält keinen Eintrag für `project-audit`
- `bin/ai-setup.sh` enthält weder `--audit` Flag noch `project-auditor` Referenz; zeigt Post-Install-Hinweis auf `/analyze`
- WORKFLOW-GUIDE, CLAUDE.md, README referenzieren nur noch `/analyze`

### Artifacts
- PATTERNS.md enthält Architecture-Inhalt aus dem Analyse-Report
- AUDIT.md enthält Hotspots + Risks + Recommendations

## Files to Modify

- `templates/commands/analyze.md`
- `.claude/commands/analyze.md`
- `lib/core.sh`
- `bin/ai-setup.sh`
- `templates/skills/project-audit/SKILL.md` (delete)
- `.claude/skills/project-audit/SKILL.md` (delete)
- `templates/agents/project-auditor.md` (delete)
- `.claude/agents/project-auditor.md` (delete)
- `templates/claude/WORKFLOW-GUIDE.md`
- `.claude/WORKFLOW-GUIDE.md`
- `templates/CLAUDE.md`
- `CLAUDE.md`
- `README.md`

## Out of Scope

- `specs/completed/` Dateien die `project-audit` erwähnen (historische Docs)
- `lib/migrations/1.4.0.sh` — historische Migration, wird nicht rückwirkend geändert
- CHANGELOG.md (wird bei Release automatisch generiert)
