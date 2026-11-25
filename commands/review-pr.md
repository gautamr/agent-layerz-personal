---
description: Run the independent reviews for this repository's current branch against its task and prepare the pull request summary.
argument_hint: "<task-id>"
---
Review the current branch against task $ARGUMENTS.

1. Confirm the repository's full check passes (the command AGENTS.md names).
2. Read the task's acceptance criteria from the board, and the spec it links to, if any.
3. Run reviewers in fresh contexts with the diff (`git diff <main>...HEAD`): architect-review
   always; domain-review when business rules changed; design-review when UI changed (with
   screenshots); security-reviewer when auth, tokens, payments, personal data, uploads,
   webhooks, dependencies or MCP servers changed.
4. BLOCKERs go back to the task's assignee; SHOULD and NOTE become follow-up tasks for this
   repository.
5. With no BLOCKERs left, write the pull request summary: task ID, what changed, how it was
   verified, findings and their status. Opening or merging the pull request is the owner's call.
