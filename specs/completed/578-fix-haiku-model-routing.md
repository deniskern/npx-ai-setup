# Spec 578: Haiku-Routing für Explore/Search-Agents erzwingen

> **Spec ID**: 578 | **Created**: 2026-03-25 | **Status**: in-review | **Complexity**: medium | **Branch**: spec/578-fix-haiku-model-routing

## Goal

Sicherstellen dass alle Explore- und Search-Agents tatsächlich mit `model: haiku` gespawnt werden, da Session-Metriken zeigen dass 88-100% der Aufrufe auf Sonnet laufen.

## Context

Session-Optimize-Analyse (2026-03-25) zeigt: 4 aktive Sessions — 0% Haiku in 3, nur 3% in einer. CLAUDE.md und `.claude/rules/agents.md` fordern Haiku für alle Explore/Search-Agents. Die Regeln greifen in der Praxis nicht. Ursache unklar: entweder fehlt `model: haiku` in den Agent-Prompts, oder die Regel ist nicht prominent genug in skills/agents.

## Steps

- [x] Step 1: Alle Skills lesen die Explore-Agents spawnen (`analyze`, `session-optimize`, `discover`, `research`, `techdebt`) — prüfen ob `model: haiku` explizit gesetzt ist
- [x] Step 2: Skills ohne `model: haiku` bei Explore-Agent-Aufrufen korrigieren
- [x] Step 3: `.claude/rules/agents.md` prüfen — CRITICAL-Hinweis auf Haiku ist vorhanden, aber Agent-Auswahl-Tabelle könnte klarer sein
- [x] Step 4: Session-extract.sh Ausgabe auf Haiku-Anteil testen: session-extract.sh läuft, zeigt aktuell Sonnet-Dominanz — fix in skills erfordert nächste Session zur Verifikation

## Acceptance Criteria

- [x] Alle Skills die Explore-Agents spawnen haben explizit `model: haiku` im Agent-Aufruf
- [x] `.claude/rules/agents.md` enthält keine Lücke die Sonnet als Default für Explore erlaubt
- [x] Kein Skill spawnt einen reinen Such-/Explore-Agent mit Sonnet oder Opus

## Files to Modify

- `.claude/skills/analyze/SKILL.md` — Explore-Agent-Aufrufe prüfen
- `.claude/skills/session-optimize/SKILL.md` — MCP-Search-Aufrufe prüfen
- `.claude/skills/discover/SKILL.md` — falls vorhanden, Explore-Agents prüfen
- `templates/skills/research/SKILL.md` — Explore-Agent-Aufrufe prüfen
- `templates/skills/techdebt/SKILL.md` — Explore-Agent-Aufrufe prüfen
- `.claude/rules/agents.md` — ggf. Klarstellung

## Out of Scope

- Modell-Wahl für Implementation-Agents (Sonnet bleibt korrekt)
- Opus-Nutzung in Routine-Sessions (→ Spec 576)
- Neue Hook-Infrastruktur für automatische Validierung
