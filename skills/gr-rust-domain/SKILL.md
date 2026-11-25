---
name: gr-rust-domain
description: Extends gr-rust for business and enterprise domains in Rust - customer-facing services, back-office systems, workflows with identity over time, transactions and several models - with Domain-Driven Design done functionally (bounded contexts, entities, aggregates as decide and evolve functions, domain events, ports and adapters, consistency and persistence). Load gr-rust first; this skill only adds to it and never restates it. Not for compilers, CLIs or tools, where gr-rust alone applies.
metadata:
  owner: gautamr
  layer: personal
  version: "1.0.0"
  reviewed: "2026-11-22"
  extends: gr-rust
---

# Rust domain engineering (extends gr-rust)

**Read `gr-rust` first.** Everything there applies unchanged: type-level design, functional
style, the pure core with effects at the edges, errors, safety, lints and testing. This skill
adds only what business domains need. Where it changes a `gr-rust` default, it says
"Overrides gr-rust §N" and why.

The aim: business rules readable from the domain's own vocabulary and types, enforced inside
small consistency boundaries, decided by pure functions, and persisted and published by thin
effectful code at the edge.

## 0. Profiles override this skill

Later entries win: the client profile `docs/standards/rust-domain.md` in the client hub, then the
repository's `docs/standards/rust-domain.md`, then rules the repository's AGENTS.md names. The
domain glossary (`docs/domain/glossary.md`, or the repository's equivalent) is the source of the
names this skill asks for.

## 1. Decide whether DDD applies

Use this skill when most of these hold; otherwise use `gr-rust` alone and say so:

- Things have identity that persists through change (a customer, an order, a contract).
- Rules change with the business and are owned by domain experts.
- State is mutated concurrently and must stay consistent (transactions, concurrency control).
- Several teams or subdomains use the same words with different meanings.
- The system integrates other systems whose models must not leak in.

## 2. Strategic design

- **Subdomains**: name the core (where the business competes), supporting and generic ones.
  Invest type-level rigour in the core; buy or keep generic subdomains simple.
- **Bounded contexts**: one model and one language per context. In Rust a context is a crate (or
  a top-level module in a small system) with its own types; contexts never share domain types.
- **Context map**: record the relationships (customer-supplier, conformist, shared kernel,
  published language). A **shared kernel** is a small crate both sides own; everything else
  crosses a boundary through translation.
- **Anti-corruption layer**: external models (partner APIs, legacy systems, other contexts) are
  translated at the boundary with `TryFrom` into this context's types, so foreign shapes and
  failure modes never reach the domain.
- **Ubiquitous language**: the glossary names every type, variant, function and module. A term
  that changes meaning across contexts gets a different type in each.

## 3. Tactical design, done functionally

Value objects are `gr-rust` §2 (newtypes, enums, parse don't validate). This skill adds the rest.

| Concept | Rust shape |
| --- | --- |
| Entity | A struct with an identity newtype (`CustomerId`), private fields, behaviour as methods or functions. Compare entities by id explicitly; do not derive `PartialEq` over all fields. |
| Aggregate | One invariant and its consistency boundary. A root type owning its parts; state as an enum when it has a lifecycle (typestate where the states carry different data). |
| Command | A value describing an intent (`enum OrderCommand { Place { .. }, Cancel { reason } }`), already parsed into domain types. |
| Decision | A pure function `decide(&State, Command, &Context) -> Result<Vec<Event>, DomainError>`. All business rules live here. |
| Domain event | A past-tense fact (`enum OrderEvent { Placed { .. }, Cancelled { .. } }`), data only, versioned when it is published or stored. |
| Evolution | A pure function `evolve(State, &Event) -> State`. Current state is `events.iter().fold(State::default(), evolve)`. |
| Domain policy | A pure function over values from several aggregates, owned by no single one. |
| Application use case | A function that loads through ports, calls `decide`, persists and publishes atomically, and authorises. No business rules. |
| Port | A narrow trait designed from the use case's need (`load`, `save` with an expected version), not a generic repository. |
| Adapter | Implements a port (database, message broker, HTTP client) and translates; never changes policy. |

The decide-and-evolve pair keeps the domain purely functional whether or not events are stored:
store state and emit events, or store events and fold them. `references/aggregates.md` has a
worked example.

**Overrides gr-rust §3 (synchronous by default):** services with network or database I/O may use
an async runtime in the application and adapter layers. The domain (decide, evolve, policies,
value objects) stays synchronous and pure.

**Overrides gr-rust "plain functions over capabilities, no repository traits":** ports are traits
at the application boundary, because the use case needs to swap a database for a test double or a
second store. Keep them narrow, one per need, with fakes that honour the full contract, failures
included.

## 4. Consistency and persistence

- **One aggregate per transaction.** Cross-aggregate consistency is eventual, through events and
  policies, unless a recorded decision says otherwise.
- **Optimistic concurrency**: every aggregate carries a version; `save` takes the expected version
  and fails on a conflict, which the use case reports or retries with the same command identity.
- **Idempotency**: commands from outside carry an idempotency key; a repeated key returns the
  first outcome.
- **Outbox**: events are written in the same transaction as state and published afterwards.
- **Persistence types stay in adapters**: database rows and ORM or query types are translated to
  domain types in the adapter; the domain never derives or depends on them. Compile-time-checked
  queries and versioned migrations are adapter concerns.
- **Time and identity generation** are inputs: the use case passes `now` and new ids to `decide`.

## 5. Errors

- **Domain errors** use business vocabulary and live in the context (`enum OrderError {
  AlreadyShipped, CreditLimitExceeded { limit } }`); they are expected outcomes, not failures.
- **Infrastructure errors** (database, network) are separate types from adapters.
- **One mapping** at the API boundary turns each into a response (HTTP status, problem detail,
  exit code). Messages shown to customers never include internal detail.

## 6. Evidence

Extends the `gr-rust` §8 table:

| Claim | Minimum useful evidence |
| --- | --- |
| A business rule holds | Given past events, when a command, then events or a domain error: tests on `decide` alone |
| An aggregate invariant always holds | `proptest`: any sequence of accepted commands keeps the invariant after `evolve` |
| State and events agree | Folding the emitted events reproduces the stored state |
| An adapter honours its port | Contract tests run against the real store (for example a test container) and the fake |
| Concurrency control works | Two use cases with the same expected version: one wins, one gets a conflict |
| Events are compatible | Stored or published events of the previous version still deserialise |

No mocks inside the domain: it is pure, so tests call it directly.

## 7. Layout of a bounded context

```text
crates/ordering/                 # one bounded context
├── src/domain.rs                # declares the modules below; re-exports the context's public API
├── src/domain/
│   ├── values.rs                # value objects for this context
│   ├── order.rs                 # aggregate: state, commands, events, decide, evolve
│   └── pricing.rs               # a domain policy
├── src/application.rs           # use cases and the ports they need
├── src/adapters/
│   ├── postgres.rs              # implements the ports
│   └── billing_acl.rs           # anti-corruption layer for an external context
└── tests/                       # use-case and adapter contract tests
```

The domain module has no dependency on adapters, async runtimes or persistence crates; enforce it
with the crate graph or `disallowed-methods`, as `gr-rust` §3 describes.

## 8. Anti-patterns specific to domain code

- **Anemic domain**: public-field structs with rules in "service" functions. Put rules in
  `decide` and policies, keep fields private.
- **Generic repository** (`Repository<T>` with CRUD): ports are designed per use case.
- **Setters on entities**: state changes only through commands and events.
- **Events as commands** ("SendEmail" as an event): events state facts; reactions are policies.
- **Persistence or API types in the domain** (database rows, request DTOs with serde derives that
  mirror tables).
- **One model shared across contexts**: translate at the boundary instead.
- **Async or I/O inside `decide` or `evolve`**.
- **Distributed transactions across aggregates** as the default.

## Maintenance

Review together with `gr-rust`; bump `version` and `reviewed` when either changes in a way that
affects this extension.
