# Token Optimization Guide

This project uses a 6-layer architecture to minimize Claude's token consumption.

## Layer 1: Prep-Scripts

Shell scripts in `.claude/scripts/*-prep.sh` gather data before Claude analyzes it. Green paths (e.g. `ALL_TESTS_PASSED`) cost zero LLM tokens.

| Script | Green Path | Savings |
|--------|-----------|---------|
| `test-prep.sh` | `ALL_TESTS_PASSED` | 90%+ |
| `scan-prep.sh` | `NO_VULNERABILITIES_FOUND` | 80-85% |
| `commit-prep.sh` | `NO_STAGED_CHANGES` | 60-65% |
| `review-prep.sh` | `NO_CHANGES_TO_REVIEW` | 70-75% |
| `build-prep.sh` | `BUILD_PASSED` | 80-90% |
| `lint-prep.sh` | `NO_LINT_ERRORS` | 80-85% |

### Writing a new prep-script

Source `prep-lib.sh` and follow the conventions documented there:

```bash
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/prep-lib.sh"

git_guard  # if git is required

# Green-path early-exit (MUST have one)
if [[ nothing_to_do ]]; then
  echo "NOTHING_TO_DO"
  exit 0
fi

# Gather data using rtk_or_raw for compression
DATA=$(rtk_or_raw git diff --staged)

# Exit 0 = success, exit 1 = error, exit 2 = issues found
```

## Layer 2: RTK (Rust Token Killer)

CLI proxy that compresses command output by 60-90%. Installed automatically during setup.

```bash
rtk gain              # Check current savings
rtk gain --history    # Usage history with savings per command
rtk --version         # Verify installation
```

RTK hooks are activated via `rtk init --global` (runs during setup). They transparently rewrite Bash tool calls: `git status` becomes `rtk git status`.

### Key RTK commands

| Command | What it does |
|---------|-------------|
| `rtk git status` | Compact status (-80%) |
| `rtk git diff` | Condensed diff (-75%) |
| `rtk test <cmd>` | Test output, failures only (-90%) |
| `rtk lint` | Lint results grouped by rule (-80%) |
| `rtk tsc` | TypeScript errors grouped by file (-80%) |
| `rtk err <cmd>` | Errors/warnings only (-85%) |

## Layer 3: Hooks

Hooks in `.claude/hooks/` intercept tool calls:

- `cli-health.sh` — warns at session start if rtk/defuddle missing
- `protect-files.sh` — blocks reads of .env, lock files, build output
- `circuit-breaker.sh` — stops after 8 edits to the same file in 10 minutes
- `context-monitor.sh` — warns at 35% remaining context

## Layer 4: Deny Patterns

`settings.json` blocks wasteful reads: `dist/`, `node_modules/`, `*.min.js`, `package-lock.json`, `.env*`. These are hard blocks — Claude cannot bypass them.

## Layer 5: Model Routing

Skills use the cheapest model that can handle the task:

| Model | Used for |
|-------|---------|
| haiku | `/commit`, explore agents, file search |
| sonnet | `/test`, `/scan`, `/debug`, code generation |
| opus | `/review` adversarial, `/spec`, architecture |

## Layer 6: Green-Path Short-Circuits

When nothing needs attention, prep-scripts return a one-line message and exit 0. Claude sees only the message — no data to analyze, no tokens consumed.

## Verification

Run these to check the system is working:

```bash
rtk gain                    # RTK savings stats
rtk gain --history          # Per-command breakdown
ls .claude/scripts/*-prep.sh  # Available prep-scripts
ls .claude/hooks/           # Active hooks
```
