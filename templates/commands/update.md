---
name: update
description: Check for ai-setup updates and install from within Claude Code
allowed-tools:
  - Bash
  - AskUserQuestion
  - Read
---

Check for ai-setup updates, show what changed, and install if the user confirms.

## Process

### Step 1: Detect installed version

```bash
jq -r '.version // empty' "${CLAUDE_PROJECT_DIR:-.}/.ai-setup.json" 2>/dev/null || echo ""
```

If no `.ai-setup.json` exists, tell the user ai-setup is not installed in this project and suggest running `npx github:onedot-digital-crew/npx-ai-setup`.

### Step 2: Check latest version

Try npm first, fall back to GitHub API:

```bash
npm view @onedot/ai-setup version 2>/dev/null || curl -fsSL --max-time 5 "https://api.github.com/repos/onedot-digital-crew/npx-ai-setup/releases/latest" 2>/dev/null | jq -r '.tag_name // empty' | sed 's/^v//'
```

If both fail, tell the user to check their network connection.

### Step 3: Compare versions

Parse both versions as semver (major.minor.patch). Only proceed if latest > installed.

- If **same version**: "Already up to date (vX.Y.Z)." — stop.
- If **installed > latest**: "You're ahead of the latest release (dev version?)." — stop.
- If **latest > installed**: continue to step 4.

### Step 4: Fetch changelog

```bash
curl -fsSL --max-time 5 "https://raw.githubusercontent.com/onedot-digital-crew/npx-ai-setup/main/CHANGELOG.md" 2>/dev/null | head -80
```

Extract entries between installed and latest version. If no CHANGELOG.md exists, skip this step.

### Step 5: Show update summary and confirm
Show:
```
## ai-setup Update Available

**Installed:** vX.Y.Z
**Latest:**    vA.B.C

### What's New
(changelog entries if available)

Will review customized templates, optionally regenerate AI context, and back up modified files.
```
Use AskUserQuestion: "Proceed with update?" Options: "Yes, update now" / "No, cancel"
If user cancels, stop.

### Step 6: Capture pre-update SHA

```bash
git -C "${CLAUDE_PROJECT_DIR:-.}" rev-parse HEAD 2>/dev/null > /tmp/ai-setup-pre-sha.txt || true
```

### Step 7: Run update

```bash
npx github:onedot-digital-crew/npx-ai-setup
```

This launches the interactive update flow.

### Step 8: Clear update cache

```bash
rm -f /tmp/ai-setup-update-*.txt /tmp/ai-setup-cli-latest-version.txt
```

### Step 9: Show changed files

Read the saved SHA and diff against it to show exactly what changed:

```bash
PRE_SHA=$(cat /tmp/ai-setup-pre-sha.txt 2>/dev/null | tr -cd 'a-f0-9'); rm -f /tmp/ai-setup-pre-sha.txt
[ -n "$PRE_SHA" ] && git -C "${CLAUDE_PROJECT_DIR:-.}" diff --name-status "$PRE_SHA" HEAD -- .claude/ templates/ CLAUDE.md 2>/dev/null | head -30 || echo "(no git history available)"
```

Display the result as a concise summary:
```
ai-setup updated: vX.Y.Z -> vA.B.C

Changed files:
  M .claude/settings.json
  A .claude/hooks/new-hook.sh
  ...

Restart Claude Code to pick up new hooks and settings.
```

If no files changed (update was a no-op or failed silently), say so explicitly.

## Next Step

After the update, restart Claude Code to pick up new hooks and settings. Run `/doctor` to verify the installation is healthy.
