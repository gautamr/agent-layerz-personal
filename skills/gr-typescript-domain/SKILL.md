---
name: gr-typescript-domain
description: Design, implement, refactor and review domain-heavy TypeScript - business rules, API contracts, persistence and asynchronous workflows - using precise types, explicit effects, DDD boundaries, small cohesive modules and evidence-based tests. Use for backend services and domain logic in any TypeScript repository, and when reviewing such changes. Not for UI-only component or styling work. Never replaces a repository's established framework.
metadata:
  owner: gautamr
  layer: personal
  version: "1.1.0"
  reviewed: "2026-11-22"
---

# TypeScript domain engineering

Write software whose business rules can be understood from its vocabulary, types and
effect boundaries. Make invalid construction difficult, expected outcomes explicit
and failures observable. Optimise for the maintainer changing the next business rule,
not for the fewest characters or the most sophisticated types.

Use the useful disciplines of Haskell and ML - algebraic data types, explicit effects,
small total functions, composition - within idiomatic TypeScript. Do not recreate a
functional language, introduce an effects framework, or redesign the repository to
apply them.

## 0. Profiles override this skill

This skill holds personal defaults. Before applying it, read the profiles that refine
it. Later entries win:

1. **Client profile**: `docs/standards/typescript.md` in the client hub. Find the hub
   through the stack's workspace hub or the repository's AGENTS.md. Single-repo
   projects have none.
2. **Repository profile**: `docs/standards/typescript.md` at the repository root.
3. Any other standards file the repository's AGENTS.md or CLAUDE.md names.

Profiles label their overrides, for example "Overrides gr-typescript-domain §5".
Follow a profile where it contradicts this skill. Where executable configuration
(`tsconfig.json`, lint, test runner) contradicts any document, the configuration is
what runs: follow it and report the mismatch. When a substantial change finds no
repository profile, say in the handoff that one would help.

## 1. Establish the contract before changing code

- Identify the repository root, package manager, compiler settings, runtime and the
  actual test commands. Read the owning contract and the relevant architecture slice,
  not the whole documentation tree.
- Separate **required behaviour**, **observed implementation** and **proposed
  improvement**. Code can violate its contract; old docs can describe unbuilt plans.
  Settle disagreements against current code and tests.
- Reuse the established schemas, result types, ID constructors, policy functions,
  adapters and transaction helpers before introducing alternatives.
- Prefer one complete vertical change over a broad migration disguised as a fix.

For a substantial change, settle this design record before implementing. For a small
fix, keep the same reasoning in proportion.

| Question | Required answer |
| --- | --- |
| Business behaviour | Actor, command, preconditions, observable outcome |
| Invariants | What must stay true, and who owns each rule |
| Types | Legal inputs, legal states, expected errors, successful output |
| Trust boundaries | Where external values become validated domain values |
| Effects | Database, network, time, randomness, files, acknowledgements |
| Consistency | Atomic writes, concurrency control, retry identity, recovery |
| Evidence | Which check fails before the change and passes after |

Write a separate design document only when the decision crosses contexts, changes a
public contract, or has lasting operational consequences.

## 2. Model the business before choosing machinery

Use the domain's vocabulary in types, functions, errors and tests. Distinguish terms
whose meanings differ: an authentication session and a checkout session are not one
model because both are called "session". A bounded context owns the meaning of its
model and the translation at its boundary; it need not be a service, package or folder.
Do not infer contexts from tables.

| Concept | Use it to express |
| --- | --- |
| Entity | Identity that persists through change |
| Value object | Validated meaning and equality by value, including units |
| Aggregate | One invariant and its transactional consistency boundary |
| Domain policy | A business decision that belongs to no single entity |
| Application use case | Authorisation, orchestration, transaction, effect order |
| Port | The smallest capability the use case needs from outside |
| Adapter | Translation to a framework, SDK, protocol or store |
| Domain event | A fact that occurred, with an owned delivery contract |

An aggregate is not every table reachable by foreign key. Keep its boundary small and
reference other aggregates by identity. DDD needs neither inheritance nor a repository
interface per table; follow the existing style of classes or records with functions.

## 3. Use types to remove ambiguity

- Discriminated unions for mutually exclusive states and outcomes. Put a field on the
  state that requires it instead of adding another optional property.
- Keep orthogonal axes separate: visibility is not necessarily a lifecycle state.
- Brand IDs and units where substitution would be a real defect (`OrderId`,
  `CustomerId`, `Paise`, `EpochMillis`). Do not brand every local string.
- `readonly` fields and `ReadonlyArray` in the domain; decisions return new values.
  Readonly is neither deep immutability nor runtime freezing.
- Closed unions for stable domain choices; open dictionaries only at integration
  boundaries. Domain errors are never arbitrary strings.
- Represent presence deliberately: omitted, `undefined`, `null`, empty and zero can
  mean different things. Do not merge them with truthiness defaults.
- **Parse at trust boundaries.** HTTP bodies, environment variables, persisted JSON,
  queue messages and SDK responses are untrusted until parsed into domain values.
  A type assertion, a generic `fetch<T>` or `satisfies` validates nothing. Keep each
  brand cast inside the constructor whose checks justify it.
- Model transitions as functions from a specific input state to a result. Types
  exclude illegal calls, runtime checks enforce value rules, persistence prevents
  concurrent change: three different guarantees, each needing its own evidence.
- Handle every member of a closed union and route the remainder through a `never`
  helper. No fallback success that hides a new member.
- Keep the type machinery proportionate: inference inside implementations, explicit
  signatures at module boundaries, no type-level programs without a concrete need.
  No `any`, double assertions, `@ts-ignore`, or non-null assertions that hide an
  unhandled state. Never weaken compiler flags to make a change compile.

Worked examples, canonical identity and type-machinery limits:
[references/types.md](references/types.md).

## 4. Separate decisions from effects

Pure functions receive what a decision needs and return values. They do not read the
clock, generate IDs, read environment variables, query a database, call a provider or
log. Pass time and randomness in as values; inject effectful capabilities into the
application layer.

- Routes parse input, call the use case and map the response.
- Business policy lives in the domain or the owning feature.
- Use cases coordinate authorisation, queries, transactions and adapters.
- Adapters translate; they never change business policy silently.
- Ports are designed from the caller's need. A fake implements the same contract as
  the real adapter, failures included.
- An application layer may use an established ORM directly; do not add a repository
  layer to match a diagram. Keep that dependency out of pure policy.
- Composition roots wire validated configuration and adapters. They hold no rules.

### Prefer functional over imperative

Functional style is the default; imperative code needs a reason.

- Pure functions that take values and return values; immutable data (`readonly`, `as const`,
  new objects instead of mutation).
- Expressions over statements: `const` bound to the result of a ternary, a `switch` in a helper,
  or a lookup, rather than `let` assigned in branches.
- Pipelines over loops with accumulators: `map`, `filter`, `flatMap`, `reduce` (when it reads
  clearly), and `Result`-returning steps composed rather than nested `if`s and flags.
- Discriminated unions with exhaustive `switch` (`never` check) over class hierarchies.
- Small composed functions; higher-order functions where they name a step.
- Effects at the edges (route, use case, adapter); the domain computes.

Imperative is better when a loop performs effects (I/O must not hide inside `map` or `forEach`
callbacks), when early exit with several conditions is clearer, or when local mutation is
measurably faster and never escapes the function. Do not build an effects framework or emulate
monads to get there.

## 5. Keep files small by keeping them cohesive

These are review defaults. A repository or profile limit takes precedence.

| Unit | Preferred shape | Review trigger |
| --- | --- | --- |
| Production module | 80-200 readable lines, one responsibility | Above ~250 lines or two reasons to change |
| Business function | 10-35 lines, one decision or orchestration step | Above ~50 lines, mixed effects, deep nesting |
| Route handler | Parse, call use case, map response | Inline SQL orchestration or repeated policy |
| Public module API | A few domain-named operations | Unrelated exports or a re-exported SDK |

They prompt a cohesion check; they are not pass/fail. A clear 230-line state machine
beats ten fragments. Tests, migrations, generated code and exhaustive policy tables
can justify other sizes.

Extract at a semantic seam - a policy, parser, use case or adapter - with a precise
name, inward dependencies and a small public surface. Never meet a size target by
compressing syntax, deleting useful explanation, scattering one decision across files,
or creating `utils`, `helpers`, `manager` or `service` dumping grounds. Comment the
invariant, trade-off or ownership boundary, not each assignment.

## 6. Errors are part of the contract

- Expected domain failures return a typed `Result` with stable error codes and one
  explicit mapping to the public contract. No nullable success that hides the reason.
- Keep invalid input, hidden or missing resources, conflicts, transient provider
  failures and defects apart. A provider outage is not bad input; a known constraint
  conflict is not automatically a 500. Inspect the driver error and constraint name.
- Pure decisions do not throw. Unexpected exceptions may cross effect boundaries to
  the established central handler. A `Promise<Result<...>>` can still reject.
- Catch only to translate, compensate, record or add safe context. Never catch
  everything and return an empty list, `undefined`, success or an unrelated error.
  Empty data and failed retrieval are different outcomes.
- Never expose stacks, SQL, hostnames, credentials or SDK bodies. Never serialise an
  unknown remainder into an error.

## 7. Persistence, retries and API limits

Read the matching reference when the change touches these areas:

- Writes, transactions, concurrency, row ownership, RLS, migrations:
  [references/persistence.md](references/persistence.md).
- Idempotency, events, outbox, consumers, webhooks, API contracts, pagination,
  limits: [references/async-and-api.md](references/async-and-api.md).

The rules that always apply:

- A typed value does not protect a write from another process. Database-enforceable
  invariants also live in constraints.
- Read-then-write without a concurrency guard is not an atomic transition. Check
  affected-row counts where they decide ownership or success.
- No network I/O inside a database transaction by default, and no transaction makes
  an external effect atomic with SQL. Design recovery for the gap.
- Every mutating command and consumer has a named idempotency key, scope and replay
  result. Never promise exactly-once without proof across both boundaries.
- Bound every collection, page, upload, batch, retry and concurrent fan-out.

## 8. Security is an invariant, not a flag

- Authorise the verified actor against current, authoritative resource state. A brand
  is not a capability, and authentication is not ownership. Never trust an
  unverified token claim for an identity or rate-limit decision.
- Each disclosure or entitlement policy has one owner and applies identically across
  list, detail, export, cache and signed-URL paths. Feature flags control rollout,
  never ownership or privacy.
- Log stable event names with minimal structured context and correlation IDs. Never
  log credentials, tokens, signed URLs, payment data or personal data. Test redaction
  on the error paths SDKs actually produce.

## 9. Choose evidence that proves the claim

| Claim | Minimum useful evidence |
| --- | --- |
| A forbidden call cannot compile | Positive and negative type examples in a real compiler run |
| A pure policy holds an invariant | Decision-table examples; property tests for large state spaces |
| An HTTP boundary preserves values | Real request validation and serialisation through the route |
| Ownership, constraints or races hold | Real database, real role, concurrent requests |
| An adapter follows a provider | Contract tests with realistic wire semantics and failures |
| An async workflow finishes | Durable receipt, resulting state, effect, replay evidence |
| A deployed fix is live | The built artifact, revision check and authorised smoke test |

For a defect, write the regression against the violated guarantee, derived from the
contract rather than the implementation. Never report a skipped, unrun or
transpile-only check as stronger evidence than it is. Details:
[references/testing.md](references/testing.md).

## 10. Evolve through existing seams

- For a known upcoming business axis, add a narrow parameter or one-member union when
  it prevents a specific rewrite. No speculative plugins for unknown products.
- Prefer additive contracts. Compatibility work names the old shape, the reader that
  accepts it, and the removal plan. No permanent second implementation of a policy.
- Refactor an oversized file only far enough to give the change a coherent home,
  unless a wider refactor is requested or needed for correctness.

## 11. Review and handoff

Before finishing, answer with evidence:

1. Can the model still represent the invalid state behind the defect? If so, is the
   remaining runtime or database guard explicit and tested?
2. Where does untrusted data become trusted, and can a cast bypass it?
3. Does each business rule have one owner, with dependencies pointing inward?
4. Are omission and null, units, identifier equality and external object identity kept?
5. What happens if two requests race, or the process dies after an external effect?
6. Can a retry repeat an effect, lose work, leak another tenant's data or resurrect a
   deleted record?
7. Are modules cohesive and readable, with only the abstractions this change needs?
8. Do the checks prove the runtime claim, not just the fake's behaviour?

Report the resulting behaviour, the key design choice, the checks actually run and
their limits. Keep completion states distinct: code changed, artifact built, pushed,
deployed, data recovered. If a required check fails for pre-existing reasons, say so
without weakening the check or expanding into unrelated cleanup.

## Maintenance

Add a rule only after a demonstrated failure or an accepted architectural change.
Do not accumulate bans from every incident or freeze transient facts here. Project
facts belong in client or repository profiles, never in this skill.
