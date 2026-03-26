# Brainstorm: Just Ship Adaptionen für npx-ai-setup

> **Source**: https://github.com/yves-s/just-ship
> **Status**: ✅ Completed — Research abgeschlossen, 4 Kandidaten-Specs erstellt (571-574, alle cancelled)
> **Erstellt**: 2026-03-24
> **Zweck**: Research welche Patterns aus dem Just Ship Multi-Agent-Framework adaptierbar sind

---

## Inventar-Vergleich

### Gesamtübersicht

| Kategorie | Just Ship | npx-ai-setup |
|-----------|-----------|--------------|
| Commands | 13 | 28 |
| Agents | 8 | 12 |
| Skills | 8 | 12 dirs |
| Hooks | 4 | 17 |
| Scripts | 4 | 16 |
| Rules | 5 | 9 |

---

## Bestandsvergleich: Was haben wir schon?

### Commands

| Just Ship | Unser Equivalent | Status |
|-----------|-----------------|--------|
| `/develop` (Ticket → Branch → Implement → Build → Review → PR) | `/spec-work` + `/commit` + `/pr` (einzeln) | ⚠️ Partial — kein End-to-End-Pipeline-Command |
| `/implement` (Feature ohne Ticket, 8-Schritt-Agent-Workflow) | `/yolo` + `/spec-work` | ⚠️ Partial — kein Agent-Orchestrierung |
| `/ship` (Commit → Push → PR → Merge → Cleanup, autonom) | `/commit` + `/pr` (getrennt, kein auto-merge) | ⚠️ Partial — kein autonomer Shipping-Flow |
| `/ticket` (PM-Quality Ticket schreiben) | `/spec` (Spec erstellen) | ✅ Covered — Specs sind unser Equivalent |
| `/status` (Aktueller Stand: Ticket, Git, Changes) | Kein Equivalent | ❌ Missing |
| `/setup-just-ship` (Stack-Erkennung, Config generieren) | `bin/ai-setup.sh` (unser Kernprodukt) | ✅ Covered — das IST unser Produkt |
| `/just-ship-update` (Templates abgleichen) | `/update` Command | ✅ Covered |
| `/connect-board` / `/disconnect-board` / `/add-project` | — | ❌ Missing (Board-spezifisch, nicht relevant) |
| `/creative-design` | — | ❌ Missing |
| `/frontend-design` | Frontend-Developer Agent | ⚠️ Partial |
| `/ux-planning` | — | ❌ Missing |

### Agents

| Just Ship | Unser Equivalent | Status |
|-----------|-----------------|--------|
| Orchestrator (Opus, zentrale Steuerung) | — | ❌ Missing — kein zentraler Orchestrator |
| Backend (Sonnet, API + Business Logic) | — | ❌ Missing (wir sind stack-agnostisch) |
| Frontend (Sonnet, UI + Design-Awareness) | `frontend-developer` Agent | ⚠️ Partial — ohne Design-Thinking |
| Data Engineer (Haiku, DB + Migrations) | — | ❌ Missing (stack-spezifisch) |
| DevOps (Haiku, Build-Checks) | `build-validator` Agent | ✅ Covered |
| QA (Haiku, Acceptance + Tests) | `verify-app` + `test-generator` | ✅ Covered |
| Security (Haiku, Security Review) | `security-reviewer` Agent | ✅ Covered |
| Triage (Haiku, Ticket-Qualität) | `/spec-validate` Command | ✅ Covered |

### Skills

| Just Ship | Unser Equivalent | Status |
|-----------|-----------------|--------|
| `creative-design.md` (Anti-AI-Slop, Greenfield Design) | — | ❌ Missing |
| `frontend-design.md` (Design-System, shadcn/ui) | `frontend-developer` Agent | ⚠️ Partial |
| `ux-planning.md` (User Flows, Screen Inventory, IA) | — | ❌ Missing |
| `design.md` (Token Architecture, Component States) | — | ❌ Missing |
| `ticket-writer.md` (PM-Quality Tickets) | `/spec` Command | ✅ Covered |
| `webapp-testing.md` (Playwright Testing) | `/test` Command | ⚠️ Partial |
| `backend.md` / `data-engineer.md` | — | ❌ Missing (stack-spezifisch) |

### Hooks

| Just Ship | Unser Equivalent | Status |
|-----------|-----------------|--------|
| `detect-ticket.sh` (SessionStart: Branch → Ticket) | `context-loader.sh` (SessionStart) | ⚠️ Partial — wir laden Context, nicht Tickets |
| `on-agent-start.sh` (SubagentStart Event) | — | ❌ Missing |
| `on-agent-stop.sh` (SubagentStop Event) | — | ❌ Missing |
| `on-session-end.sh` (SessionEnd Event) | — | ❌ Missing |

### Rules

| Just Ship | Unser Equivalent | Status |
|-----------|-----------------|--------|
| `no-premature-merge.md` | `git.md` (teilweise) | ⚠️ Partial |
| `brainstorming-design-awareness.md` | — | ❌ Missing |
| `no-duplicate-finishing-skill.md` | — | N/A (Superpowers-spezifisch) |
| `supabase-db-routing.md` | — | N/A (projekt-spezifisch) |
| `ticket-number-format.md` | — | N/A (projekt-spezifisch) |

---

## Kandidaten für Adaption

### 1. End-to-End Development Pipeline Command

**Was es tut**: Just Ship's `/develop` orchestriert 11 Schritte autonom: Ticket holen → Status update → Branch → Triage → Implement (parallele Agents) → Build → QA Review → Docs → Commit → Push → PR.

**Unsere Lücke**: Wir haben die Einzelteile (`/spec-work`, `/commit`, `/pr`, `/review`), aber keinen Command der alles verkettet. User muss manuell zwischen Schritten navigieren.

**Aufwand**: Mittel — neuer Command der bestehende Commands orchestriert
**Wert**: ★★★★ — Reduziert manuelle Schritte drastisch
**Empfehlung**: Adaptieren als `/develop` oder `/auto` Command, der `/spec-work` → `/review` → `/commit` → `/pr` verkettet

---

### 2. Agent Lifecycle Hooks (SubagentStart/Stop)

**Was es tut**: Just Ship trackt jeden Agent-Start und -Stop via Pipeline-Events. Ermöglicht Transparenz und Metriken.

**Unsere Lücke**: Wir haben 17 Hooks, aber keinen für Agent-Lifecycle. Kein Tracking welche Agents wie oft/lange laufen.

**Aufwand**: Gering — 2 Hook-Dateien + Event-Logging
**Wert**: ★★★ — Debugging-Hilfe, Token-Optimierung (welche Agents kosten am meisten?)
**Empfehlung**: Adaptieren für Metriken/Logging, ohne Board-Integration

---

### 3. `/ship` — Autonomer Shipping-Flow

**Was es tut**: Commit → Push → PR erstellen → Merge (Squash) → Zurück auf main → Pull. Alles ohne Rückfrage.

**Unsere Lücke**: `/commit` und `/pr` sind getrennt. Kein auto-merge. User muss 3 Commands ausführen.

**Aufwand**: Gering — neuer Command der `/commit` + `/pr` + merge verkettet
**Wert**: ★★★★ — Massiver Workflow-Speed-Up für "fertig, ab damit"
**Empfehlung**: Adaptieren, aber **mit Safety-Gate**: Auto-merge nur auf explizite Bestätigung ("ship it", "passt")

---

### 4. Konversationelle Trigger

**Was es tut**: Wörter wie "passt", "done", "fertig" triggern automatisch `/ship`.

**Unsere Lücke**: Keine konversationellen Trigger. User muss explizit Commands aufrufen.

**Aufwand**: Gering — Rule in `.claude/rules/` die bestimmte Patterns erkennt
**Wert**: ★★ — Nettes UX-Feature, aber Risiko für ungewollte Aktionen
**Empfehlung**: Optional — als Rule für eigene Projekte dokumentieren, nicht als Default

---

### 5. Design Skills Suite (Creative Design, UX Planning, Frontend Design)

**Was es tut**: 3 spezialisierte Skills für Design-Arbeit:
- `creative-design.md`: Anti-AI-Slop-Regeln, Greenfield-Design-Prinzipien
- `ux-planning.md`: User Flows, Screen Inventory, Information Architecture
- `frontend-design.md`: Design-System-Compliance, Component States, Token Architecture

**Unsere Lücke**: Wir haben `frontend-developer` Agent, aber keine Design-Methodik-Skills. Kein Anti-AI-Slop, kein UX-Planning-Framework.

**Aufwand**: Mittel — 3 neue Skill-Dateien
**Wert**: ★★★ — Bessere Design-Qualität bei UI-lastigen Projekten
**Empfehlung**: `creative-design` und `ux-planning` als optionale Skills für Frontend-Stacks (React, Vue, Nuxt, Next.js)

---

### 6. `/status` Command

**Was es tut**: Zeigt kompakte Übersicht: aktives Ticket, Git-Branch, uncommitted Changes.

**Unsere Lücke**: Kein Quick-Status-Command. User muss `git status` + `/spec-board` separat aufrufen.

**Aufwand**: Gering — einfacher Command
**Wert**: ★★ — Nice-to-have, aber `git status` reicht meistens
**Empfehlung**: Niedrige Priorität — `/spec-board` deckt den Spec-Status ab

---

### 7. Orchestrator-Pattern (Zentrale Agent-Steuerung)

**Was es tut**: Ein Opus-Level Orchestrator plant die Arbeit selbst (kein separater Planner), delegiert an spezialisierte Agents mit konkreten Code-Snippets statt vagen Prompts. Key Insight: "Pass exact code snippets to implementation agents rather than vague exploration prompts."

**Unsere Lücke**: Unsere Agents arbeiten isoliert. Kein zentrales Routing-Pattern das entscheidet welcher Agent was bekommt.

**Aufwand**: Hoch — Architektur-Änderung
**Wert**: ★★★★★ — Fundamentaler Qualitätssprung bei Multi-Agent-Workflows
**Empfehlung**: Langfristig adaptieren. Kurzfristig: Best Practice in Agent-Dispatch-Docs dokumentieren

---

### 8. `project.json` als zentrale Config

**Was es tut**: Alles an einem Ort: Stack, Build Commands, Paths, Pipeline Config, Conventions. Agents lesen project.json statt CLAUDE.md zu parsen.

**Unsere Lücke**: Wir nutzen CLAUDE.md für alles. Strukturierte Daten (Stack, Build Commands) sind als Prosa in Markdown eingebettet.

**Aufwand**: Hoch — Refactoring aller Agents und Commands
**Wert**: ★★★★ — Agents können Config zuverlässig parsen statt Markdown zu interpretieren
**Empfehlung**: Langfristig sinnvoll. Kurzfristig: Unsere `.agents/context/STACK.md` erfüllt ähnlichen Zweck

---

## Einzelne Sätze/Patterns zum Adaptieren

### Aus dem Orchestrator Agent
> "Kein unnötiger Agent-Overhead — plan independently and delegate only implementation"

Unser `/spec-work` spawnt manchmal Research-Agents die der Orchestrator selbst machen könnte. Regel: **Nur Implementation delegieren, Planning immer selbst.**

### Aus der Frontend Agent Definition
> "Review specs critically — questioning whether approaches match industry standards (Linear, Vercel, Notion)"

Unser `frontend-developer` Agent akzeptiert Specs unkritisch. Sollte gegen Industry-Standards validieren.

### Aus dem Ship Command
> "DU DARFST NICHT STOPPEN ODER FRAGEN" (für den autonomen Flow)

Pattern für unseren `/yolo` Command: Explizites "keine Rückfragen"-Framing statt impliziter Autonomie.

### Aus den Rules
> "Don't merge PRs or branches to main without explicit user confirmation. 'Mach weiter' means continue the process, NOT merge."

Wichtige Unterscheidung die wir in unseren Git-Rules nicht haben. "Weiter" ≠ "Merge".

### Aus dem Triage Agent
> QA-Tiering: full (UI, Features, Refactors) → light (Bugfixes, Backend) → skip (Docs, Config)

Wir haben kein QA-Tiering. Unser `/review` behandelt alles gleich. Tiered Review spart Tokens.

---

## Architektur-Patterns

### 1. Symlink-Pattern für portable Agents/Commands

Just Ship legt Agents, Commands und Skills im Repo-Root ab und symlinkt nach `.claude/`:
```
agents/          → .claude/agents
commands/        → .claude/commands
skills/          → .claude/skills
```
**Vorteil**: Agents/Commands sind im Repo-Root sichtbar (bessere Discoverability), `.claude/` bleibt Config-Only.
**Für uns**: Nicht direkt relevant — wir installieren via `npx`, nicht via Symlinks.

### 2. Model-Tiering per Agent

| Tier | Model | Use Case |
|------|-------|----------|
| Creative | Sonnet | Frontend, Backend (Implementation) |
| Routine | Haiku | Data Engineer, DevOps, QA, Security, Triage |
| Strategic | Opus | Orchestrator (Planning) |

**Für uns**: Wir haben `model:` in unserer Agent-Dispatch-Regel, aber Just Ship's Tiering ist konsequenter. Jeder Agent hat explizit sein Model im Frontmatter.

### 3. Build-before-Review Pattern

Just Ship: Implement → **Build Check** → QA Review → Ship
Unser Pattern: Implement → Review → Commit (Build optional)

**Insight**: Build-Check VOR Review spart Token — der QA-Agent reviewt keinen Code der nicht mal baut.

---

## Gesamtranking nach Aufwand/Nutzen

| # | Kandidat | Wert | Aufwand | Empfehlung |
|---|----------|------|---------|------------|
| 1 | `/ship` (autonomer Shipping-Flow) | ★★★★ | Gering | **Adaptieren** — neuer Command |
| 2 | End-to-End Pipeline (`/develop`) | ★★★★ | Mittel | **Adaptieren** — orchestriert bestehende Commands |
| 3 | QA-Tiering (full/light/skip) | ★★★ | Gering | **Adaptieren** — in `/review` integrieren |
| 4 | Agent Lifecycle Hooks | ★★★ | Gering | **Adaptieren** — Metriken + Debugging |
| 5 | "Weiter ≠ Merge" Rule | ★★★ | Trivial | **Adaptieren** — in `git.md` Rule |
| 6 | Build-before-Review Pattern | ★★★ | Gering | **Adaptieren** — in `/spec-work` Reihenfolge |
| 7 | Design Skills Suite | ★★★ | Mittel | **Optional** — für Frontend-Stacks |
| 8 | Orchestrator-Pattern | ★★★★★ | Hoch | **Langfristig** — dokumentieren, schrittweise |
| 9 | `project.json` zentrale Config | ★★★★ | Hoch | **Langfristig** — STACK.md reicht vorerst |
| 10 | Konversationelle Trigger | ★★ | Gering | **Optional** — Risiko ungewollter Aktionen |
| 11 | `/status` Command | ★★ | Gering | **Niedrig** — git status reicht |

---

## Was Just Ship NICHT hat, was wir haben

- **Spec-Driven Development** komplett (Board, Create, Validate, Work, Review) — Just Ship nutzt Tickets statt Specs
- **Token-Optimierung** (RTK, Prep-Scripts, Defuddle) — Just Ship hat keine Token-Sparmaßnahmen
- **Multi-Stack Support** (26 Skill-Templates für verschiedene Stacks) — Just Ship ist Single-Project
- **Security Scanning** (`/scan`) — Just Ship hat nur Code-Review
- **Tech Debt Management** (`/techdebt`) — Just Ship hat nichts Vergleichbares
- **Session Management** (`/pause`, `/resume`) — Just Ship hat kein Session-Persistence
- **Code Analysis** (`/analyze`, `/reflect`) — Just Ship hat keine Retrospektiven
- **Cross-Platform** (Codex, Gemini Delegation) — Just Ship ist Claude-Only
