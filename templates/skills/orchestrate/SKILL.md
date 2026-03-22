---
name: orchestrate
description: Delegate a task to Gemini or Codex CLI. Use when the user says "use gemini for X", "use codex for X", "delegate to gemini", "delegate to codex", "ask gemini", or "ask codex". Only triggers on explicit delegation requests — never auto-routes.
---

# Orchestrate — Delegate Tasks to External AI Engines

Sends a prompt to Gemini CLI or Codex CLI and returns the result inside Claude Code.

## When to Use
- User explicitly asks to delegate: "use gemini to research X", "ask codex to write tests"
- User wants a second opinion from a different model
- Task benefits from Gemini's search/synthesis or Codex's speed

## Avoid If
- User does not explicitly name an engine — do not auto-route
- Task requires editing files (delegated engines lack Claude's conversation context)
- Task requires multi-turn interaction (delegation is single-shot)

## Process

1. **Identify the engine** from the user's request:
   - "gemini" / "google" → Gemini CLI
   - "codex" / "openai" → Codex CLI
   - If ambiguous, ask via AskUserQuestion with options: [Gemini, Codex]

2. **Check availability** — run the appropriate check via Bash:
   ```bash
   command -v gemini && echo "available" || echo "not installed"
   ```
   If the engine is not installed or API key is missing, inform the user clearly and stop. Do not silently fall back to another engine.

3. **Formulate the prompt** — take the user's task description and pass it to the wrapper script. Do NOT include Claude's conversation history — the delegated engine only gets the task prompt plus AGENTS.md project context (injected automatically by the wrapper).

4. **Execute delegation** via Bash:
   ```bash
   bash .claude/scripts/delegate-gemini.sh "the task prompt" 120
   ```
   or:
   ```bash
   bash .claude/scripts/delegate-codex.sh "the task prompt" 120
   ```
   Adjust timeout (second argument, in seconds) based on task complexity:
   - Quick research/questions: 60s
   - Code generation/analysis: 120s (default)
   - Large research tasks: 300s

5. **Present the result** — show the delegated engine's output to the user. Add a brief header:
   ```
   ## Result from [Gemini/Codex]
   [output]
   ```

6. **Important constraints to communicate if relevant**:
   - The delegated engine did not have access to your conversation history
   - If the output suggests file edits, those were NOT applied — the user should review and decide
   - The delegated engine's token usage is not tracked in Claude Code's metrics

## Error Handling
- Engine not installed → tell user how to install (`npm install -g @google/gemini-cli` or `@openai/codex`)
- API key missing → tell user which env var to set (`GEMINI_API_KEY` or `OPENAI_API_KEY`)
- Timeout → report the timeout and suggest increasing it or simplifying the task
- Non-zero exit → show the error message from stderr
