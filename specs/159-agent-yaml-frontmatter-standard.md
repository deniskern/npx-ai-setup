# Spec 159: Agent YAML Frontmatter Standard

> Status: Draft
> Referenz: specs/158-evaluate-agency-agents.md (Prio 1, Item 1 + Prio 2, Item 6)

## Goal

Einheitliches YAML-Frontmatter fuer alle Agent-Dateien einfuehren und ein Lint-Script erstellen das die Einhaltung prueft.

## Context

Unsere 12 Agent-Dateien haben bereits Frontmatter (name, description, tools, model, max_turns), aber:
- Kein `emoji` Feld (schnelle visuelle Erkennung)
- Kein `vibe` Feld (Einzeiler-Persoenlichkeit fuer Agent-Verhalten)
- Kein Validierungs-Script das prueeft ob alle Pflichtfelder vorhanden sind
- Kein automatisches Discovery (z.B. `grep "^description:" agents/*.md`)

## Steps

### Step 1: Frontmatter-Schema definieren
- Pflichtfelder: `name`, `description`, `tools`, `model`
- Optionale Felder: `emoji`, `max_turns`, `memory`, `vibe`
- Schema in `templates/agents/README.md` dokumentieren (kurz, max 15 Zeilen)

### Step 2: emoji + vibe zu allen 12 Agents hinzufuegen
- Passende Emojis und Einzeiler-Vibes fuer jeden Agent waehlen
- Beide Verzeichnisse synchron halten: `templates/agents/` + `.claude/agents/`

### Step 3: Agent-Lint-Script erstellen
- `scripts/lint-agents.sh` — prueft:
  - Frontmatter vorhanden (beginnt mit `---`)
  - Pflichtfelder (name, description, tools, model)
  - Pflicht-Sektionen im Body: `## When to Use`, `## Avoid If`, `## Behavior` oder `## Rules`
  - Mindestlaenge: Body >= 20 Zeilen
- Exit 0 bei nur Warnings, Exit 1 bei Errors

### Step 4: Lint in Verify-Workflow integrieren
- Agent-Lint als optionalen Check in build-validator oder als eigenstaendigen CI-Schritt referenzieren

## Acceptance Criteria
- [ ] Alle 12 Agent-Dateien (x2 Verzeichnisse = 24 Dateien) haben vollstaendiges Frontmatter
- [ ] `scripts/lint-agents.sh` existiert und validiert alle Agents fehlerfrei
- [ ] Lint-Script findet absichtlich kaputte Agent-Datei (Negativtest)

## Files to Modify
- `templates/agents/*.md` (12 Dateien)
- `.claude/agents/*.md` (12 Dateien)
- `scripts/lint-agents.sh` (neu)
- `templates/agents/README.md` (neu, optional)

## Out of Scope
- Multi-Tool-Konvertierung (Cursor, Copilot etc.)
- Aenderungen am Agent-Dispatch-System
- Neue Agents
