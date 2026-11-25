---
description: Start a feature slice from spec to ready-to-build tasks.
argument_hint: "<NNN-slug>"
---
Start slice $ARGUMENTS.

1. Create `specs/$ARGUMENTS/` with spec.md, plan.md, review.md and NOTES.md from the slice
   templates in the delivery-protocol skill (references/formats.md).
2. Interview the owner with multiple-choice questions, a few at a time, and have the
   domain-expert write spec.md: stories, Given/When/Then criteria, business rules, out of scope,
   design links, open questions.
3. Have domain-review check spec.md in a fresh context. Resolve gaps with the owner.
4. Have the architect write plan.md and create the slice's board tasks, labelled
   `slice:$ARGUMENTS`.
5. Have the qa-engineer write failing end-to-end tests for every criterion.
6. Report: spec summary, plan, open questions, ready tasks. `needs:owner-approval` tasks wait.
