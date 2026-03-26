# Session Optimize — Findings Log

> Persistent checklist for session-optimize findings. Check off when addressed. Clean up quarterly.
> session-optimize reads this file as a pre-filter — checked items are never re-reported.

## Open

<!-- Add new findings here after each /session-optimize run -->
<!-- Format: - [ ] [Category] Title — Fix applied: `file:line` or Spec NNN -->
- [x] [T] spec-validate 6.1→2.2KB, spec-review 5.7→2.6KB, spec-work-all 5.5→2.0KB — Spec 588 (2026-03-26)
- [x] [T] Model-Routing in Spec-Skills beim Trimming ergänzt (spec-review + spec-work-all) — Spec 589 (2026-03-26)
- [x] [Q] apply-learnings Mapping für Process/CLI → CLAUDE.md war bereits vorhanden (Zeile 19) — Spec 590 (2026-03-26)
- [x] [T] templates/claude/rules/agents.md hat bereits Model-Routing — Spec 591 (2026-03-26)
- [x] [E] Specs 577+578 in specs/ nicht zu completed/ verschoben — verschoben (2026-03-25)
- [ ] [T] Haiku 0% — Verifikation nach Spec 578 ausständig; Sonnet-Limit aktuell voll, Validierung ab ~2026-03-30 möglich
- [ ] [T] Opus für Non-Code-Projekte (Obsidian, Finanzplanung) — Sonnet reicht für Markdown-Editing, 15x günstiger
- [ ] [E] npx-ai-setup Sessions haben quasi keine Subagents (0-2) trotz 100+ Tool-Calls — Skills wie /analyze, /review nutzen
- [ ] [T] Große Opus-Sessions ohne Parallelisierung (mcp-platform 226 Tools/2 SA, shop-force-os 212 Tools/5 SA)
- [ ] [E] Projekte ohne ai-setup haben 0 Subagents — crew-buddy, mcp-platform, Obsidian Vaults fehlt Parallelisierungs-Guidance
- [x] [T] Template CLAUDE.md fehlte Model-Routing-Sektion — 8 Zeilen ergänzt, templates/CLAUDE.md (2026-03-26)
- [x] [T] spec-work SKILL.md 11.5KB → 4.4KB (62% Reduktion) — Verbose Erklärungen, Debugging-Discipline, Blockquotes kondensiert (2026-03-26)
- [x] [T] apply-learnings Mapping für CLAUDE.md — bereits vorhanden (Zeile 19), stale Observation #25044 (2026-03-26)
- [x] [T] template/skills/ nicht mit .claude/skills/ synchronisiert — token-optimizer 295→142, release 214→86, spec 187→115 (2026-03-25)
- [x] [Q] update.sh Version-Check schlägt lautlos fehl bei GitHub API Fehler — tui_hint nach letztem Fallback ergänzt, lib/update.sh:60 (2026-03-25)
- [x] [E] Spec-Backlog 165–170 obsolet (alte Nummerierungsrunde) — alle 6 nach specs/completed/ verschoben (2026-03-25)
- [x] [T] Keine Skills in hochkomplexen Sessions — /reflect + /commit nach >30 Tool-Call Sessions in CLAUDE.md ergänzt (2026-03-25)
- [x] [T] Template Domain-Skills laden für alle User — obsolet: Domain-Skills kommen aus Boilerplates, nicht aus core templates (2026-03-25)
- [x] [T] agent-browser/SKILL.md 686 Zeilen (26KB, ~6.500 Token) — auf 81 Zeilen (2.3KB) getrimmt, Spec 586 (2026-03-25)

- [x] [E] /analyze unsichtbar in Session-Metriken — session-extract.sh: progress_msgs + Agent-tool-call-Fallback für Subagent-Count (2026-03-25)
- [x] [T] token-optimizer/SKILL.md 350→142 Zeilen — Bash-Details aus Agent-Prompts entfernt (2026-03-25)
- [x] [T] release/SKILL.md 214→86 Zeilen — Phase 2 Inventory kondensiert, Slack-Template gestrafft (2026-03-25)

## Addressed

<!-- Move items here once fixed. Keep for 30 days, then delete. -->

- [x] [E] session-optimize repeated same findings — findings-log.md als Pre-Filter eingebaut, Spec 584 (2026-03-25)
- [x] [T] spec-review Agent-Spawns ohne explizites Model — `model: sonnet` ergänzt, Spec 583 (2026-03-25)
- [x] [T] techdebt verify-app ohne Model → Sonnet-Vererbung — `model: haiku` gesetzt (2026-03-25)
- [x] [T] Opus in Routine-Sessions (spec-review) — Spec 579 closed (2026-03-25)
- [x] [Q] yolo Safety Guards fehlend — Spec 581 completed, `## Safety Guards` Sektion ergänzt (2026-03-25)
- [x] [Q] CLAUDE.md Autonomy-Docs fehlend — Spec 582 completed (2026-03-25)
