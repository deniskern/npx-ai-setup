# Developer Workflow Guide

Dieses Setup macht Claude Code zum strukturierten Entwicklungswerkzeug statt einer Chat-Box. Statt "mach mal Feature X" gibt es einen klaren Prozess: Idee bewerten, Plan erstellen, ausfuehren, reviewen, committen. Jeder Schritt ist ein Slash-Command, jede Aenderung nachvollziehbar.

**Was laeuft automatisch im Hintergrund:**
- **Hooks + Settings** verhindern typische Fehler: Hooks geben Warnungen oder blocken riskante Edits, waehrend `permissions.deny` in `settings.json` harte Read-Blocks fuer Build-Output, Secrets und andere teure Dateien setzt
- **Context-Dateien** geben Claude sofort Wissen ueber Stack, Architektur und Conventions — ohne jedes Mal erklaeren zu muessen
- **Prep-Scripts** sammeln Daten in Shell bevor Claude sie sieht — spart 60-90% Tokens

**Was das bringt:** Konsistente Code-Qualitaet ueber das Team, nachvollziehbare Specs statt ad-hoc Aenderungen, automatische Sicherheitsnetze die greifen bevor etwas kaputt geht.

---

## Quick Start

```bash
claude                # Claude Code im Projekt oeffnen
/spec-board           # aktive Specs anzeigen
/doctor               # Setup-Health pruefen
/analyze              # Codebase-Analyse → PATTERNS.md + AUDIT.md (empfohlen nach Erstinstallation)
```

---

## Onboarding

Einmalig ausfuehren wenn du in eine neue Codebase einsteigst oder ein groesseres Vorhaben planst.

| Command | Was es tut | Wann nutzen |
|---------|------------|-------------|
| `/analyze` | Parallele Agents analysieren die Codebase, erzeugen PATTERNS.md (Architektur-Patterns) und AUDIT.md (Hotspots, Risks, Recommendations) | Direkt nach Erstinstallation und wenn sich die Codebase stark veraendert hat |
| `/explore "topic"` | Read-Only Thinking Partner — Codebase erkunden, Tradeoffs aufzeigen, ASCII-Diagramme. Aendert keine Dateien | Wenn du verstehen willst wie etwas funktioniert, ohne Code anzufassen |
| `/research "tool"` | Deep-Research eines externen Repos/Tools/Patterns, produziert Brainstorm-Dokument | Bevor ein neues Tool oder Pattern eingefuehrt wird |
| `/context-load` | Context-Dateien on-demand laden (STACK.md, ARCHITECTURE.md, CONVENTIONS.md) | Wenn Claude Kontext verloren hat oder du gezielt Stack-Details brauchst |

---

## Development Cycle

Der Standard-Ablauf fuer jede Aenderung die mehr als ein einzelnes File betrifft. Specs sorgen dafuer, dass Claude einen Plan hat bevor es Code schreibt — das verhindert Scope Creep und macht Aenderungen reviewbar.

### Der Ablauf

```
1. /spec "task description"       ← Komplexitaet einschaetzen, Spec erstellen
2. /spec-validate NNN             ← Spec-Qualitaet pruefen vor Ausfuehrung
3. /spec-work NNN                 ← Schritt fuer Schritt ausfuehren
4. /test                          ← Tests laufen lassen + Failures fixen
5. /review                        ← Uncommitted Changes reviewen
6. /commit                        ← Stagen + Conventional Commit Message
7. gh pr create                   ← PR direkt via CLI
8. /release                       ← Version bump, CHANGELOG, Tag
```

**Spec-Lifecycle:** `draft` → `in-progress` → `in-review` → `completed`

Fuer kleine Aenderungen (Typo, Config, einzelnes File) direkt mit Schritt 4-7 starten — kein Spec noetig.

### Wo anfangen?

```
Neue Idee oder Feature?
├── Einfach (1-2 Files, klarer Scope) → /spec direkt
├── Komplex oder unklar → /challenge zuerst → dann /spec
├── Externes Tool/Repo evaluieren → /research
└── Frei erkunden (kein Urteil) → /explore
```

### Spec Commands

| Command | Was es tut |
|---------|------------|
| `/spec "task"` | Komplexitaet einschaetzen, Implementation durchdenken, Spec erstellen |
| `/spec-validate NNN` | Spec-Qualitaet scoren bevor sie ausgefuehrt wird |
| `/spec-work NNN` | Spec Schritt fuer Schritt ausfuehren, ohne Commits waehrend der Umsetzung |
| `/spec-run NNN` | Full Pipeline: validate → implement → review → commit (self-healing) |
| `/spec-run-all` | Full Pipeline fuer alle Draft-Specs parallel in Git Worktrees |
| `/spec-work-all` | Alle Draft-Specs parallel in isolierten Git Worktrees ausfuehren |
| `/spec-review NNN` | Review gegen Acceptance Criteria + Finishing Gate |
| `/spec-board` | Kanban-Board aller Specs |

### Code Quality

| Command | Was es tut |
|---------|------------|
| `/test` | Tests laufen lassen + Failures fixen (bis zu 3 Versuche) |
| `/review` | Uncommitted Changes reviewen (Quick Scan / Standard / Adversarial) |
| `/lint` | Linter ausfuehren, sichere Violations auto-fixen |
| `/scan` | Security-Vulnerability-Scan (snyk/npm audit/pip-audit) |
| `/techdebt` | End-of-Session Sweep — Dead Code, Unused Imports aufspueren |

### Build & Deploy

| Command | Was es tut |
|---------|------------|
| `/commit` | Stagen + Conventional Commit Message generieren |
| `gh pr create` | PR direkt via GitHub CLI erstellen (kein separater Skill) |
| `/release` | Version bump, CHANGELOG aktualisieren, Git Tag |
| `/build-fix` | Build-Error iterativ fixen — parsen, fixen, rebuilden (max 10x) |

### Debugging & Planung

| Command | Was es tut |
|---------|------------|
| `/debug "description"` | Hypothesen-getriebene Bug-Untersuchung mit strukturiertem Protokoll |
| `/challenge "idea"` | Schnelles Critical Gate — GO/SIMPLIFY/REJECT vor Spec-Investment |
| `/research "tool"` | Deep-Research eines externen Tools/Repos/Patterns |
| `/explore "topic"` | Read-Only Thinking Partner — keine Dateiaenderungen |
| `/orchestrate "task"` | Task an Gemini oder Codex CLI delegieren |

---

## Hotfix Flow

Fuer Production-Bugs die den normalen Spec-Cycle umgehen.

```
/debug "symptom"               # Root Cause isolieren
/test                          # Fix mit Tests verifizieren
/commit                        # Conventional Commit: fix(scope): description
gh pr create                   # Fast-Track PR via CLI
```

Kein Spec noetig — `/debug` Output dient als Untersuchungsprotokoll.

---

## Session Management

| Command | Was es tut |
|---------|------------|
| `/pause` | Session-State in `.continue-here.md` speichern, WIP committen. Nutzen wenn du die Session beendest. |
| `/resume` | State wiederherstellen und zur naechsten Aktion routen. Nutzen beim Start einer neuen Session. |
| `/reflect` | Session-Learnings als permanente Regeln speichern. Nach langen Sessions (>30 Tool Calls). |
| `/apply-learnings` | Gesammelte Learnings aus LEARNINGS.md in die richtigen Context-Dateien einarbeiten. |
| `/session-optimize` | Vergangene Sessions analysieren — Qualitaet, Effizienz, Token-Savings verbessern. |
| `/doctor` | AI-Setup Health Check — Hooks, Settings, Context, MCP pruefen. |
| `/update` | ai-setup Updates pruefen und installieren. |

---

## Utilities

| Command | Was es tut |
|---------|------------|
| `/context-load` | Context-Dateien on-demand laden (STACK, ARCHITECTURE, CONVENTIONS). |
| `/context-refresh` | Context-Dateien neu generieren (STACK.md, ARCHITECTURE.md, CONVENTIONS.md). |
| `/gh-cli` | GitHub CLI Reference — Repos, Issues, PRs, Actions, Releases. |
| `/agent-browser` | Browser-Automation — Seiten navigieren, Formulare ausfuellen, Screenshots. |
| `/bash-defensive-patterns` | Defensive Bash-Techniken fuer Production-Grade Scripts. |

---

## Permission Governance

Dieses Setup unterscheidet bewusst zwischen Repo-Baseline und Operator-Entscheidungen.

- **Projekt-Baseline**: `.claude/settings.json` im Repo. Das ist die teamfaehige Standard-Policy.
- **Workstation-Settings**: `~/.claude/settings.json`. Das sind lokale Operator- oder Maschinenentscheidungen.
- **Hooks**: lokale Warn- und Safety-Netze
- **`permissions.deny`**: harte technische Read-/Command-Blocks

Permission-Modes sind keine versteckten Defaults:

- `default` und `plan` sind die sichere Standard-Empfehlung
- `acceptEdits` ist eine bewusste Komfortentscheidung fuer trusted lokale Arbeit
- `dontAsk` ist eine lokale Power-User-Entscheidung, nicht der Team-Baseline-Mode
- `auto` und `bypassPermissions` sind fortgeschrittene Betriebsmodi fuer klar verstandene Umgebungen

---

## Session Handoff

Es gibt jetzt drei bewusst getrennte Ebenen:

- `.claude/session-state.json`: kanonische machine-readable Handoff-Schicht fuer `/pause`, `/resume` und Compact-Recovery
- `.continue-here.md`: menschlich lesbare Zusammenfassung fuer Entscheidungen, Restarbeiten und Blocker
- Spec-Markdown in `specs/*.md`: fachliche Source of Truth fuer Fortschritt und Acceptance Criteria

Die JSON-Datei ersetzt die Specs nicht. Sie beantwortet nur: Was ist gerade aktiv, in welcher Phase bin ich, und was ist der naechste Schritt?

---

## Context-Dateien

In `.agents/context/` — automatisch beim Setup generiert, committed, teamweit geteilt. Claude kennt dadurch euren Stack und eure Conventions von der ersten Session an.

| Datei | Inhalt | Erzeugt durch |
|-------|--------|---------------|
| `STACK.md` | Tech Stack, Versionen, Key Dependencies | Setup (automatisch) |
| `ARCHITECTURE.md` | Systemarchitektur und Datenfluesse | Setup (automatisch) |
| `CONVENTIONS.md` | Naming Patterns, Coding Standards, Testing | Setup (automatisch) |
| `PATTERNS.md` | Wiederverwendbare Code-Patterns, Module Boundaries | `/analyze` (manuell) |
| `AUDIT.md` | Hotspots, Risks, Recommendations | `/analyze` (manuell) |

STACK/ARCHITECTURE/CONVENTIONS regenerieren: `/context-refresh` oder `npx @onedot/ai-setup` → **Regenerate** → **Context**.
PATTERNS/AUDIT regenerieren: `/analyze` ausfuehren.

---

## Tips

| Shortcut | Was es tut |
|----------|------------|
| `Esc Esc` | Letzte Antwort zurueckspulen (Tokens zurueckgewinnen) |
| `! git status` | Bash-Command direkt ausfuehren (kein Token-Overhead) |
| `@src/index.ts` | Datei kompakt in den Kontext importieren |
| `ultrathink:` | Prefix fuer Extended Reasoning |
| `/compact` | Kontext komprimieren (eingebauter Claude Code Command, kein Skill) |
| `/` | Autocomplete fuer alle verfuegbaren Commands |

---

## Troubleshooting

**Claude editiert dieselbe Datei in einer Endlosschleife?**
Circuit-Breaker greift nach 3 Edits. Stop, Problem anders beschreiben.

**Kontext ist nach langer Session veraltet?**
`Esc Esc` zum Komprimieren, oder `/pause` + neue Session + `/resume`.

**Spec-Schritte nach Crash teilweise abgehakt?**
`/spec-work NNN` erneut ausfuehren — erkennt `[x]` Schritte und setzt beim ersten offenen fort.

**Wer blockt eigentlich was?**
`permissions.deny` in `.claude/settings.json` blockt harte Reads wie `.env*`, `dist/` oder Lockfiles. Hooks wie `protect-files.sh` und `context-monitor.sh` sind dagegen lokale Sicherheitsnetze fuer Edit-Flows, Warnings und Runtime-Hinweise.

**Build schlaegt nach spec-work fehl?**
`/build-fix` — parsed den ersten Error, fixt minimal, rebuildet, wiederholt.

**Command nicht gefunden?**
`/` in Claude Code tippen fuer Autocomplete, oder in `.claude/skills/` schauen.

**Sandbox blockt Pre-Commit Hook?**
Manuell committen: `! git commit -m "msg"`

---

*Installiert von `@onedot/ai-setup`. Wird nicht automatisch in den Claude-Kontext geladen.*
