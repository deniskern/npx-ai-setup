# Spec 169: Memory-Recall Injection (UserPromptSubmit Hook)

> **Status**: In-Progress
> **Source**: [OpenViking Research](specs/166-research-openviking.md)
> **Goal**: Relevante Memories automatisch als Context injizieren wenn der User einen Prompt eingibt.

## Context

OpenVikings `user-prompt-submit.sh` prüft den Prompt und injiziert relevante Memories als `additionalContext`. Aktuell injiziert unser `context-reinforcement.sh` nur CLAUDE.md-Inhalte — keine semantische Memory-Suche basierend auf dem Prompt. Der Hook soll claude-mem (semantische Suche) bevorzugen und auf Auto-Memory (Datei-basiert) fallen.

## Steps

- [x] 1. Hook-Script `memory-recall.sh` erstellen: Triggert auf `UserPromptSubmit`. Guards: ≥15 Zeichen, keine Slash-Commands, keine kurzen Bestätigungen
- [x] 2. claude-mem Integration: Erkennt claude-mem in .mcp.json → gibt Hint als additionalContext statt selbst zu suchen (MCP-Tools direkt von Claude nutzbar)
- [x] 3. Auto-Memory Fallback: Keyword-Extraktion → grep durch .agents/memory/ → Top-Matches als Context (max 20 Dateien, neueste zuerst)
- [x] 4. Token-Budget: MAX_CONTEXT_CHARS=2000 (~500 Tokens). Bricht ab wenn Budget erreicht
- [x] 5. Template-Version erstellt in `templates/claude/hooks/memory-recall.sh`
- [x] 6. settings.json aktualisiert: UserPromptSubmit Hook registriert (timeout: 2s)
- [ ] 7. Testen: Prompts mit bekannten Memory-Themen → prüfen ob relevante Memories injiziert werden

## Acceptance Criteria

- Hook läuft in <2s (blockiert Prompt-Verarbeitung)
- Nur relevante Memories injiziert (Precision > Recall)
- Max 500 Tokens zusätzlicher Context
- Graceful degradation: claude-mem → Auto-Memory → skip
- Keine Injection bei kurzen Prompts oder Slash-Commands

## Files to Modify

- `templates/claude/hooks/memory-recall.sh` (neu)
- `templates/claude/settings.json` (Hook registrieren)
- `.claude/hooks/` (aktive Installation)
