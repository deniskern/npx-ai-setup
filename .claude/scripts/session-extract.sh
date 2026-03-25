#!/usr/bin/env bash
# session-extract.sh — Extract metrics from Claude Code session JSONL files
# Usage: bash .claude/scripts/session-extract.sh [project-path-slug] [--last N]
#
# Examples:
#   bash .claude/scripts/session-extract.sh                    # current project, last 5 sessions
#   bash .claude/scripts/session-extract.sh --last 10          # current project, last 10
#   bash .claude/scripts/session-extract.sh -Users-deniskern-Sites-npx-ai-setup --last 3

set -euo pipefail

SLUG="${1:--Users-deniskern-Sites-npx-ai-setup}"
[[ "$SLUG" == "--last" ]] && SLUG="-Users-deniskern-Sites-npx-ai-setup" && shift
LAST="${2:-5}"
[[ "${1:-}" == "--last" ]] && LAST="${2:-5}"

SESSION_DIR="$HOME/.claude/projects/$SLUG"

if [[ ! -d "$SESSION_DIR" ]]; then
  echo "ERROR: No sessions at $SESSION_DIR"
  exit 1
fi

# Get most recent N session files (exclude subagent dirs)
SESSION_FILES=()
while IFS= read -r f; do
  SESSION_FILES+=("$f")
done < <(find "$SESSION_DIR" -maxdepth 1 -name "*.jsonl" -type f -print0 | xargs -0 ls -t | head -n "$LAST")

if [[ ${#SESSION_FILES[@]} -eq 0 ]]; then
  echo "No session files found."
  exit 0
fi

echo "SESSION_EXTRACT_START $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""
echo "=== SESSIONS (last $LAST) ==="
echo ""

python3 - "${SESSION_FILES[@]}" <<'PYEOF'
import json, sys, os
from datetime import datetime
from collections import Counter

files = sys.argv[1:]

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

    # Timestamps
    timestamps = [e.get('timestamp') for e in entries if e.get('timestamp')]
    if timestamps:
        first_ts = min(timestamps)
        last_ts = max(timestamps)
        # Parse ISO timestamps
        try:
            t1 = datetime.fromisoformat(first_ts.replace('Z', '+00:00'))
            t2 = datetime.fromisoformat(last_ts.replace('Z', '+00:00'))
            duration_min = (t2 - t1).total_seconds() / 60
            start_str = t1.strftime('%Y-%m-%d %H:%M')
        except:
            duration_min = 0
            start_str = first_ts[:16]
    else:
        duration_min = 0
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
    print(f"--- {session_id[:8]}... | {start_str} | {duration_min:.0f}min ---")
    print(f"  Turns: {user_turns} user / {len(assistant_msgs)} assistant")
    print(f"  Tools: {total_tools} calls — {', '.join(f'{n}:{c}' for n,c in tool_counts.most_common(5))}")
    print(f"  Skills: {', '.join(skills) if skills else 'none'}")
    print(f"  Models: {', '.join(f'{m}:{c}' for m,c in models.most_common())}")
    print(f"  Subagents: {subagent_count}")
    print(f"  Est. output: ~{est_output_tokens:,} tokens")
    print(f"  Branch: {', '.join(branches) if branches else '?'}")
    print()

PYEOF

echo "SESSION_EXTRACT_END"
