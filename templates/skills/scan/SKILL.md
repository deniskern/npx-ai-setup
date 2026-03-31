---
name: scan
description: "Scans project dependencies for security vulnerabilities. Uses `scan-prep.sh` to gather and filter raw audit data before Claude analyzes it — zero tokens spent on data collection."
model: sonnet
allowed-tools: Read, Bash, Glob
---

Scans project dependencies for security vulnerabilities. Uses `scan-prep.sh` to gather and filter raw audit data before Claude analyzes it — zero tokens spent on data collection.

## Process

1. **Run the prep script** (zero LLM tokens):
   ```
   ! bash .claude/scripts/scan-prep.sh
   ```
   - Exit 0 → `NO_VULNERABILITIES_FOUND` — report clean and stop.
   - Exit 1 → tool/config error — report the error message and stop.
   - Exit 2 → vulnerabilities found, output contains pre-grouped severity summary.

2. **Analyze the prep output** — the script already groups by CRITICAL / HIGH / MEDIUM / LOW with package names, versions, and CVE IDs. Do not re-run the scanner.

3. **Report results**:
   - Show the grouped findings from prep output.
   - For each severity group, add remediation hint:
     - Node.js: `npm audit fix` (non-breaking) or `npm audit fix --force` (breaking)
     - Python: `pip install --upgrade <package>`
     - Ruby: `bundle update <gem>`
     - Snyk: `snyk fix`

## Rules
- Do NOT auto-fix — only report and suggest fix commands.
- Do NOT install any tools — only use what is already available.
- Do NOT re-run the scanner if prep script already ran.
- Run in the project root.

## Deep Analysis (CRITICAL/HIGH only)

If the prep script reports CRITICAL or HIGH vulnerabilities:
- Spawn `security-reviewer` agent (model: sonnet) with the vulnerability list and affected files
- The agent checks whether the vulnerable code paths are actually reachable in this project
- Report agent findings alongside the prep output — distinguishes "vulnerable dependency installed" from "vulnerability actively exploitable"

## Next Step

After reviewing vulnerabilities, apply the suggested fix commands, then run `/test` to verify nothing broke, and `/commit` to checkpoint the fixes.
