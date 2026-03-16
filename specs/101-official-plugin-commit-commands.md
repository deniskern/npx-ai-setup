# Spec: Add commit-commands to Official Plugins

> **Spec ID**: 101 | **Created**: 2026-03-16 | **Status**: draft | **Branch**: —

## Goal
Add the official `commit-commands` plugin to the auto-install list so projects get `/commit`, `/commit-push-pr`, and `/clean_gone` out of the box.

## Context
`install_official_plugins()` in `lib/plugins.sh` already installs `code-review`, `feature-dev`, and `frontend-design`. The `commit-commands` plugin (from `anthropics/claude-plugins-official`) provides git workflow slash commands that complement the existing setup. It is not installed today.

## Steps
- [ ] Step 1: In `lib/plugins.sh` `OFFICIAL_PLUGINS` array, add `"commit-commands:Git workflow slash commands (/commit, /commit-push-pr, /clean_gone)"`

## Acceptance Criteria
- [ ] `commit-commands` appears in the `OFFICIAL_PLUGINS` array in `lib/plugins.sh`
- [ ] Setup run attempts to install the plugin (or shows manual install hint)
- [ ] Existing plugins (code-review, feature-dev, frontend-design) are unaffected

## Files to Modify
- `lib/plugins.sh` — add entry to `OFFICIAL_PLUGINS` array

## Out of Scope
- Custom commit message templates
- Changes to git hook behaviour
