---
description: Run the independent reviews for a finished task or slice and prepare the pull request summary.
argument_hint: "<task-id | NNN-slug>"
---
Review $ARGUMENTS.

1. Confirm the full check and end-to-end tests pass. If not, send the failing task back to
   `In Progress` with a comment.
2. Run reviewers in fresh contexts with the criteria, spec.md, plan.md and the diff:
   architect-review always; domain-review when business rules changed; design-review when UI
   changed (with screenshots); security-reviewer when auth, tokens, payments, personal data,
   uploads, webhooks, dependencies, MCP servers or plugins changed.
3. Write findings to the slice's review.md (or the task notes). BLOCKERs go back to their
   owners; SHOULD and NOTE become follow-up tasks.
4. With no BLOCKERs left: the pull request summary (what changed, how it was verified, findings
   and their status, screenshots), and move the tasks to `Done`.
5. Ask each agent that worked on it to record its lessons in its memory.
