# Spec: Comprehensive Token Optimization — Close All 6-Layer Gaps

> **Spec ID**: 157 | **Created**: 2026-03-22 | **Status**: in-progress | **Complexity**: medium | **Branch**: —

## Goal
Close all identified token-saving gaps across the 6-layer architecture: transparent RTK activation, defuddle auto-invoke, RTK-enhanced prep-scripts, green-path hardening, and CLI-tool health checks — targeting 40-60% total token reduction for typical dev sessions.

## Context
Audit of the 6-layer token-saving architecture revealed:
- RTK is installed (`required` in cli-tools.sh) but `rtk init --global` is never called during setup → hooks not active
- Defuddle is installed but not referenced in template CLAUDE.md
- Prep-scripts call raw commands instead of RTK-compressed versions
- review-prep.sh runs full analysis even on clean worktrees
- No session-start check verifies CLI tools are available

RTK's own hook system (`rtk init --global`) registers a PreToolUse hook in `~/.claude/settings.json` that transparently rewrites Bash commands (e.g., `git status` → `rtk git status`). This is the correct integration path — no custom hook needed.

RTK also provides `rtk test`, `rtk lint`, `rtk tsc`, `rtk err` which compress test/build/lint output by 80-90%. Prep-scripts should use these when available for double compression (prep filtering + RTK compression).

Spec 156 covers 4 new prep scripts (build, lint, pr, changelog) — this spec covers everything else.

## Steps

### Phase 1: RTK Activation in Setup (P0 — highest impact)
- [x] Step 1: Add `rtk init --global` call to `bin/ai-setup.sh` after CLI tool installation step. Guard with `command -v rtk` check. This activates RTK's built-in Claude Code hooks automatically.
- [x] Step 2: Add "## Token Optimization" section to `templates/CLAUDE.md` (max 5 lines): mention RTK auto-compression is active, prep-scripts handle structured analysis, and defuddle replaces WebFetch for web content.
- [ ] Step 3: Update README "Optional Extensions" section — RTK is no longer optional (it's `required` in cli-tools.sh), move to main features or correct the registry.

### Phase 2: RTK-Enhanced Prep-Scripts (P0)
- [ ] Step 4: Create `templates/scripts/prep-lib.sh` — shared helper library sourced by all prep-scripts. Contains: `has()` function, `rtk_or_raw()` function that returns `rtk <cmd>` if rtk available, else `<cmd>` raw. Standardizes the RTK fallback pattern.
- [ ] Step 5: Update existing prep-scripts (test-prep.sh, scan-prep.sh, review-prep.sh, commit-prep.sh) to source `prep-lib.sh` and use `rtk_or_raw` for git/test/lint commands. Backward-compatible: works without RTK installed.

### Phase 3: Defuddle Auto-Invoke (P0)
- [ ] Step 6: Add defuddle instruction to `templates/CLAUDE.md` rules: "Prefer `defuddle parse <url> --md` over WebFetch for reading web pages — strips noise, saves ~80% tokens."
- [ ] Step 7: Verify defuddle is `required` in `lib/cli-tools.sh` — already there, confirm and document.

### Phase 4: Green-Path Hardening (P1)
- [ ] Step 8: Add clean-worktree early-exit to `templates/scripts/review-prep.sh` — if `git status -s` is empty AND no branch diff vs main, emit `NO_CHANGES_TO_REVIEW` and exit 0.
- [ ] Step 9: Verify `commit-prep.sh` NO_STAGED_CHANGES guard works correctly (already exists).
- [ ] Step 10: Document green-path convention for Spec 156 prep-scripts: every prep-script MUST have an early-exit when there's nothing to do.

### Phase 5: CLI Health Check at Session Start (P1)
- [ ] Step 11: Create `templates/claude/hooks/cli-health.sh` — SessionStart hook that checks if required CLI tools (rtk, defuddle) are installed and RTK hooks are active (`rtk gain` returns 0). If missing, emit one-line warning to stderr. Silent when all OK. Max 100ms.
- [ ] Step 12: Register cli-health.sh in `templates/claude/settings.json` as SessionStart hook.

### Phase 6: Documentation (P1)
- [ ] Step 13: Create `templates/docs/token-optimization.md` — developer-facing guide: all 6 layers explained, how to verify RTK is active (`rtk gain`), how to write new prep-scripts, RTK command reference for common operations.
- [ ] Step 14: Mirror all template changes to `.claude/` project files.

## Acceptance Criteria
- [ ] `rtk init --global` runs during setup when rtk is installed
- [ ] All existing prep-scripts use RTK when available via shared `prep-lib.sh`
- [ ] Defuddle instruction is in template CLAUDE.md
- [ ] review-prep.sh exits early on clean worktree with `NO_CHANGES_TO_REVIEW`
- [ ] cli-health.sh warns about missing tools in < 100ms, silent when all OK
- [ ] RTK hooks remain inactive gracefully when rtk is not installed (no errors)
- [ ] token-optimization.md documents all 6 layers with verification commands
- [ ] All template changes mirrored to .claude/ project files

## Files to Modify
- `bin/ai-setup.sh` — add `rtk init --global` post-install step
- `templates/scripts/prep-lib.sh` — new shared helper library
- `templates/scripts/test-prep.sh` — source prep-lib.sh, use rtk_or_raw
- `templates/scripts/scan-prep.sh` — source prep-lib.sh, use rtk_or_raw
- `templates/scripts/review-prep.sh` — source prep-lib.sh, use rtk_or_raw, add green-path
- `templates/scripts/commit-prep.sh` — source prep-lib.sh, use rtk_or_raw
- `templates/CLAUDE.md` — token optimization section + defuddle rule
- `templates/claude/hooks/cli-health.sh` — new
- `templates/claude/settings.json` — register cli-health hook
- `templates/docs/token-optimization.md` — new dev guide
- `README.md` — correct RTK section (required, not optional)
- `.claude/` — mirror all changes

## Risks
- `rtk init --global` modifies `~/.claude/settings.json` — could conflict with existing user config. Mitigation: only run if RTK hooks not already present (check before running).
- Prep-scripts sourcing prep-lib.sh: path must be relative to script location. Use `SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"` pattern.
- cli-health.sh must not block session start. Use `timeout 0.1s` or background check.

## Out of Scope
- New prep scripts (covered by Spec 156)
- Prep-script output caching (future Spec 158 — cache layer with invalidation is its own system)
- Error-pattern-learner hook (future spec)
- Automatic model routing (requires Claude Code platform changes)
