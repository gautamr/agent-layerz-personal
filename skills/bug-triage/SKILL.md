---
name: bug-triage
description: Triage bugs and other Triage items on a Backlog.md board - gather evidence, find duplicates, set severity S1-S3 by harm (security, privacy, data loss, safety, money), set project, milestone and priority, and accept, reshape or archive with a reason; also how anyone files a bug. Use when the engineering manager runs triage or someone reports a defect. A client profile may add domain-specific severity examples.
metadata:
  owner: gautamr
  layer: personal
  version: "1.0.0"
  reviewed: "2026-11-21"
---

# Bug triage

A bug is behaviour that contradicts a contract: an acceptance criterion, an invariant, the API
specification, or the approved design for UI. A missing feature is not a bug; neither is an
unanswered product question (that is an `owner:human` task).

## 1. Severity

Severity is harm, not effort. When two levels fit, take the higher one. A client profile adds
examples in its own domain language; these are the defaults.

| Severity | Meaning | Examples |
| --- | --- | --- |
| `severity:S1` critical | Security or privacy breach, data loss, physical safety, money | Another user's data readable; a secret or token in a log or response; personal data kept that must be stripped; a lost write on retry; a payment amount set by the client |
| `severity:S2` major | A core flow broken with no workaround, or wrong numbers presented as fact | Sign-in, checkout or the main user flow fails; a metric computed with the wrong definition |
| `severity:S3` minor | A workaround exists, or cosmetic | Copy mismatch, layout issue, slow but working endpoint |

An S1 touching security or privacy also gets `area:security` or `area:privacy`, and its fix
always gets the security review.

## 2. Procedure, per Triage item

1. **Read**: `backlog task view <id> --plain`.
2. **Duplicates**: `backlog search "<key words>" --plain`. If it duplicates an open task,
   comment on the original with the new evidence and the duplicate's ID, then archive this one.
3. **Evidence**: steps, expected result (with the contract it comes from), actual result. If
   missing, ask the reporter in a comment and leave it in `Triage`. Reproduce only with local,
   read-only checks; never against production.
4. **Classify**: type `bug` (or reshape into `feature`/`task`), project, milestone, severity,
   area labels.
5. **Priority**: S1 → `High`; S2 → `High` or `Medium`; S3 → `Medium` or `Low`.
6. **Decide**:
   - Accept: add the criterion "a regression test fails before the fix and passes after", set
     `To Do`. S1 also joins the current sprint now and the owner is told immediately.
   - Not a bug: reshape it, or archive it after a comment with the reason.
   - Needs a product answer: create an `owner:human` task for the question and make the bug
     depend on it.

## 3. Definition of done for a fix

- A regression test named after the guarantee it protects fails before the change and passes
  after.
- The fix, the task ID in the commit, and a fresh-context review (security review for S1).
- For a security or privacy S1: the notes say whether stored data is affected, and a follow-up
  task exists for any clean-up.

## 4. Filing a bug (any session)

```bash
backlog task create "Short statement of the wrong behaviour" --type bug -s Triage \
  --project <repo> -m "<milestone>" -d "Steps: ... Expected (per <contract>): ... Actual: ..."
```

From a sibling repository of a hub, prefix `BACKLOG_CWD=../<hub>`. Leave severity to triage
unless it is clearly S1; then add the label and tell the owner.
