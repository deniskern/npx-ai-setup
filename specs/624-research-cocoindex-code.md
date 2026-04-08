# Brainstorm: CocoIndex Code Adaptionen fuer npx-ai-setup

> **Source**: https://github.com/cocoindex-io/cocoindex-code
> **Erstellt**: 2026-04-07
> **Zweck**: Research ob semantische Codesuche als Integration sinnvoll ist
> **Backlog-Ref**: BACKLOG.md "Evaluate" Section — Status war "Watch"

## Was ist CocoIndex Code?

Python-basiertes Tool fuer AST-basierte semantische Codesuche. Kernfeatures:
- Tree-sitter AST-Chunking (28+ Sprachen)
- Lokale Embeddings via SentenceTransformers (kein API-Key noetig)
- SQLite-vec als Vector-Store (kein externer DB-Service)
- Daemon-Architektur: Hintergrundprozess, CLI als Client
- MCP-Server-Modus fuer Claude Code Integration
- Skill-Datei fuer Claude Code Agent-Lifecycle

## Bestandsvergleich

| Externes Item | Unser Aequivalent | Status |
|--------------|-------------------|--------|
| `ccc search` (semantische Suche) | Grep/Glob (keyword-basiert) | ❌ Missing — wir haben keine semantische Suche |
| `ccc` MCP Server | MCP-Server-Config in .mcp.json | ⚠️ Partial — MCP-Infra vorhanden, dieser Server fehlt |
| `ccc` Skill (SKILL.md) | Skill-Template-System | ⚠️ Partial — System vorhanden, Skill fehlt |
| `ccc doctor` (Health Check) | doctor.sh (12 Checks) | ✅ Covered — unser Doctor ist deutlich umfangreicher |
| `ccc index` (Indexierung) | Kein Aequivalent | ❌ Missing — wir indexieren Codebases nicht |
| CLAUDE.md (Code Conventions) | CLAUDE.md + 8 Rules | ✅ Covered — unsere deutlich umfangreicher |
| Pre-commit Hooks (ruff, mypy) | Post-edit Lint Hook | ✅ Covered — anderer Ansatz, aber gleicher Zweck |
| Docker Deployment | Kein Aequivalent | ❌ Missing — aber irrelevant fuer unser Setup |
| E2E Test Strategie | smoke-test.sh + template tests | ✅ Covered — andere Domäne |

## Kandidaten fuer Adaption

### 1. Semantic Search MCP Server Integration (HIGH VALUE)

**Was**: CocoIndex als optionalen MCP-Server in ai-setup installierbar machen.

**Unser Gap**: Grep/Glob sind keyword-basiert. Bei grossen Codebases mit 500+ Dateien findet man Patterns wie "Wo wird die User-Authentifizierung gehandhabt?" nicht via Keyword-Suche. Semantische Suche koennte hier 50-70% Token-Einsparung bringen, weil Agents weniger Dateien durchsuchen muessen.

**Aufwand**: Mittel. Braucht:
- Python/pip als Dependency (unser Stack ist Shell/Node)
- MCP-Config-Template fuer .mcp.json
- Optional: Skill-Template fuer `ccc` Lifecycle

**Bedenken**:
- Python-Dependency ist ein Bruch mit unserem Shell/Node-Stack
- `pipx` oder `uv` muss installiert sein
- Embedding-Model Download (~90MB) beim ersten Index
- Daemon-Prozess laeuft im Hintergrund (Ressourcen)
- Projekt ist Alpha (v0.x) — API-Stabilitaet unklar

### 2. Skill-Template fuer ccc (LOW-MEDIUM VALUE)

**Was**: SKILL.md fuer `ccc` als optionales Skill-Template bereitstellen.

**Unser Gap**: Wenn ein User cocoindex manuell installiert, fehlt die Agent-Integration. Ein Skill-Template wuerde Setup-Reibung reduzieren.

**Aufwand**: Gering. Ein SKILL.template.md mit Lifecycle-Anweisungen.

**Bedenken**: Nur sinnvoll wenn #1 auch umgesetzt wird. Standalone-Skill ohne MCP hat wenig Wert.

### 3. Doctor-Integration fuer MCP-Server Health (LOW VALUE)

**Was**: Doctor-Check ob cocoindex-Daemon laeuft und Index aktuell ist.

**Unser Gap**: Unser Doctor prueft MCP-Health generisch (Verbindung). Ein cocoindex-spezifischer Check koennte Index-Freshness validieren.

**Aufwand**: Minimal — ein weiterer Check in doctor.sh.

**Bedenken**: Nur relevant wenn cocoindex installiert ist. Conditional Check.

## Einzelne Patterns zum Adaptieren

### Aus CLAUDE.md

> "We prefer end-to-end tests on user-facing APIs, over unit tests on smaller internal functions."

Wir machen das bereits mit smoke-test.sh, aber das Prinzip ist gut formuliert. Koennte in unsere testing.md Rule als Leitlinie.

### Aus SKILL.md (Lifecycle-Pattern)

> "Freshness: Execute `ccc index` or `ccc search --refresh` when code changes occur or at session start"

Gutes Pattern fuer MCP-Tools generell: Session-Start-Freshness-Check. Unser context-freshness.sh macht etwas Aehnliches fuer Context-Files, aber nicht fuer externe Tools.

### Aus Docker/Entrypoint

> `ccc init -f 2>/dev/null || true` — Silent init mit Force-Flag

Robustes Pattern fuer idempotente Tool-Initialisierung. Wir nutzen aehnliche Patterns in ai-setup.sh.

## Architektur-Patterns

### Daemon-Architektur
CocoIndex trennt CLI (duennes Client) von Daemon (schwerer Prozess). Das ist fuer ein Indexierungs-Tool sinnvoll, aber fuer unseren Use Case (Setup-Tool) irrelevant.

### MCP als Primary Interface
Interessant: cocoindex bietet CLI, Skill UND MCP — drei Integrationswege. Das ist ein gutes Modell fuer Tools die in verschiedenen Kontexten genutzt werden.

### Chunking-Registry
Erweiterbare Chunker via Registry-Pattern (siehe `chunking.py`). Fuer uns nicht direkt relevant, aber das Extension-Pattern ist sauber.

## Gesamtranking nach Aufwand/Nutzen

| # | Item | Value | Aufwand | Empfehlung |
|---|------|-------|---------|------------|
| 1 | Semantic Search MCP Integration | ★★★★ | Mittel | **WAIT** — Python-Dep ist Bruch, Projekt noch Alpha |
| 2 | ccc Skill-Template | ★★ | Gering | **WAIT** — abhaengig von #1 |
| 3 | Doctor MCP-Health Check | ★ | Minimal | **WAIT** — abhaengig von #1 |
| 4 | E2E-Test-Leitlinie in Rules | ★ | Minimal | **SKIP** — haben wir implizit schon |
| 5 | Session-Start Freshness fuer Tools | ★★ | Gering | **PIVOT** — generisches Pattern, nicht cocoindex-spezifisch |

## Strategische Analyse

### Token Economics
Semantische Suche koennte bei grossen Codebases (500+ Dateien) signifikant Token sparen, weil Agents gezielter die richtigen Dateien finden. Geschaetzt 30-50% weniger Explore-Agent-Calls. Bei kleinen Projekten (<100 Dateien) kein Vorteil gegenueber Grep/Glob.

### Quality Impact
Hoehere Trefferqualitaet bei natuerlichsprachlichen Queries ("Wo wird Error-Handling gemacht?" statt `grep -r "catch\|try\|error"`). Aber: Claude Code's eigene Suche ist bereits gut — der Marginalnutzen ist unklar.

### Maintenance Cost
Python-Dependency wuerde Maintenance-Burden erhoehen. Unser Stack ist bewusst Shell + Node — Python einfuehren bedeutet neue Failure-Modes, neue Update-Zyklen, neue User-Probleme.

### Team Impact
Minimal. Semantische Suche ist "nice to have", nicht "must have" fuer Onboarding.

## Fazit

CocoIndex Code ist ein solides Tool, aber **passt aktuell nicht in unseren Stack**:

1. **Python-Dependency** — Bruch mit Shell/Node-Prinzip
2. **Alpha-Status** — API kann sich noch aendern
3. **Marginaler Nutzen** — Claude Code's eingebaute Suche (Grep/Glob + Agent-Heuristik) ist fuer die meisten Codebases ausreichend
4. **Zielgruppe** — Interessant fuer Teams mit 1000+ Datei Codebases, nicht fuer typische npx-ai-setup User

**Empfehlung**: Status bleibt "Watch" im Backlog. Erneut evaluieren wenn:
- Projekt stable release (v1.0) erreicht
- `npx`/Node-basierte Installation verfuegbar wird
- User semantische Suche als Feature requesten
