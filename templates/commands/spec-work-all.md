---
model: sonnet
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent
---

Executes all draft specs in parallel using isolated worktrees. Use to batch-implement multiple independent specs.

## Process

### 1. Discover draft specs
Scan `specs/` for all `NNN-*.md` files (excluding `specs/completed/`). Only pick specs with `Status: draft`. Read each spec's Goal and Out of Scope to build a dependency map.

### 2. Dependency detection
A spec is **dependent** on another if its "Out of Scope" section explicitly names another spec number (e.g. "Spec 010", "spec 009"). Dependent specs must run after the spec they reference.

Group specs into:
- **Parallel group**: specs with no dependencies on each other
- **Sequential queue**: specs that depend on a parallel spec (run after their dependency completes)

### 3. Execute in waves

#### Wave setup — before launching subagents
For each spec in the current wave:

1. Derive branch name: `spec/NNN-title` (lowercase, hyphens, from spec filename without `.md`)
2. Update spec header in the **main working directory** spec file:
   - Set `**Status**: in-progress`
   - Set `**Branch**: spec/NNN-title`

#### Wave execution — parallel subagents
Launch one Agent subagent per spec simultaneously using `isolation: "worktree"`. Each subagent receives:
**Prompt for each subagent:**
```
Execute this spec. You are running in an isolated Git worktree.
Do first:
1. Rename the current branch to `spec/NNN-title`:
   git branch -m spec/NNN-title
2. Get the main repo path (the parent of this worktree):
   MAIN_REPO=$(git worktree list | head -1 | awk '{print $1}')
3. Copy .env files from the main repo (skip .env.example and .env.template):
   for f in "$MAIN_REPO"/.env*; do
     [[ -f "$f" ]] || continue
     base=$(basename "$f")
     [[ "$base" == ".env.example" || "$base" == ".env.template" ]] && continue
     cp "$f" . 2>/dev/null || echo "⚠️  Could not copy $base — continuing"
   done
4. Install dependencies if a lockfile exists (run from worktree root):
   if [ -f "bun.lockb" ]; then bun install --frozen-lockfile 2>/dev/null || echo "⚠️  bun install failed"
   elif [ -f "package-lock.json" ]; then npm ci 2>/dev/null || echo "⚠️  npm ci failed"
   elif [ -f "pnpm-lock.yaml" ]; then pnpm install --frozen-lockfile 2>/dev/null || echo "⚠️  pnpm install failed"
   elif [ -f "yarn.lock" ]; then yarn install --frozen-lockfile 2>/dev/null || echo "⚠️  yarn install failed"
   fi
Then follow the `/spec-work` process for this spec inside the worktree: read context, load referenced skills, execute each step in order, verify acceptance criteria, then commit with `git add -A && git commit -m "spec(NNN): [spec title]"`.
Spec content:
[full spec content here]
```

#### Wave post-processing — after each subagent returns
For each completed subagent, using the branch and worktree path from the Agent result:

If the subagent **failed or returned no usable result**:
1. Set spec status to `blocked`
2. Add a `## Review Feedback` section to the spec with: "subagent failed — [error message or 'no result returned']"
3. Report: "Spec NNN blocked — subagent did not complete. Run `/spec-work NNN` to retry manually."
4. Skip remaining post-processing for this spec.

If the subagent **succeeded**:
1. Check all spec steps off in `specs/NNN-*.md`
2. Mark all acceptance criteria as checked
3. Set spec status to `in-review`
4. Prepend CHANGELOG entry under `## [Unreleased]`:
   - Add: `- **Spec NNN**: [Title] — [1-sentence summary]`
   - Insert after the `## [Unreleased]` heading
5. Remove the worktree (branch is preserved for `/spec-review`):
   `git worktree remove --force <worktree-path-from-agent-result> || true`

**Wave 2+**: After each wave completes, launch the next wave of specs that are now unblocked.

### 4. Final summary
After all waves complete:
1. Run `git worktree prune` to clean up stale worktree registrations
2. Report:
   - Completed specs (with spec ID, title, and branch name)
   - Failed specs (with spec ID and reason)
   - Total: N completed, M failed
   - Next step: `Run /spec-review NNN for each completed spec, or /spec-board for overview`

## Rules
- Follow each spec exactly — no scope creep
- If a step in a spec is blocked or unclear, mark it unchecked and continue remaining steps
- If `specs/` has no draft specs, report "No draft specs found" and stop
- If an Agent subagent fails, mark the spec as `blocked` and report the error

## Next Step

After all specs complete, run `/spec-review NNN` for each completed spec to validate against acceptance criteria, then `/pr` to open a pull request.
