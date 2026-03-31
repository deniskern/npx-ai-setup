# Code Review Reception

## Source-Specific Handling

- **User feedback**: Trusted — implement after understanding. Ask if scope is unclear.
- **External reviewers**: Verify technical correctness and alignment with prior decisions before implementing. Don't blindly apply changes that conflict with existing design choices.
- **Review agents**: Fix mandatory findings immediately; implement suggestions if straightforward.

## Review Process

1. Read all feedback completely before reacting.
2. Restate the requirement to confirm understanding.
3. Verify the issue against the actual current codebase — don't fix what isn't broken.
4. Evaluate technical soundness and impact.
5. Implement one change at a time with testing after each.

## YAGNI Check

When reviewers suggest new or enhanced features: search for actual usage in the codebase first.
Unused code = push back with a removal suggestion. Used code = implement properly.

## Communication

No effusive language ("absolutely right", "great point"). Report technical requirements and actionable work only.
