# Spec: Spec-Skill Code-Flow-Analyse vor Step-Generierung

> **Spec ID**: 595 | **Created**: 2026-03-27 | **Status**: in-progress | **Complexity**: simple | **Branch**: —

## Goal
`/spec` soll vor Step-Generierung die Laufzeit-Logik der betroffenen Funktionen analysieren, damit Steps keine existierende Logik duplizieren und Guards/Fehlerfälle als explizite Steps erscheinen.

## Context
Spec 594 hatte 3 Qualitätsprobleme: redundanter Step (Funktion setzt Variable schon), übersehener Guard (`has_system_config()` blockt Updates), Fehlerfall nur in Acceptance Criteria statt als Step. Ursache: Phase 1d skizziert mental, liest aber nicht die Call-Chain und Guard-Conditions der betroffenen Funktionen. Phase 1e prüft nur statische Assumptions, keine Laufzeit-Logik.

### Verified Assumptions
- Phase 1d ist "mental sketch" ohne Code-Flow-Pflicht — Evidence: `SKILL.md:28-33` | Confidence: High
- Phase 1e scannt Files nur für Assumptions, nicht für Guards/Conditions — Evidence: `SKILL.md:37-38` | Confidence: High
- Phase 2 Step 3 hat keine Dedup-Prüfung gegen existierende Logik — Evidence: `SKILL.md:52-57` | Confidence: High

## Steps
- [x] Step 1: Phase 1d in `SKILL.md` — neuen Abschnitt "Code-Flow-Analyse" nach dem mentalen Sketch einfügen: Für jede betroffene Funktion den Call-Path tracen (wer ruft was, welche Guards/Conditions, welche Variablen werden gesetzt). Ergebnis als kurze Liste im Chat ausgeben.
- [x] Step 2: Phase 1d in `SKILL.md` — Dedup-Check-Regel hinzufügen: "Jeder Step muss einen NEUEN Code-Change einführen. Wenn existierender Code das bereits tut → kein Step. Guards die den neuen Flow blockieren → eigener Step."
- [x] Step 3: Phase 2 Step 3 in `SKILL.md` — Step-Validierung nach Drafting: "Für jeden Step prüfen: Wird das nicht schon von existierendem Code erledigt? Fehlt ein Step für Guards/Conditions die den neuen Flow blockieren?"

## Acceptance Criteria

### Truths
- [ ] SKILL.md Phase 1d enthält explizite Code-Flow-Analyse-Anweisung
- [ ] SKILL.md Phase 1d enthält Dedup-Check gegen existierende Funktionslogik
- [ ] SKILL.md Phase 2 Step 3 enthält Step-Validierung gegen Redundanz

### Artifacts
- [ ] `.claude/skills/spec/SKILL.md` — erweiterte Phase 1d + Phase 2 Step 3

## Files to Modify
- `.claude/skills/spec/SKILL.md` — Phase 1d erweitern, Phase 2 Step 3 Validierung

## Out of Scope
- Änderungen an `/spec-validate` (bleibt als Safety-Net)
- Änderungen am Spec-Template Format
