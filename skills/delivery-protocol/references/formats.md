# Formats

## Delegation brief

From a lead (or the engineering manager's handoff) to a specialist.

```text
Task: <task ID and title>
Objective: <one sentence>
Read first: <exact file paths and sections>
Produce: <file paths and format>
Allowed to edit: <paths from the role's ownership>
Out of scope: <what not to touch>
Done when: <the acceptance criteria and checks>
Return: summary under 300 words, paths written, open questions.
```

## Review findings

```text
[BLOCKER | SHOULD | NOTE] file:line
What is wrong, in one sentence.
Why it matters: the spec line, invariant or risk.
Suggested fix, in one sentence.
```

End with a one-line verdict. Only `BLOCKER` stops a merge.

## Task

```text
Title: <verb + outcome>
Goal: <why this matters, one sentence>
Assignee: <role>
Priority: High | Medium | Low
Dependencies: <task IDs>
Labels: <per the board profile>
Acceptance criteria:
- [ ] <observable, testable result>
```

## Decision record

Use the board's decisions (`backlog decision create "<the decision, stated as a sentence>"`)
unless the profile says the project keeps ADR files in `docs/adr/`. For an ADR file:

```markdown
# NNNN Title
Status: proposed | accepted | superseded by NNNN
Date: YYYY-MM-DD
Deciders: owner, <agents>

## Context
What forces this decision, in a few sentences.

## Options considered
1. Option, with its main trade-off.

## Decision
The chosen option, in one sentence.

## Consequences
What gets easier, what gets harder, what to watch.
```

A decision is `accepted` only when the owner stated it in this session; otherwise `proposed`.

## Slice templates

A slice lives in `specs/<NNN-slug>/` with four files.

`spec.md`:

```markdown
# NNN Slice name

## Why
Who benefits and how we'll know it worked.

## User stories
- As a <user>, I want <goal> so that <benefit>.

## Acceptance criteria
- Given <state>, when <action>, then <observable result>.

## Business rules
- Rule, with its invariant name from the domain docs.

## Out of scope
-

## Designs
- Links for each screen state, including empty, loading and error.

## Open questions
-
```

`plan.md`:

```markdown
# NNN Plan
## Contract changes
## Data model and migrations (expand, migrate, contract)
## Modules and events touched
## Non-functional targets
## Risks and decisions (links)
## Test strategy
## Tasks created (board IDs)
```

`review.md`:

```markdown
# NNN Review
## Findings
| Severity | Reviewer | Location | Finding | Status |
| --- | --- | --- | --- | --- |

## Metrics
- Cycle time:
- First-time pass rate:
- Rework rounds:
- Blockers found in review:
```

`NOTES.md`, updated by agents before they stop so a fresh session can resume:

```markdown
# NNN Notes
## Decisions
## Done
## Next
```
