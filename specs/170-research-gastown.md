# Brainstorm: Gas Town Adaptionen für npx-ai-setup

> **Source**: https://github.com/steveyegge/gastown
> **Erstellt**: 2026-03-24
> **Zweck**: Research welche Patterns aus Stevey's Multi-Agent-Orchestrierung für unser Single-Project-Setup adaptierbar sind

## Was ist Gas Town?

Multi-Agent-Orchestrierung (Go, CLI `gt`) für 20-30+ parallele AI-Coding-Agents (Claude Code, Copilot, Codex, Gemini). Kernidee: **persistenter Arbeitsstatus in Git-Worktrees** ("Hooks"), zentrale Koordination durch "Mayor" (AI-Koordinator), dezentrale Arbeit durch "Polecats" (Worker-Agents).

**Stack:** Go Binary, Dolt (SQL DB), Beads (Git-backed Issue Tracking), tmux Sessions, OpenTelemetry.

**Skala:** 20-30 gleichzeitige Agents, Merge-Queue, Watchdog-Chain, federated Work Network.

## Fundamentaler Unterschied

| Dimension | Gas Town | npx-ai-setup |
|-----------|----------|--------------|
| Scope | Multi-Agent-Plattform | Single-Project Setup-Tool |
| Agents | 20-30 gleichzeitig | 1-3 (Haupt + Subagents) |
| Sprache | Go Binary | Bash/Shell Scripts |
| Issue Tracking | Beads (eigenes System) | Specs (Markdown) |
| Koordination | Mayor + Polecats + Mail | Direkte User-Interaktion |
| Persistenz | Dolt SQL + Git Worktrees | Git Commits + `.continue-here.md` |

---

## Bestandsvergleich: Was haben wir schon?

| Gas Town Feature | Unser Equivalent | Status |
|-----------------|-----------------|--------|
| `.claude/commands/` (3: patrol, backup, reaper) | `templates/commands/` (28 commands) | ✅ Deutlich mehr Coverage |
| `.claude/skills/` (3: ghi-list, pr-list, pr-sheriff) | `templates/skills/` (26 skills) | ✅ Deutlich mehr Coverage |
| AGENTS.md (Agent-Verhalten) | `.claude/rules/agents.md` + Agent-Templates | ✅ Covered + granularer |
| `gt prime` (Context Recovery) | `/resume` + `/pause` | ⚠️ Partial — Seance geht weiter |
| Convoy (Work Tracking) | `/spec-board` (Kanban) | ⚠️ Partial — Convoys sind mächtiger |
| Formulas (TOML Workflows) | Specs (Markdown) | ⚠️ Partial — Formulas sind wiederverwendbar |
| Multi-Agent Runtimes | Nur Claude Code | ❌ Nur Claude Code |
| Watchdog/Health Monitoring | Nichts | ❌ Kein Health-Check für laufende Agents |
| Merge Queue (Refinery) | Nichts | ❌ Kein Merge-Queue |
| Seance (Session Discovery) | `/pause` + `/resume` | ❌ Kein Cross-Session Query |
| Activity Feed (TUI) | Nichts | ❌ Kein Live-Monitoring |
| Escalation System | Nichts | ❌ Keine strukturierte Eskalation |
| OpenTelemetry | Nichts | ❌ Keine Observability |
| Wasteland (Federation) | Nichts | ❌ Kein Cross-Town Sharing |
| Directives & Overlays | CLAUDE.md + Rules | ✅ Ähnliches Konzept |
| Dashboard (Web) | Nichts | ❌ Kein Web-Dashboard |
| PR Sheriff (Triage) | `/review` Command | ⚠️ Partial — Sheriff ist umfangreicher |
| Agent Identity (persistent) | Nichts | ❌ Agents sind ephemeral |

---

## Kandidaten für Adaption

### 1. Seance — Cross-Session Context Recovery ★★★★★

**Was es tut:** Entdeckt vorherige Agent-Sessions via `.events.jsonl` Logs. Agents können Vorgänger-Sessions nach Kontext und Entscheidungen fragen.

**Unsere Lücke:** `/pause` + `/resume` speichern nur den letzten Zustand. Es gibt keine Möglichkeit, eine beliebige vorherige Session zu befragen ("Was hast du bei Feature X entschieden?").

**Adaptionsidee:**
- Session-Logs als strukturierte JSONL-Dateien speichern (kompakter als `.continue-here.md`)
- `/seance` Command: Liste vorheriger Sessions + One-Shot-Queries an vergangene Sessions
- Nutzt `claude-mem` MCP als Backend statt eigener Logs

**Aufwand:** Medium (neues Command + Log-Format)
**Wert:** Hoch — löst das Problem "Was wurde in der letzten Session entschieden?"

### 2. PR Sheriff — Automated PR Triage ★★★★☆

**Was es tut:** Kategorisiert offene PRs in EASY-WIN / NEEDS-CREW / NEEDS-HUMAN. Auto-merged triviale Changes. Nutzt ephemere Beads für Orchestrierung.

**Unsere Lücke:** `/review` prüft lokale Changes, aber keine systematische Triage aller offenen PRs eines Repos.

**Adaptionsidee:**
- Neues Skill `pr-sheriff` das alle offenen PRs eines Repos scannt
- Kategorien: AUTO-MERGE (trivial), REVIEW-NEEDED (standard), ESCALATE (security/arch)
- Integration mit `/gh-cli` Skill für GitHub-Operationen

**Aufwand:** Medium (neues Skill, ~200 Zeilen)
**Wert:** Hoch für Teams — spart Review-Overhead

### 3. Activity Feed / Session Monitoring ★★★☆☆

**Was es tut:** TUI-Dashboard (`gt feed`) zeigt Agent-Aktivität in Echtzeit. Problems-View erkennt stuck Agents.

**Unsere Lücke:** Keine Sichtbarkeit über laufende Subagent-Arbeit. Bei `/spec-work-all` mit parallelen Worktrees keine Statusübersicht.

**Adaptionsidee:**
- Lightweight Status-Tracker für parallele Subagent-Arbeit
- Progress-Logging in `.claude/agent-activity.jsonl`
- Einfaches `gt feed`-artiges TUI als optionales Tool

**Aufwand:** Hoch (TUI erfordert ncurses oder ähnlich in Bash)
**Wert:** Medium — nur relevant bei paralleler Arbeit

### 4. Formulas (Reusable TOML Workflows) ★★★☆☆

**Was es tut:** TOML-definierte Workflow-Templates mit Steps, Dependencies, Variables. Können versioniert, geshared und in "Molecules" instanziiert werden.

**Unsere Lücke:** Specs sind einmalige Markdown-Dokumente. Kein Konzept für wiederverwendbare Workflow-Templates.

**Adaptionsidee:**
- Spec-Templates als TOML-Dateien in `templates/formulas/`
- Variables (`{{version}}`, `{{feature_name}}`) für parametrische Specs
- `bd cook`-ähnliches Command das aus Template eine Spec generiert

**Aufwand:** Medium-Hoch (neues Template-System)
**Wert:** Medium — unsere Specs funktionieren gut für Einmal-Aufgaben

### 5. Escalation System ★★★☆☆

**Was es tut:** Severity-basierte Issue-Eskalation (CRITICAL/HIGH/MEDIUM). Agents die Blocker treffen eskalieren statt zu warten. Routing: Agent → Deacon → Mayor → Overseer.

**Unsere Lücke:** Wenn ein Subagent stuck ist, gibt es keine strukturierte Eskalation. Der User merkt es erst beim Review.

**Adaptionsidee:**
- Subagents die >3 Minuten keinen Fortschritt machen, loggen eine Escalation
- Escalation-Bead in `.claude/escalations/` mit Severity + Kontext
- Hauptagent prüft Escalations periodisch

**Aufwand:** Medium
**Wert:** Medium — relevant bei paralleler Arbeit

### 6. Multi-Runtime Support ★★☆☆☆

**Was es tut:** Unterstützt Claude Code, Codex, Copilot, Gemini, Cursor als austauschbare Runtimes pro Rig.

**Unsere Lücke:** Wir generieren nur Claude-Code-Konfiguration. Kein Support für andere AI-Agents.

**Adaptionsidee:**
- Setup-Skript erkennt installierte AI-Tools
- Generiert auch `AGENTS.md` (Codex), `.github/copilot-instructions.md`, `.gemini/`
- Multi-Agent-Config als optionales Feature

**Aufwand:** Hoch (viele Formate, Maintenance-Last)
**Wert:** Medium — wir haben das teilweise mit `/orchestrate`

---

## Einzelne Sätze/Patterns zum Adaptieren

### Aus AGENTS.md:
> "gt nudge is the ONLY way to send text to another agent's session"

**Pattern:** Dedizierter Inter-Agent-Kommunikationskanal statt gemeinsamer Dateien. Unser `/spec-work-all` nutzt Dateien für Koordination — ein Mailbox-System wäre robuster.

### Aus der Architecture:
> "Polecats manage their own lifecycle end-to-end. The Witness observes but does NOT gate completion."

**Pattern:** Observer-only Monitoring statt Gating. Watchdogs die beobachten und eskalieren, aber nicht blockieren. Relevant für unsere Subagent-Delegation.

### Aus dem Persistent Polecat Pool:
> "Three distinct lifecycle concepts were incorrectly merged into one: Identity, Sandbox, Session"

**Pattern:** Trennung von Agent-Identität (persistent), Workspace (wiederverwendbar) und Session (ephemer). Unser Worktree-Management könnte davon profitieren — Worktrees nicht nach jeder Spec zerstören.

### Aus PR Sheriff:
> "Uses ephemeral beads (wisps) for orchestration work to avoid permanent ledger pollution"

**Pattern:** Temporäre Tracking-Einheiten für Orchestrierung, die automatisch aufgeräumt werden. Relevant für unsere Subagent-Koordination.

### Aus Formula Resolution:
> "Project maintainers know their workflows best — project-level formulas override system defaults"

**Pattern:** Dreistufige Precedence (Project > User > System). Wir haben das mit CLAUDE.md-Hierarchie, aber nicht für Commands/Skills.

---

## Architektur-Patterns

### 1. Git als Persistenz-Layer
Gas Town nutzt Git-Worktrees als primäre Persistenz für Agent-Arbeit. Jeder Hook ist ein Worktree mit vollständiger History. Das ist robuster als Dateisystem-State.
**Relevanz:** Wir nutzen Worktrees schon für parallele Spec-Arbeit, aber nicht als Persistenz-Mechanismus.

### 2. Beobachtung statt Kontrolle (Observer Pattern)
Watchdogs (Witness, Deacon, Dogs) beobachten Agent-Gesundheit ohne zu blockieren. Erst bei Problemen wird eingegriffen (Nudge → Handoff → Escalation).
**Relevanz:** Unsere Subagents laufen blind — kein Health-Check möglich.

### 3. Dolt als Shared State
Alle Agents teilen eine Dolt SQL-Datenbank für konsistente Sicht auf den Arbeitsstand. Kein Dateisystem-basierter State.
**Relevanz:** Wir nutzen Markdown-Dateien — funktioniert für Single-Agent, aber skaliert nicht.

### 4. TOML-basierte Workflow-Definition
Formulas definieren Steps, Dependencies und Variables in TOML. Instanziierung erzeugt trackbare Molecules.
**Relevanz:** Unsere Specs sind ähnlich, aber handgeschrieben statt templated.

---

## Gesamtranking nach Aufwand/Nutzen

| # | Item | Wert ★ | Aufwand | Empfehlung |
|---|------|--------|---------|------------|
| 1 | Seance (Cross-Session Query) | ★★★★★ | Medium | **Adaptieren** — löst echtes Problem |
| 2 | PR Sheriff (PR Triage Skill) | ★★★★☆ | Medium | **Adaptieren** — hohes Team-Value |
| 3 | Observer-Pattern für Subagents | ★★★★☆ | Low | **Adaptieren** — Pattern in bestehende Agent-Rules |
| 4 | Lifecycle-Trennung (Identity/Sandbox/Session) | ★★★☆☆ | Medium | **Evaluieren** — Worktree-Management verbessern |
| 5 | Reusable Formulas (TOML Specs) | ★★★☆☆ | Hoch | **Notieren** — erst bei Bedarf |
| 6 | Activity Feed | ★★★☆☆ | Hoch | **Notieren** — Nice-to-have |
| 7 | Escalation System | ★★★☆☆ | Medium | **Notieren** — relevant wenn mehr Parallelität |
| 8 | Multi-Runtime | ★★☆☆☆ | Hoch | **Skip** — zu viel Maintenance |
| 9 | Wasteland (Federation) | ★☆☆☆☆ | Sehr hoch | **Skip** — anderes Problem-Domain |
| 10 | Dashboard | ★☆☆☆☆ | Hoch | **Skip** — overkill für Single-Agent |

---

## Strategische Analyse

### Token Economics
- **Seance** spart Tokens durch gezielten Zugriff auf vergangene Sessions statt Kontext-Neuaufbau
- **PR Sheriff** spart manuelle Review-Zeit, Token-neutral
- **Observer Pattern** kostet nichts zusätzlich — nur Rule-Änderung

### Quality Impact
- **Seance** verbessert Entscheidungs-Konsistenz über Sessions hinweg
- **PR Sheriff** erhöht Code-Review-Qualität durch systematische Triage
- **Observer Pattern** verhindert stuck Subagents

### Maintenance Cost
- **Seance**: Low (Command + claude-mem Integration)
- **PR Sheriff**: Medium (GitHub API Changes, Edge Cases)
- **Observer Pattern**: Zero (nur Rule-Text)

### Team Impact
- **PR Sheriff** ist der größte Gewinn für Teams (>2 Entwickler)
- **Seance** hilft bei Solo-Arbeit über mehrere Sessions
