---
name: release
description: Complete release workflow — version bump, CHANGELOG, docs sync, Slack. Triggers: 'release', 'ship', 'publish', '/release', version strings like 'v2.0.0'.
---

# Release — Version Bump, Changelog, Docs Sync, Slack Message

Full release workflow: validate → changelog → docs sync → version bump → slack message → commit + tag.

## Process

### Phase 1: Pre-flight Validation

1. `git status` + `git diff --cached` — abort if uncommitted/staged changes
2. Collect scope: `git describe --tags --abbrev=0`, `git log --oneline <tag>..HEAD`, read `CHANGELOG.md [Unreleased]`, read `package.json` version

### Phase 2: Docs Audit

Run `bash .claude/scripts/docs-audit.sh`. The script counts skills, hooks, agents, and rules from the filesystem and compares against stated counts in README.md and WORKFLOW-GUIDE.md.

If discrepancies are found, ask via AskUserQuestion:
- "Fix docs automatically" — update counts and tables, then continue
- "Fix manually first" — abort so user can fix
- "Skip docs sync" — continue without fixing (not recommended)

When fixing automatically:
- **README.md**: Fix counts in prose and headings, add missing entries to tables (read model + description from SKILL.md/agent frontmatter)
- **WORKFLOW-GUIDE.md** (root + `templates/`): Fix hook count in prose
- Additive only — never remove entries, only add missing ones and fix counts

### Phase 3: Version Bump

Ask via AskUserQuestion (show commits + CHANGELOG [Unreleased]):
- `patch` — bug fixes, docs, small improvements
- `minor` — new features, new commands/agents/hooks
- `major` — breaking changes

Update `package.json` version. Update `CHANGELOG.md`: rename `[Unreleased]` → `[vX.Y.Z] — YYYY-MM-DD`, add new empty `[Unreleased]` above. If [Unreleased] is empty, auto-generate from commits grouped by type.

### Phase 4: Slack Announcement

Generate dev team message. Only include categories with entries:

```
:rocket: *@onedot/ai-setup vX.Y.Z*

*Was ist neu:*
:wrench: *Neue Tools* — `/command` — Was es tut
:brain: *Agents* — `name` — Was der Agent macht
:zap: *Token-Optimierung* — Konkrete Einsparung
:sparkles: *Skills* — `name` — Stack + Funktion
:gear: *Verbesserungen* — Wichtigste Änderung

*Zahlen:* N Commands | N Agents | N Hooks | N Skills
*Update:* `npx github:onedot-digital-crew/npx-ai-setup`
```

Show copy-ready, ask: "Passt so" / "Anpassen" / "Ohne Slack"

### Phase 5: Commit and Tag

```bash
git add package.json CHANGELOG.md README.md  # + WORKFLOW-GUIDE if changed
git diff --staged --stat
git commit -m "release: vX.Y.Z"
git tag vX.Y.Z
```

Report: "Tagged vX.Y.Z. Run `git push && git push --tags` when ready."

## Rules

- **Never push automatically** — leave push to user
- **Never skip the docs audit** — stale counts are the #1 source of confusion
- **Count from filesystem** — run actual ls/wc/grep, never guess
- **Template parity** — if `WORKFLOW-GUIDE.md` changes, `templates/WORKFLOW-GUIDE.md` must match
- **Additive only** — docs sync adds, never removes (removal = manual review)
- Stop if uncommitted changes or missing `[Unreleased]` in CHANGELOG
