# Spec: /spec Skill — Deeper Questioning + Multi-System Awareness

> **Spec ID**: 646 | **Created**: 2026-04-25 | **Status**: completed | **Complexity**: medium | **Branch**: —

## Goal
`/spec` Skill schärfen: ein konsolidierter AskUserQuestion-Call (≤4 Fragen) für Anforderungs-Klärung, named context-scanner Subagent (haiku, read-only) für context-files+stack-Scan vor Phase 1d, explizite multi-system Awareness (6 stack profiles).

## Context
Aktueller `/spec` Skill (158 Zeilen) fragt User nur "if ambiguity blocks a good spec", Challenge-Gate-Antworten kommen vom Skill selbst, Haiku-Subagent ist Fallback bei >10 files, Stack-Profil unbeachtet. Anthropic-Doku (`code.claude.com/skills`): SKILL.md sollte <100 Zeilen sein, Details in `references/` für progressive disclosure. AskUserQuestion-Tool erlaubt 1-4 Fragen pro Call (Doku: agent-sdk/user-input). Subagents laut Doku als named-agents mit explicit tools-array.

### Verified Assumptions
- `lib/detect-stack.sh` exposes 6 profiles (default, laravel, nextjs, nuxt-storyblok, nuxtjs, shopify-liquid) — Evidence: `lib/detect-stack.sh:profile=` | Confidence: High | If Wrong: Multi-System Awareness fällt weg
- AskUserQuestion erlaubt 1-4 Fragen pro Call mit 2-4 Optionen — Evidence: `code.claude.com/agent-sdk/user-input` | Confidence: High | If Wrong: 4-Fragen-Bundle muss auf 2 Calls splitten
- Named subagents in `.claude/agents/<name>.md` werden via Agent-Tool spawnable — Evidence: SDK-Doku `agents:{"context-scanner": ...}` | Confidence: High | If Wrong: Inline-prompt fallback
- SKILL.md <100 Zeilen Best Practice — Evidence: `code.claude.com/skills` "keep main SKILL.md focused, place detailed reference in separate files" | Confidence: High | If Wrong: Aktuelle 158-Zeilen-Variante OK

## Steps
- [x] Step 1: Phase 1b einen konsolidierten AskUserQuestion-Call einführen mit 4 Fragen: (a) Anforderung präzisieren, (b) Scope-Bound, (c) Stack-Coverage (single/multi/all aus 6 profiles), (d) Out-of-Scope-Items
- [x] Step 2: Phase 1c.5 Challenge-Gate: 4 Challenge-Fragen via einem AskUserQuestion-Call an User, multiSelect für Empfehlung "Weiter / Adjust / Abbrechen"
- [x] Step 3: Named subagent erstellen: `.claude/agents/context-scanner.md` (model=haiku, tools=Read+Glob+Grep+Bash) — liest `.agents/context/*.md`, ruft `bash lib/detect-stack.sh`, parsed package.json/composer.json, returned ≤1-page summary
- [x] Step 4: Phase 1c neue Sub-Phase "Context-Scan": spawnt context-scanner subagent, präsentiert Output, dann mandatory Phase-1b AskUserQuestion (Stack-Coverage-Frage nutzt subagent-Output als Default)
- [x] Step 5: Spec-Template um "Stack Coverage" Section erweitern (welche profiles, was unterscheidet sich pro stack)
- [x] Step 6: Progressive Disclosure: SKILL.md auf <100 Zeilen trimmen — Spec-Template, Challenge-Gate-Details, Code-Flow-Analyse in `references/{template,challenge,code-flow,context-scan}.md`
- [x] Step 7: `templates/skills/spec/SKILL.template.md` + `.claude/skills/spec/SKILL.md` syncen, beide editieren
- [x] Step 8: Smoke-Test: quality-gate grün (432/0), SKILL.md 81 Zeilen, references vorhanden, context-scanner agent in templates/ + .claude/agents/

## Acceptance Criteria
- [ ] `/spec "any task"` ruft genau **1** AskUserQuestion-Call in Phase 1b mit ≥3 questions (clarify), **1** Call in Phase 1c.5 (challenge) — ≤2 Calls total vor Phase 2
- [ ] Phase 1c spawnt named context-scanner subagent (sichtbar in TaskList), Output enthält stack_profile + key versions + relevante context-files-summary
- [ ] Generated Spec hat "Stack Coverage" Section mit konkreten profiles aus detect-stack.sh
- [ ] SKILL.md ≤100 Zeilen, references-Files vorhanden und verlinkt
- [ ] `bash .claude/scripts/quality-gate.sh` grün
- [ ] /spec-work, /spec-validate, /spec-board kompatibel (Spec-Template-Format Backward-compatible)

## Files to Modify
- `templates/skills/spec/SKILL.template.md` — Phase 1b/1c/1c.5 verschärfen, progressive disclosure (≤100 Zeilen)
- `.claude/skills/spec/SKILL.md` — sync mit template
- `templates/skills/spec/references/context-scan.md` — NEU, context-scanner Subagent-Aufruf-Pattern
- `templates/skills/spec/references/challenge.md` — NEU, Challenge-Gate-Details
- `templates/skills/spec/references/template.md` — NEU, Spec-Template (ausgelagert)
- `templates/skills/spec/references/code-flow.md` — NEU, Code-Flow-Analyse-Details
- `templates/agents/context-scanner.md` — NEU, named subagent (haiku, read-only)
- `.claude/agents/context-scanner.md` — sync
- `specs/TEMPLATE.md` — Stack Coverage Section ergänzen

## Out of Scope
- /spec-validate, /spec-work, /spec-board updaten (eigene Specs falls nötig)
- Auto-fix für detected stack mismatches (nur warnen)
- AskUserQuestion-Bundling über mehr als 4 Fragen (Tool-Limit hart)
