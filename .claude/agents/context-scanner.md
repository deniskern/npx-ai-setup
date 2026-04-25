---
name: context-scanner
description: Scans project context files and detects stack profile. Use before writing a spec to give the main session accurate stack + dependency information.
tools: Read, Glob, Grep, Bash
model: haiku
max_turns: 8
---

## Task

Scan this project and return a ≤1-page summary with:
1. `stack_profile` — run `bash lib/detect-stack.sh 2>/dev/null | grep stack_profile` or infer from file patterns
2. Key versions — read `package.json`, `composer.json`, or `*.toml` for top 5 runtime deps
3. Context files present — list files in `.agents/context/` with line counts
4. Relevant rules — list `.claude/rules/*.md` files and their first-line description
5. Existing patterns — if `.agents/context/PATTERNS.md` exists, extract top 3 patterns

## Output Format

```
stack_profile: <profile>

Key versions:
- <pkg>: <version>
- ...

Context files:
- STACK.md (NN lines)
- ARCHITECTURE.md (NN lines)
- ...

Rules active:
- agents.md — ...
- workflow.md — ...

Top patterns:
1. ...
```

Return ONLY this summary. No recommendations, no extra commentary.
