# Spec: Agent Lifecycle Hooks — SubagentStart/Stop Metriken

> **Spec ID**: 574 | **Created**: 2026-03-24 | **Status**: ✅ completed (cancelled) | **Complexity**: simple | **Branch**: —
> **Source**: [specs/570-research-just-ship.md](570-research-just-ship.md) Kandidat #4

## Goal
SubagentStart/Stop Hooks die Agent-Spawns mit Name, Model und Dauer in eine lokale Metriken-Datei loggen — **nur für dieses Repo** (`.claude/`), nicht als Template für Kundenprojekte.

## Context
Just Ship trackt Agent-Lifecycle via Pipeline-Events für Board-Transparenz. Für uns relevant: lokales Logging welche Agents wie oft/lange laufen. Ermöglicht Debugging ("warum war die Session teuer?") und Optimierung der Agent-Dispatch-Regeln.

**Scope-Entscheidung**: Hooks gehen in `.claude/settings.json` dieses Repos, NICHT in `templates/claude/settings.json`. End-User wollen keine Agent-Metriken-Logs in ihren Projekten.

## Steps
- [ ] Step 1: `templates/claude/hooks/agent-start.sh` erstellen
  - Input: `$CLAUDE_AGENT_NAME` (oder verfügbare Env-Vars)
  - Loggt: Timestamp, Agent-Name, Model (falls verfügbar)
  - Format: append-only JSONL in `.claude/agent-metrics.log`
- [ ] Step 2: `templates/claude/hooks/agent-stop.sh` erstellen
  - Loggt: Timestamp, Agent-Name, Dauer (berechnet aus Start-Timestamp), Exit-Status
  - Format: JSONL append
- [ ] Step 3: Hook-Registrierung in `templates/claude/settings.json` unter `SubagentStart` / `SubagentStop`
- [ ] Step 4: `.claude/agent-metrics.log` in `.gitignore` Template aufnehmen
- [ ] Step 5: Testen: Agent spawnen → Log-Einträge in `.claude/agent-metrics.log` prüfen

## Acceptance Criteria
- [ ] SubagentStart Hook loggt Agent-Name + Timestamp bei jedem Agent-Spawn
- [ ] SubagentStop Hook loggt Agent-Name + Dauer bei Agent-Ende
- [ ] Log-Format ist JSONL (maschinenlesbar, eine Zeile pro Event)
- [ ] Log-Datei wird nicht committed (in .gitignore)
- [ ] Hooks haben Timeout (max 3s) und scheitern leise (kein Workflow-Blocker)

## Files to Modify
- `.claude/hooks/agent-start.sh` — neuer Hook (nur dieses Repo)
- `.claude/hooks/agent-stop.sh` — neuer Hook (nur dieses Repo)
- `.claude/settings.json` — Hook-Registrierung (nur dieses Repo)
- `.gitignore` — agent-metrics.log excludieren

## Out of Scope
- Board/Pipeline-Event-Sending (nur lokales Logging)
- Token-Kosten-Tracking (nicht in Hook-Env-Vars verfügbar)
- Dashboard/Visualisierung der Metriken
