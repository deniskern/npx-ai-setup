---
name: ais:spec-run
description: "Run full spec pipeline — validate, implement, review, commit. Triggers: /spec-run NNN, 'run spec pipeline NNN', 'execute spec NNN end to end'."
model: sonnet
---

Runs the complete spec lifecycle for spec $ARGUMENTS. Self-healing: fixes issues found during review automatically.

## Pipeline

### Phase 1 — Validate
Invoke `/spec-validate $ARGUMENTS`.
- **Grade A/B**: continue
- **Grade C**: fix the spec issues inline, re-validate once. Second C → stop.
- **Grade F**: stop, show fixes needed.
Refresh `.claude/session-state.json` with phase `validate` and next action `/spec-validate $ARGUMENTS`.

### Phase 2 — Implement
Invoke `/spec-work $ARGUMENTS --skip-validate`.
- All steps checked: continue
- Any step blocked: stop, report blocked steps.
Refresh `.claude/session-state.json` with phase `implementation` and next action `/spec-work $ARGUMENTS --skip-validate`.

### Phase 3 — Review
Invoke `/spec-review $ARGUMENTS`.
- **APPROVED**: continue to Phase 4
- **CHANGES REQUESTED**: apply the feedback fixes, re-run review once. Second CHANGES REQUESTED → stop, report remaining issues.
- **REJECTED**: stop.
Refresh `.claude/session-state.json` with phase `review` and next action `/spec-review $ARGUMENTS`.

### Phase 4 — Commit
Invoke `/commit`.
Refresh `.claude/session-state.json` with phase `commit` and next action `/commit`.

## Rules
- Self-healing: fix issues from validate (Grade C) and review (CHANGES REQUESTED) automatically — max 1 retry per phase.
- Grade F and REJECTED always stop — too broken to auto-fix.
- If resumed after manual fix, detect spec status and skip completed phases (e.g. `in-progress` skips Phase 1).
- Pass `--skip-validate` to spec-work since Phase 1 already validated.
- Keep `.claude/session-state.json` aligned with the current pipeline phase, but do not replace spec Markdown as the human source of truth.

## Next Step

> 📋 Naechster Schritt: `/spec-board` — Spec-Uebersicht pruefen, oder `/release` wenn main-Branch
