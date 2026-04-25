---
name: agent-browser
model: haiku
description: "Browser automation for visual verification. **MANDATORY for frontend changes** — after editing Vue/React components, Liquid templates, CSS, or layouts: open dev server, screenshot, verify rendering before declaring done. Also: form testing, scraping, page interaction. Prefer over WebFetch when JS rendering or interaction needed. Triggers: 'check the page', 'take screenshot', 'fill form', 'verify component', 'test web app', after any *.vue/*.tsx/*.liquid/*.css edit."
allowed-tools: Bash(npx agent-browser:*), Bash(agent-browser:*)
---

# Browser Automation with agent-browser

Install: `npm i -g agent-browser` or `brew install agent-browser`. Run `agent-browser install` to download Chrome.

## Core Workflow

```bash
agent-browser open https://example.com
agent-browser snapshot -i                  # get @refs: @e1 [input], @e2 [button]
agent-browser fill @e1 "user@example.com"
agent-browser click @e2
agent-browser wait --load networkidle
agent-browser snapshot -i                  # re-snapshot after navigation
```

Chain with `&&` when you don't need intermediate output. Run separately when parsing refs first.

## Essential Commands

```bash
# Navigation
agent-browser open <url>
agent-browser close

# Snapshot
agent-browser snapshot -i                  # interactive elements with refs (default)
agent-browser snapshot -i -C              # include cursor-interactive divs
agent-browser snapshot -s "#selector"     # scope to CSS selector

# Interact (use @refs from snapshot)
agent-browser click @e1
agent-browser fill @e1 "text"             # clear + type
agent-browser type @e1 "text"             # type without clearing
agent-browser select @e1 "option"
agent-browser check @e1
agent-browser press Enter
agent-browser scroll down 500

# Wait
agent-browser wait @e1                    # wait for element
agent-browser wait --load networkidle
agent-browser wait --text "Welcome"
agent-browser wait 2000

# Get
agent-browser get url
agent-browser get text @e1

# Capture
agent-browser screenshot
agent-browser screenshot --full
agent-browser pdf output.pdf
```

## Common Patterns

**Auth — use existing browser session:**
```bash
agent-browser --auto-connect state save ./auth.json
agent-browser --state ./auth.json open https://app.example.com
```

**Auth — persistent profile:**
```bash
agent-browser --profile ~/.myapp open https://app.example.com
```

**Data extraction:**
```bash
agent-browser open https://example.com
agent-browser snapshot -i
agent-browser get text @e1
```

For full reference: `agent-browser --help` or `agent-browser <command> --help`.
