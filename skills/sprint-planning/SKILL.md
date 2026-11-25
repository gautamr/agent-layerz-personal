---
name: sprint-planning
description: Plan, get approval for, run and close a sprint on a Backlog.md board that has no sprint feature - goal, capacity, selection by milestone and dependency, balance across repositories, owner gates, sprint:N labels, and the closing review. Use when the engineering manager plans or closes a sprint, or someone asks what the sprint should contain. Not for routing one task (task-routing) or bug severity (bug-triage).
metadata:
  owner: gautamr
  layer: personal
  version: "1.0.0"
  reviewed: "2026-11-21"
---

# Sprint planning

Backlog.md has no sprints, points or velocity. A sprint is a **label** (`sprint:N`) on its
tasks plus a board doc stating its goal. Milestones stay the roadmap.

## 1. Policy defaults

A profile may set these; until it does, propose values and ask the owner.

| Setting | Default |
| --- | --- |
| Length | One week |
| Capacity | At most 3 implementation tasks per repository with an active session, plus their reviews |
| Milestone order | Enablers that unblock other work first, then the earliest product milestone |
| Owner time | Counted separately: the owner is one person |

Record the owner's answers as a board decision.

## 2. Plan

1. **Close the last sprint first** (§4) so carry-over is known.
2. **Candidates**: ready tasks (task-routing §1), earliest milestone first, then priority, then
   tasks that unblock the most dependents (`backlog task list --ready --plain`).
3. **Goal**: one sentence anyone can check at the end. Choose tasks that serve it.
4. **Dependencies**: include a task only if its dependencies are `Done` or earlier in this
   sprint. Order producers before consumers.
5. **Balance**: spread work across repositories so sessions can run in parallel; never two tasks
   in one repository that touch the same files.
6. **Owner gates**: list every `owner:human` and `needs:owner-approval` task the sprint needs,
   with the decision each asks for. A goal that depends on an unanswered owner question is not
   ready.
7. **Bugs**: S1 joins the current sprint at once; S2 this or the next (bug-triage).
8. **Propose** to the owner: goal, ordered tasks (ID, title, project, role), capacity used,
   owner decisions needed, and what was left out and why.

## 3. After approval

1. `backlog task edit <id> --add-label sprint:N` for each task.
2. Route each one in plan order (task-routing §3).
3. Record the plan: `backlog doc create "Sprint N"` (see `backlog doc --help` for content) with
   the goal, tasks and owner decisions.

## 4. Close

1. Each `sprint:N` task: `Done`, carried over (add `sprint:N+1`, comment why), or back to
   `To Do` without a sprint label.
2. Goal met or not, with evidence.
3. Run the retrospective skill with the owner.
4. Append the result to the sprint doc.

## 5. Never

- Add work to a running sprint without the owner, except S1 bugs.
- Count work as done because a session said so: `Done` needs the definition of done.
- Use milestones as sprints, or a sprint label as a milestone.
