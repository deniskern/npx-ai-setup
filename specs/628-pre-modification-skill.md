# Spec: Pre-Modification Skill

> **Spec ID**: 628 | **Created**: 2026-04-08 | **Status**: in-review | **Complexity**: medium | **Branch**: feat/628-pre-modification-skill

## Problem

Grosse Code-Änderungen (Multi-File-Refactorings, neue Abstraktionsschichten, Systemintegrationen) werden ohne vorherige Risikoabschätzung gestartet. Der `code-architect`-Agent existiert bereits, wird aber nur auf expliziten Befehl aufgerufen. Ein automatischer Pre-Check vor risikoreichen Änderungen fehlt — Blast-Radius, betroffene Dependencies und architekturelle Konflikte werden erst im Nachhinein sichtbar.

## Acceptance Criteria

1. Ein Skill `pre-modification` existiert unter `templates/skills/pre-modification/SKILL.template.md`
2. Der Skill hat `user-invocable: false` — er wird nie manuell aufgerufen, nur automatisch durch Trigger
3. Der Skill triggert **nur** bei Multi-File- oder architekturellen Änderungen (Scoping-Kriterien, siehe unten) — nicht bei Single-File-Edits oder Trivial-Changes
4. Bei Trigger: `code-architect`-Agent wird via `Agent`-Tool aufgerufen für Risikoabschätzung
5. Ausgabe enthält immer: Blast-Radius-Schätzung, betroffene Dependencies, architekturelle Bedenken
6. Verdict ist immer eines von: `GO` / `CAUTION` / `STOP` mit einzeiligem Rationale
7. Fallback: Wenn `code-architect` keine verwertbare Antwort liefert, Warnung ausgeben und fortfahren (kein hartes Blocking)
8. Skill wird via `install_agents()` / `install_skills()` in Zielprojekte installiert — keine manuelle Registrierung nötig
9. Smoke-Tests laufen grün

## Scoping-Kriterien: WANN triggern, WANN nicht

### Trigger (Skill aktiviert sich)
- Änderungen an 3+ Dateien in einem Task beschrieben
- Refactoring-Keywords im Task: "refactor", "restructure", "migrate", "replace X with Y", "move X to Y"
- Neue Abstraktionsschichten: "create a service", "add a new module", "introduce a layer"
- Cross-System-Änderungen: API + DB + Frontend gleichzeitig
- Architektur-Keywords: "architecture", "redesign", "rewrite", "extract", "split", "merge modules"

### Skip (Skill schweigt)
- Single-File-Edits ohne architekturellen Impact (z.B. "fix typo in component", "update copy")
- Neue Dateien die nichts Bestehendes ändern (neue Tests, neue Docs, neue Config-Values)
- Style/Lint-Fixes
- Tasks mit explizitem `--no-review`-Flag oder bereits nach `/review` laufend
- Kleine Bug-Fixes in isolierten Funktionen (kein State, keine Dependencies)

## Implementierungsschritte

### Step 1 — Template erstellen
Datei: `templates/skills/pre-modification/SKILL.template.md`

Inhalt gemäss SKILL.md Content Block unten.

### Step 2 — Smoke-Test prüfen / anpassen
Datei: `tests/smoke/` (existierende Test-Suite prüfen)

- Prüfen ob Smoke-Tests Skills per Name validieren
- Falls ja: `pre-modification` zur erwarteten Skill-Liste hinzufügen
- Keine neuen Test-Dateien erstellen — bestehende anpassen

### Step 3 — Smoke-Test laufen lassen
```bash
bash tests/smoke/run-tests.sh
```

## SKILL.md Content

Das folgende ist der vollständige Inhalt von `templates/skills/pre-modification/SKILL.template.md`:

```markdown
---
name: pre-modification
description: "ALWAYS run this BEFORE modifying, refactoring, or restructuring existing code across multiple files or introducing new architectural layers."
user-invocable: false
---

# Pre-Modification Risk Assessment

Automatic pre-flight check before risky code changes. Delegates to `code-architect` for blast-radius analysis and returns a GO / CAUTION / STOP verdict.

## Trigger Conditions

Run this skill when the task involves ANY of:
- Changes to 3 or more existing files
- Refactoring, restructuring, migrating, or replacing existing code
- Introducing new abstractions (services, modules, layers, shared utilities)
- Cross-system changes (frontend + backend + DB in the same task)
- Keywords: "refactor", "restructure", "migrate", "rewrite", "extract", "split", "merge"

## Skip Conditions

Do NOT run when:
- Single-file edits without system-wide impact
- Adding new files that don't modify existing behaviour
- Style, lint, or copy fixes
- Bug fixes in isolated functions with no shared state

---

## Step 1 — Assess Scope

Before calling code-architect, extract from the task description:
- **Target files**: Which files will be modified? List them explicitly.
- **Change type**: Refactor / Migration / New Abstraction / Cross-System / Other
- **Entry points affected**: Are public APIs, exported functions, or shared interfaces touched?

If fewer than 3 files are affected AND no architectural keywords are present, stop here and proceed without review.

## Step 2 — Delegate to code-architect

Use the Agent tool to invoke `code-architect` with the following prompt:

```
Pre-modification risk assessment requested.

Task description: [paste the user's task description]

Target files:
[list of files to be modified]

Change type: [Refactor / Migration / New Abstraction / Cross-System]

Please assess:
1. Blast radius — what else could break if these files change?
2. Dependencies affected — imports, consumers, callers of changed code
3. Architectural concerns — does this change fight the existing architecture?
4. Verdict: PROCEED / PROCEED WITH CHANGES / REDESIGN
```

## Step 3 — Summarize and Recommend

Parse the code-architect output and present a compact summary:

```
## Pre-Modification Check

**Blast Radius**: [Low / Medium / High] — [one sentence: what could break]
**Dependencies**: [list of affected modules/files, max 5]
**Architectural Concern**: [NONE / LOW / HIGH] — [one sentence if any]

**Verdict**: GO / CAUTION / STOP
[One sentence rationale]
```

Verdict mapping from code-architect output:
- `PROCEED` → `GO`
- `PROCEED WITH CHANGES` → `CAUTION` (list the required changes)
- `REDESIGN` → `STOP` (do not proceed — link to the concern)

## Step 4 — Fallback

If code-architect returns no output, an error, or content that cannot be parsed:

```
⚠ Pre-modification check incomplete — code-architect did not return a usable assessment.
Proceeding with caution. Recommend manual review before merging.
```

Continue with the task. Never block on a fallback — a missing review is a warning, not a hard stop.

## Rules

- Do NOT implement anything. This skill is assessment-only.
- If verdict is STOP, present the concern and ask the user to confirm before continuing.
- If verdict is CAUTION, list the required changes and ask the user if they want to address them first.
- If verdict is GO, proceed immediately without further prompts.
- Keep the summary under 10 lines — brevity over completeness.
```

## Files to Create / Modify

| File | Action |
|------|--------|
| `templates/skills/pre-modification/SKILL.template.md` | Create |
| `tests/smoke/` (relevant test file, TBD after inspection) | Modify — add `pre-modification` to expected skill list |

## Out of Scope

- MCP-basiertes `get_risk()` wie bei Repowise — kein MCP-Equivalent vorhanden
- Blocking auf Basis von Verdict (STOP ist immer user-confirmable, kein hartes Gate)
- Konfigurierbare Schwellwerte (z.B. ab wie vielen Files trigger) — erst wenn Bedarf aus Nutzung entsteht
- Anpassung des `code-architect`-Agents selbst

## Verified Assumptions

- Skills werden 1:1 aus `templates/skills/` nach `.claude/skills/` kopiert via `install_skills()` in `lib/setup.sh:663` — keine separate Registrierung nötig
- `code-architect`-Agent liegt in `templates/agents/code-architect.md` und wird via `install_agents()` in `lib/setup-skills.sh:21` in Zielprojekte installiert — beide landen in `.claude/agents/`
- `user-invocable: false` verhindert manuelle Aufrufbarkeit via Skill-Listing
- Kein Skip-Flag für `pre-modification` in `install_skills()` nötig (kein `test-setup`-Äquivalent)
