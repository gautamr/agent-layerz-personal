---
name: board-conventions
description: How every session uses a Backlog.md board - status meanings, the claim rule, one project per repository, milestones versus sprint labels, label families, the shape of a good task, the lifecycle from claim to review, the definition of done, and exact backlog commands, including from a sibling repository of a hub. Use before creating, claiming, planning, updating, reviewing or finishing a task, and before filing a bug. Project-specific values (projects, milestones, labels) come from the client or repository profile.
metadata:
  owner: gautamr
  layer: personal
  version: "1.0.0"
  reviewed: "2026-11-21"
---

# Board conventions

Work is tracked on a Backlog.md board. A task that is not on the board does not exist; work
that is not linked to a task is not done.

## 0. Profiles

The client layer or repository supplies the concrete values: where the board is, its projects,
milestones and labels. Look for, in order: a client-layer board skill (for example
`<client>-board`), `docs/standards/delivery.md` in the hub, then in the repository. Where a
profile and this skill disagree, the profile wins where it says so.

## 1. Reaching the board

| Board lives in | Session started in | Command form |
| --- | --- | --- |
| this repository | this repository | `backlog <command>` |
| a client hub | the hub | `backlog <command>` |
| a client hub | a sibling repository | `BACKLOG_CWD=../<hub> backlog <command>` |

- Run `backlog instructions overview` once per conversation, and the matching guide before a
  lifecycle step: `task-creation`, `task-execution`, `task-finalization`.
- Use the CLI or the Backlog MCP server. **Never edit files under `backlog/` by hand.** The board
  configuration (`backlog/config.yml`) changes only through a task, by the owner or the
  engineering manager.
- Add `--plain` when you read output yourself.

## 2. Fields

### Statuses (default set)

| Status | Meaning | Who moves a task here |
| --- | --- | --- |
| `Triage` | Reported, not yet accepted: new bugs, ideas, unsized requests | anyone |
| `To Do` | Accepted, sized, has acceptance criteria | the engineering manager or the owner |
| `In Progress` | Claimed by exactly one assignee who is working on it | the assignee, when claiming |
| `In Review` | Finished, evidence recorded, waiting for review or the owner | the assignee |
| `Done` | Every criterion checked, review passed, summary written | the reviewer or the owner |

A task that will not be done is archived (`backlog task archive <id>`) after a comment saying
why. It never moves to `Done`.

### Projects, milestones, sprints

- **Project** = the repository whose files the work changes. Exactly one per task. Work across
  repositories is a parent task in the hub with one subtask per repository (`-p <parent>`).
- **Milestone** = the roadmap step the task serves. Every task has one.
- **Sprint** = a label `sprint:N`, never a milestone, so milestones stay the roadmap. Only the
  engineering manager sets sprint labels.

### Types and labels

- Types: `feature` (new behaviour), `bug` (behaviour contradicts a contract), `task` (other
  engineering work), `chore` (upkeep, no behaviour change), `docs`, `spike` (time-boxed
  investigation ending in notes or a decision, not production code).
- Label families: `area:<surface>`, `severity:S1`-`S3` (bugs only), `owner:human` (only the
  owner can do it; agents never claim it), `needs:owner-approval` (the plan waits for the
  owner), `sprint:N`, `discovered` (found while doing another task).

### Priority and assignee

- `High`: blocks other work or the sprint goal. `Medium`: this or the next sprint. `Low`: later.
- Assignees are agent names (`@architect`, `@backend-engineer`, …) or the owner's handle.
  Assign only an agent that exists in the session that will run the task.

## 3. A good task

- **Title**: the outcome, imperative, under 80 characters.
- **Description**: why it matters, what is out of scope, and the IDs and documents it relies on
  (`--ref`, `--doc`).
- **Acceptance criteria**: each observable and checkable by someone else, phrased as a result
  with how to check it: "GET /v1/items returns `title` (route test)". One behaviour each; no
  "works well".
- **Dependencies** with `--dep`, never a sentence.
- Never put secrets, tokens or personal data in a task.

## 4. Lifecycle

1. **Pick**: a `To Do` task in your project, dependencies `Done`, no `owner:human`, earliest
   sprint, highest priority (`backlog task list --status "To Do" --project <repo> --ready --plain`).
2. **Claim before work**: `backlog task edit <id> -s "In Progress" -a @<you>`. Backlog.md has
   no locking; a task already `In Progress` with another assignee is not yours.
3. **Plan**: `--plan` with files to change, the check that proves each criterion, and risks.
   With `needs:owner-approval`, stop here until the owner approves in a comment.
4. **Work** in the task's repository only; `--append-notes` as you go.
5. **Evidence**: `--check-ac <n>` only after running the check; the command and result go in
   the notes.
6. **Hand over**: `-s "In Review" --final-summary "..."`: what changed, checks run with
   results, what is left open.
7. **Close**: the reviewer or the owner moves it to `Done`. New work found → a new task.

## 5. Definition of done

- Every acceptance criterion checked, with evidence in the notes.
- The change stays inside the task's project repository.
- If agent layers changed: `alz build` ran and `alz check` passes in each affected repository.
- A fresh-context review happened (a reviewer agent or the owner).
- Commits use Conventional Commits with the task ID, under the identity in the Commits rule.

## 6. Commands

```bash
backlog task create "Title" -d "Why and scope" --project <repo> -m "<milestone>" \
  --type feature -l area:api --priority Medium --ac "Observable result (check)" --ref <doc>
backlog task create "Subtask" -p <parent-id> --project <repo> -m "<milestone>" --type task
backlog task list --project <repo> --status "To Do" --ready --plain
backlog task view <id> --plain
backlog task edit <id> -s "In Progress" -a @<you>
backlog task edit <id> --plan "..."
backlog task edit <id> --append-notes "..."
backlog task edit <id> --check-ac 1
backlog task edit <id> -s "In Review" --final-summary "..."
backlog task edit <id> --comment "..." --comment-author @<you>
backlog search "<words>" --plain
backlog task archive <id>
```

Run `backlog <command> --help` before any command not listed here.
