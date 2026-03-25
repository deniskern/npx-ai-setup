# Brainstorm: OpenViking Adaptionen für npx-ai-setup

> **Source**: https://github.com/volcengine/OpenViking
> **Erstellt**: 2026-03-23
> **Zweck**: Research welche Patterns aus ByteDances Context-Database adaptierbar sind

## Was ist OpenViking?

Open-source Context Database für AI Agents (18k+ Stars). Kernidee: `viking://`-URI-Protokoll für alle Kontextobjekte, dreistufiges Ladesystem (L0 Abstracts → L1 Overviews → L2 Full Content). Behauptete Ergebnisse: 43-49% bessere Task Completion, 83-96% weniger Input Tokens.

Stack: Python + Go + Rust CLI, FastAPI Server (Port 1933), Docker-ready. Nicht direkt vergleichbar mit unserem Bash-CLI-Setup-Tool — aber enthält Claude Code Integration Patterns.

---

## Bestandsvergleich: Was haben wir schon?

| External Item | Our Equivalent | Status |
|---|---|---|
| Claude Memory Plugin (4 Hooks) | claude-mem MCP Plugin | ✅ Covered — anderer Ansatz (MCP vs Hooks) |
| Session Start/End Hooks | hooks/context-monitor.sh, context-freshness.sh | ⚠️ Partial — keine Session-Persistenz |
| Stop Hook (Transcript Ingestion) | - | ❌ Missing — Auto-Ingestion von Transkripten |
| UserPromptSubmit Memory Hint | hooks/context-reinforcement.sh | ⚠️ Partial — kein Memory-Recall bei Prompts |
| Skills (search/add/operate) | .claude/skills/ (11 Skills) | ✅ Covered — andere Domäne |
| MCP Query Server (RAG) | claude-mem MCP | ⚠️ Partial — kein RAG/Embedding |
| .pr_agent.toml (Review Rules) | agents/code-reviewer.md, staff-reviewer.md | ⚠️ Partial — keine automatischen PR-Labels |
| Pre-commit (ruff) | hooks/post-edit-lint.sh | ✅ Covered |
| L0/L1/L2 Context Loading | .agents/context/ (STACK, ARCH, CONV) | ⚠️ Partial — kein URI-Schema, kein stufenweises Laden |
| ov CLI (Rust, TUI) | bin/ai-setup.sh (Bash) | ✅ Covered — andere Sprache |
| Docker Deployment | - | ❌ Missing (aber nicht relevant für CLI-Tool) |

### Gruppierung

**Already Covered (4):**
- Pre-commit Linting → post-edit-lint.sh
- Skills-System → unsere 11 Skills
- CLI Tool → ai-setup.sh
- Memory Plugin Konzept → claude-mem

**Partially Covered (4):**
- Session Lifecycle Hooks — wir monitoren Context, aber persistieren keine Sessions
- Memory Recall bei Prompts — context-reinforcement injiziert CLAUDE.md, nicht Memory
- PR Review Automation — unsere Agents reviewen, aber kein Auto-Label/Auto-Trigger
- Tiered Context Loading — .agents/context/ hat Dateien, aber kein L0→L1→L2 Paradigma

**New / Missing (2):**
- Transcript Auto-Ingestion (Stop Hook parst Transkript → speichert automatisch)
- RAG-basierte Suche über projektspezifische Dokumente

---

## Kandidaten für Adaption

### 1. Transcript Auto-Ingestion (Stop Hook) ★★★★

**Was es tut:** OpenVikings `stop.sh` parst nach jeder Claude-Antwort das Transkript und extrahiert relevante Informationen automatisch in die Memory-Datenbank. Fire-and-forget async.

**Unsere Lücke:** Wir haben `/reflect` und `/pause` als manuelle Skills, aber nichts Automatisches. Erkenntnisse gehen verloren wenn der User vergisst `/reflect` zu nutzen.

**Adaptionsidee:** Hook `Stop` → parst letzte Antwort → extrahiert Learnings/Decisions → schreibt nach `.agents/memory/` oder claude-mem. Minimal-Variante: nur bei Sessions >20 Nachrichten.

**Aufwand:** Medium (1 Hook-Script + Bridge-Logik)
**Empfehlung:** Adaptieren — löst ein echtes Problem (Memory-Verlust)

### 2. L0/L1/L2 Tiered Context Loading ★★★★★

**Was es tut:** Drei Detailstufen für jedes Kontextobjekt:
- L0: Einzeiler-Abstract (Name + Beschreibung)
- L1: Strukturierter Überblick (Sections, Key Points)
- L2: Vollständiger Inhalt

Agent entscheidet basierend auf Relevanz welche Stufe geladen wird. Ergebnis: 83-96% weniger Input Tokens.

**Unsere Lücke:** `.agents/context/` lädt IMMER alles. STACK.md + ARCHITECTURE.md + CONVENTIONS.md = ~2000 Tokens die in JEDEM Request geladen werden, auch wenn irrelevant.

**Adaptionsidee:** Context-Dateien mit YAML-Frontmatter versehen (`abstract:` Feld). SessionStart-Hook lädt nur Abstracts → Agent requested bei Bedarf L1/L2 via Skill.

**Aufwand:** Hoch (Context-Format-Änderung + Hook + Skill)
**Empfehlung:** Evaluieren — enormes Token-Spar-Potenzial, aber komplex

### 3. Session-Lifecycle Management ★★★

**Was es tut:** OpenVikings Hooks bilden einen vollständigen Session-Lifecycle:
- `session-start.sh`: Initialisiert Session, gibt System-Message + Context zurück
- `user-prompt-submit.sh`: Injiziert Memory-Recall
- `stop.sh`: Parst Transkript async
- `session-end.sh`: Committed Session-Daten

**Unsere Lücke:** Unsere Hooks sind unabhängige Utilities (monitor, reinforce, lint), aber kein orchestriertes Session-Modell. `/pause` und `/resume` sind manuell.

**Adaptionsidee:** Session-ID-Konzept einführen. SessionStart generiert ID → alle Hooks nutzen diese → SessionEnd speichert Zusammenfassung.

**Aufwand:** Hoch (alle Hooks müssen Session-aware werden)
**Empfehlung:** Beobachten — aktuell löst `/pause`+`/resume` das Problem manuell

### 4. PR Agent Labels & Auto-Review Rules ★★

**Was es tut:** `.pr_agent.toml` definiert 7 Custom Labels (memory-pipeline, async, embedding, etc.) und 15 Review-Regeln die automatisch bei PRs angewendet werden.

**Unsere Lücke:** Unsere Review-Agents (code-reviewer, staff-reviewer) haben keine vordefinierten Label-Taxonomie. Labels müssen manuell gesetzt werden.

**Adaptionsidee:** Template für `.pr_agent.toml` oder GitHub Actions Label-Automation.

**Aufwand:** Niedrig (1 Template-Datei)
**Empfehlung:** Nice-to-have — nicht kritisch für unser CLI-Setup-Tool

### 5. Memory-Recall bei User Prompts ★★★

**Was es tut:** `user-prompt-submit.sh` prüft ob der Prompt ≥10 Zeichen lang ist und injiziert dann relevante Memories als `additionalContext`.

**Unsere Lücke:** `context-reinforcement.sh` injiziert CLAUDE.md-Inhalte, aber keine semantische Memory-Suche basierend auf dem Prompt-Inhalt.

**Adaptionsidee:** Hook erweitern: Prompt → claude-mem search → Top-3-Ergebnisse als additionalContext.

**Aufwand:** Medium (Hook-Erweiterung + claude-mem CLI Integration)
**Empfehlung:** Evaluieren — könnte Memory-Nutzung dramatisch verbessern

---

## Einzelne Sätze/Patterns zum Adaptieren

### Aus `common.sh` — Robuste PATH-Erweiterung
```bash
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:/usr/local/bin:$PATH"
```
Unsere Hooks setzen PATH nicht explizit → kann zu `command not found` führen wenn Tools in nicht-standard Pfaden liegen. **→ In hook-common.sh übernehmen.**

### Aus `stop.sh` — Fire-and-forget Pattern
```bash
# Async ingestion - don't block Claude's response
nohup "$BRIDGE" ingest-stop ... >/dev/null 2>&1 &
```
Wir nutzen `run_in_background` für Agents, aber unsere Hooks blocken immer. **→ Async-Pattern für teure Hook-Operationen evaluieren.**

### Aus `session-start.sh` — Config Validation vor Session
```bash
if [ ! -f "$CONFIG_FILE" ]; then
  echo '{"systemMessage": "⚠️ Configuration missing..."}'
  exit 0
fi
```
Graceful degradation statt Fehler. **→ cli-health.sh könnte ähnlich reagieren statt zu warnen.**

### Aus `.pr_agent.toml` — Spezifische Review-Regeln
```toml
[pr_reviewer.extra_instructions]
"If the PR modifies async code, verify proper use of asyncio.Lock"
"Flag any embedding dimension changes as breaking"
```
Domänenspezifische Review-Regeln als Konfiguration statt im Prompt. **→ Für unsere Review-Agents als optionales Config-Format.**

---

## Architektur-Patterns

### 1. Bridge-Script Pattern
OpenViking nutzt ein Python-Script (`ov_memory.py`) als "Bridge" zwischen Bash-Hooks und dem Backend. Hooks rufen nur die Bridge auf, die die eigentliche Logik enthält.
**Unser Äquivalent:** `.claude/scripts/*-prep.sh` — ähnliches Pattern, aber weniger formalisiert.

### 2. State Directory Pattern
`STATE_DIR=$PROJECT_DIR/.openviking/memory/` — ein dediziertes Verzeichnis für Session-State.
**Unser Äquivalent:** `.agents/memory/` — haben wir bereits, aber ohne formalen Lifecycle.

### 3. Backend-Detection Pattern
Bridge erkennt automatisch ob ein lokaler oder HTTP-Backend verfügbar ist und wählt entsprechend.
**Relevanz:** Könnte für claude-mem vs. lokales Memory relevant sein.

---

## Token-Ökonomie

| Pattern | Geschätztes Token-Sparpotenzial |
|---|---|
| L0/L1/L2 Tiered Loading | 500-1500 Tokens/Request (Context-Dateien) |
| Transcript Auto-Ingestion | Indirekt — verhindert Re-Recherche in späteren Sessions |
| Memory-Recall Injection | 200-500 Tokens/Request (relevanter Context statt alles) |
| Async Stop Hook | 0 direkt (spart Latenz, nicht Tokens) |

---

## Gesamtranking nach Aufwand/Nutzen

| # | Item | Value | Aufwand | Empfehlung |
|---|---|---|---|---|
| 1 | L0/L1/L2 Tiered Context Loading | ★★★★★ | Hoch | Evaluieren — größtes Token-Spar-Potenzial |
| 2 | Transcript Auto-Ingestion | ★★★★ | Medium | **Adaptieren** — löst echtes Problem |
| 3 | Memory-Recall bei Prompts | ★★★ | Medium | Evaluieren — abhängig von claude-mem |
| 4 | PATH-Erweiterung in Hooks | ★★ | Niedrig | **Sofort übernehmen** — trivial, verhindert Bugs |
| 5 | Session-Lifecycle Management | ★★★ | Hoch | Beobachten — manueller Workflow reicht aktuell |
| 6 | PR Agent Labels | ★★ | Niedrig | Nice-to-have |
| 7 | Async Hook Pattern | ★★ | Niedrig | Evaluieren für teure Hooks |
