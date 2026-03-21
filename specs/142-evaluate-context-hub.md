# Brainstorm: Context Hub Adaptionen für npx-ai-setup

> **Source**: https://github.com/andrewyng/context-hub
> **Erstellt**: 2026-03-22
> **Zweck**: Evaluierung welche Patterns aus andrewyng/context-hub adaptierbar sind
> **Status**: complete

## Was ist Context Hub?

CLI-Tool (`@aisuite/chub`) für Coding-Agents — liefert LLM-optimierte Dokumentation und Skills on-demand.
300+ kuratierte Library-Docs (React, FastAPI, pandas, etc.), durchsuchbar via BM25 Full-Text-Search.
Hat auch einen eingebauten MCP-Server (`chub-mcp`).

**Kernfeatures:**
- 7 CLI-Befehle: `search`, `get`, `annotate`, `feedback`, `update`, `cache`, `build`
- Multi-Source Registry (official + community + private)
- Language-spezifische Doc-Varianten (Python, JS, TS, Ruby, C#)
- Persistent Annotations (User-Notizen zu Docs)
- Feedback-System (Docs bewerten)
- Agent-Detection (erkennt Claude Code, Cursor, Windsurf, Copilot)
- Graceful Degradation (Netzwerk-Ausfälle blocken CLI nicht)
- BYOD (Bring Your Own Docs) für private/interne Inhalte

---

## Bestandsvergleich: Was haben wir schon?

| Context Hub Feature | Unser Äquivalent | Status |
|---|---|---|
| `chub search` — Docs durchsuchen | Context7 MCP für Library-Docs | ⚠️ Partial — Context7 liefert Docs, aber kein lokales Caching |
| `chub get` — Docs abrufen | Context7 `resolve-library-id` + `get-library-docs` | ⚠️ Partial — kein Offline-Fallback |
| `chub annotate` — User-Notizen | claude-mem MCP (Observations) | ✅ Covered — claude-mem ist mächtiger |
| `chub feedback` — Docs bewerten | Kein Äquivalent | ❌ Missing |
| `chub build` — Registry generieren | Kein Äquivalent | ❌ Missing |
| `chub update` — Registry refreshen | Kein Äquivalent (Context7 ist live) | ⚠️ Partial |
| `chub cache` — Cache-Management | Kein Äquivalent | ❌ Missing |
| MCP-Server (`chub-mcp`) | Context7 MCP | ⚠️ Partial — unterschiedliche Doc-Quellen |
| Multi-Source Registry | Plugin-System (`lib/plugins.sh`) | ⚠️ Partial — Plugins, aber keine Doc-Registry |
| Agent Detection | Kein Äquivalent | ❌ Missing |
| BM25 Full-Text Search | Grep/Glob (kein semantischer Index) | ❌ Missing (aber weniger relevant) |
| BYOD (Private Docs) | `.agents/context/` Dateien | ⚠️ Partial — nur projektspezifisch |
| Graceful Degradation | Offline-fähig (pure bash, keine Netzwerk-Deps) | ✅ Covered — besser sogar |
| Content Frontmatter Standard | Eigenes Frontmatter in Agents/Specs | ⚠️ Partial |

---

## Kandidaten für Adaption

### 1. ★★★★★ chub als MCP-Server in Setup integrieren
**Was:** `chub-mcp` als zusätzlichen MCP-Server in `settings.json` aufnehmen
**Unser Gap:** Context7 liefert Docs, aber chub hat 300+ kuratierte, LLM-optimierte Docs mit Offline-Cache
**Aufwand:** Klein — MCP-Server-Eintrag in Template + `npx @aisuite/chub` als Dependency
**Empfehlung:** Sofort umsetzen. Komplementär zu Context7, nicht konkurrierend.

### 2. ★★★★☆ Stack-aware Doc Pre-fetching
**Was:** Bei `npx @onedot/ai-setup` automatisch `chub get` für erkannte Stack-Technologien ausführen
**Unser Gap:** Wir erkennen den Stack (STACK.md), nutzen ihn aber nicht für Doc-Delivery
**Aufwand:** Mittel — Stack-Detection → chub-Mapping → Prefetch in Setup-Script
**Empfehlung:** Hoher Wert. Developer hat sofort relevante Docs offline.

### 3. ★★★☆☆ Feedback-Loop für Skills/Commands
**Was:** Rating-System für installierte Skills/Commands (up/down + Kommentar)
**Unser Gap:** Kein Mechanismus um Qualität von Skills zu tracken
**Aufwand:** Mittel — Neues Command + Persistenz in `.claude/feedback/`
**Empfehlung:** Langfristig wertvoll, aber nicht dringend.

### 4. ★★★☆☆ BYOD / Private Doc Registry
**Was:** `chub build` für interne Firmen-Docs nutzen (eigene Registry erstellen)
**Unser Gap:** Kein standardisierter Weg für firmeninterne API-Docs in Claude Code
**Aufwand:** Mittel — Integration in Plugin-System, BYOD-Template
**Empfehlung:** Sehr relevant für Agentur-Kontext (one-dot.de Client-APIs).

### 5. ★★☆☆☆ Agent Detection Pattern
**Was:** Erkennen welcher AI-Agent (Claude Code, Cursor, etc.) das Tool nutzt
**Unser Gap:** Wir sind Claude-Code-only, aber Erkennung könnte Stack-Detection ergänzen
**Aufwand:** Klein — Environment-Variable-Check
**Empfehlung:** Niedrige Priorität. Wir sind bewusst Claude-Code-fokussiert.

---

## Einzelne Patterns zum Adaptieren

### Aus `cli/src/lib/cache.js`:
- **Multi-Tier Fallback Chain**: `local → cache → bundled → CDN` — Robust gegen Netzwerk-Ausfälle
- Relevant für: Unsere Plugin-Installation (aktuell nur GitHub-Download, kein Fallback)

### Aus `cli/src/lib/identity.js`:
- **Agent Detection via Environment**: Prüft `CLAUDE_CODE`, `CURSOR_SESSION`, `WINDSURF_SESSION` etc.
- Relevant für: Könnte in Setup-Script helfen, um Agent-spezifische Configs zu generieren

### Aus `cli/src/lib/config.js`:
- **YAML Config mit Defaults-Merge**: Sauberes Pattern für User-Config + Defaults
- Relevant für: Unser `settings.json` Merge-Verhalten

### Aus `docs/design.md`:
- **Three-Layer Architecture**: Content → Registry → CLI — saubere Trennung
- Relevant für: Unser Plugin-System könnte ähnlich strukturiert werden

---

## Architektur-Patterns

### Multi-Source Registry
Context Hub erlaubt mehrere Quellen in `~/.chub/config.yaml`:
```yaml
sources:
  - name: official
    url: https://cdn.aichub.org/v1
  - name: internal
    url: https://docs.company.com/chub
```
**Adaptierbar für:** Unser Plugin-System — aktuell nur GitHub-Repos, könnte auch lokale/private Registries unterstützen.

### Content-as-Code mit Frontmatter
Jedes Doc/Skill hat standardisiertes YAML-Frontmatter:
```yaml
name: react
description: React documentation for AI agents
metadata:
  languages: "javascript,typescript"
  versions: "19.0.0,18.3.1"
  source: official
  tags: "frontend,ui,components"
```
**Adaptierbar für:** Konsistenteres Frontmatter in unseren Agent/Command-Templates.

---

## Gesamtranking nach Aufwand/Nutzen

| # | Item | Value | Aufwand | Empfehlung |
|---|---|---|---|---|
| 1 | chub-mcp als MCP-Server integrieren | ★★★★★ | Klein | **Sofort umsetzen** |
| 2 | Stack-aware Doc Pre-fetching | ★★★★☆ | Mittel | **Spec erstellen** |
| 3 | BYOD / Private Doc Registry | ★★★☆☆ | Mittel | Evaluieren für Agentur-Use-Case |
| 4 | Feedback-Loop für Skills | ★★★☆☆ | Mittel | Backlog |
| 5 | Multi-Source Plugin Registry | ★★☆☆☆ | Groß | Langfristig |
| 6 | Agent Detection | ★★☆☆☆ | Klein | Nice-to-have |
| 7 | Fallback Chain für Plugin-Downloads | ★★☆☆☆ | Mittel | Backlog |
