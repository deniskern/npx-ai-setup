---
disable-model-invocation: true
allowed-tools: Bash
---

Bumps version, updates CHANGELOG, commits, and tags the release. Use when shipping a new version.

Runs the release script interactively — asks for bump type (patch/minor/major), shows commits since last tag, updates package.json and CHANGELOG.md, then commits and tags.

!.claude/scripts/release.sh
