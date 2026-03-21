---
model: sonnet
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

Bumps version, updates CHANGELOG, commits, and tags the release. Use when shipping a new version.

## Pre-flight

0. **Pre-flight validation** (run before anything else)
   - Run `bash scripts/validate-release.sh` from the repo root (if it exists)
   - If it exits non-zero, stop and fix the reported issues before continuing
   - The script checks: version/CHANGELOG consistency, clean working tree, template integrity

## Process

1. **Read current state**
   - Run `git log --oneline $(git describe --tags --abbrev=0 2>/dev/null)..HEAD 2>/dev/null || git log --oneline` to see commits since last tag
   - Read `CHANGELOG.md` — find the `## [Unreleased]` section and collect its entries
   - Read `package.json` to get current version

2. **Determine version bump**
   - Show the unreleased commits and CHANGELOG entries to the user
   - Ask which version bump to apply:
     - **patch** (1.1.4 → 1.1.5): bug fixes, small improvements
     - **minor** (1.1.4 → 1.2.0): new features, backward-compatible
     - **major** (1.1.4 → 2.0.0): breaking changes
   - Calculate the new version from the current one

3. **Check README counts**
   - Commands: `ls .claude/commands/*.md 2>/dev/null | wc -l` — compare to stated count in README ("15 commands", etc.)
   - Agents: `ls .claude/agents/*.md 2>/dev/null | wc -l` — compare to stated count in README ("8 agents", etc.)
   - Hooks: `ls .claude/hooks/*.sh 2>/dev/null | wc -l` — compare to stated count in README ("6 hooks", etc.)
   - If any count differs, report all discrepancies and ask user to fix README before proceeding

4. **Update package.json**
   - Replace `"version": "X.Y.Z"` with the new version
   - Show the change as a diff

5. **Update CHANGELOG.md**
   - Replace the `## [Unreleased]` heading with `## [vX.Y.Z] — YYYY-MM-DD` (today's date)
   - Add a new empty `## [Unreleased]` section above it:
     ```
     ## [Unreleased]

     ## [vX.Y.Z] — YYYY-MM-DD
     <previous entries>
     ```
   - If `[Unreleased]` is empty, still add it but note there were no unreleased entries

6. **Commit and tag**
   - Stage: `git add package.json CHANGELOG.md`
   - Commit: `git commit -m "release: vX.Y.Z"`
   - Tag: `git tag vX.Y.Z`
   - Report: "Tagged vX.Y.Z. Run `git push && git push --tags` when ready."

## Rules
- Never push automatically — always leave push to the user
- Never skip the CHANGELOG update
- If [Unreleased] section is missing from CHANGELOG.md, stop and ask the user to run the CHANGELOG migration first
- Do NOT bump version if there are uncommitted changes (run `git status` check first)
