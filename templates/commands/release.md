---
disable-model-invocation: true
allowed-tools: Bash
---

Bumps version, updates CHANGELOG, commits, and tags the release. Use when shipping a new version.

Runs the release script interactively — asks for bump type (patch/minor/major), shows commits since last tag, updates package.json and CHANGELOG.md, then commits and tags.

0. **Pre-flight validation** (run before anything else)
   - Run `bash scripts/validate-release.sh` from the repo root
   - If it exits non-zero, stop and fix the reported issues before continuing
   - The script checks: version/CHANGELOG consistency, clean working tree, template integrity

!.claude/scripts/release.sh
