---
name: session-optimize
description: Analyzes past sessions via claude-mem and raw JSONL metrics to surface quality, efficiency, and token-saving improvements. Triggers: /session-optimize, 'analyze sessions', 'optimize setup from sessions'.
model: sonnet
allowed-tools: Read, Bash, Glob, Grep, mcp__plugin_claude-mem_mcp-search__search, mcp__plugin_claude-mem_mcp-search__get_observations, mcp__plugin_claude-mem_mcp-search__timeline
---

Analyzes the last 30 days of sessions **across all projects** — combining semantic observations (claude-mem) with raw session metrics (JSONL) — and outputs a prioritized list of setup improvements focused on **Qualität, Effizienz und Tokenersparnis**.

## Process

### 1. Extract raw session metrics (zero LLM tokens)

```
! bash .claude/scripts/session-extract.sh --all --last 5
```

This produces per-session across all projects: turns, tool usage counts, model distribution, skills invoked, subagent count, `active` and `wall` duration, and estimated output tokens. `active` duration caps long idle gaps so open-but-idle sessions do not look artificially inefficient.

### 2. Choose analysis mode

- If claude-mem MCP tools are available: run the full workflow below.
- If they are unavailable: switch to **LOCAL FALLBACK** mode, skip semantic steps 3-4, and base findings only on JSONL metrics plus current-file verification. Label the report clearly as local-only.

### 3. Gather semantic data from claude-mem (parallel)

Run these 4 searches in parallel via `mcp__plugin_claude-mem_mcp-search__search`:

- Query: `"skill broken incomplete failed blocked"` — finds skill/workflow failures
- Query: `"token expensive slow model routing"` — finds token-waste patterns
- Query: `"repeated asked same question twice"` — finds recurring friction
- Query: `"workaround manual fallback missing"` — finds capability gaps

All **without** `project:` filter (cross-project), `limit: 10`, `dateStart: 30 days ago`.

### 4. Fetch key observations

From the results, identify the 5–8 most signal-rich observations (type: bugfix, decision, refactor preferred). Fetch with `mcp__plugin_claude-mem_mcp-search__get_observations`.

### 5. Cross-analyze metrics + observations

Use both sources in full mode, or JSONL metrics alone in local fallback. Look for:

**T (Tokenersparnis):**
- Sessions with high Bash call count (>50) — may indicate missing prep scripts
- Model distribution: Opus/Sonnet used where Haiku would suffice (search/explore)
- Sessions with 0 subagents but >200 tool calls — missing parallelization
- High turn count relative to `active` duration — indicates back-and-forth friction
- Skill files over 5KB (`wc -c .claude/skills/*/SKILL.md | sort -rn | head -5`) — bloated skills load all tokens on trigger; flag any >200 lines as candidate for trimming. **Quality gate**: For each trimming candidate, spawn a Haiku subagent (model: haiku) that reads the skill and lists its critical elements (decision tables, output format templates, agent spawn configs with model/tools, conditional logic with specific values, exact CLI flags/options). Include these in the finding as `**Critical elements:**` so the trimming spec knows what to preserve.

**Q (Qualität):**
- Skills invoked frequently that appear in failure observations
- Sessions with many Edit calls but few Bash (test) calls — missing verification
- Observations about broken workflows, status inconsistencies

**E (Effizienz):**
- Same skill invoked across multiple sessions without progress — stalled workflow
- High tool diversity per session — indicates unclear routing
- Sessions with no skills used — manual work that could be automated

### 6. Verify findings still apply

**Pre-filter**: Read `.claude/findings-log.md`. Extract all entries under `## Addressed`. If a candidate finding matches an addressed entry (by topic or title), drop it immediately — do not include it in the report.

For each remaining finding that references a specific skill or config file, read the current file to confirm the issue still exists. Drop findings already fixed.

### 7. Output report

```
# Session Optimize Report — <date>

## Metrics Snapshot (last N sessions)
Total sessions: N | Avg duration: Xmin | Avg tools/session: Y
Model split: sonnet X% / opus Y% / haiku Z%
Top tools: Tool1 (N), Tool2 (N), Tool3 (N)
Top skills: Skill1 (N sessions), Skill2 (N sessions)
Mode: Full | Local fallback

## Summary
<1-2 sentences on dominant pattern found. Use `active` duration for efficiency conclusions; `wall` duration is context only.>

## Findings

### [Priority] [Q/E/T] <Title>
**Evidence:** <metric from JSONL + observation from claude-mem>
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
- **Model routing**: Use `model: haiku` for all MCP searches (Steps 2–3) and quality-gate subagents. Use `model: sonnet` only for pattern synthesis (Step 4 onwards). Never use Opus in this skill.
- **Token savings ≠ quality loss**: Every trimming recommendation MUST include a `**Critical elements:**` list (from Haiku subagent analysis). Trimming without this list is incomplete — the downstream spec-work quality gate depends on it.

## Next Step

Review findings and pick top items to address. For each fix: open a spec (`/spec`) or apply directly if it's a single-line change.

After the report: add all new findings to `.claude/findings-log.md` under `## Open`. When a finding is resolved, move it to `## Addressed` with date and fix reference.
