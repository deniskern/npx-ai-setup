# Learnings

> Curated session learnings from /reflect. Persistent across updates — generate.sh never touches this file.

## Corrections
- /research muss Kandidaten gegen CONCEPT.md und Projektphilosophie validieren BEVOR Specs erstellt werden — Session 2026-03-24 erstellte 4 Specs, 3 wurden nach Review cancelled (safety-first violation, wrong architecture layer, feature already exists)

## Architecture
- Stack-spezifische Skills gehören in Boilerplate-Repos (lib/boilerplate.sh), nicht in den Base-Setup (lib/skills.sh) — lib/skills.sh Kommentar bestätigt: "Stack-specific skills are handled by boilerplate repos or /find-skills on demand"
- Dev-Tools (Metriken, Debugging) gehören in .claude/ dieses Repos, nicht in templates/ — Templates sind für End-User, Dev-Tools für Maintainer
- SubagentStart und SubagentStop sind valide Claude Code Hook-Types — bestätigt via Just Ship settings.json und eigenem Smoke-Test
