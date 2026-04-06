# Fast Mode — 3 Parallel Agent Prompts

Spawn all three agents simultaneously using the Agent tool in parallel.

## Agent 1 — Architecture (model: haiku)

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

## Agent 2 — Hotspots (model: haiku)

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

## Agent 3 — Risks (model: haiku)

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
