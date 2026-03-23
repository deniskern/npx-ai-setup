# Spec 167: L0/L1/L2 Tiered Context Loading

> **Status**: In-Progress
> **Source**: [OpenViking Research](specs/166-research-openviking.md)
> **Goal**: Context-Dateien stufenweise laden statt alles auf einmal. Token-Ersparnis: 500-1500 Tokens/Request.

## Context

OpenViking nutzt ein dreistufiges Ladesystem: L0 (Einzeiler-Abstracts), L1 (Sections-Übersicht), L2 (vollständiger Inhalt). Aktuell laden wir STACK.md + ARCHITECTURE.md + CONVENTIONS.md komplett in jeder Session (~2000 Tokens), auch wenn der Task nur eine Datei betrifft.

## Steps

- [x] 1. YAML-Frontmatter zu allen `.agents/context/` Dateien hinzufügen: `abstract:` (1 Zeile), `sections:` (Liste der Haupt-Sections mit Einzeiler-Beschreibung)
- [x] 2. Template-Versionen in `templates/` analog anpassen (STACK.md, ARCHITECTURE.md, CONVENTIONS.md Template-Struktur)
- [x] 3. SessionStart-Hook erstellen/anpassen: Nur `abstract:` + `sections:` aus Frontmatter laden statt volle Dateien. Output als `additionalContext`
- [x] 4. Skill `context-load` erstellen: Agent kann gezielt einzelne Sections oder volle Datei anfordern (`/context-load STACK.md` oder `/context-load STACK.md#runtime`)
- [x] 5. CLAUDE.md aktualisieren: Instruktion dass Agent bei Bedarf `/context-load` nutzen soll statt die Dateien direkt zu lesen
- [ ] 6. Token-Vergleich messen: Vorher/Nachher mit `rtk gain` über 5 Sessions

## Acceptance Criteria

- SessionStart lädt max 400 Tokens Context (statt ~2000)
- Agent kann jederzeit volle Dateien laden wenn nötig
- Kein Funktionsverlust bei komplexen Tasks
- Template-System bleibt kompatibel

## Files to Modify

- `.agents/context/STACK.md`, `ARCHITECTURE.md`, `CONVENTIONS.md`
- `templates/` (entsprechende Template-Dateien)
- `.claude/hooks/` oder `templates/claude/hooks/` (SessionStart Hook)
- `.claude/skills/` (neuer context-load Skill)
- `CLAUDE.md`
