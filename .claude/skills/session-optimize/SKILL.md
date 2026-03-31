---
name: session-optimize
description: "Analyzes past sessions via claude-mem and raw JSONL metrics to surface quality, efficiency, and token-saving improvements. Triggers: /session-optimize, 'analyze sessions', 'optimize setup from sessions'."
model: sonnet
allowed-tools: Read, Bash, Glob, Grep, mcp__plugin_claude-mem_mcp-search__search, mcp__plugin_claude-mem_mcp-search__get_observations, mcp__plugin_claude-mem_mcp-search__timeline
---

Analyzes sessions for setup improvements focused on **Qualität, Effizienz und Tokenersparnis**.

## Modes

- **Portfolio mode (default):** analyze the last 30 days **across all projects** via JSONL metrics plus claude-mem when available.
- **Deep-dive mode:** if the user provides a specific exported session file (`session-*.txt`) or asks about one session explicitly, analyze that session first before generalizing. Use the export as primary evidence even when claude-mem is unavailable.
- **Devtools assist:** if the user mentions a running `claude-devtools` app, use it only as an extra source for live tool timing, repeated UI actions, or event traces. Do not block on it.

## Process

### 1. Detect scope

- If the request includes a concrete export path like `/Users/.../session-*.txt`: switch to **Deep-dive mode**
- Otherwise: stay in **Portfolio mode**
- If both are available: do the deep dive first, then compare against portfolio patterns

### 2. Extract raw session metrics (zero LLM tokens)

```
! bash .claude/scripts/session-extract.sh --all --last 5
```

This produces per-session across all projects: turns, tool usage counts, model distribution, skills invoked, subagent count, `active` and `wall` duration, and estimated output tokens. `active` duration caps long idle gaps so open-but-idle sessions do not look artificially inefficient.

Before interpreting findings for an ai-setup-managed project, detect installed setup version:

- Read `.ai-setup.json` if present and extract `version`, `installed_at`, `updated_at`
- Read `package.json` and `CHANGELOG.md` in this repo to know the current ai-setup version and which fixes landed in which release
- If the analyzed session predates the installed project's `updated_at`, treat setup-related findings as potentially stale until confirmed
- If a finding maps to a fix documented in a newer ai-setup version than the analyzed project had at that time, classify it as `version-bound`, not as a current workflow bug
- Prefer findings that still reproduce on the project's current installed ai-setup version

In Deep-dive mode, read the export file directly and extract:

- session duration, total/cache/input/output tokens, messages
- number of `USER`, `ASSISTANT`, `THINKING`, `Tool: Skill`, and `Tool: Agent` blocks
- count of correction markers such as `geht nicht`, `nein`, `immer noch`, `rückgängig`, `anders`, `falsch`, `nochmal`
- obvious topic shifts inside one session (for example implementation -> bugfix -> performance -> tooling)
- skill drop-off: skill used in opening turns, then long manual phase without another skill

### 3. Choose analysis mode

- If claude-mem MCP tools are available: run the full workflow below.
- If they are unavailable: switch to **LOCAL FALLBACK** mode, skip semantic steps 3-4, and base findings only on JSONL metrics plus current-file verification. Label the report clearly as local-only.

### 4. Gather semantic data from claude-mem (parallel)

Run these 4 searches in parallel via `mcp__plugin_claude-mem_mcp-search__search`:

- Query: `"skill broken incomplete failed blocked"` — finds skill/workflow failures
- Query: `"token expensive slow model routing"` — finds token-waste patterns
- Query: `"repeated asked same question twice"` — finds recurring friction
- Query: `"workaround manual fallback missing"` — finds capability gaps

All **without** `project:` filter (cross-project), `limit: 10`, `dateStart: 30 days ago`.

### 5. Fetch key observations

From the results, identify the 5–8 most signal-rich observations (type: bugfix, decision, refactor preferred). Fetch with `mcp__plugin_claude-mem_mcp-search__get_observations`.

### 6. Cross-analyze metrics + observations

Use both sources in full mode, or JSONL metrics alone in local fallback. Look for:

**T (Tokenersparnis):**
- Sessions with high Bash call count (>50) — may indicate missing prep scripts
- Model distribution: Opus/Sonnet used where Haiku would suffice (search/explore)
- Sessions with 0 subagents but >200 tool calls — missing parallelization
- High turn count relative to `active` duration — indicates back-and-forth friction
- Deep-dive exports with huge cache reads plus many mid-session pivots — likely missing task segmentation or reset point
- Sessions with only 1 initial skill but long manual follow-up (>20 user turns after first skill) — automation opportunity after kickoff
- Skill files over 5KB (`wc -c .claude/skills/*/SKILL.md | sort -rn | head -5`) — bloated skills load all tokens on trigger; flag any >200 lines as candidate for trimming. **Quality gate**: For each trimming candidate, spawn a Haiku subagent (model: haiku) that reads the skill and lists its critical elements (decision tables, output format templates, agent spawn configs with model/tools, conditional logic with specific values, exact CLI flags/options). Include these in the finding as `**Critical elements:**` so the trimming spec knows what to preserve.

**Q (Qualität):**
- Skills invoked frequently that appear in failure observations
- Sessions with many Edit calls but few Bash (test) calls — missing verification
- Observations about broken workflows, status inconsistencies
- Reversal language inside one session (`mach das rückgängig`, `nein`, `immer noch`) — indicates weak confirmation, missing intermediate verification, or wrong abstraction
- Multiple topic shifts in one long session — likely context drift causing lower implementation precision

**E (Effizienz):**
- Same skill invoked across multiple sessions without progress — stalled workflow
- High tool diversity per session — indicates unclear routing
- Sessions with no skills used — manual work that could be automated
- Many user correction turns after a single initial spec/plan — missing mid-session re-planning hook
- Repeated bugfix wording around the same UI element in one export — missing local reproduction or instrumentation

### 7. Verify findings still apply

**Pre-filter**: Read `.claude/findings-log.md`. Extract all entries under `## Addressed`. If a candidate finding matches an addressed entry (by topic or title), drop it immediately — do not include it in the report.

For each remaining finding that references a specific skill or config file, read the current file to confirm the issue still exists. Drop findings already fixed.

For ai-setup-related findings, also verify version status:

- If the target project has `.ai-setup.json`, compare its installed version to the release that introduced the relevant fix
- Use `CHANGELOG.md` or completed specs as the source of truth for "fixed in vX.Y.Z"
- If the project is on an older version, report the finding as `Update candidate` rather than `Broken current setup`
- If the project is already on a version that should contain the fix, keep the finding only if current-file verification shows it still applies
- In deep-dive reports, distinguish clearly between `historical session issue` and `current reproducible issue`

### 8. Output report

```
# Session Optimize Report — <date>

## Metrics Snapshot (last N sessions)
Total sessions: N | Avg duration: Xmin | Avg tools/session: Y
Model split: sonnet X% / opus Y% / haiku Z%
Top tools: Tool1 (N), Tool2 (N), Tool3 (N)
Top skills: Skill1 (N sessions), Skill2 (N sessions)
Mode: Full | Local fallback
ai-setup context: project vX.Y.Z | latest repo vA.B.C | status: current / behind / unknown

## Deep-Dive Snapshot (if a specific export was provided)
Session: <id> | Duration: X | Messages: Y
Skills: N | Agents: N | User corrections: N
Topic shifts: N | Automation drop-off: Yes/No
Primary drift pattern: <1 line>
Version lens: historical-only / still relevant / fixed in newer ai-setup

## Summary
<1-2 sentences on dominant pattern found. Use `active` duration for efficiency conclusions; `wall` duration is context only.>

## Findings

### [Priority] [Q/E/T] <Title>
**Evidence:** <metric from JSONL + observation from claude-mem>
**Version:** <project ai-setup version context; fixed in vX.Y.Z? yes/no>
**Impact:** <what breaks or costs tokens>
**Fix:** <concrete 1-line change>
**File:** <path>
---
```

Priority: 🔴 High (recurring + high impact) / 🟡 Medium / ⚪ Low

Sort by priority descending. Max 8 findings — cut noise below ⚪.

## Rules

- Never make changes — report only.
- If a finding references a file, verify the issue still exists before including it.
- If metrics and semantic data both return nothing, report: "No signal in last 30 days — setup looks clean."
- In local fallback mode, do not invent semantic evidence; say explicitly that claude-mem was unavailable.
- Read `.claude/findings-log.md` as pre-filter before Step 5 — drop any finding that matches an entry in `## Addressed`.
- In Deep-dive mode, prefer concrete transcript evidence over generic heuristics.
- Treat repeated correction phrases inside one session as first-class evidence, not anecdote.
- If `claude-devtools` is available, use it only to strengthen evidence for loops, slow tool phases, or repeated UI interactions; do not rely on it as the sole source.
- Do not report ai-setup findings without checking version context first when `.ai-setup.json` exists.
- Prefer "fixed by update to vX.Y.Z" over "needs redesign" when the evidence points to a known released fix.
- **Model routing**: Use `model: haiku` for all MCP searches (Steps 2–3) and quality-gate subagents. Use `model: sonnet` only for pattern synthesis (Step 4 onwards). Never use Opus in this skill.
- **Token savings ≠ quality loss**: Every trimming recommendation MUST include a `**Critical elements:**` list (from Haiku subagent analysis). Trimming without this list is incomplete — the downstream spec-work quality gate depends on it.

## Next Step

Review findings and pick top items to address. For each fix: open a spec (`/spec`) or apply directly if it's a single-line change.

After the report: add all new findings to `.claude/findings-log.md` under `## Open`. When a finding is resolved, move it to `## Addressed` with date and fix reference.
