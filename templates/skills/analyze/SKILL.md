---
description: Produces a structured codebase overview via parallel agents. Use when exploring or preparing for major changes.
model: sonnet
allowed-tools: Read, Glob, Grep, Bash, Agent
---

Produces a structured codebase overview via parallel agents. Use when exploring or preparing for major changes.

## Process

### 0. Count source files

Run this command to get the source file count:

```bash
git ls-files 2>/dev/null | grep -E '\.(ts|tsx|js|jsx|py|go|rs|rb|php|java|kt|swift|vue|svelte|sh|sql)$' | grep -v -E '(\.lock|\.min\.|dist/|build/|node_modules/|vendor/|\.next/|\.nuxt/)' | wc -l
```

Store the count and the file list. This determines the analysis mode.

**Source extensions**: ts, tsx, js, jsx, py, go, rs, rb, php, java, kt, swift, vue, svelte, sh, sql
**Excluded**: lockfiles, minified files, build output, vendor directories

### 1. Choose analysis mode

- **Fast mode** (<=30 source files): Go to Step 2A — launch 3 agents simultaneously
- **Batch mode** (>30 source files): Go to Step 2B — batched analysis with synthesizer

---

### 2A. Fast mode — 3 parallel agents

Spawn all three agents at the same time using the Agent tool in parallel:

**Agent 1 — Architecture** (model: haiku)

```
You are an Architecture exploration agent. Analyze this codebase and report:

1. Read `.agents/context/ARCHITECTURE.md` if it exists — use it as the starting point.
2. Identify entry points (main files, index files, CLI entrypoints, server bootstraps).
3. Trace the primary data flow from input to output.
4. Map module/package boundaries and their responsibilities.
5. Identify key abstractions (base classes, interfaces, core utilities, shared types).
6. Note the directory structure and what lives where.

Return a concise report under the heading: ## Architecture
Include sub-sections: Entry Points, Data Flow, Module Boundaries, Key Abstractions.
Keep it factual and dense — no padding.
```

**Agent 2 — Hotspots** (model: haiku)

```
You are a Hotspots exploration agent. Find the most active and complex areas of this codebase:

1. Run: git log --format="%f" | sort | uniq -c | sort -rn | head -20
   List the top 20 most-changed files with their change counts.
2. Find the 10 largest files by line count (use: find . -name "*.{js,ts,py,rb,go,sh}" -not -path "*/node_modules/*" -not -path "*/.git/*" | xargs wc -l 2>/dev/null | sort -rn | head -15).
3. Identify complex areas: deeply nested functions, files with many responsibilities, long functions.
4. Note any files that appear in both "most changed" and "largest" — these are highest-risk hotspots.

Return a concise report under the heading: ## Hotspots
Include sub-sections: Most Changed Files, Largest Files, Complexity Areas.
```

**Agent 3 — Risks** (model: haiku)

```
You are a Risk exploration agent. Find quality issues and risk areas in this codebase:

1. Search for TODO/FIXME/HACK/XXX comments: grep -rn "TODO\|FIXME\|HACK\|XXX" --include="*.{js,ts,py,rb,go,sh,md}" --exclude-dir={node_modules,.git,dist,build} . 2>/dev/null | head -40
2. Look for dead code patterns: exported symbols never imported, commented-out code blocks.
3. Check for missing error handling: unhandled promise rejections, bare catch blocks, unchecked return values.
4. Identify inconsistent naming: mixed camelCase/snake_case, inconsistent file naming conventions.
5. Note any security-adjacent patterns: hardcoded strings that look like credentials, unvalidated inputs.

Return a concise report under the heading: ## Risks
Include sub-sections: TODOs/FIXMEs, Dead Code, Error Handling Gaps, Naming Inconsistencies.
```

After all 3 agents return, go to **Step 3**.

---

### 2B. Batch mode — batched analysis with synthesizer

**Step 2B.1**: Split the source file list into batches of 8 files each.

**Step 2B.2**: Process batches in waves of up to 3 concurrent agents. Each agent (model: haiku) receives:

```
You are a Batch Analysis agent. Analyze these source files and report findings.

Files to analyze:
[list of 8 file paths]

For each file:
1. Read the file completely.
2. Note: purpose (1 sentence), key exports/functions, dependencies (imports), complexity (low/medium/high).
3. Identify any issues: TODOs, error handling gaps, security concerns, dead code.

Also analyze cross-file patterns within this batch:
- Which files depend on each other?
- Are there shared patterns or inconsistencies?

Return a structured JSON report:
{
  "files": [{"path": "...", "purpose": "...", "exports": [...], "imports": [...], "complexity": "...", "issues": [...]}],
  "crossFilePatterns": ["..."],
  "issues": [{"file": "...", "type": "...", "description": "..."}]
}
```

**Step 2B.3**: After all batches complete, dispatch one **Synthesizer agent** (model: sonnet):

```
You are a Synthesis agent. You receive batch analysis results from multiple agents that each analyzed a subset of the codebase. Your job is to produce a unified analysis report.

Batch results:
[paste all batch outputs here]

Total source files analyzed: [count]

Produce a unified report with these sections:

## Architecture
- Entry points and bootstrapping
- Module boundaries and responsibilities
- Key abstractions and data flow
- Directory structure overview

## Hotspots
- Most complex files (by reported complexity)
- Files with most cross-dependencies
- Areas with clustered issues

## Risks
- All issues found across batches, deduplicated
- Cross-cutting concerns (patterns that appear in multiple batches)
- Inconsistencies between batches

## Recommendations
- 3-5 actionable items ranked by impact

Resolve contradictions between batches (e.g., one batch calls a file "clean", another flags it).
Keep it factual and dense — no padding.
```

---

### 3. Synthesize and output

Combine all agent outputs into a single structured report:

```
## Architecture
[Architecture findings]

## Hotspots
[Hotspot findings]

## Risks
[Risk findings]

## Recommendations
[3-5 actionable recommendations based on findings above]
```

---

### 4. Persist analysis artifacts

After outputting the report, save it as team-shared context files.

**4.1 — Check existing files**

```bash
ls .agents/context/PATTERNS.md .agents/context/AUDIT.md 2>/dev/null
```

If either file exists, ask the user:

> "`.agents/context/PATTERNS.md` and/or `AUDIT.md` already exist. Regenerate?"

If the user says **No**: stop here.

**4.2 — Write PATTERNS.md**

Create `.agents/context/PATTERNS.md` from the Architecture section of the report:

```
# Patterns

> Generated by /analyze — do not edit manually. Re-run /analyze to refresh.

[Architecture findings verbatim from Step 3 output]
```

**4.3 — Write AUDIT.md**

Create `.agents/context/AUDIT.md` from the Hotspots, Risks, and Recommendations sections:

```
# Audit

> Generated by /analyze — do not edit manually. Re-run /analyze to refresh.

[Hotspots findings verbatim from Step 3 output]

[Risks findings verbatim from Step 3 output]

[Recommendations verbatim from Step 3 output]
```

**4.4 — Commit**

```bash
git add .agents/context/PATTERNS.md .agents/context/AUDIT.md
git commit -m "chore: update project analysis artifacts"
```

---

## Rules

- Launch agents in parallel — do not wait for one before starting the next.
- Each agent works independently — no shared state between them.
- Always write PATTERNS.md and AUDIT.md after the report — this is the primary output.
- Keep each section dense and factual; omit padding and filler phrases.
- If a command fails (e.g. git not available), note it and continue with available data.
- In batch mode: if a batch agent fails, continue with remaining batches and note the gap.

## Next Step

After reviewing the analysis report, run `/spec "task description"` to create a spec for any identified improvement or architectural change.
