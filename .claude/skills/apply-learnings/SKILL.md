---
name: apply-learnings
description: Applies pending learnings from LEARNINGS.md into the correct project context files. Marks applied entries so they are not processed again.
model: sonnet
allowed-tools: Read, Edit, Glob, Grep
---

Liest `.agents/context/LEARNINGS.md` und überträgt jeden unerledigten Eintrag in die passende Zieldatei. LEARNINGS.md bleibt als Audit-Log erhalten — erledigte Einträge werden markiert.

## Category → Target File Mapping

| LEARNINGS.md Section | Zieldatei |
|---|---|
| `## Corrections` | `.claude/rules/general.md` |
| `## Architecture` | `.agents/context/ARCHITECTURE.md` |
| `## Stack` | `.agents/context/STACK.md` |
| `## Conventions` | `.agents/context/CONVENTIONS.md` |
| `## Agent Delegation` | `.claude/rules/agents.md` |
| `## Applied` | — (bereits erledigt, überspringen) |

Falls eine Section keiner Zieldatei zugeordnet werden kann: User fragen.

## Process

### 1. LEARNINGS.md lesen

Read `.agents/context/LEARNINGS.md`.

Identifiziere alle **unerledigten** Einträge:
- Nicht in der `## Applied` Section
- Nicht mit `~~` gestrichen

Überspringe: Einträge in `## Applied`, Zeilen mit `~~text~~`.

Gruppiere nach Section (Corrections, Architecture, Stack, etc.).

### 2. Für jeden Eintrag: Zieldatei bestimmen

Nutze das Mapping oben. Bei unbekannter Section: frage den User welche Datei gemeint ist.

### 3. Zieldatei lesen und Duplikat-Check

Read die Zieldatei. Prüfe ob der Kern-Inhalt des Eintrags bereits vorhanden ist (inhaltlich, nicht wörtlich). Falls ja: Eintrag überspringen und direkt als Applied markieren.

### 4. Minimal einarbeiten

Füge den Eintrag an der passenden Stelle in der Zieldatei ein:
- `rules/*.md` — unter der thematisch nächsten Sektion als Bullet
- `ARCHITECTURE.md` — unter `## Key Patterns` oder thematisch passender Sektion
- `STACK.md` — unter passendem Block
- `CONVENTIONS.md` — unter passendem Block

**Nicht als Block-Append** — inhaltlich integrieren. Max 1-2 Zeilen pro Eintrag.

### 5. Eintrag in LEARNINGS.md als Applied markieren

Nach erfolgreichem Einarbeiten: verschiebe den Eintrag von seiner Section nach `## Applied`.

Format in `## Applied`:
```
- ~~[original text]~~ → `path/to/target.md`
```

Falls `## Applied` noch nicht existiert: am Ende der Datei hinzufügen.

### 6. Abschlussbericht

Nach allen Einträgen:
```
apply-learnings — Abschlussbericht
Angewandt: N Einträge
Übersprungen (Duplikat): N Einträge
Zieldateien geändert: [Liste]
```

## Rules

- Niemals Inhalte aus Zieldateien löschen — nur hinzufügen
- Nie mehr als 2 Zeilen pro Eintrag in Zieldateien einfügen — CLAUDE.md Token-Budget gilt
- Duplikate still überspringen, nicht melden (außer im Abschlussbericht)
- Bei Unsicherheit über Zieldatei: fragen, nicht raten
- LEARNINGS.md-Einträge die Worktree-Files referenzieren: erst prüfen ob File existiert (Glob), bevor angewandt wird
