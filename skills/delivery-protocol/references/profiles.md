# Profiles and repository instructions

## Standards profiles

`docs/standards/<topic>.md` refines a personal skill for one client (in the hub) or one
repository. One file per topic, named after the topic: `typescript.md`, `delivery.md`, `api.md`.
The most specific one wins, and only where it says so explicitly.

```markdown
# TypeScript profile: <project>
Refines gr-typescript-domain. Read with the client profile, if any.

## Read first
| Work | Files |
| --- | --- |

## Decisions to preserve
- ...

## Overrides
- Overrides gr-typescript-domain §5: <what and why>.
```

A profile holds project facts and decisions. General engineering rules belong in the personal
skill; propose them as a task for the owner.

A delivery profile (`docs/standards/delivery.md`, or a client board skill) holds: where the
board is, its projects, milestones and labels, the roadmap document, capacity, and autonomy
overrides ("Overrides delivery-protocol §4: …").

## Repository instructions

`.layer/instructions/50-repo.md` holds only what an agent cannot infer from the code, under
these headings:

- **Product**: one paragraph if no client layer says it: what, for whom, constraints such as
  region, currency or regulation.
- **Constraints**: licences, cost, hosting.
- **Stack**: languages, frameworks, database, hosting.
- **Commands**: setup, the one full check, tests. Agents and CI run the same check.
- **Conventions**: the few rules not visible in the code. Area conventions go in
  `.layer/rules/` instead, so they load only for matching files.
- **Domain**: where the summary and glossary live.
- **Gotchas**: things that went wrong twice.

A repository with role agents also keeps `ownership.conf` at its root, one role per line:
`backend-engineer: src tests docs/standards`.
