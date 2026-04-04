---
name: ais:commit
description: Stages changes and creates a conventional commit message. Uses `commit-prep.sh` to collect diff context before Claude generates the message — focused input, fewer tokens.
model: haiku
allowed-tools: Read, Bash, Glob, Grep
---

Stages changes and creates a conventional commit message. Uses `commit-prep.sh` to collect diff context before Claude generates the message — focused input, fewer tokens.

## Process

1. **Run the prep script** (zero LLM tokens):
   ```
   ! bash .claude/scripts/commit-prep.sh
   ```
   - Output `NO_STAGED_CHANGES` → nothing to commit; stop and inform the user.
   - Otherwise: output contains branch name, staged diff, staged stat, and recent commits.

2. **Analyze the prep output** — determine if this is a new feature, enhancement, bug fix, refactor, test, or docs update.

3. **Stage relevant files by name** (`git add <file>...`). Do NOT use `git add -A` or `git add .` — avoid accidentally staging secrets or binaries.

4. **Write a concise conventional commit message** (1-2 sentences) focusing on **why**, not what.

5. Commit. Do NOT push. Do NOT use `--no-verify`.

## Next Step

- Feature-Branch: `> 📤 Naechster Schritt: /pr — Pull Request erstellen`
- Main-Branch: `> 🏷️ Naechster Schritt: /release — Version bump + Tag`
- Session >30 tool calls: `> 💡 Naechster Schritt: /reflect — Learnings sichern`

## Rules
- Never stage `.env`, credentials, or large binaries.
- Never push — only commit locally.
- Never skip hooks (`--no-verify`).
- If there are no changes, say so and stop.
