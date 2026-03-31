#!/usr/bin/env bash
# session-extract.sh — Extract metrics from Claude Code session JSONL files
# Usage: bash .claude/scripts/session-extract.sh [project-path-slug] [--last N] [--all]
#
# Examples:
#   bash .claude/scripts/session-extract.sh                    # current project, last 5 sessions
#   bash .claude/scripts/session-extract.sh --last 10          # current project, last 10
#   bash .claude/scripts/session-extract.sh --all --last 10    # all projects, last 10 per project
#   bash .claude/scripts/session-extract.sh -Users-deniskern-Sites-npx-ai-setup --last 3

set -euo pipefail

ALL_PROJECTS=false
SLUG="-Users-deniskern-Sites-npx-ai-setup"
LAST=5
SESSION_IDLE_CAP_MINUTES="${SESSION_IDLE_CAP_MINUTES:-10}"

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --all) ALL_PROJECTS=true; shift ;;
    --last) LAST="${2:-5}"; shift 2 ;;
    *) SLUG="$1"; shift ;;
  esac
done

PROJECTS_DIR="${SESSION_EXTRACT_PROJECTS_DIR:-$HOME/.claude/projects}"

if $ALL_PROJECTS; then
  DIRS=()
  while IFS= read -r d; do
    DIRS+=("$d")
  done < <(find "$PROJECTS_DIR" -mindepth 1 -maxdepth 1 -type d | sort)
else
  DIRS=("$PROJECTS_DIR/$SLUG")
fi

echo "SESSION_EXTRACT_START $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

for SESSION_DIR in "${DIRS[@]}"; do
  [[ ! -d "$SESSION_DIR" ]] && continue

  _slug=$(basename "$SESSION_DIR")
  # Extract project name from slug: -Users-foo-Sites-my-project → my-project
  if echo "$_slug" | grep -q -- '-Sites-'; then
    PROJECT_LABEL=$(echo "$_slug" | sed 's/.*-Sites-//')
  else
    PROJECT_LABEL=$_slug
  fi

  # Get most recent N session files (exclude subagent dirs)
  SESSION_FILES=()
  while IFS= read -r f; do
    SESSION_FILES+=("$f")
  done < <(find "$SESSION_DIR" -maxdepth 1 -name "*.jsonl" -type f -print0 2>/dev/null | xargs -0 ls -t 2>/dev/null | head -n "$LAST")

  [[ ${#SESSION_FILES[@]} -eq 0 ]] && continue

  echo "=== PROJECT: $PROJECT_LABEL (last $LAST) ==="
  echo ""

  python3 - "$SESSION_IDLE_CAP_MINUTES" "${SESSION_FILES[@]}" <<'PYEOF'
import json, sys, os
from datetime import datetime
from collections import Counter

try:
    idle_cap_minutes = max(float(sys.argv[1]), 0.0)
except Exception:
    idle_cap_minutes = 10.0

files = sys.argv[2:]

for filepath in files:
    session_id = os.path.basename(filepath).replace('.jsonl', '')

    with open(filepath) as f:
        entries = []
        for line in f:
            line = line.strip()
            if line:
                try:
                    entries.append(json.loads(line))
                except:
                    pass

    if not entries:
        continue

    # Basic counts
    user_msgs = [e for e in entries if e.get('type') == 'user']
    assistant_msgs = [e for e in entries if e.get('type') == 'assistant']
    progress_msgs = [e for e in entries if e.get('type') == 'progress']

    # Timestamps: report both wall time and "active" time with idle gaps capped.
    timestamps = [e.get('timestamp') for e in entries if e.get('timestamp')]
    if timestamps:
        first_ts = min(timestamps)
        last_ts = max(timestamps)
        wall_duration_min = 0
        active_duration_min = 0
        try:
            t1 = datetime.fromisoformat(first_ts.replace('Z', '+00:00'))
            t2 = datetime.fromisoformat(last_ts.replace('Z', '+00:00'))
            wall_duration_min = max((t2 - t1).total_seconds() / 60, 0)
            start_str = t1.strftime('%Y-%m-%d %H:%M')

            parsed_times = []
            for ts in sorted(timestamps):
                try:
                    parsed_times.append(datetime.fromisoformat(ts.replace('Z', '+00:00')))
                except Exception:
                    pass

            if len(parsed_times) <= 1:
                active_duration_min = wall_duration_min
            else:
                idle_cap_seconds = idle_cap_minutes * 60
                for prev, curr in zip(parsed_times, parsed_times[1:]):
                    gap_seconds = max((curr - prev).total_seconds(), 0)
                    active_duration_min += min(gap_seconds, idle_cap_seconds)
                active_duration_min /= 60
        except:
            wall_duration_min = 0
            active_duration_min = 0
            start_str = first_ts[:16]
    else:
        wall_duration_min = 0
        active_duration_min = 0
        start_str = '?'

    # Model used
    models = Counter()
    for e in assistant_msgs:
        msg = e.get('message', {})
        if isinstance(msg, dict):
            model = msg.get('model', '?')
            models[model] += 1

    # Tool usage
    tool_counts = Counter()
    for e in assistant_msgs:
        msg = e.get('message', {})
        content = msg.get('content', []) if isinstance(msg, dict) else []
        if isinstance(content, list):
            for c in content:
                if isinstance(c, dict) and c.get('type') == 'tool_use':
                    tool_counts[c.get('name', '?')] += 1

    total_tools = sum(tool_counts.values())

    # Skills invoked (check both assistant and progress messages)
    skills = []
    for e in assistant_msgs + progress_msgs:
        msg = e.get('message', {})
        content = msg.get('content', []) if isinstance(msg, dict) else []
        if isinstance(content, list):
            for c in content:
                if isinstance(c, dict) and c.get('type') == 'tool_use' and c.get('name') == 'Skill':
                    inp = c.get('input', {})
                    if isinstance(inp, dict):
                        skills.append(inp.get('skill', '?'))

    # Agent tool calls (proxy for subagents spawned via skills)
    agent_calls = 0
    for e in assistant_msgs + progress_msgs:
        msg = e.get('message', {})
        content = msg.get('content', []) if isinstance(msg, dict) else []
        if isinstance(content, list):
            for c in content:
                if isinstance(c, dict) and c.get('type') == 'tool_use' and c.get('name') == 'Agent':
                    agent_calls += 1

    # Subagent count — directory first, fall back to Agent tool call count
    subagent_dir = os.path.join(os.path.dirname(filepath), session_id, 'subagents')
    subagent_count = len([f for f in os.listdir(subagent_dir) if f.endswith('.jsonl')]) if os.path.isdir(subagent_dir) else agent_calls

    # Token estimate (rough: count text characters in assistant responses)
    assistant_chars = 0
    for e in assistant_msgs:
        msg = e.get('message', {})
        content = msg.get('content', []) if isinstance(msg, dict) else []
        if isinstance(content, list):
            for c in content:
                if isinstance(c, dict):
                    assistant_chars += len(str(c.get('text', '')))
    est_output_tokens = assistant_chars // 4  # rough estimate

    # User turns (actual messages, not system)
    user_turns = len(user_msgs)

    # Git branch
    branches = set()
    for e in entries:
        b = e.get('gitBranch')
        if b:
            branches.add(b)

    # Print session summary
    print(f"--- {session_id[:8]}... | {start_str} | {active_duration_min:.0f}min active / {wall_duration_min:.0f}min wall ---")
    print(f"  Turns: {user_turns} user / {len(assistant_msgs)} assistant")
    print(f"  Tools: {total_tools} calls — {', '.join(f'{n}:{c}' for n,c in tool_counts.most_common(5))}")
    print(f"  Skills: {', '.join(skills) if skills else 'none'}")
    print(f"  Models: {', '.join(f'{m}:{c}' for m,c in models.most_common())}")
    print(f"  Subagents: {subagent_count}")
    print(f"  Est. output: ~{est_output_tokens:,} tokens")
    print(f"  Branch: {', '.join(branches) if branches else '?'}")
    print()

PYEOF

done

echo "SESSION_EXTRACT_END"
