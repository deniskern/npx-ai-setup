---
model: sonnet
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

Delegates to the release skill. Use `/release` to ship a new version.

## Process

1. Check if `.claude/skills/release/SKILL.md` exists
2. If yes: invoke the `release` skill via the Skill tool — it handles everything (changelog, docs sync, version bump, slack message)
3. If no: fall back to the inline process below

## Fallback (when skill is not installed)

### 0. Gather Changelog Data

Run `! bash .claude/scripts/changelog-prep.sh` to collect and group commits since last tag.

- If output contains `NO_NEW_COMMITS`: report "No changes since last tag." and stop.
- Use the `=== FEATURES ===`, `=== BUG FIXES ===`, `=== BREAKING CHANGES ===` sections to pre-fill CHANGELOG entries.

### 1. Pre-flight

Run `bash scripts/validate-release.sh` (if exists). Check clean working tree. Read CHANGELOG.md [Unreleased] and package.json version.

### 2. Version Bump

Ask user (patch/minor/major), update package.json.

### 3. CHANGELOG

Replace [Unreleased] with [vX.Y.Z] — YYYY-MM-DD using grouped output from changelog-prep.sh, add new [Unreleased].

### 4. Commit + Tag

`release: vX.Y.Z`, tag, report (no auto-push).

## Rules
- Never push automatically
- Never skip CHANGELOG update
- Do NOT bump with uncommitted changes
