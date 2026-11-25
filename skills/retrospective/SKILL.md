---
name: retrospective
description: Run a sprint or weekly retrospective from board evidence - tasks done, first-time pass rate, rework, review blockers, unnecessary escalations - and turn every repeated correction into a task against the narrowest layer it belongs to (repository, client or personal). Use at the end of a sprint, once a week, or when the owner asks how the agents are doing.
metadata:
  owner: gautamr
  layer: personal
  version: "1.0.0"
  reviewed: "2026-11-21"
---

# Retrospective

Improve the setup from evidence, not impressions, and change it only through tasks the owner
approves.

## 1. Gather

From the board for the period (`backlog task list --plain`, task notes, review findings in
`specs/*/review.md`):

| Signal | How |
| --- | --- |
| Tasks done | `Done` in the period |
| First-time pass rate | Tasks that passed review without going back to `In Progress` |
| Rework rounds | Times a task went back from `In Review` |
| Review blockers | `BLOCKER` findings, and any that reached the owner after review |
| Escalations | Owner-labelled tasks, and how many the owner thought were needed |
| Stuck work | `In Progress` or `In Review` longer than two days |
| Tokens and cost | `npx -y ccusage@latest daily` (Claude Code) and `npx -y @ccusage/codex@latest daily` (Codex): local logs, open source; flag tasks far above the median |

## 2. Find repeated corrections

Anything corrected twice is a missing rule. For each, decide the narrowest place it belongs:

| It applies to | Put it in |
| --- | --- |
| One area of one repository | A path rule in that repository's `.layer/rules/` |
| One repository | That repository's `.layer/instructions/` or a repository profile |
| Every repository of a client | The client layer, or the client profile in the hub |
| Every project | The personal layer, through the owner only |
| A check a tool can enforce | A hook, a lint rule or a test, rather than prose |

## 3. Propose, don't edit

- Write each proposal as a task labelled `area:agents` and `needs:owner-approval`, naming the
  layer and the exact text or check to add. Never edit the layers yourself in a retrospective.
- Propose removing rules, skills and hooks that never fired or no longer help.

## 4. Record

Append a dated summary to the sprint doc (or `backlog doc create "Retrospective YYYY-MM-DD"`):
the signals, what went well, what slowed work, and the proposal task IDs.
