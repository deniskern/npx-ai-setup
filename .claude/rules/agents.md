# Agent Delegation Rules

## CRITICAL: Model Routing

Always set `model:` when spawning subagents. Haiku is the default — Sonnet only for substantial work.

| Model | Use for |
|-------|---------|
| `haiku` | **DEFAULT** — Explore, search, codebase questions, simple edits, config changes, single-file fixes |
| `sonnet` | **Only** multi-file implementation, complex code generation, full test suites |
| `opus` | Architecture review, complex analysis, spec creation |

Before spawning: Can Haiku handle this? If yes, use Haiku. Sonnet is the scarcest budget.
Prefer direct Glob/Grep/Read over agent spawns when < 3 tool calls needed.
Threshold: spawn agents only for tasks requiring ≥3 distinct tool calls AND write operations or code generation. Read-only exploration → no agent, use tools directly.
Escalation rule: if the session is likely to exceed ~8 tool calls and the work splits cleanly into independent tracks, delegate at least one bounded Haiku subagent instead of keeping everything serial.
Re-check rule: if you have already crossed >30 tool calls with no subagents, pause and explicitly decide whether the remaining work can be parallelized.

## Agent Selection

Each agent file contains `## When to Use` and `## Avoid If` sections. Read these before spawning an agent.

**Selection rules:**
- Match the task against `When to Use` bullet points — all conditions should broadly apply
- Check `Avoid If` first — if any condition matches, pick a different agent
- When two agents seem applicable, `Avoid If` sections will indicate which one to defer to
- Never spawn an agent if the task has fewer than 3 tool calls worth of work
- Never let subagents inherit your session context — construct exactly what they need in the prompt
- Never invent or guess file paths — verify with Glob/Grep before referencing
- If an agent reports a file path or symbol, verify it exists before acting on the report
- claude-mem observations may reference worktree files never merged to main — always verify paths exist before acting on them
- Skills with `disable-model-invocation: true` but no `model:` on agent spawns inherit the parent session model — in Opus sessions this costs 5× too much; always set `model:` explicitly on every agent spawn
