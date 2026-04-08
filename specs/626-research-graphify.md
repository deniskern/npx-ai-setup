# Brainstorm: Graphify Adaptionen fuer npx-ai-setup

> **Source**: https://github.com/safishamsi/graphify
> **Erstellt**: 2026-04-08
> **Zweck**: Research welche Patterns aus Graphify adaptierbar sind
> **Status**: COMPLETE
> **Ergebnis**: Eigenes Lightweight graph.json (Spec 627). Graphify als Referenz-Architektur, nicht als Dependency.
> **Entscheidung**: Graphify fuer Graph-Layer, Repowise fuer Intelligence-Layer (complementary, nicht competing)

## Was ist Graphify?

Graphify ist ein AST-basierter Knowledge-Graph-Builder fuer Codebasen (7.5k Stars, MIT, Python).
Pipeline: `detect()` -> `extract()` -> `build_graph()` -> `cluster()` -> `analyze()` -> `report()` -> `export()`.
Unterstuetzt 19 Sprachen via tree-sitter. Kein LLM fuer Code-Extraktion (deterministic AST), LLM nur fuer Docs/Papers/Images.

Kernkonzept: Statt rohe Dateien in den Context zu laden, baut Graphify einen persistenten Graph (graph.json) und beantwortet Queries dagegen. Claimed 71.5x Token-Reduktion auf realen Repos (Karpathy).

## Inventar

```
GRAPHIFY: 12 Python-Module, 1 Skill (5 Plattform-Varianten), 1 MCP Server, 1 CI Workflow, 367 Tests
OURS:     20 Commands, 11 Agents, 34 Skills, 8 Rules, 23 Hooks
```

## Bestandsvergleich: Was haben wir schon?

| Graphify Feature | Unser Equivalent | Status |
|-----------------|------------------|--------|
| Graph-basierte Code-Navigation | `/analyze` + ARCHITECTURE.md | ⚠️ Partial |
| MCP Server fuer Graph-Queries | Kein MCP fuer Codestruktur | ❌ Missing |
| PreToolUse Hook (Graph surfacing) | `context-loader` Hook | ⚠️ Partial |
| God Nodes Analyse | `/analyze` via Agents | ⚠️ Partial |
| Community Detection (Clustering) | Nicht vorhanden | ❌ Missing |
| Token Benchmarking | `session-optimize` Skill | ⚠️ Partial |
| Incremental Caching (SHA256) | Checksum-based dedup in `pull` | ⚠️ Partial |
| Multi-Format Export (HTML, Obsidian, Neo4j) | Nicht vorhanden | ❌ Missing |
| Git Post-Commit Hook (auto-rebuild) | `post-edit-lint` Hook | ⚠️ Partial |
| `.graphifyignore` Support | `.gitignore` (implicit) | ✅ Covered |
| Security (SSRF, Path Traversal) | `security-reviewer` Agent | ✅ Covered |
| 19-Sprachen AST Parsing | Nicht vorhanden (LLM-basiert) | ❌ Missing |
| Confidence-tagged Edges | Nicht vorhanden | ❌ Missing |
| Watch Mode (auto-sync) | Nicht vorhanden | ❌ Missing |
| Obsidian Vault Export | Nicht vorhanden | ❌ Missing |

## Kandidaten fuer Adaption

### 1. Graph-basiertes Codebase-Verstaendnis (statt reine LLM-Analyse)

**Was Graphify macht**: AST-Extraktion baut einen persistenten `graph.json` mit allen Funktionen, Klassen, Imports, Call-Chains. Folgende Queries laufen gegen diesen Graph statt gegen rohe Dateien:
- "Was haengt von X ab?"
- "Kuerzester Pfad zwischen A und B?"
- "God Nodes (hoechste Kopplung)?"

**Unsere Luecke**: `/analyze` spawnt Agents die Dateien lesen und Freitext-Zusammenfassungen schreiben (ARCHITECTURE.md). Kein queryable Datenmodell. Jede Session liest dieselben Dateien neu.

**Aufwand**: Hoch — erfordert Python-Dependency oder eigene JS/TS-Implementierung.
**Wert**: Hoch fuer grosse Projekte (>100 Dateien). Fuer kleinere Projekte (wie unsere Kundenprojekte, 20-50 Dateien) ueberproportionaler Overhead.

### 2. GRAPH_REPORT.md als Context-Priming

**Was Graphify macht**: Generiert ein 1-Seiten Summary mit God Nodes, Surprising Connections, Suggested Questions, Community-Struktur. PreToolUse Hook surfaced diesen Report bevor Glob/Grep ausgefuehrt werden — Claude navigiert per Graph statt Keyword-Suche.

**Unsere Luecke**: Unser `context-loader` Hook laedt L0-Abstracts aus .agents/context/ — aber keine strukturelle Analyse (welche Module am staerksten gekoppelt sind, welche Edges ueberraschend sind).

**Aufwand**: Mittel — koennte als optionale Erweiterung von `/analyze` gebaut werden.
**Wert**: Mittel — wuerde die Navigation in fremden Codebases verbessern, aber fuer eigene Projekte (die man kennt) marginaler Nutzen.

### 3. Confidence-tagged Relationships

**Was Graphify macht**: Jede Edge hat `confidence: EXTRACTED | INFERRED | AMBIGUOUS` mit Score 0.0-1.0.
- `EXTRACTED`: Direkt im Source gefunden (imports, calls)
- `INFERRED`: Abgeleitet (call-graph analysis, co-occurrence)
- `AMBIGUOUS`: Unsicher, zur Review markiert

**Unsere Luecke**: Unsere Agents liefern Freitext-Reviews mit HIGH/MEDIUM Confidence — aber kein formales Schema. Kein maschinenlesbares Confidence-Modell.

**Aufwand**: Niedrig — Pattern koennte in Agent-Output-Formate uebernommen werden.
**Wert**: Niedrig — unsere Agents reviewen Code, nicht Graphen. Das Pattern passt semantisch nicht 1:1.

### 4. Token Benchmarking (Subgraph vs. Full Corpus)

**Was Graphify macht**: `benchmark.py` misst Token-Reduktion: "Graph-Query brauchte X Tokens vs. voller Corpus haette Y Tokens gebraucht." Karpathy-Repos: 71.5x Reduktion.

**Unsere Luecke**: `session-optimize` analysiert Session-JSONL, aber misst nicht den Unterschied zwischen "mit Context-Priming" und "ohne".

**Aufwand**: Niedrig — als Erweiterung von `session-optimize`.
**Wert**: Mittel — wuerde den ROI unseres Context-Loading-Systems quantifizierbar machen.

### 5. MCP Server fuer Code-Struktur

**Was Graphify macht**: `serve.py` startet einen MCP stdio Server mit Tools: `query_graph`, `get_node`, `get_neighbors`, `shortest_path`, `god_nodes`. Claude kann den Graphen interaktiv abfragen.

**Unsere Luecke**: Wir haben keinen MCP Server fuer Codebase-Struktur. Claude muss Dateien lesen um die Architektur zu verstehen.

**Aufwand**: Hoch — braucht zuerst den Graphen (Kandidat 1).
**Wert**: Hoch — wuerde den Context-Window-Verbrauch drastisch senken.

### 6. Watch Mode (Auto-Rebuild bei Aenderungen)

**Was Graphify macht**: `watch.py` nutzt `watchdog` um Datei-Aenderungen zu erkennen. AST-Extraktion laueft automatisch (kein LLM), Flag-File signalisiert "Graph outdated".

**Unsere Luecke**: `context-freshness.sh` checkt ob `package.json` oder git HEAD geaendert wurde — aber reagiert nicht automatisch, sondern warnt nur.

**Aufwand**: Niedrig — als Hook oder Background-Prozess.
**Wert**: Niedrig — unsere Context-Files aendern sich selten genug dass manuelles `/context-refresh` reicht.

## Einzelne Saetze/Patterns zum Adaptieren

1. **"Suggested Questions"** aus `analyze.py`:
   > Generate 7 question types: ambiguous edges, bridge nodes, uncertain god nodes, isolates, low-cohesion communities.
   Unser `/analyze` liefert keine actionable Questions — nur Beschreibungen. Questions wuerden den Output nützlicher machen.

2. **"graph_diff()"** fuer Delta-Analyse:
   > Compare two graph snapshots to show what changed structurally.
   Koennte als Erweiterung von `/review` dienen — nicht nur "welche Zeilen aenderten sich" sondern "welche Abhaengigkeiten aenderten sich".

3. **Lazy-Loading via `__getattr__`** in `__init__.py`:
   > Heavy deps loaded only when accessed, not on import.
   Pattern fuer unsere Shell-Scripts: Sourcing von lib/ Dateien nur bei Bedarf statt global.

4. **"Corpus Health Check"** aus `detect.py`:
   > Warns when corpus is <50k words (unnecessary) or >500k words (expensive).
   Unser `/doctor` koennte eine aehnliche Check haben: "Projekt hat X Dateien, Context-Generation wird Y Tokens kosten."

5. **3-Layer Node Deduplication** aus `build.py`:
   > Within-file (AST seen_ids), between-file (NetworkX idempotent add_node), semantic merge (explicit seen set).
   Systematic dedup-pattern, relevant wenn wir eigene Indexierung bauen.

## Architektur-Patterns

### Deterministic-First, LLM-Second
Graphify's Kernprinzip: AST-Parsing ist deterministisch (tree-sitter), kostet keine Tokens, liefert praezise Ergebnisse. LLM kommt nur fuer non-code Content (Docs, Papers, Bilder). Das spart massiv Tokens und macht Ergebnisse reproduzierbar.

**Relevanz fuer uns**: Unser `/analyze` ist vollstaendig LLM-basiert — Agents lesen Dateien und schreiben Zusammenfassungen. Ein deterministischer Vorverarbeitungsschritt (z.B. einfaches AST-basiertes Dependency-Mapping via tree-sitter WASM) koennte den Token-Verbrauch senken und Ergebnisse stabiler machen.

### Self-Installing Skill Pattern
`graphify claude install` schreibt eine CLAUDE.md-Sektion und einen PreToolUse Hook in `settings.json`. Das Projekt braucht keine vorkonfigurierte `.claude/` Struktur — die Skill installiert sich selbst.

**Relevanz fuer uns**: Wir machen das Gegenteil — Template-basierte Installation. Graphify's Ansatz ist interessant fuer externe Tool-Integration: ein Tool das sich selbst in die Claude Code Config einklinkt.

### Persistent Queryable Artifact
Statt jede Session bei Null anzufangen, baut Graphify ein persistentes Artefakt (graph.json) das ueber Sessions hinweg queryable ist. MCP Server macht es direkt zugreifbar.

**Relevanz fuer uns**: Unser ARCHITECTURE.md ist semi-persistent (wird bei `/context-refresh` ueberschrieben), aber nicht queryable. Ein maschinenlesbares Format (JSON) wuerde es ermoeglichen, spezifische Fragen zu beantworten ohne den ganzen Context zu laden.

## Gesamtranking nach Aufwand/Nutzen

| # | Kandidat | Wert | Aufwand | Empfehlung |
|---|----------|------|---------|------------|
| 1 | Suggested Questions in /analyze | ★★★ | Niedrig | **ADOPT** — einfache Erweiterung, sofort nuetzlich |
| 2 | Token Benchmark (Context ROI) | ★★☆ | Niedrig | **ADOPT** — quantifiziert Context-Loading-Nutzen |
| 3 | Corpus Health Check in /doctor | ★★☆ | Niedrig | **ADOPT** — warnt vor zu grossen/kleinen Projekten |
| 4 | GRAPH_REPORT.md als Context-Priming | ★★★ | Mittel | **EVALUATE** — braucht eigenes Graph-Building |
| 5 | graph_diff() fuer /review | ★★☆ | Mittel | **EVALUATE** — strukturelles Delta statt Zeilen-Delta |
| 6 | MCP Server fuer Codestruktur | ★★★ | Hoch | **DEFER** — abhaengig von Graph-Building |
| 7 | Graph-basiertes Codebase-Verstaendnis | ★★★ | Hoch | **DEFER** — grosses Unterfangen, unklar ob ROI fuer unsere Projektgroessen |
| 8 | Watch Mode | ★☆☆ | Niedrig | **SKIP** — manuelles Refresh reicht |
| 9 | Confidence-tagged Edges | ★☆☆ | Niedrig | **SKIP** — passt nicht zu unserem Review-Modell |
| 10 | Obsidian Vault Export | ★☆☆ | Mittel | **SKIP** — kein Bedarf |

## Strategische Einschaetzung

Graphify loest ein echtes Problem: Token-Effizienz bei Code-Navigation. Die 71.5x Reduktion ist beeindruckend, aber auf grosse Mixed-Corpora bezogen (Code + Papers + Images). Fuer typische Kundenprojekte (20-80 Dateien, ein Stack) ist der Overhead des Graph-Buildings fraglich.

**Was wir uebernehmen sollten**: Die Low-Hanging-Fruits (Suggested Questions, Corpus Health, Token Benchmark) — einfache Erweiterungen unserer existierenden Skills die sofort Wert liefern.

**Was wir beobachten sollten**: Graph-basiertes Code-Verstaendnis als Trend. Wenn Projekte groesser werden (Monorepos, >500 Dateien), wird ein queryable Graph kritisch. Graphify koennte dann als optionale Dependency integriert werden statt eigene Implementation.

**Was nicht passt**: Die Multi-Format-Exports (Obsidian, Neo4j, SVG) und Watch Mode sind Features eines eigenstaendigen Tools — nicht eines Setup-Frameworks.
