# Spec 168: Transcript Auto-Ingestion (Stop Hook)

> **Status**: In-Progress
> **Source**: [OpenViking Research](specs/166-research-openviking.md)
> **Goal**: Automatische Extraktion von Learnings/Decisions aus Claude-Transkripten nach jeder Session.

## Context

OpenVikings `stop.sh` Hook parst nach jeder Claude-Antwort das Transkript und extrahiert relevante Informationen. Aktuell haben wir `/reflect` und `/pause` als manuelle Skills — Erkenntnisse gehen verloren wenn der User vergisst sie zu nutzen. Der Hook soll async (fire-and-forget) laufen und sowohl claude-mem als auch Auto-Memory unterstützen.

## Steps

- [x] 1. Hook-Script `transcript-ingest.sh` erstellen: Triggert auf `Stop` Event. Prüft ob Session lang genug war (>10 Nachrichten)
- [x] 2. Haiku summarization integriert: Extrahiert Entscheidungen, Bugfixes, Patterns. Integriert in Hook (kein separates Bridge-Script nötig)
- [x] 3. Backend-Detection: claude-mem MCP check → Fallback .agents/memory/ → skip. Inkl. memory size limits (50 files, 200KB)
- [x] 4. Template-Version erstellt in `templates/claude/hooks/transcript-ingest.sh`
- [x] 5. settings.json aktualisiert: Stop Hook registriert (timeout: 120s)
- [ ] 6. Testen: 3 Sessions durchführen, prüfen ob sinnvolle Learnings extrahiert werden

## Acceptance Criteria

- Hook läuft async — blockiert Claude-Antworten nicht
- Nur bei substantiellen Sessions (>10 Nachrichten)
- Fallback: claude-mem → Auto-Memory → skip (graceful degradation)
- Extrahierte Learnings sind tatsächlich nützlich (kein Noise)
- Kein Token-Overhead in der laufenden Session

## Files to Modify

- `templates/claude/hooks/transcript-ingest.sh` (neu)
- `templates/claude/hooks/transcript-bridge.sh` oder `.py` (neu)
- `templates/claude/settings.json` (Hook registrieren)
- `.claude/hooks/` (aktive Installation)
