# Brainstorm: claude-peers-mcp Adaptionen für npx-ai-setup

> **Source**: https://github.com/louislva/claude-peers-mcp
> **Erstellt**: 2026-03-26
> **Zweck**: Research ob Inter-Session-Kommunikation zwischen Claude Code Instanzen adaptierbar ist
> **Status**: ✅ Completed — lokal installiert, kein Plugin fuer ai-setup

## Was ist claude-peers-mcp?

MCP-Server, der Claude Code Instanzen auf derselben Maschine verknüpft. Ein Broker-Daemon (localhost:7899, SQLite) registriert jede Session als "Peer" mit cwd, git_root, TTY und Work-Summary. Sessions können sich gegenseitig finden (`list_peers`), Nachrichten senden (`send_message`) und per claude/channel-Protokoll sofort empfangen.

**Stack**: TypeScript, Bun, @modelcontextprotocol/sdk, SQLite (bun:sqlite)
**Architektur**: Broker (Singleton) + N MCP-Server (je Session) + CLI-Tool
**Voraussetzungen**: Bun, Claude Code v2.1.80+, `--dangerously-skip-permissions`, `--dangerously-load-development-channels`

## Bestandsvergleich

| claude-peers Feature | Unser Equivalent | Status |
|---------------------|------------------|--------|
| Peer Discovery (list_peers) | Keine | ❌ Missing |
| Inter-Session Messaging (send_message) | Keine | ❌ Missing |
| Work Summary Broadcasting (set_summary) | claude-mem Observations (async, nicht real-time) | ⚠️ Partial |
| Channel Push (instant delivery) | Keine | ❌ Missing |
| CLI Management (status, peers, send) | Keine | ❌ Missing |
| Auto-Summary (OpenAI gpt-5.4-nano) | Keine | ❌ Missing |
| Subagent Coordination | Agent Teams (CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS) | ✅ Covered (anderer Scope) |

**Kernunterschied**: Wir koordinieren Agents *innerhalb* einer Session (Agent Teams, Subagents). claude-peers koordiniert *zwischen* Sessions auf derselben Maschine.

## Kandidaten fuer Adaption

### K1: Inter-Session Peer Discovery & Messaging

**Was es tut**: Jede Claude-Session registriert sich beim Broker mit Kontext (Verzeichnis, Git-Repo, Branch). Andere Sessions koennen Peers finden und direkt Nachrichten schicken.

**Use Cases**:
- Session A arbeitet am Backend, fragt Session B (Frontend) nach dem API-Contract
- Session in Projekt X fragt Session in Projekt Y nach einer shared Library-Aenderung
- Monitoring-Session beobachtet alle aktiven Arbeitsstreams

**Unsere Luecke**: Komplett. Wir haben null Inter-Session-Kommunikation. claude-mem ist async (write/read), nicht real-time (send/receive).

**Aufwand**: Mittel-Hoch. MCP-Server + Broker-Daemon + Channel-Integration
**Wert**: ★★★ (Multi-Projekt-Workflows sind ein realer Use Case bei Denis mit 5+ parallelen Sessions)

### K2: Work Summary Broadcasting

**Was es tut**: Jede Session beschreibt automatisch woran sie arbeitet. Andere Sessions sehen das bei `list_peers`.

**Unsere Luecke**: claude-mem speichert Observations, aber nicht als Live-Status sichtbar fuer andere Sessions.

**Aufwand**: Niedrig (wenn K1 implementiert)
**Wert**: ★★ (Ueberblick ueber parallele Arbeit)

### K3: CLI fuer Session-Management

**Was es tut**: `bun cli.ts status/peers/send/kill-broker` - Session-Ueberblick und Messaging von der Kommandozeile.

**Unsere Luecke**: Kein CLI fuer Session-Ueberblick. `/pause` + `/resume` sind single-session.

**Aufwand**: Niedrig (wenn Broker existiert)
**Wert**: ★★ (Operational Awareness)

## Architektur-Patterns

### Broker-Daemon Pattern
- Singleton-Prozess, auto-launched beim ersten Connect
- SQLite fuer State (Peers + Messages)
- HTTP-API, prepared statements, 30s stale-cleanup
- **Bewertung**: Robust, simpel, kein externer Service noetig

### Channel Protocol
- `--dangerously-load-development-channels` ermoeglicht Push-Nachrichten in Sessions
- Nachrichten erscheinen sofort im Kontext
- **Bewertung**: Maechtig, aber "dangerously" im Flag-Namen signalisiert Instabilitaet

### Auto-Summary via External LLM
- Nutzt OpenAI gpt-5.4-nano fuer Zusammenfassungen
- **Bewertung**: Unnoetiger externer Dependency. Claude kann das selbst via `set_summary` Tool.

## Kritische Bewertung

### Sicherheitsbedenken
1. **`--dangerously-skip-permissions`** - Pflicht fuer Channel-Mode. Entfernt ALLE Permission-Checks. Das widerspricht fundamental unserer Safety-First-Philosophie.
2. **`--dangerously-load-development-channels`** - "Development" im Namen = nicht production-ready
3. **Localhost HTTP ohne Auth** - Jeder Prozess auf der Maschine kann Messages an Claude-Sessions senden
4. **Prompt Injection Vector** - Eine kompromittierte Session kann Messages an andere senden, die als "Peer-Nachrichten" vertraut werden

### Technische Bedenken
1. **Bun-Dependency** - Wir setzen auf Node/npm. Bun waere eine neue Runtime-Dependency.
2. **Channel API Stabilitaet** - "dangerously" Flags deuten auf experimentellen Status
3. **SQLite Lock Contention** - Bei vielen parallelen Sessions moeglich
4. **Kein Auth/Authz** - Kein Mechanismus um zu kontrollieren wer wem Nachrichten schickt

### Token-Oekonomie
- MCP-Server registriert 4 Tools = ~800 Tokens pro Request zusaetzlich
- Messages im Channel erhoehen den Kontext jeder empfangenden Session
- Kein Mechanismus um Message-Volume zu begrenzen

## Gesamtranking

| # | Kandidat | Wert | Aufwand | Sicherheit | Empfehlung |
|---|----------|------|---------|------------|------------|
| K1 | Peer Discovery & Messaging | ★★★ | Hoch | 🔴 Kritisch | WAIT - Channel API muss stable werden |
| K2 | Work Summary Broadcasting | ★★ | Niedrig | 🟡 Mittel | WAIT - haengt von K1 ab |
| K3 | CLI Session-Management | ★★ | Niedrig | 🟢 OK | PIVOT - als standalone ohne Messaging moeglich |

## Fazit

claude-peers loest ein echtes Problem (Multi-Session-Koordination), aber die aktuelle Implementierung basiert auf experimentellen APIs (`--dangerously-*` Flags) und hat keine Sicherheitsgrenzen. Fuer ein Setup-Tool, das Safety-First propagiert, ist die direkte Adaption derzeit nicht empfehlenswert.

**Update 2026-03-26**: Auto-Mode ersetzt `--dangerously-skip-permissions` mit einem Classifier. Agent Teams (built-in, experimentell) decken 80% der Koordinations-Use-Cases ab. claude-peers bleibt relevant fuer Cross-Projekt-Discovery zwischen unabhaengigen Sessions.

**Lokal installiert**: `~/claude-peers-mcp/` — MCP-Server global registriert in `~/.claude.json` (scope: user). Kein Plugin in ai-setup, nur lokales Setup fuer Denis.
