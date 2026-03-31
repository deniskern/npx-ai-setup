# Spec: Sandbox-Safe Global Side Effects

> **Spec ID**: 599 | **Created**: 2026-03-29 | **Status**: completed | **Complexity**: medium | **Branch**: spec/599-sandbox-safe-global-side-effects

## Goal
Make project setup succeed in sandboxed and test environments by isolating or softening global home-directory side effects.

## Context
The current fresh-install path writes into `~/.claude/agents` during normal project setup and fails under restricted filesystem permissions, which broke `tests/integration.sh` in this repo. The project installer should keep per-project setup reliable while making global convenience installs explicit, optional, or gracefully skippable.

### Verified Assumptions
- Project setup should not require writable real home-directory Claude config to succeed — Evidence: `tests/integration.sh` is intended as an offline fresh-install check | Confidence: High | If Wrong: tests and docs must explicitly require writable `$HOME`.
- Global agent installation is additive convenience, not core setup functionality — Evidence: agents are already installed into `.claude/agents/` per project | Confidence: High | If Wrong: the installer needs a preflight guard and clearer failure messaging before any writes.
- Hermetic integration tests are valuable for this CLI because environment coupling is a major failure source — Evidence: existing temp-project/stubbed offline test strategy | Confidence: High | If Wrong: integration coverage can remain host-dependent but should be documented as such.

## Steps
- [x] Step 1: Refactor the global-agent path in `lib/setup-skills.sh` so writes to `~/.claude/agents` are best-effort or explicitly gated, and cannot abort the core project install when global targets are unwritable.
- [x] Step 2: Adjust `bin/ai-setup.sh` so global side-effect steps are clearly separated from required per-project installation and emit actionable warnings when skipped.
- [x] Step 3: Review other home-directory touches in the setup flow, especially global Claude settings/statusline checks, and make restricted-environment behavior consistent with the new global-agent handling.
- [x] Step 4: Harden `tests/integration.sh` to run hermetically by redirecting `HOME` to the temp fixture or otherwise isolating global write paths from the host environment.
- [x] Step 5: Update `README.md` to document which setup actions are project-local versus global, and how sandboxed/CI/test runs behave when global writes are unavailable.
- [x] Step 6: Verify the installer still provisions project-local agents and settings correctly while integration tests pass without relying on host-home write access.

## Acceptance Criteria
- [x] `bash tests/integration.sh` passes in a sandboxed temp-project run without attempting to write to the host user's real `~/.claude/agents`.
- [x] If global Claude directories are unwritable, `bin/ai-setup.sh` still completes project-local installation and reports a warning instead of aborting.
- [x] Project-local agent installation under `.claude/agents/` still succeeds after the change.
- [x] `README.md` clearly distinguishes project-local setup from optional global convenience installation.

## Files to Modify
- `bin/ai-setup.sh` - separate mandatory local install from optional global side effects
- `lib/setup-skills.sh` - harden global agent installation against unwritable home directories
- `lib/setup-compat.sh` - align statusline/global settings behavior with sandbox-safe handling
- `tests/integration.sh` - isolate home-directory state for hermetic integration coverage
- `README.md` - document global versus local install behavior

## Out of Scope
- Redesigning the broader plugin installation model
- Removing global agent support entirely
- Adding new global features unrelated to installer isolation
