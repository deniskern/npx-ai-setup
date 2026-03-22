# Spec 160: Claude Code als Multi-Agent Orchestrator

**Status:** in-progress
**Complexity:** Medium
**Branch:** `feat/160-multi-agent-orchestrator`
**Depends on:** Spec 159 (Gemini/Codex Infrastruktur)

## Goal

Claude Code als zentralen Orchestrator einrichten, der Tasks gezielt an Gemini CLI oder Codex CLI delegieren kann. Routing basiert auf Task-Typ, Kosten und Modell-Stärken. User arbeitet nur in Claude Code — Gemini/Codex laufen als Backend-Engines.

## Context

- Spec 159 liefert die Basis: Config-Templates, Skills-Symlinks, AGENTS.md Router
- Gemini CLI unterstützt `gemini -p "prompt"` (pipe/non-interactive mode)
- Codex CLI unterstützt `codex -q "prompt"` (quiet mode, execute and return)
- Claude Code kann beide via Bash-Tool als Subprozesse aufrufen
- Ziel: Modell-Diversität nutzen ohne Tool-Wechsel

## Architecture

```
┌─────────────────────────────────────────┐
│  Claude Code (User-Facing Orchestrator) │
│                                         │
│  ┌─────────────┐  ┌──────────────────┐  │
│  │ Agent Rules  │  │ Routing Config   │  │
│  │ (agents.md)  │  │ (orchestrator)   │  │
│  └──────┬──────┘  └────────┬─────────┘  │
│         │                  │            │
│  ┌──────▼──────────────────▼─────────┐  │
│  │      Orchestrator Skill           │  │
│  │  - Parse task type                │  │
│  │  - Select engine (Claude/Gemini/  │  │
│  │    Codex) based on routing rules  │  │
│  │  - Execute via Bash subprocess    │  │
│  │  - Collect & present result       │  │
│  └──────┬───────────┬───────┬────────┘  │
│         │           │       │           │
│    ┌────▼───┐ ┌─────▼──┐ ┌─▼────────┐  │
│    │ Claude │ │ Gemini │ │  Codex   │  │
│    │ Native │ │ CLI -p │ │  CLI -q  │  │
│    └────────┘ └────────┘ └──────────┘  │
└─────────────────────────────────────────┘
```

## Routing Strategy

| Task-Typ | Primary Engine | Fallback | Reasoning |
|----------|---------------|----------|-----------|
| Architecture, Specs, Complex Analysis | Claude (Opus) | — | Strongest reasoning |
| Code Implementation, Refactoring | Claude (Sonnet) | Codex | Both strong at code gen |
| Quick Fixes, Single-File Edits | Codex | Claude (Haiku) | Fast, cheap |
| Research, Web Search, Summarization | Gemini | Claude (Sonnet) | Gemini strong at search/synthesis |
| Code Review, Security Audit | Claude (Opus) | Gemini | Deep analysis needed |
| Test Writing | Codex | Claude (Sonnet) | Fast iteration |
| Documentation | Gemini | Claude (Sonnet) | Good at synthesis |

**Routing-Logik**: Konfigurierbar, nicht hardcoded. Default-Routing als Template, User kann überschreiben.

## Steps

### Step 1: CLI-Wrapper-Skripte (`templates/scripts/`)
- [x] `templates/scripts/delegate-gemini.sh` — Wrapper für `gemini -p` mit:
  - CLI-Verfügbarkeit prüfen (`command -v gemini`)
  - Timeout (default 120s, konfigurierbar via Argument)
  - Error Handling (non-zero exit → stderr message)
  - Kontext-Injection: AGENTS.md Inhalt als Prefix in den Prompt
  - Output auf stdout (für Claude Code Bash-Tool consumption)
- [x] `templates/scripts/delegate-codex.sh` — Wrapper für `codex -q` mit gleichem Pattern
- [x] Beide Skripte idempotent via `install_claude_scripts` deployen

### Step 2: Orchestrator-Skill (`templates/skills/orchestrate/`)
- [x] SKILL.md mit Trigger-Description: "use gemini for X", "use codex for X", "delegate to gemini/codex"
- [x] Skill-Logik (nur explizite Delegation, kein Auto-Routing):
  1. User sagt explizit welche Engine ("use gemini to...", "use codex to...")
  2. Engine-Verfügbarkeit prüfen via Bash
  3. Prompt an gewählte Engine senden via `scripts/delegate-*.sh`
  4. Output einsammeln und dem User präsentieren
- [x] Fallback: Engine nicht verfügbar → User informieren, nicht silent fallback
- [x] Hinweis an User: Delegierte Engine hat keinen Zugriff auf Konversationshistorie

### Step 3: Dokumentation
- [ ] AGENTS.md: Delegation-Hinweis in Commands-Sektion (1-2 Zeilen)
- [ ] WORKFLOW-GUIDE: "Multi-Agent Delegation" Absatz mit Beispielen

## Acceptance Criteria

- [ ] `"use gemini to research X"` in Claude Code → delegiert an Gemini CLI, zeigt Ergebnis
- [ ] `"use codex to write tests for X"` → delegiert an Codex CLI, zeigt Ergebnis
- [ ] Graceful Error: Wenn Engine nicht installiert → klare Fehlermeldung, kein Crash
- [ ] Kein Datenverlust: Delegierter Output wird vollständig in Claude Code angezeigt
- [ ] Funktioniert auch wenn nur Claude installiert ist (Skill ist no-op)
- [ ] Delegation ist immer explizit — niemals Auto-Routing

## Risks & Constraints

1. **Kontext-Verlust**: Delegierte Engines kennen nur AGENTS.md + den übergebenen Prompt, nicht die Claude-Konversation
2. **Read-Only Delegation**: Delegierte Engines sollten nur recherchieren/generieren, nicht Dateien editieren (Sync-Problem mit Claude)
3. **API-Keys**: Müssen im Environment sein — Skill prüft Verfügbarkeit, speichert aber nie Keys

## Out of Scope (v2)

- Auto-Routing (Claude entscheidet welche Engine)
- Kosten- und Speed-Tracking
- Integration in bestehende Skills (spec-work, test)
- Parallele Delegation an mehrere Engines
- File-Editing durch delegierte Engines
- Config-Datei für Routing-Regeln

## Files to Create

- `templates/scripts/delegate-gemini.sh` — neu
- `templates/scripts/delegate-codex.sh` — neu
- `templates/skills/orchestrate/SKILL.md` — neu
- `templates/AGENTS.md` — Delegation-Hinweis
- `.claude/WORKFLOW-GUIDE.md` — Multi-Agent Absatz
