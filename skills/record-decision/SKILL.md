---
name: record-decision
description: Record an owner decision or a proposed decision - as a Backlog.md decision by default, or an ADR file when the project keeps docs/adr - and link it from the tasks it affects. Use when the owner chooses between options, or when a hard-to-reverse choice must be written down.
metadata:
  owner: gautamr
  layer: personal
  version: "1.0.0"
  reviewed: "2026-11-21"
---

# Record a decision

1. **Status**: `accepted` only if the owner stated the decision in this session; otherwise
   `proposed`, and label the related task for the owner (delivery-protocol §5).
2. **Where**:
   - Default: `backlog decision create "<the decision stated as one sentence>" -s <status>`.
     The title carries the decision, so write it as the rule ("Sprints are labels, milestones
     stay the roadmap"), not the topic.
   - If the profile says the project keeps ADRs, or the decision is architectural and
     `docs/adr/` exists: create `docs/adr/NNNN-<slug>.md` numbered after the highest existing
     one, from the template in the delivery-protocol skill's `references/formats.md`.
3. **Link**: comment on each affected task with the decision ID; remove the owner label if the
   decision resolves it.
4. **Supersede, never rewrite**: a changed decision gets a new record that names the one it
   supersedes; edit the old one's status only.
