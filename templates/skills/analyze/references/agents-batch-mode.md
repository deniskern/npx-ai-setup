# Batch Mode — Agent Prompts

## Batch Agent Prompt (model: haiku, up to 3 concurrent)

Each batch agent receives up to 8 files:

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

## Synthesizer Agent Prompt (model: sonnet)

After all batch agents complete, dispatch one synthesizer:

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
