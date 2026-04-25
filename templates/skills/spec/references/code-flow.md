# Code-Flow Analysis Reference

For each function the spec will modify or call (max 5), trace:

1. **Who calls it** — what guards/conditions gate execution
2. **What state it sets** — variables, side effects, file writes
3. **Error paths** — what fails silently vs. loudly

Present as a numbered list before writing steps:

```
1. fn_name() in path/to/file.sh:NN
   - Called by: main(), update_flow()
   - Guards: [ -f .ai-setup.json ] || return 0
   - Sets: TEMPLATE_MAP, UPD_CHANGED
   - Error paths: silently skips if file missing (no exit 1)
```

**Step dedup rule**: If existing code already does a step → remove it. If a guard blocks the new flow → that guard-removal IS a step. If an error path is unhandled → add explicit step.

Scope boundary: once defined, the spec boundary is FIXED. New capabilities discovered during code-flow → note as follow-up spec, do NOT expand.
