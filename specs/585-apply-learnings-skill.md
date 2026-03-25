# Spec: Apply Learnings to Project Context

> **Spec ID**: 585 | **Created**: 2026-03-25 | **Status**: in-review | **Complexity**: medium | **Branch**: —

## Goal

Learnings aus LEARNINGS.md werden automatisch in die richtigen Projekt-Zieldateien übertragen — LEARNINGS.md wird zum Transit-Log, nicht zum Endlager.

## Context

`/reflect` schreibt Learnings nach `.agents/context/LEARNINGS.md`, aber die Learnings landen nie automatisch in den Zieldateien (`rules/`, `ARCHITECTURE.md`, `CONVENTIONS.md`, `CLAUDE.md`). Das führt dazu, dass Learnings akkumulieren ohne Wirkung zu entfalten. Der User muss manuell einen Apply-Schritt ausführen — oder die Learnings bleiben dauerhaft ungenutzt.

Lösung: neuer Skill `/apply-learnings` der LEARNINGS.md liest, jeden Eintrag dem richtigen Zieldatei zuordnet, und ihn dort einträgt. Der Skill kann auch direkt am Ende von `/reflect` aufgerufen werden (empfohlen).

## Steps

- [x] Step 1: Skill-Struktur anlegen — `.claude/skills/apply-learnings/SKILL.md`
- [x] Step 2: Mapping-Logik definieren (Kategorie → Zieldatei):
  - `Corrections` → `.claude/rules/general.md`
  - `Architecture` → `.agents/context/ARCHITECTURE.md`
  - `Stack` → `.agents/context/STACK.md`
  - `Conventions` → `.agents/context/CONVENTIONS.md`
  - `Agent Delegation` → `.claude/rules/agents.md`
  - Fallback: User fragt welche Datei
- [x] Step 3: Apply-Logik implementieren — für jeden unmarkierten Learning-Eintrag:
  1. Zieldatei lesen
  2. Prüfen ob Inhalt bereits vorhanden (Duplikat-Check)
  3. Minimal an passender Stelle einarbeiten (Edit, nicht Append-Dump)
  4. Eintrag in LEARNINGS.md als `~~applied~~` markieren
- [x] Step 4: `/reflect` Skill prüfen ob Apply-Step dort integriert werden kann (letzter Schritt)
- [x] Step 5: LEARNINGS.md Struktur anpassen — `## Applied` Section hinzufügen für Archiv
- [x] Step 6: Smoke-Test — LEARNINGS.md mit 2-3 Test-Einträgen befüllen, Skill ausführen, Zieldateien prüfen

## Acceptance Criteria

- [x] `/apply-learnings` existiert als lokaler Skill in `.claude/skills/`
- [x] Jede Learning-Kategorie wird der richtigen Zieldatei zugeordnet
- [x] Bereits vorhandene Inhalte werden nicht doppelt eingetragen
- [x] Eingetragene Learnings werden in LEARNINGS.md als applied markiert
- [x] LEARNINGS.md bleibt als Audit-Log erhalten (kein Löschen)
- [x] Skill ist token-effizient: liest nur die betroffenen Zieldateien

## Files to Modify

- `.claude/skills/apply-learnings/SKILL.md` — neu erstellen
- `.agents/context/LEARNINGS.md` — Applied-Section ergänzen
- (Optional) Installed reflect skill — Apply-Step am Ende

## Out of Scope

- Automatische LEARNINGS.md-Generierung (das bleibt bei /reflect)
- Learnings aus anderen Projekten importieren
- LLM-basierte Kategorie-Erkennung — Rule-based Mapping reicht
