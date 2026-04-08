---
name: ais:session-optimize
description: "Analyzes past sessions via claude-mem and raw JSONL metrics to surface quality, efficiency, and token-saving improvements. Triggers: /session-optimize, 'analyze sessions', 'optimize setup from sessions'."
model: sonnet
allowed-tools: Read, Bash, Glob, Grep, mcp__plugin_claude-mem_mcp-search__search, mcp__plugin_claude-mem_mcp-search__get_observations, mcp__plugin_claude-mem_mcp-search__timeline
---

Analyzes sessions for setup improvements focused on **Qualitat, Effizienz und Tokenersparnis**.

## Modes

- **Portfolio (default):** last 30 days across all projects via JSONL + claude-mem
- **Deep-dive:** specific export file (`session-*.txt`) — run `bash .claude/scripts/session-deep-dive.sh <path>` first, then refine
- **Insights:** parse `~/.claude/usage-data/report.html` (from `/insights` command) for aggregated cross-session metrics, friction patterns, and CLAUDE.md suggestions. Use as enrichment layer on top of Portfolio or Deep-dive.
- **Token analysis:** cross-project token breakdown via `token_analysis.py` — run when user asks for token usage per project, costliest sessions, or cache hit ratios.
- **Devtools assist:** extra source only for tool timing/loops — never sole source

## Token Analysis

Wenn der User Token-Verbrauch pro Projekt, teuerste Sessions oder Cache-Hit-Ratio sehen will:

```bash
! python3 .claude/skills/session-optimize/token_analysis.py
```

Output landet in `~/.claude/token-analysis/token_report.md`. Umgebungsvariablen:
- `SINCE_DAYS=30` — nur letzte 30 Tage
- `SINCE_DATE=2026-04-01` — ab Datum
- `TOKEN_ANALYSIS_OUTPUT=/pfad` — Output-Verzeichnis überschreiben

Cache-Hit-Ratio sollte >85% sein. Darunter: zu viele Idle-Gaps (>5min Pause mid-session).

## Process

### 1. Detect scope
- Concrete export path → Deep-dive; otherwise → Portfolio; both → deep-dive first, then compare
- Always check if `~/.claude/usage-data/report.html` exists — if yes, extract Insights data as enrichment

### 2. Extract metrics
```
! bash .claude/scripts/session-extract.sh --all --last 5
```
- Check `.ai-setup.json` for `version`/`updated_at`; compare with repo `package.json`/`CHANGELOG.md`
- Session predates project's `updated_at` → findings are `version-bound`, not current bugs
- Deep-dive: also extract USER/ASSISTANT/THINKING/Skill/Agent block counts, correction markers (`geht nicht`, `nein`, `immer noch`, `ruckgangig`, `anders`, `falsch`, `nochmal`), topic shifts, skill drop-off, config drift

### 2b. Extract Insights (if report.html exists)
Read `~/.claude/usage-data/report.html` and extract:
- **Stats**: messages, sessions, lines changed, files touched, msgs/day
- **Tool distribution**: top tools with counts (bar-value divs)
- **Friction categories**: title + description from `.friction-category` blocks
- **Outcomes**: Fully/Mostly/Partially/Not Achieved counts
- **Satisfaction**: Frustrated/Dissatisfied/Likely Satisfied/Satisfied counts
- **CLAUDE.md suggestions**: text from `.cmd-code` elements
- **Multi-Clauding**: overlap events, sessions involved, percentage
- **Big wins**: titles from `.big-win-title` elements

Cross-reference Insights friction with claude-mem observations — matching patterns get priority boost.

### 3. claude-mem (skip if unavailable → LOCAL FALLBACK, label report)
4 parallel searches (`limit: 10`, `dateStart: 30d ago`, no `project:` filter):
- `"skill broken incomplete failed blocked"` | `"token expensive slow model routing"` | `"repeated asked same question twice"` | `"workaround manual fallback missing"`

Fetch 5-8 most signal-rich observations via `get_observations`.

### 4. Cross-analyze — look for these patterns

**T (Tokenersparnis):**
- Bash >50 → missing prep scripts
- Opus/Sonnet where Haiku suffices (search/explore)
- 0 subagents + >200 tools → missing parallelization
- >300 messages or >10M cache-read + corrections → recommend reset
- 1 initial skill + >20 manual turns → automation gap
- Skills >5KB (`wc -c .claude/skills/*/SKILL.md | sort -rn | head -5`) → trimming candidate; >200 lines → spawn Haiku subagent for critical elements list (decision tables, output templates, model configs, thresholds, CLI flags). **Include `Critical elements:` in finding — required for downstream trimming.**

**Q (Qualitat):**
- Frequent skills in failure observations
- Many Edits + few Bash(test) → missing verification
- >=3 same-theme corrections or >=5 total → recommend instrumentation
- Multiple topic shifts in long session → context drift

**E (Effizienz):**
- Same skill across sessions without progress → stalled
- No skills used → manual work candidates
- >=8 turns after last skill with no new skill, or >=3 corrections after last plan → forced re-plan
- Current ai-setup version but missing routing text → config drift

### 5. Verify findings
- Pre-filter: read `.claude/findings-log.md` `## Addressed` — drop matches
- Read referenced files to confirm issue still exists
- Version check: `.ai-setup.json` vs `CHANGELOG.md` — older version → `Update candidate`; current version + still broken → keep; current + config mismatch → `config drift`
- Deep-dive: distinguish `historical session issue` vs `current reproducible issue`

### 6. Output report

```
# Session Optimize Report — <date>

## Metrics Snapshot (last N sessions)
Total sessions: N | Avg duration: Xmin | Avg tools/session: Y
Model split: sonnet X% / opus Y% / haiku Z%
Top tools: Tool1 (N), Tool2 (N), Tool3 (N)
Top skills: Skill1 (N sessions), Skill2 (N sessions)
Mode: Full | Local fallback
ai-setup context: project vX.Y.Z | latest repo vA.B.C | status: current / behind / unknown

## Deep-Dive Snapshot (if export provided)
Session: <id> | Duration: X | Messages: Y | Skills: N | Agents: N | Corrections: N
Topic shifts: N | Automation drop-off: Yes/No | Primary drift: <1 line>
Version lens: historical-only / still relevant / fixed in newer ai-setup
Config drift: none / possible / confirmed

## Insights Snapshot (if report.html found)
Period: <date range> | Sessions: N | Messages: N | Satisfaction: X%
Top friction: <category> (N instances) | Outcomes: N fully / N partial / N not
CLAUDE.md suggestions: N new / N already addressed
Multi-Clauding: N overlap events (X% of messages)

## Summary
<1-2 sentences. Use `active` duration for efficiency; `wall` is context only.>

## Findings (max 8, sorted by priority)

### [Priority] [Q/E/T] <Title>
**Evidence:** <metric + observation>
**Version:** <ai-setup version context>
**Impact:** <what breaks or costs tokens>
**Fix:** <concrete 1-line change>
**File:** <path>
```

Priority: P1 High (recurring + high impact) / P2 Medium / P3 Low

## Fix Routing

When the user asks to implement findings: **always fix in `templates/` first**, then sync to the target project.
Fixes only in individual projects verpuffen beim naechsten Setup — Templates sind die Source of Truth.

## Rules

- Report only — never make changes (unless user explicitly asks to fix)
- Verify file state before including any finding
- Local fallback: no invented semantic evidence
- Deep-dive thresholds: >=5 corrections, >=3 same-theme, >=8 turns since plan, >300 messages, >10M cache-read
- Model routing: `haiku` for MCP searches + quality-gate subagents; `sonnet` for synthesis; never Opus
- Trimming findings without `Critical elements:` list = incomplete

## Next Step

After report: add new findings to `.claude/findings-log.md` under `## Open`. Resolved → `## Addressed` with date.
