# Spec 577: Leere Sektionen aus templates/CLAUDE.md entfernen

> **Spec ID**: 577 | **Created**: 2026-03-25 | **Status**: in-review | **Complexity**: low | **Branch**: —

## Goal

`## Commands` und `## Critical Rules` ohne Inhalt aus `templates/CLAUDE.md` entfernen, da sie ~120 Token pro Session in allen User-Installationen verschwenden.

## Context

Token-Overhead-Audit (Observation #23989, 2026-03-24) identifizierte leere Placeholder-Sektionen in templates/CLAUDE.md. Bestätigt am 2026-03-25: File hat 715 Bytes, beide Sektionen sind leer. Jeder User der das Template installiert zahlt pro Session ~120 Token für Headings ohne Content.

## Steps

- [x] Step 1: `templates/CLAUDE.md` lesen und leere Sektionen identifizieren
- [x] Step 2: `## Commands` und `## Critical Rules` Sektionen entfernen
- [x] Step 3: Prüfen ob weitere leere Sektionen existieren und ggf. entfernen

## Acceptance Criteria

- [x] `templates/CLAUDE.md` enthält keine leeren `##` Sektionen mehr
- [x] Alle verbleibenden Sektionen haben inhaltliche Substanz
- [x] File-Größe kleiner als vorher

## Files to Modify

- `templates/CLAUDE.md` — leere Sektionen entfernen

## Out of Scope

- Inhaltliche Änderungen an bestehenden Sektionen
- Änderungen an anderen CLAUDE.md Dateien im Projekt
