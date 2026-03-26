# Spec: Design Skills Suite — Template Skills für Frontend-Stacks

> **Spec ID**: 573 | **Created**: 2026-03-24 | **Status**: ✅ completed (cancelled) | **Complexity**: medium | **Branch**: —
> **Source**: [specs/570-research-just-ship.md](570-research-just-ship.md) Kandidat #3

## Goal
3 Design-Skills als Template-Skills die bei Frontend-Stack-Erkennung (React, Vue, Next.js, Nuxt, Astro) automatisch installiert werden.

## Context
Just Ship hat spezialisierte Design-Skills mit Anti-AI-Slop-Regeln und UX-Methodik. Unser `frontend-developer` Agent hat keine Design-Thinking-Grundlage. Frontend-Projekte profitieren von strukturierter Design-Methodik statt generischer AI-Ästhetik.

## Steps
- [ ] Step 1: `templates/skills/creative-design/` erstellen
  - Anti-AI-Slop-Regeln: keine generischen Fonts, keine Purple Gradients, keine centered-everything Layouts
  - Greenfield-Design-Prinzipien: Purpose, Tone, Differentiation
  - Typography-Regeln, Farbwahl-Methodik
  - Adaptiert von Just Ship, aber stack-agnostisch formuliert
- [ ] Step 2: `templates/skills/ux-planning/` erstellen
  - User Flows VOR Screens designen
  - Screen Inventory: alle Screens + States auflisten
  - Information Architecture: Navigation, Hierarchie
  - State Coverage: empty, loading, error, success, partial
- [ ] Step 3: `templates/skills/frontend-design/` erstellen
  - Design-System-Compliance (Tokens, Components)
  - Component States: default, hover, active, focus, disabled, loading, error
  - Accessibility: 44x44px Touch Targets, WCAG 2.1 AA
  - Transitions: 200ms Standard, Easing-Regeln
- [ ] Step 4: Stack-Erkennung in `lib/skills.sh` erweitern — diese 3 Skills installieren wenn Frontend-Framework erkannt wird
- [ ] Step 5: Testen: `ai-setup` auf React-Projekt → Design Skills werden installiert

## Acceptance Criteria
- [ ] 3 Skill-Verzeichnisse unter `templates/skills/` mit vollständigen Skill-Dateien
- [ ] Skills werden bei React/Vue/Next/Nuxt/Astro-Erkennung automatisch installiert
- [ ] Skills sind stack-agnostisch (nicht an shadcn/ui oder spezifisches Framework gebunden)
- [ ] Anti-AI-Slop-Regeln sind konkret und prüfbar (nicht vage Prinzipien)
- [ ] Jeder Skill hat klares "When to use" / "Avoid if"

## Files to Modify
- `templates/skills/creative-design/` — neuer Skill (erstellen)
- `templates/skills/ux-planning/` — neuer Skill (erstellen)
- `templates/skills/frontend-design/` — neuer Skill (erstellen)
- `lib/skills.sh` — Stack-Erkennung erweitern

## Out of Scope
- Design-System-Generator (Skills sind Methodik, kein Tooling)
- Figma/Sketch-Integration
- Marketplace-Publishing (kommt ggf. später)
