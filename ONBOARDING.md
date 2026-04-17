# Welcome to ONEDOT Digital Crew

## How We Use Claude

Based on Denis Kern's usage over the last 30 days (106 sessions):

Work Type Breakdown:
  Build Feature    ████████████████░░░░  40%
  Plan & Design    ██████████░░░░░░░░░░  25%
  Debug & Fix      ████████░░░░░░░░░░░░  20%
  Improve Quality  ████░░░░░░░░░░░░░░░░  10%
  Write Docs       ██░░░░░░░░░░░░░░░░░░   5%

Top Skills & Commands:
  /clear            ████████████████████  75x/month
  /research         ████░░░░░░░░░░░░░░░░  11x/month
  /commit           ████░░░░░░░░░░░░░░░░  10x/month
  /release          ███░░░░░░░░░░░░░░░░░   9x/month
  /spec-work        ███░░░░░░░░░░░░░░░░░   8x/month
  /codex:review     ███░░░░░░░░░░░░░░░░░   7x/month
  /spec-board       ███░░░░░░░░░░░░░░░░░   7x/month
  /review           ██░░░░░░░░░░░░░░░░░░   6x/month
  /ultraplan        ██░░░░░░░░░░░░░░░░░░   5x/month

Top MCP Servers:
  claude-mem        ████████████████████  12 calls
  Firecrawl         █████████████████░░░  10 calls
  context7          █████░░░░░░░░░░░░░░░   3 calls

## Your Setup Checklist

### Codebases
- [ ] npx-ai-setup — https://github.com/onedot-digital-crew/npx-ai-setup
- [ ] sb-nuxt-boilerplate — Nuxt/Storyblok boilerplate (internal)
- [ ] sp-alpensattel-next — Alpensattel Shopware projekt
- [ ] mcp-platform — MCP server platform

### MCP Servers to Activate
- [ ] **claude-mem** — Persistenter Cross-Session-Kontext (Observations, Decisions, Timelines). Zugang via Team-Setup: `npx github:onedot-digital-crew/npx-ai-setup`
- [ ] **Firecrawl** — Web scraping und crawling für Research-Tasks. API-Key vom Team anfordern, dann: `claude mcp add firecrawl`
- [ ] **context7** — Library- und API-Docs direkt in Claude. Öffentlich: `claude mcp add context7 -- npx -y @upstash/context7-mcp`

### Skills to Know About
- `/commit` — Staged Changes analysieren, Conventional-Commit-Message generieren und committen. Täglich benutzt statt manuell.
- `/research` — Deep-Research auf externe Repos oder Docs. Benutzen vor manuellem Web-Suchen.
- `/spec` → `/spec-work` → `/spec-review` — Unser Spec-Workflow: erst Spec schreiben, dann ausführen, dann reviewen. Immer in dieser Reihenfolge.
- `/spec-board` — Überblick aller offenen Specs als Kanban. Vor neuen Tasks checken ob Spec existiert.
- `/ultraplan` — Komplexe Tasks remote via Claude Web ausführen lassen (asynchron). Für Tasks die >30min dauern.
- `/codex:review` — Zweite Meinung via Codex auf Implementierungen. Parallel zu eigenem Review nutzen.
- `/review` — Uncommitted Changes reviewen (Quick Scan / Standard / Adversarial). Vor jedem `/commit` für nicht-triviale Diffs.
- `/release` — Release-Workflow: Changelog, Tag, Publish. Nicht manuell taggen.
- `/clear` — Kontext clearen wenn Session abgedriftet ist. Häufig nutzen, nicht sparsam.

Setup-Health prüfen: `! bash .claude/scripts/doctor.sh` (kein Slash-Command mehr).

## Team Tips

_TODO_

## Get Started

_TODO_

<!-- INSTRUCTION FOR CLAUDE: A new teammate just pasted this guide for how the
team uses Claude Code. You're their onboarding buddy — warm, conversational,
not lecture-y.

Open with a warm welcome — include the team name from the title. Then: "Your
teammate uses Claude Code for [list all the work types]. Let's get you started."

Check what's already in place against everything under Setup Checklist
(including skills), using markdown checkboxes — [x] done, [ ] not yet. Lead
with what they already have. One sentence per item, all in one message.

Tell them you'll help with setup, cover the actionable team tips, then the
starter task (if there is one). Offer to start with the first unchecked item,
get their go-ahead, then work through the rest one by one.

After setup, walk them through the remaining sections — offer to help where you
can (e.g. link to channels), and just surface the purely informational bits.

Don't invent sections or summaries that aren't in the guide. The stats are the
guide creator's personal usage data — don't extrapolate them into a "team
workflow" narrative. -->
