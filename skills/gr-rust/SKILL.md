---
name: gr-rust
description: Core skill for all Rust - CLIs, libraries, tools and services. Idiomatic Rust in a functional style (pure functions, immutable values, expressions, iterator and combinator pipelines) with type-level design (make illegal states unrepresentable, parse don't validate, typestate, capabilities, algebraic merge laws), typed errors, a pure core with effects at the edges, strict lints and evidence-based tests. Use for any Rust code in any repository, and when porting code from another language to Rust. For business and enterprise domains, gr-rust-domain extends this skill with DDD. Never carries another language's structure, types or habits into Rust.
metadata:
  owner: gautamr
  layer: personal
  version: "1.0.0"
  reviewed: "2026-11-22"
---

# Rust engineering

Write Rust whose rules are enforced by the compiler wherever the compiler can enforce them, and
by tests only where it cannot. Count the states a type allows; every state the specification
forbids is a bug waiting for a test. Optimise for the maintainer adding the next rule, not for
cleverness: prefer the simplest type that holds exactly the legal states.

Write idiomatic Rust, with no compromise. When porting, the old code is a reference for
*behaviour* only, never for module layout, type shape, error style or naming.

Prefer functional programming over imperative programming, everywhere (§3a). This skill is the
core for all Rust; `gr-rust-domain` extends it for business and enterprise domains and never
restates it.

## 0. Profiles override this skill

This skill holds personal defaults. Later entries win:

1. **Client profile**: `docs/standards/rust.md` in the client hub (find it through the
   repository's AGENTS.md). Single-repo projects have none.
2. **Repository profile**: `docs/standards/rust.md`, or the repository's own Rust rules in
   AGENTS.md or `.claude/rules/`.

Where executable configuration (`Cargo.toml` lints, `clippy.toml`, `rustfmt.toml`, CI) contradicts
any document, the configuration is what runs: follow it and report the mismatch.

## 1. Establish the contract before changing code

- Find the workspace root, `rust-toolchain.toml`, edition, `rust-version` (MSRV), the lint table
  and the real check commands (CI is the truth).
- Separate **required behaviour** (spec, tests), **observed implementation** and **proposed
  improvement**. Settle disagreements against the spec and tests, not old docs.
- Reuse the crate's existing newtypes, error enums, capability types and helpers before adding
  alternatives.

For a substantial change, answer before coding:

| Question | Required answer |
| --- | --- |
| Behaviour | Command or call, preconditions, observable outcome |
| States | Every legal state, and the type whose values are exactly those |
| Boundaries | Where untrusted bytes become typed values |
| Effects | Files, processes, environment, terminal, network, time; which capability reaches each |
| Laws | Properties that must hold (determinism, merge laws, monotone security) |
| Evidence | Which check fails before the change and passes after |

## 2. Type-level design: the core discipline

Read `references/types.md` for worked examples. The rules:

1. **Cardinality.** A struct is a product (|A| × |B| states), an enum a sum (|A| + |B|);
   `Option<T>` has 1 + |T|, `()` has one, `Infallible` none. Design the type whose cardinality
   equals the number of legal states. Two `bool`s are four states: if three are legal, write a
   three-variant enum.
2. **Parse, don't validate.** Untrusted input is parsed once, at the boundary, into a type that
   carries the proof (`LayerName`, `AccountName`, `SafeRelPath`, `ObjectId`). Private field, one
   fallible constructor (`TryFrom`, `FromStr`, or `#[serde(try_from = "String")]`). Never an
   infallible `From<String>` for a validated type. Downstream code takes the type, never `&str`.
3. **Sum types over flags and strings.** Enums for kinds, modes and outcomes; `ValueEnum` for CLI
   choices; `bitflags` only for genuinely independent flags.
4. **Exhaustive matching.** No `_` arm on enums you own, so a new variant breaks the build
   wherever it must be handled. Use `#[non_exhaustive]` only on public types meant to grow (error
   kinds, options), never on closed algebraic sets.
5. **Typestate.** Steps that must happen in order consume `self` and return the next state type
   (`Plan<Draft>` → `Plan<Checked>` → applied). Methods that exist in one state live in that
   state's `impl`. Separate types when states carry different data; `PhantomData` markers only
   when they carry the same data.
6. **Capabilities and proof values.** Reach effects only through values that grant them: a
   read-only directory handle has no write methods; a `PersonAtTerminal` value exists only after
   the terminal check. A function that does not receive the capability cannot perform the effect,
   which is a stronger guarantee than any test.
7. **Phantom-typed identifiers** (`Id<T>(u64, PhantomData<fn() -> T>)`) when mixing up ids of
   different things is a real risk; implement `Clone`/`Copy` by hand to avoid a `T: Clone` bound.
8. **Sealed traits** for closed extension points (`mod sealed { pub trait Sealed {} }`).
9. **Totality.** Library functions return a value for every input: no `unwrap`, `expect`,
   panicking index or slice, or division by a possible zero (`NonZero*`) on any path reachable
   from input.
10. **Algebra for combining values.** Name the structure and test its laws:
    - "Most specific wins" is the last-writer-wins monoid: associative, not commutative,
      identity "unset".
    - Unions of sets or maps are join-semilattices: associative, commutative, idempotent, so the
      result does not depend on order or duplicates.
    - "Security only gets stricter" is a join on an ordered enum (`Allow < Ask < Deny`, merge is
      `max`): a monotone merge, so a later input can raise a setting but never lower it.
    - A fold of a stack with these merges, followed by a pure render over ordered collections
      (`BTreeMap`, never `HashMap` in output), is deterministic by construction.
    Implement an inherent `merge` plus `Default`; do not pull in a category-theory crate.
    Property tests state the laws (see §8).

Keep type machinery proportionate: a newtype or enum that removes a whole class of bugs is worth
it; a type-level number system for one check is not.

## 3. Shape: a pure core with effects at the edges

- **Functional core, imperative shell.** Decisions (parsing, resolving, merging, rendering,
  policy) are pure functions over typed values. Effects (filesystem, processes, environment,
  terminal, clock) sit at the edge behind capability types. The binary wires them together.
- **Enforce the boundary.** Put the core in its own crate with no effect dependencies, and ban
  effectful calls there with `disallowed-methods` in that crate's `clippy.toml`
  (`std::fs::*`, `std::process::*`, `std::env::var*`). A boundary the build enforces does not
  erode.
- **Thin binary.** `main` parses arguments, calls the library, renders diagnostics once and maps
  the outcome to `std::process::ExitCode`. Only `main` decides the exit code.
- **Crates by boundary, not by folder.** Start with one crate; split only for an enforced
  boundary (pure core vs effects), a second consumer, or build time. Flat `crates/` folder, folder
  name equals crate name, `xtask` for automation. See `references/layout-and-tooling.md`.
- **Modules.** `foo.rs` beside `foo/`, not `mod.rs`. Re-export items one by one, never with a
  glob; no `prelude` module; one public path per item. No `utils`, `helpers`, `Manager`,
  `Service` or `Factory` names: name modules and types after the domain.
- **Synchronous by default.** No async runtime without concurrent network I/O and a recorded
  reason. Prefer `std::thread::scope` to shared `Arc<Mutex<_>>`.

## 3a. Prefer functional over imperative

Functional style is the default; imperative code needs a reason.

- **Pure functions**: data in, data out. A function that decides does not read files, the clock,
  the environment or global state; those arrive as values or capabilities (§3).
- **Immutable values by default.** `let`, not `let mut`. Model an update as a function that
  consumes or borrows the old value and returns the new one (`fn merge(self, later: Self) ->
  Self`); consuming `self` makes this cheap. No shared mutable state.
- **Expressions over statements.** Bind the result of `match`, `if` and blocks
  (`let kind = match source { … };`) instead of declaring a variable and assigning it later.
- **Pipelines over loops with accumulators.** `iter().map().filter_map().collect()`, `fold`,
  `try_fold`, `any`/`all`, `partition`, and `collect::<Result<Vec<_>, _>>()` to traverse fallible
  work. `Option` and `Result` combinators (`map`, `and_then`, `ok_or_else`, `unwrap_or_default`)
  and `?` instead of nested `if let` and early-assigned flags.
- **Algebraic data types and pattern matching** over class-like hierarchies and dynamic dispatch.
- **Composition of small functions**; closures and higher-order functions where they name a step.
- **Effects at the edge.** The shell may loop and mutate; the core computes.

Where imperative is the better Rust (say why in the code or the review):
- A `for` loop when the body performs effects (I/O, writes): side effects belong in loops, never
  hidden inside `map` or `for_each` closures.
- A `for` loop when a long chain would be harder to read, or when early exit with several
  conditions is clearer.
- Local `mut` inside a function when it is clearer or measurably faster and never escapes.
- No deep recursion over input-sized data: Rust has no guaranteed tail calls; use iteration.
- No emulated monad transformers, higher-kinded types or point-free contortions.

## 4. Ownership and APIs

- Borrow by default: take `&str`, `&[T]`, `&Path` or `impl AsRef<Path>`; take ownership only to
  store or consume. Never `&String` or `&Vec<T>`.
- Before cloning to satisfy the borrow checker, try: named bindings or blocks, `mem::take`,
  `mem::replace` or `Option::take`, splitting a struct into independently borrowed parts. Clone
  small data deliberately, not reflexively.
- `Cow<'_, str>` when ownership is only sometimes needed. Structs own their data; keep `Rc`,
  `Arc`, `Box` and `RefCell` out of public signatures. `Rc<RefCell<_>>` and reflexive
  `Arc<Mutex<_>>` are design smells: restructure ownership first.
- Iterators over index loops; short chains, no intermediate `collect`; return
  `impl Iterator<Item = &T> + '_`. Explicit loops when the body is large.
- API Guidelines: `as_`/`to_`/`into_` conversion names; no `get_` prefix on getters; `new` and
  `with_…` constructors; a builder (infallible setters, `build() -> Result`) once optional
  settings multiply; private fields; trait bounds on `impl` blocks, not structs; no out
  parameters; implement `From`/`TryFrom`, never `Into`.
- Derive eagerly where meaningful: `Debug` on every public type (redacting for secrets),
  `Clone`, `PartialEq`, `Eq`, `Hash`, `Ord`, `Default`; `Display` for anything a person reads.

## 5. Errors are part of the contract

Read `references/errors-and-effects.md`.

- **Library crates**: typed errors, `thiserror` enums (one per boundary), implementing
  `std::error::Error + Send + Sync + 'static`, with `source()` chains and `Display` text in lower
  case without trailing punctuation. Never `String`, `()`, `Box<dyn Error>` or `anyhow::Error` as
  a public error type. Convert with `From`, not repeated `map_err`.
- **User-facing problems are values**, not errors: collect diagnostics (code, message, location)
  so one run reports every problem; render them in one place.
- **Binary**: typed outcomes mapped to exit codes; `anyhow` only for unexpected failures, with
  `.context()` naming the path or operation. Print the chain once, to stderr.
- **Panics are for bugs only**, never for bad input. An intentional panic carries a message
  (`expect("why this cannot fail")`). No `catch_unwind` as control flow. Destructors never fail;
  offer `close() -> Result` when closing can fail.
- Never discard errors silently (`let _ =`, `.ok()`); the lints in §7 catch it.

## 6. Safety: unsafe, files, processes, untrusted input

- `unsafe_code = "forbid"` in the workspace lints. Where unsafe is truly needed it lives in the
  smallest module, each block with a `// SAFETY:` comment, checked by Miri.
- **Files**: validate untrusted relative paths by components (reject `ParentDir`, `RootDir`,
  `Prefix`); scope access with `cap_std::fs::Dir` or `rustix` `openat`/`O_NOFOLLOW` rather than
  canonicalise-then-check (a TOCTOU race); create exclusively with `File::create_new`; write
  atomically with a temp file in the same directory and a rename (`tempfile::NamedTempFile::
  persist`).
- **Processes**: `Command::new(prog).args([...])`, never a shell with interpolated strings; `--`
  before untrusted positionals; control the child environment explicitly (`env_clear`,
  `env_remove`); check the status.
- **Environment**: in edition 2024 `set_var`/`remove_var` are `unsafe`. Snapshot the environment
  once at start and pass it down; never mutate it, in tests included.
- **Untrusted text in output**: strip or escape control and format characters before printing.

## 7. Lints and tooling

Read `references/layout-and-tooling.md` for the full `Cargo.toml` lint table.

- Lints live in `[workspace.lints]`, inherited with `[lints] workspace = true`; groups at
  `priority = -1`. Never `#![deny(warnings)]` in source; CI passes `-D warnings`.
- Clippy `pedantic` at warn; `correctness` stays deny; never the whole `restriction` group.
  Selected restriction lints, each for a reason: `unwrap_used`, `panic_in_result_fn`,
  `unwrap_in_result`, `indexing_slicing`, `string_slice`, `allow_attributes`,
  `allow_attributes_without_reason`, `dbg_macro`, `todo`, `unimplemented`, `print_stdout`,
  `print_stderr`, `exit`, `as_conversions`, `map_err_ignore`, `let_underscore_must_use`,
  `unused_result_ok`, `mem_forget`, `wildcard_enum_match_arm`, `clone_on_ref_ptr`, `rc_buffer`,
  `undocumented_unsafe_blocks`, `tests_outside_test_module`.
- Suppress with `#[expect(lint, reason = "…")]`, never a bare `allow`.
- `rustfmt` with defaults; `missing_docs` on public items; `cargo deny` (licences, bans,
  advisories, sources) and an MSRV job in CI; `cargo doc` with `-D warnings`.
- CI: `cargo fmt --check`, `cargo clippy --all-targets --all-features -- -D warnings`,
  `cargo nextest run` plus `cargo test --doc`, `cargo doc`, `cargo deny check`, MSRV.

## 8. Evidence: tests that prove the claim

Read `references/testing.md`.

| Claim | Minimum useful evidence |
| --- | --- |
| An illegal state cannot be built | The constructor's `Err` cases, plus a `compile_fail` doc test where the type system is the guard |
| A parser accepts exactly the spec | Examples for each rule, `proptest` round-trips (`parse(print(x)) == x`), `cargo fuzz` for untrusted formats |
| A merge obeys its laws | `proptest` for associativity, idempotence, identity, and monotonicity of security settings |
| Output is deterministic | Build twice, compare bytes; snapshot tests (`insta`) |
| A command behaves | `assert_cmd` (`cargo_bin_cmd!`) in a real temporary directory, asserting exit code, stdout, stderr and files on disk |
| An effect cannot happen | The function does not receive the capability (a type signature), plus one test |

Real temporary directories over mocked filesystems. Narrow seams (`impl Read`/`impl Write`, a
clock parameter) where a test truly needs one. Write the failing test before fixing a bug.

## 9. Domain language everywhere; full DDD only through gr-rust-domain

In every Rust codebase: name types and modules with the specification's words (no synonyms),
model values as newtypes and enums (§2), and translate external formats at one boundary (an
anti-corruption module).

Entities, aggregates, bounded contexts, ports, application services and domain events belong to
business and enterprise systems (identity over time, concurrent mutation, transactions, several
models). For those, load `gr-rust-domain`, which extends this skill. For compilers, CLIs and tools,
plain functions over typed values and capabilities for effects do the job; say which you chose
and why in the design record.

## 10. Anti-patterns, especially from TypeScript and JavaScript

Read `references/anti-patterns.md`. The short list: stringly typed data and
`HashMap<String, Value>` as an object; sentinel values; `unwrap()` used like TypeScript's `!`;
panics or `catch_unwind` as exceptions; trait hierarchies or `Deref` imitating classes;
over-generic code and single-implementation traits; `Box<dyn Error>` everywhere; mocked
filesystems; `Arc<Mutex<_>>` by default; async without concurrency; clone to quiet the borrow
checker; glob re-exports (barrel files); getters and setters for every field; `utils.rs`; bags of
`Option` fields where an enum of shapes is the model; `as` casts and float `==`.

## 11. Review and handoff

A review checks, in order: the states the types allow against the spec; boundaries where input
is parsed; effects reachable without a capability; imperative code (mutation, accumulator loops,
side effects inside closures) without a stated reason; error types and diagnostics; laws and
their tests; lints passing without new suppressions; docs on public items. Report the checks run with
their output, and what remains unverified.

## Maintenance

Sources are listed in `references/sources.md`. Review this skill when the edition, the MSRV
policy or a referenced guideline changes, and bump `version` and `reviewed`.
