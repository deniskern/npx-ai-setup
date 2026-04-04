---
name: ais:release
description: "Complete release workflow — version bump, CHANGELOG, Slack. Triggers: 'release', 'ship', 'publish', '/release', version strings like 'v2.0.0'."
---

# Release — Version Bump, Changelog, Slack Message

Full release workflow: validate → changelog → version bump → slack → commit + tag.

## Process

### Phase 1: Pre-flight Validation

1. `git status` + `git diff --cached` — abort if uncommitted/staged changes
2. Run `npm run verify:release` when `package.json` exists. Treat this as a hard gate.
3. If `verify:release` fails or runtime validation is skipped because Claude is not authenticated, stop the release and fix the issue first.
4. Collect scope: `git describe --tags --abbrev=0`, `git log --oneline <tag>..HEAD`, read `CHANGELOG.md [Unreleased]`
5. Detect version source: `package.json`, `Cargo.toml`, `pyproject.toml`, `version.txt`, or ask user

### Phase 2: Version Bump

Ask via AskUserQuestion (show commits + CHANGELOG [Unreleased]):
- `patch` — bug fixes, docs, small improvements
- `minor` — new features, new APIs, new capabilities
- `major` — breaking changes

Update version file. Update `CHANGELOG.md`: rename `[Unreleased]` → `[vX.Y.Z] — YYYY-MM-DD`, add new empty `[Unreleased]` above. If [Unreleased] is empty, auto-generate from commits grouped by type (feat/fix/chore).

### Phase 3: Slack Announcement

Generate a release message and write it into `CHANGELOG.md` directly below the version heading, wrapped in `<!-- slack-announcement -->` / `<!-- /slack-announcement -->` markers. This block is automatically posted to Slack.

Derive the project name from `package.json` name, repo name, or ask. Only include categories with entries:

```
<!-- slack-announcement -->
:rocket: *<project-name> vX.Y.Z*

*Was ist neu:*
:sparkles: *Features* — Kurze Beschreibung
:wrench: *Fixes* — Was gefixt wurde
:gear: *Verbesserungen* — Wichtigste Änderung

*Update:* `<install-command>`
<!-- /slack-announcement -->
```

Show the generated message and ask: "Passt so" / "Anpassen" / "Ohne Slack"

### Phase 4: Commit and Tag

```bash
git add <version-file> CHANGELOG.md README.md
git diff --staged --stat
git commit -m "release: vX.Y.Z"
git tag vX.Y.Z
```

Report: "Tagged vX.Y.Z. Run `git push && git push --tags` when ready."

## Rules

- **Never push automatically** — leave push to user
- **Detect version source** — don't assume package.json, check what exists
- **Release verification is mandatory** — no version bump, tag, or publish step before `verify:release` passes
- **Fix immediately on failure** — do not continue the release with skips, warnings, or known runtime gaps
- Stop if uncommitted changes or missing `[Unreleased]` in CHANGELOG

## Next Step

> 📤 Naechster Schritt: `git push && git push --tags` — Release veroeffentlichen
