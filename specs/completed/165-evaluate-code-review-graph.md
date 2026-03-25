# Brainstorm: code-review-graph Adaptionen für npx-ai-setup

> **Source**: https://github.com/tirth8205/code-review-graph
> **Erstellt**: 2026-03-23
> **Zweck**: Evaluierung welche Patterns aus code-review-graph adaptierbar sind

## Was ist code-review-graph?

Persistenter, inkrementell aktualisierter Knowledge Graph für token-effiziente Code Reviews. Parst Codebases via Tree-sitter (14 Sprachen), baut einen SQLite-Graph (Nodes/Edges), exponiert 9 MCP-Tools. Benchmarks: 6.8x durchschnittliche Token-Reduktion (bis 49x in Monorepos).

**Stack**: Python 3.10+, Tree-sitter, SQLite, FastMCP, NetworkX
**Distribution**: PyPI (`pip install code-review-graph`) + Claude Code Plugin
**Popularitaet**: 2.7k Stars, 237 Forks, v1.8.4

## Bestandsvergleich: Was haben wir schon?

| Externes Item | Unser Equivalent | Status |
|--------------|-----------------|--------|
| `/build-graph` Skill | — | ❌ Missing |
| `/review-delta` Skill | `/review` Command | ⚠️ Partial — unser Review hat keine Blast-Radius-Analyse |
| `/review-pr` Skill | `/review` + `/pr` Commands | ⚠️ Partial — kein Graph-basiertes Impact Mapping |
| PostToolUse Hook (auto-update) | PreToolUse/PostToolUse Hooks | ⚠️ Partial — wir haben Hooks, aber keinen Graph-Update-Trigger |
| SessionStart Hook (graph guidance) | SessionStart Hooks | ⚠️ Partial — wir haben SessionStart-Hooks, aber keine Graph-Instruktion |
| MCP Server (9 Tools) | Context7 MCP | ⚠️ Partial — Context7 liefert Docs, nicht Codebase-Graphen |
| Plugin Manifest (.claude-plugin/) | Plugin-System (lib/plugins.sh) | ✅ Covered — wir installieren Plugins bereits |
| Tree-sitter AST Parsing | — | ❌ Missing (nicht unser Scope) |
| SQLite Knowledge Graph | — | ❌ Missing (nicht unser Scope) |
| Blast-Radius-Analyse | — | ❌ Missing |
| Semantic Search | — | ❌ Missing |

## Kandidaten fuer Adaption

### 1. Plugin-Integration: code-review-graph als optionalen Plugin anbieten

**Was**: code-review-graph als Plugin in `lib/plugins.sh` aufnehmen, aehnlich wie claude-mem oder coderabbit.
**Unser Gap**: Wir bieten kein Graph-basiertes Code-Review-Tool an.
**Aufwand**: Klein (1 Funktion in plugins.sh, Marketplace-Install-Befehl)
**Empfehlung**: ★★★★★ — Sofort umsetzbar, hoher Mehrwert fuer groessere Projekte

### 2. SessionStart Hook: Graph-Awareness

**Was**: Beim Session-Start pruefen ob `.code-review-graph/graph.db` existiert und Claude instruieren, MCP-Tools vor manuellen Scans zu bevorzugen.
**Unser Gap**: Unsere SessionStart-Hooks kennen code-review-graph nicht.
**Aufwand**: Minimal (Conditional in bestehenden Hook oder neuen Hook)
**Empfehlung**: ★★★★☆ — Nur relevant wenn Plugin installiert, aber gutes UX-Pattern

### 3. PostToolUse Hook: Inkrementelle Graph-Updates

**Was**: Nach Write/Edit/Bash automatisch `code-review-graph update` ausfuehren.
**Unser Gap**: Wir haben PostToolUse-Hooks, aber keinen Graph-Update-Trigger.
**Aufwand**: Minimal (1 Hook-Eintrag)
**Empfehlung**: ★★★★☆ — Haelt Graph aktuell ohne manuellen Aufwand

### 4. Review-Command Erweiterung: Blast-Radius-Analyse

**Was**: Unser `/review` Command um optionale Blast-Radius-Analyse erweitern wenn code-review-graph verfuegbar ist.
**Unser Gap**: Unser Review analysiert nur die geaenderten Dateien, nicht deren Abhaengigkeiten.
**Aufwand**: Mittel (Review-Command-Template anpassen, conditional MCP-Tool-Nutzung)
**Empfehlung**: ★★★☆☆ — Wertvoll, aber abhaengig von Plugin-Installation

### 5. Structured Review Output Pattern

**Was**: code-review-graph's `review-delta` definiert ein klares Output-Format: Summary → Risk Level → Issues → Blast Radius → Recommendations.
**Unser Gap**: Unser `/review` hat Intensitaetsstufen (Quick/Standard/Adversarial) aber kein standardisiertes Risk-Level-Rating.
**Aufwand**: Klein (Template-Anpassung)
**Empfehlung**: ★★★☆☆ — Verbessert Konsistenz der Review-Outputs

## Einzelne Saetze/Patterns zum Adaptieren

### Aus dem SessionStart Hook:
```
"prefer using the code-review-graph MCP tools before scanning files manually"
```
**Adaptierbar als**: Generisches Pattern — wenn ein MCP-Tool existiert, zuerst MCP nutzen, dann Fallback auf Grep/Glob/Read. Koennte in unsere `general.md` Rule als generische MCP-First-Strategie.

### Aus review-delta SKILL.md:
```
"Risk Level — Low/Medium/High classification"
```
**Adaptierbar als**: Standardisiertes Risk-Level in unserem `/review` Output. Aktuell fehlt eine explizite Risikoklassifikation.

### Aus dem PostToolUse Hook:
```json
"matcher": "Write|Edit|Bash"
```
**Adaptierbar als**: Pattern fuer bedingte Post-Tool-Hooks — reagiere nur auf datei-aendernde Tools. Wir koennten aehnliche Trigger fuer andere Post-Tool-Aktionen nutzen.

### Aus CLAUDE.md Security Invariants:
```
"_sanitize_name() strips control characters, caps at 256 chars (prompt injection defense)"
```
**Adaptierbar als**: Security-Pattern fuer MCP-Tool-Outputs. Wenn wir eigene MCP-Server entwickeln, ist Input-Sanitization gegen Prompt Injection ein Muss.

## Architektur-Patterns

### 1. Plugin als MCP-Server-Bundle
code-review-graph buendelt MCP-Server + Hooks + Skills in einem Plugin-Paket. Das ist ein sauberes Distributionsmodell: ein `plugin.json` definiert alles, Claude Code installiert alles auf einmal. **Wir nutzen dieses Pattern bereits** mit unserer Plugin-Installation.

### 2. Graph-before-Search Paradigma
Die zentrale Idee: bevor Claude den Codebase manuell durchsucht, zuerst den vorberechneten Graphen abfragen. Das spart massiv Tokens. **Dieses Pattern koennten wir als generische Rule formulieren**: "Wenn ein MCP-Server Codebase-Wissen anbietet, nutze es vor manuellen Scans."

### 3. Inkrementelle Aktualisierung via Hooks
Statt den Graphen manuell neu zu bauen, wird er automatisch bei jeder Datei-Aenderung aktualisiert. **Wir koennten aehnliche Patterns fuer andere Tools anbieten** (z.B. Kontext-Dateien automatisch aktualisieren nach groesseren Aenderungen).

## Gesamtranking nach Aufwand/Nutzen

| # | Item | Value | Aufwand | Empfehlung |
|---|------|-------|---------|------------|
| 1 | Plugin-Integration in plugins.sh | ★★★★★ | Klein | **Umsetzen** — einfachste Integration, groesster Hebel |
| 2 | SessionStart Hook fuer Graph-Awareness | ★★★★☆ | Minimal | **Umsetzen** — Teil der Plugin-Integration |
| 3 | PostToolUse Hook fuer Graph-Updates | ★★★★☆ | Minimal | **Umsetzen** — Teil der Plugin-Integration |
| 4 | "MCP-First" Rule in general.md | ★★★☆☆ | Minimal | **Umsetzen** — generisch nuetzlich |
| 5 | Risk-Level im Review Output | ★★★☆☆ | Klein | **Evaluieren** — sinnvoll, aber nicht dringend |
| 6 | Review Blast-Radius-Erweiterung | ★★★☆☆ | Mittel | **Spaeter** — abhaengig von Plugin-Verbreitung |

## Nicht adaptieren

- **Tree-sitter Parsing / SQLite Graph**: Nicht unser Scope. Wir sind ein Setup-Tool, kein Code-Analyse-Tool.
- **VS Code Extension**: Anderer Kanal, nicht relevant fuer CLI-basiertes Setup.
- **Python-basierte Architektur**: Unser Stack ist Bash, eine Python-Dependency waere ein Bruch.
