---
name: task-routing
description: Decide whether a task is ready, which role agent or person takes it, which repository session runs it, and write the handoff that lets that session start without questions; split cross-repository work producer-first. Use when the engineering manager assigns work, answers "what next", or a lead delegates. Not for writing a task (board-conventions) or ordering a sprint (sprint-planning).
metadata:
  owner: gautamr
  layer: personal
  version: "1.0.0"
  reviewed: "2026-11-21"
---

# Task routing

Routing answers three questions for one task: **is it ready, who takes it, where does it run.**
The answer is written into the task, so the board carries the handoff, not a chat.

A client or repository profile may add a routing table (repositories, areas, extra roles).
Where it does, it wins.

## 1. Readiness

| Check | If it fails |
| --- | --- |
| Status `To Do` | `Triage` items go through bug-triage or shaping first |
| Exactly one project, and the work changes only that repository | Split under a hub parent, one subtask per repository |
| Milestone set | Set it |
| Acceptance criteria observable, each with a way to check it | Rewrite; ask the owner if the intent is unclear |
| Every dependency `Done` | Route the dependency instead |
| No unanswered owner question behind a criterion | Create an `owner:human` task for the question and depend on it |
| Not `owner:human` | Route to the owner with exactly what to do and where |
| `needs:owner-approval` approved in a comment | Wait; list it in the owner decisions |

A task without a plan can still be ready: planning is the assignee's first step, unless the
change is large (below).

## 2. Who takes it

| Task | Role |
| --- | --- |
| Large or unclear: new bounded context, new public contract, cross-repository slice, schema change on a populated table | `architect` (plan only), with `domain-expert` when business rules are unsettled |
| Business rules, glossary, invariants, owner interviews | `domain-expert` |
| Brand, tokens, component specs, screens, copy | `designer` (copy-heavy pages: `content-writer`) |
| Planned server-side code, tests, migrations | `backend-engineer` |
| Planned client code, components | `frontend-engineer` |
| Failing end-to-end tests from criteria, test data, preview testing | `qa-engineer` |
| Containers, CI, deployment configuration, environments, runbooks | `platform-engineer` |
| Agent layers: agents, skills, rules, hooks | the engineer of that repository, labelled `area:agents` |
| Review after build | `architect-review` always; `domain-review` when business rules changed; `design-review` when UI changed; `security-reviewer` when auth, payments, personal data, uploads, webhooks, dependencies, MCP servers or plugins changed |
| Console access, credentials, product answers, approvals | the owner |
| Board, sprints, triage | `engineering-manager` |

Rules:
- One assignee at a time. The builder and the reviewer are never the same session.
- Security-relevant work always gets `security-reviewer`, whatever its size.
- A task runs in the session of its project's repository, never in another repository.
- If a role's agent does not exist in that repository yet, route to the role anyway and say in
  the handoff that the ordinary session acts as that role.

## 3. Assign and hand over

1. `backlog task edit <id> -a @<role>`; keep the status `To Do`; the assignee claims it.
2. Append the handoff with `--append-notes`:

```text
Handoff (engineering-manager, YYYY-MM-DD)
- Run in: <repository> session (cd ../<repository> && claude)
- Agent: <role>
- Start with: "Work on <id>"
- Read first: <documents and sections>
- Allowed to edit: <the role's paths in this repository>
- Done means: criteria 1..n checked with evidence, then In Review
- Watch out: <risks, invariants by ID, open questions not to answer>
```

3. Tell the owner which sessions to open for which tasks, in priority order.

## 4. Cross-repository work

- A hub parent states the end-to-end outcome; one subtask per repository.
- Order with `--dep` from producer to consumer: the repository that owns a contract changes it
  first, and that subtask is `Done` and reviewed before any consumer starts.
- The parent is `Done` only when every subtask is `Done` and its own end-to-end criteria are
  checked.

## 5. Stale and stuck work

- `In Progress` with no new notes for two days: ask for status, or return it to `To Do` with a
  comment.
- `In Review` for two days: route the review explicitly.
- Bounced back twice: it was not ready; reshape it with the architect.
