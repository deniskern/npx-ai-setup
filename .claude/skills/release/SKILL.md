---
name: release
description: "Complete release workflow — version bump, CHANGELOG, Slack."
disable-model-invocation: true
---

# Release — Version Bump, Changelog, Slack Message

Full release workflow: validate → changelog → version bump → slack → commit + tag.

## Process

### Phase 1: Pre-flight Validation

Run the prep script first — it collects all Phase 1 data in one shell pass (zero LLM tokens):

```bash
bash .claude/scripts/release-prep.sh
```

The output contains: dirty state, verify:release result, last tag, commits since tag, CHANGELOG [Unreleased], version info, and inventory counts.

**Abort conditions** (check from prep output):
- `UNCOMMITTED_CHANGES` → abort, commit or stash first
- `Verify: FAIL` → fix before proceeding. If runtime validation is skipped because Claude is not authenticated, stop the release.
- Detect version source: `package.json`, `Cargo.toml`, `pyproject.toml`, `version.txt`, or ask user

Do NOT re-run `git status`, `verify:release`, or read CHANGELOG — all data is in the prep output.

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

Report: "Tagged vX.Y.Z. Push in this order to avoid CI race conditions:"

```bash
git push          # CHANGELOG must land on GitHub before the tag triggers the workflow
git push --tags   # Tag push triggers release workflow — only after code is on remote
```

**CRITICAL: always push commits before tags.** The release workflow reads CHANGELOG.md from the repo — if the tag arrives before the commit, the workflow fails with "No changelog section found".

## Rules

- **Never push automatically** — leave push to user
- **Detect version source** — don't assume package.json, check what exists
- **Release verification is mandatory** — no version bump, tag, or publish step before `verify:release` passes
- **Fix immediately on failure** — do not continue the release with skips, warnings, or known runtime gaps
- Stop if uncommitted changes or missing `[Unreleased]` in CHANGELOG

## Next Step

> 📤 Naechster Schritt: `git push && git push --tags` — erst Code, dann Tag (Reihenfolge wichtig)
