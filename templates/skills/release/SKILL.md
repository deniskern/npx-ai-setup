---
name: release
description: Complete release workflow — version bump, CHANGELOG, docs sync, Slack. Triggers: 'release', 'ship', 'publish', '/release', version strings like 'v2.0.0'.
disable-model-invocation: true
---

# Release — Version Bump, Changelog, Docs Sync, Slack Message

Full release workflow: validate → changelog → docs sync → version bump → slack message → commit + tag.

## Process

### Phase 1: Pre-flight Validation

1. **Clean working tree check**
   - Run `git status` — abort if uncommitted changes exist
   - Run `git diff --cached` — abort if staged changes exist
   - Tell the user: "Commit or stash changes first."

2. **Run validation script** (if exists)
   - `bash scripts/validate-release.sh`
   - If non-zero exit: stop and show the errors

3. **Collect release scope**
   - Run `git describe --tags --abbrev=0 2>/dev/null` to find last tag
   - Run `git log --oneline <last-tag>..HEAD` to list all commits since last release
   - Read `CHANGELOG.md` — find `## [Unreleased]` section entries
   - Read `package.json` to get current version
   - Count completed specs: `ls specs/completed/ 2>/dev/null | wc -l` vs specs moved since last tag

### Phase 2: Deep Audit — Inventory Count Verification

**This is the critical phase. Count everything. Trust nothing from memory.**

4. **Count commands**
   - `ls .claude/commands/*.md 2>/dev/null | wc -l`
   - Read README.md — extract stated count (e.g. "24 slash commands")
   - Read WORKFLOW-GUIDE.md — extract stated count (e.g. "## Commands (24)")
   - Compare all three: filesystem vs README vs WORKFLOW-GUIDE

5. **Count agents**
   - `ls .claude/agents/*.md 2>/dev/null | wc -l`
   - Extract from README (e.g. "12 subagent templates")
   - Extract from WORKFLOW-GUIDE (e.g. "## Subagents (12)")
   - Compare all three

6. **Count hooks**
   - Count hooks in `settings.json` or `templates/settings.json` (parse JSON, count hook entries)
   - Extract from README (e.g. "13 hooks")
   - Extract from WORKFLOW-GUIDE (e.g. "## Hooks (13)")
   - Compare all three

7. **Count skills**
   - `ls -d .claude/skills/*/ 2>/dev/null | wc -l`
   - Extract from README if mentioned

8. **Count rules**
   - `ls .claude/rules/*.md 2>/dev/null | wc -l`
   - Extract from README if mentioned

9. **Verify command table completeness**
   - List all `.claude/commands/*.md` filenames
   - For each one: grep in README.md command table — is it listed?
   - For each one: grep in WORKFLOW-GUIDE.md command table — is it listed?
   - Report any commands missing from either table

10. **Verify agent table completeness**
    - List all `.claude/agents/*.md` filenames
    - For each one: grep in README.md agent table — is it listed?
    - For each one: grep in WORKFLOW-GUIDE.md agent table — is it listed?
    - Report any agents missing from either table

11. **Verify hook table completeness**
    - Extract all hook names from settings.json
    - For each one: grep in WORKFLOW-GUIDE.md hook table — is it listed?
    - Report any hooks missing from the table

12. **Report all discrepancies**
    - Show a summary table:
      ```
      | Item     | Filesystem | README | WORKFLOW-GUIDE | Status |
      |----------|-----------|--------|----------------|--------|
      | Commands | 24        | 24     | 24             | OK     |
      | Agents   | 12        | 12     | 12             | OK     |
      | Hooks    | 13        | 13     | 13             | OK     |
      ```
    - List any missing entries from tables
    - Even if all counts match, proceed to Phase 3 to verify table completeness row-by-row
    - If ANY discrepancy: show the full diff and ask user how to proceed via AskUserQuestion:
      - "Fix docs automatically" — proceed to Phase 3 with fixes
      - "Fix manually first" — stop, let user fix, re-run /release
      - "Skip docs sync" — skip fixes, proceed to Phase 4

### Phase 3: Documentation Sync

**Always run this phase. Skip individual steps only if the audit (Phase 2) confirmed 0 discrepancies AND all tables were 100% complete. When in doubt, run the sync — it is additive-only and safe.**

13. **Update README.md**
    - Fix counts in prose text (e.g. "24 slash commands" → actual count)
    - Add missing commands to the command table (with model + description from the .md file frontmatter)
    - Add missing agents to the agent table (with purpose from frontmatter)
    - Do NOT remove entries — only add. Removed items need manual review.

14. **Update WORKFLOW-GUIDE.md** (both `templates/claude/` and `.claude/`)
    - Fix section header counts: `## Commands (N)`, `## Subagents (N)`, `## Hooks (N)`
    - Add missing commands to the appropriate category table
    - Add missing agents to the agent table (with model from frontmatter)
    - Add missing hooks to the hook table
    - Keep existing descriptions — only add new rows

15. **Update templates/CLAUDE.md** (if it references counts)
    - Only touch if explicit counts are stated

### Phase 4: Version Bump

16. **Ask version bump strategy** via AskUserQuestion:
    - Show commits since last tag + CHANGELOG [Unreleased] entries
    - Options:
      - "patch (X.Y.Z+1)" — bug fixes, docs, small improvements
      - "minor (X.Y+1.0)" — new features, new commands/agents/hooks
      - "major (X+1.0.0)" — breaking changes, removed features
    - Calculate new version

17. **Update package.json**
    - Replace version string with new version

18. **Update CHANGELOG.md**
    - Replace `## [Unreleased]` heading with `## [vX.Y.Z] — YYYY-MM-DD`
    - Add new empty `## [Unreleased]` section above
    - If [Unreleased] section is empty, auto-generate entries from commits:
      - Group by type: feat → "New Features", fix → "Bug Fixes", refactor → "Improvements"
      - Include spec references where commit messages contain `spec(NNN)`

### Phase 5: Slack Announcement

19. **Generate Slack message** for the dev team:

    First, categorize CHANGELOG entries into highlight categories:
    - **Neue Tools/Commands**: New slash commands, what they do, when to use them (1 sentence each)
    - **Neue Agents**: New subagents with their purpose
    - **Token-Optimierungen**: Any changes that save tokens (prep scripts, RTK, compression)
    - **Neue Skills**: Stack-specific skills added, what stack they support
    - **Workflow-Verbesserungen**: Changes to existing commands, hooks, or processes
    - **Bug Fixes**: Only if user-facing

    Then compose the message:

```
:rocket: *@onedot/ai-setup vX.Y.Z*

*Was ist neu:*
:wrench: *Neue Tools*
- `/command-name` — Was es tut und wann man es nutzt
- `/other-command` — Kurze Erklaerung

:brain: *Agents*
- `agent-name` — Was der Agent macht (1 Satz)

:zap: *Token-Optimierung*
- [Konkrete Verbesserung und geschaetzte Ersparnis]

:sparkles: *Skills*
- `skill-name` — Fuer welchen Stack, was es kann

:gear: *Verbesserungen*
- [Wichtigste Verbesserung kurz erklaert]

*Zahlen:* N Commands | N Agents | N Hooks | N Skills

*Update:*
\`npx github:onedot-digital-crew/npx-ai-setup\`

*Workflow-Guide:* `.claude/WORKFLOW-GUIDE.md` — Komplette Referenz aller Commands, Agents und Hooks
```

    - Only include categories that have entries (skip empty sections)
    - Each item: 1 sentence max, fokus auf "was bringt es MIR als Entwickler"
    - Show the message to the user — copy-ready format
    - Use AskUserQuestion: "Slack-Nachricht anpassen?" with options:
      - "Passt so" — keep as-is
      - "Anpassen" — user provides edits
      - "Ohne Slack" — skip

### Phase 6: Commit and Tag

20. **Stage all changed files**
    - `git add package.json CHANGELOG.md README.md`
    - If WORKFLOW-GUIDE was changed: add both copies
    - If templates/CLAUDE.md was changed: add it
    - Run `git diff --staged --stat` to show what will be committed

21. **Commit and tag**
    - `git commit -m "release: vX.Y.Z"`
    - `git tag vX.Y.Z`
    - Report: "Tagged vX.Y.Z. Run `git push && git push --tags` when ready."

22. **Show final summary**
    ```
    Release vX.Y.Z complete
    - CHANGELOG: N new entries
    - Docs synced: [list of files updated]
    - Slack message: [ready / skipped]
    - Next: git push && git push --tags
    ```

## Rules
- **Never push automatically** — always leave push to the user
- **Never skip the docs audit** — stale counts are the #1 source of confusion for users
- **Count from filesystem, not from memory** — run actual ls/wc/grep commands for every count
- **Template parity** — if `.claude/WORKFLOW-GUIDE.md` is updated, `templates/claude/WORKFLOW-GUIDE.md` must match
- **Additive only** — docs sync adds missing items but never removes existing ones (removal needs manual review)
- Do NOT bump version if there are uncommitted changes
- If `[Unreleased]` section is missing from CHANGELOG.md, stop and ask the user
- **Skill-First**: Check `ls .claude/skills/` — if a skill covers a sub-task, invoke it
