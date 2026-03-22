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

1. **Pre-flight**: Run `bash scripts/validate-release.sh` (if exists). Check clean working tree.
2. **Read state**: `git log --oneline <last-tag>..HEAD`, read CHANGELOG.md [Unreleased], read package.json version
3. **Version bump**: Ask user (patch/minor/major), update package.json
4. **CHANGELOG**: Replace [Unreleased] with [vX.Y.Z] — YYYY-MM-DD, add new [Unreleased]
5. **Commit + tag**: `release: vX.Y.Z`, tag, report (no auto-push)

## Rules
- Never push automatically
- Never skip CHANGELOG update
- Do NOT bump with uncommitted changes
