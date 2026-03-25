# Session Optimize — Findings Log

> Persistent checklist for session-optimize findings. Check off when addressed. Clean up quarterly.
> session-optimize reads this file as a pre-filter — checked items are never re-reported.

## Open

<!-- Add new findings here after each /session-optimize run -->
<!-- Format: - [ ] [Category] Title — Fix applied: `file:line` or Spec NNN -->
- [x] [E] Specs 577+578 in specs/ nicht zu completed/ verschoben — verschoben (2026-03-25)
- [ ] [T] Haiku 0% — Verifikation nach Spec 578 ausständig; nächste Session mit /analyze triggern und Modell-Split prüfen
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
