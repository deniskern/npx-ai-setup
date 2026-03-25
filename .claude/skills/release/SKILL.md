---
name: release
description: Complete release workflow — version bump, CHANGELOG, docs sync, Slack. Triggers: 'release', 'ship', 'publish', '/release', version strings like 'v2.0.0'.
disable-model-invocation: true
---

# Release — Version Bump, Changelog, Docs Sync, Slack Message

Full release workflow: validate → changelog → docs sync → version bump → slack message → commit + tag.

## Process

### Phase 1: Pre-flight Validation

1. `git status` + `git diff --cached` — abort if uncommitted/staged changes
2. `bash scripts/validate-release.sh` — abort on non-zero exit
3. Collect scope: `git describe --tags --abbrev=0`, `git log --oneline <tag>..HEAD`, read `CHANGELOG.md [Unreleased]`, read `package.json` version

### Phase 2: Inventory Audit — Count Everything

**Count from filesystem, not memory.** For commands, agents, hooks, skills, rules:
- Count files via `ls .claude/{commands,agents,rules,skills}/ | wc -l` and `jq` hook entries from settings.json
- Extract stated counts from README.md and WORKFLOW-GUIDE.md
- Compare filesystem vs README vs WORKFLOW-GUIDE for each category
- Verify table completeness row-by-row: list all filenames, grep each in README + WORKFLOW-GUIDE

Show discrepancy summary. If ANY mismatch: ask via AskUserQuestion:
- "Fix docs automatically" / "Fix manually first" / "Skip docs sync"

### Phase 3: Documentation Sync

Run unless Phase 2 confirmed 0 discrepancies AND tables 100% complete.

- **README.md**: Fix counts in prose, add missing commands/agents to tables (with model + description from frontmatter)
- **WORKFLOW-GUIDE.md** (both `.claude/` and `templates/claude/`): Fix section header counts, add missing rows to command/agent/hook tables
- **templates/CLAUDE.md**: Only if explicit counts are stated
- Additive only — never remove entries

### Phase 4: Version Bump

Ask via AskUserQuestion (show commits + CHANGELOG [Unreleased]):
- `patch` — bug fixes, docs, small improvements
- `minor` — new features, new commands/agents/hooks
- `major` — breaking changes

Update `package.json` version. Update `CHANGELOG.md`: rename `[Unreleased]` → `[vX.Y.Z] — YYYY-MM-DD`, add new empty `[Unreleased]` above. If [Unreleased] is empty, auto-generate from commits grouped by type.

### Phase 5: Slack Announcement

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

### Phase 6: Commit and Tag

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
- **Template parity** — if `.claude/WORKFLOW-GUIDE.md` changes, `templates/claude/WORKFLOW-GUIDE.md` must match
- **Additive only** — docs sync adds, never removes (removal = manual review)
- Stop if uncommitted changes or missing `[Unreleased]` in CHANGELOG
