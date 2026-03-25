---
name: session-optimize
description: Analyzes past sessions via claude-mem and raw JSONL metrics to surface quality, efficiency, and token-saving improvements. Triggers: /session-optimize, 'analyze sessions', 'optimize setup from sessions'.
model: sonnet
allowed-tools: Read, Bash, Glob, Grep, mcp__plugin_claude-mem_mcp-search__search, mcp__plugin_claude-mem_mcp-search__get_observations, mcp__plugin_claude-mem_mcp-search__timeline
---

Analyzes the last 30 days of sessions for this project — combining semantic observations (claude-mem) with raw session metrics (JSONL) — and outputs a prioritized list of setup improvements focused on **Qualität, Effizienz und Tokenersparnis**.

## Process

### 1. Extract raw session metrics (zero LLM tokens)

```
! bash .claude/scripts/session-extract.sh --last 10
```

This produces per-session: turns, tool usage counts, model distribution, skills invoked, subagent count, duration, and estimated output tokens.

### 2. Gather semantic data from claude-mem (parallel)

Run these 4 searches in parallel via `mcp__plugin_claude-mem_mcp-search__search`:

- Query: `"skill broken incomplete failed blocked"` — finds skill/workflow failures
- Query: `"token expensive slow model routing"` — finds token-waste patterns
- Query: `"repeated asked same question twice"` — finds recurring friction
- Query: `"workaround manual fallback missing"` — finds capability gaps

All with `project: npx-ai-setup`, `limit: 10`, `dateStart: 30 days ago`.

### 3. Fetch key observations

From the results, identify the 5–8 most signal-rich observations (type: bugfix, decision, refactor preferred). Fetch with `mcp__plugin_claude-mem_mcp-search__get_observations`.

### 4. Cross-analyze metrics + observations

Combine both data sources. Look for:

**T (Tokenersparnis):**
- Sessions with high Bash call count (>50) — may indicate missing prep scripts
- Model distribution: Opus/Sonnet used where Haiku would suffice (search/explore)
- Sessions with 0 subagents but >200 tool calls — missing parallelization
- High turn count relative to duration — indicates back-and-forth friction

**Q (Qualität):**
- Skills invoked frequently that appear in failure observations
- Sessions with many Edit calls but few Bash (test) calls — missing verification
- Observations about broken workflows, status inconsistencies

**E (Effizienz):**
- Same skill invoked across multiple sessions without progress — stalled workflow
- High tool diversity per session — indicates unclear routing
- Sessions with no skills used — manual work that could be automated

### 5. Verify findings still apply

For each finding that references a specific skill or config file, read the current file to confirm the issue still exists. Drop findings already fixed.

### 6. Output report

```
# Session Optimize Report — <date>

## Metrics Snapshot (last N sessions)
Total sessions: N | Avg duration: Xmin | Avg tools/session: Y
Model split: sonnet X% / opus Y% / haiku Z%
Top tools: Tool1 (N), Tool2 (N), Tool3 (N)
Top skills: Skill1 (N sessions), Skill2 (N sessions)

## Summary
<1-2 sentences on dominant pattern found>

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
- If both data sources return nothing, report: "No signal in last 30 days — setup looks clean."
- Skip findings that duplicate what's already in `.agents/context/LEARNINGS.md`.
- **Model routing**: Use `model: haiku` for all MCP searches (Steps 2–3). Use `model: sonnet` only for pattern synthesis (Step 4 onwards). Never use Opus in this skill.

## Next Step

Review findings and pick top items to address. For each fix: open a spec (`/spec-create`) or apply directly if it's a single-line change.
