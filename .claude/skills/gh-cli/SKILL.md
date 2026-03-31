---
name: gh-cli
description: "GitHub CLI (gh) comprehensive reference for repositories, issues, pull requests, Actions, projects, releases, gists, codespaces, organizations, extensions, and all GitHub operations from the command line."
---

# GitHub CLI (gh)

> Core commands reference (v2.85.0). For advanced options, flags, and edge cases: read `references/full.md`.

## Auth

```
gh auth login                                    # interactive login
gh auth login --with-token < token.txt          # token from file
gh auth logout
gh auth status [--show-token]
gh auth token                                    # print active token
gh auth switch --hostname github.com --user <u>
```

## Repo

```
gh repo clone <owner>/<repo>
gh repo create <name> [--public|--private] [--clone]
gh repo fork <owner>/<repo> [--clone]
gh repo view [--web]
gh repo list [<owner>] [--limit 30]
gh repo set-default <owner>/<repo>
```

## Pull Requests

```
gh pr create --title "..." --body "..." [--base main] [--draft]
gh pr list [--state open|closed|merged] [--author @me]
gh pr view <number> [--web]
gh pr checkout <number>
gh pr merge <number> [--squash|--merge|--rebase] [--auto] [--delete-branch]
gh pr review <number> [--approve|--request-changes|--comment] [-b "body"]
gh pr checks <number>
gh pr diff <number>
gh pr edit <number> [--title "..."] [--body "..."] [--add-label bug]
gh pr close <number>
gh pr reopen <number>
gh pr ready <number>                             # mark as ready for review
gh pr update-branch <number>                     # update from base branch
```

## Issues

```
gh issue create --title "..." --body "..." [--label bug] [--assignee @me]
gh issue list [--state open|closed] [--assignee @me] [--label bug]
gh issue view <number> [--web]
gh issue close <number>
gh issue reopen <number>
gh issue edit <number> [--title "..."] [--add-label ...]
gh issue comment <number> --body "..."
```

## Workflow Runs (CI/CD)

```
gh run list [--workflow <name>] [--branch main] [--limit 10]
gh run view <run-id> [--log]
gh run watch <run-id>
gh run rerun <run-id> [--failed-only]
gh run cancel <run-id>
gh workflow list
gh workflow run <workflow-name> [--ref main]
```

## Releases

```
gh release create <tag> [files...] --title "..." --notes "..."
gh release list
gh release view <tag>
gh release edit <tag> [--draft] [--prerelease]
gh release download <tag> [--pattern "*.zip"]
```

## Search

```
gh search repos <query> [--language go] [--stars ">100"]
gh search issues <query> [--repo owner/repo]
gh search prs <query>
```

## Misc

```
gh status                                        # activity overview
gh browse [<path>] [--branch main]              # open in browser
gh api <endpoint> [--method POST] [-f key=val]  # raw API calls
gh secret set <name>                            # set Actions secret
gh secret list
gh label list
gh label create <name> --color RRGGBB
```

## Output & Scripting

```
# JSON output + jq filter (available on most commands)
gh pr list --json number,title,state --jq '.[] | select(.state=="OPEN")'

# Global flags
--repo owner/repo    # target specific repo
--json <fields>      # machine-readable output
--jq <expr>          # filter JSON with jq
--template <tmpl>    # Go template output
-R / --repo          # shorthand for --repo
```

---

> Full reference with all subcommands, flags, and examples: `references/full.md`
