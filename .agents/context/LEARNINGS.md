# Learnings

> Curated session learnings from /reflect. Persistent across updates — generate.sh never touches this file.

## Corrections
- /research muss Kandidaten gegen CONCEPT.md und Projektphilosophie validieren BEVOR Specs erstellt werden — Session 2026-03-24 erstellte 4 Specs, 3 wurden nach Review cancelled (safety-first violation, wrong architecture layer, feature already exists)
- User-Anfragen genau lesen — "skill-creator" meinte Session-Analyse-Skill für dieses Projekt, nicht generischen Scaffolder
- session-optimize Findings IMMER gegen aktuellen File-State verifizieren bevor Spec erstellt wird — Obs #23989 (typescript.md, domain-skills) waren beide bereits gefixt, hätte unnötige Specs erzeugt

## Architecture
- Stack-spezifische Skills gehören in Boilerplate-Repos (lib/boilerplate.sh), nicht in den Base-Setup (lib/skills.sh) — lib/skills.sh Kommentar bestätigt: "Stack-specific skills are handled by boilerplate repos or /find-skills on demand"
- Dev-Tools (Metriken, Debugging) gehören in .claude/ dieses Repos, nicht in templates/ — Templates sind für End-User, Dev-Tools für Maintainer
- SubagentStart und SubagentStop sind valide Claude Code Hook-Types — bestätigt via Just Ship settings.json und eigenem Smoke-Test
- Spec-Lifecycle-Integrität über drei Entry Points: spec-work (verify-fail Kontext schreiben), pause (Inkonsistenzen in Blockers), spec-board (Type A/B/C Repair)
- session-optimize Skill nutzt claude-mem MCP Search als Datenquelle — 4 parallele Queries nach Kategorien (failures, token-waste, friction, gaps)
- claude-mem Observations können auf Worktree-Files referenzieren die nie nach main committed wurden — Specs 581/582 existierten in Observations aber nicht als Files auf main
- Skills mit `disable-model-invocation: true` UND ohne `model:` auf Agent-Spawns erben das Parent-Session-Modell — bei Opus-Sessions kostet das 5× zu viel (spec-review, techdebt betroffen, beide gefixt 2026-03-25)
