# Types: worked examples and the reasoning behind them

Read this when designing domain types, parsers, state transitions, capability boundaries or merge
rules. The examples form one illustrative module; in a real crate, reuse its existing types.

## Contents
- Counting states
- Parse, don't validate
- Sum types instead of flags
- Typestate
- Capabilities and proof values
- Merge algebra and its laws
- Keeping type machinery proportionate

## Counting states

A type's cardinality is the number of values it can hold:

| Type | Cardinality |
| --- | --- |
| `()` | 1 |
| `bool` | 2 |
| `enum E { A, B, C }` | 3 |
| `struct S { a: A, b: B }` (product) | \|A\| × \|B\| |
| `enum E { X(A), Y(B) }` (sum) | \|A\| + \|B\| |
| `Option<T>` | 1 + \|T\| |
| `Result<T, E>` | \|T\| + \|E\| |
| `Infallible`, `enum Never {}` | 0 |

Design the type whose cardinality equals the number of legal states. The difference between the
two is the set of states a test must rule out, now and after every change.

```rust
// Four states, one illegal ("connected but not authenticated" is fine, "authenticated but not
// connected" is not):
struct Session { connected: bool, authenticated: bool }

// Exactly the three legal states:
enum Session { Disconnected, Connected, Authenticated { user: UserName } }
```

The same argument applies to `Option` fields: three `Option`s are eight shapes. If only some
combinations are meaningful, an enum of those shapes is the model.

## Parse, don't validate

A validator returns `()` or `bool` and throws the knowledge away; every later caller must trust
or repeat it. A parser returns a value of a type that can only hold valid data, so the proof
travels with the value.

```rust
/// A layer name: non-empty, lowercase ASCII letters, digits and `-`, at most 64 bytes.
#[derive(Debug, Clone, PartialEq, Eq, Hash, PartialOrd, Ord, serde::Deserialize)]
#[serde(try_from = "String")]
pub struct LayerName(String);

#[derive(Debug, thiserror::Error, PartialEq, Eq)]
pub enum InvalidLayerName {
    #[error("is empty")]
    Empty,
    #[error("is longer than 64 bytes")]
    TooLong,
    #[error("contains a character other than a-z, 0-9 or -")]
    BadCharacter,
}

impl TryFrom<String> for LayerName {
    type Error = InvalidLayerName;

    fn try_from(s: String) -> Result<Self, Self::Error> {
        if s.is_empty() {
            return Err(InvalidLayerName::Empty);
        }
        if s.len() > 64 {
            return Err(InvalidLayerName::TooLong);
        }
        if !s.bytes().all(|b| b.is_ascii_lowercase() || b.is_ascii_digit() || b == b'-') {
            return Err(InvalidLayerName::BadCharacter);
        }
        Ok(Self(s))
    }
}

impl LayerName {
    /// The name as text.
    #[must_use]
    pub fn as_str(&self) -> &str {
        &self.0
    }
}
```

Notes:
- The field is private, so the only way in is `try_from` (and serde, which calls it).
- The error never contains the rejected text: input is untrusted, and errors get printed.
- Prefer a structured value over a validated string where the data has structure: an object id
  is `enum ObjectId { Sha1([u8; 20]), Sha256([u8; 32]) }`, not a hex `String`.

## Sum types instead of flags

```rust
// Boolean blindness: what does `true` mean at the call site?
fn write_file(path: &Path, bytes: &[u8], overwrite: bool) -> io::Result<()>;

// The call site states the intent, and a third mode is a compile error until handled:
pub enum Overwrite { Never, IfGenerated }
fn write_file(path: &Path, bytes: &[u8], overwrite: Overwrite) -> io::Result<()>;
```

Outcome enums make failure modes total:

```rust
pub enum Resolution {
    Applied(AccountFolder),
    Default,
    Kept(ForeignValue),
    FailsClosed(FailClosed),
}

pub enum FailClosed {
    MissingFolder(AccountName),
    CacheMiss { recorded: AccountName },
    DeclarationChanged,
    SourceGone,
    Conflict,
}
```

Match without a `_` arm. Adding a variant then fails to compile everywhere a decision must be
made for it, which is exactly where a reviewer would otherwise have to look.

## Typestate

Use the type system to enforce an order of operations. Each transition consumes the old state.

```rust
pub struct Stack<S> { layers: Vec<Layer>, state: S }

pub struct Declared;
pub struct Resolved { lock: Lock }

impl Stack<Declared> {
    pub fn resolve(self, cache: &ReadOnlyCache) -> Result<Stack<Resolved>, ResolveError> {
        /* ... */
    }
}

impl Stack<Resolved> {
    #[must_use]
    pub fn merge(&self) -> Merged { /* only a resolved stack can be merged */ }
}
```

Here the states carry different data (`Resolved` holds the lock), so they are real types, not
`PhantomData` markers. Use zero-sized markers only when every state has the same fields.

## Capabilities and proof values

A capability is a value whose possession grants an effect; a proof value is a value that can only
exist if a check passed. Both move rules from "every caller must remember" to "the signature says
so".

```rust
/// A directory that can only be read. No method writes, creates or deletes.
pub struct ReadOnlyDir { /* cap_std::fs::Dir or an rustix fd */ }

/// The repository root; writes are confined below it.
pub struct RepoRoot { /* ... */ }

/// Exists only after stdin was a terminal and no agent-session marker was set.
pub struct PersonAtTerminal { _private: () }

impl PersonAtTerminal {
    pub fn check(env: &Env, stdin: &impl IsTerminal) -> Result<Self, NotAPerson> { /* ... */ }
}

// Cannot write and cannot run git, by construction:
pub fn resolve_account(cwd: &Path, home: &ReadOnlyDir, env: &Env) -> Resolution { /* ... */ }

// Cannot be called without the check having passed:
pub fn record_approval(state: &StateDir, who: &PersonAtTerminal, entry: Approval)
    -> Result<(), WriteError> { /* ... */ }
```

The `_private: ()` field stops other modules constructing the value directly.

## Merge algebra and its laws

When values from several layers combine, name the algebraic structure; its laws are the tests.

**Last writer wins** (a monoid; associative, not commutative):

```rust
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Setting<T>(Option<T>);

// Written by hand: `#[derive(Default)]` would add a needless `T: Default` bound.
impl<T> Default for Setting<T> {
    fn default() -> Self {
        Self(None)
    }
}

impl<T> Setting<T> {
    /// The later value wins; `Default` (unset) is the identity.
    #[must_use]
    pub fn merge(self, later: Self) -> Self {
        Self(later.0.or(self.0))
    }
}
```

Laws: `a.merge(Setting::default()) == a`, `Setting::default().merge(a) == a`,
`a.merge(b).merge(c) == a.merge(b.merge(c))`.

**Union** (a join-semilattice; associative, commutative, idempotent): merging `BTreeSet`s or
`BTreeMap`s with a commutative value merge. Order and duplicates do not change the result.

**Security floor** (a monotone join on a total order):

```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub enum Policy { Allow, Ask, Deny }

impl Policy {
    /// Stricter wins: a later layer can raise a policy but never lower it.
    #[must_use]
    pub fn merge(self, later: Self) -> Self {
        self.max(later)
    }
}
```

Law: `a <= a.merge(b)` for every `b` (monotone). This is what "security only gets stricter"
means, stated so a property test can check it.

**Determinism.** A build that folds the stack with these merges and renders through ordered
collections is a pure function: `build(x) == build(x)` byte for byte. `HashMap` iteration order
breaks this; use `BTreeMap` or `IndexMap` for anything serialised or printed.

```rust
proptest! {
    #[test]
    fn policy_merge_is_monotone(a in any_policy(), b in any_policy()) {
        prop_assert!(a <= a.merge(b));
    }

    #[test]
    fn setting_merge_is_associative(a in any_setting(), b in any_setting(), c in any_setting()) {
        prop_assert_eq!(a.clone().merge(b.clone()).merge(c.clone()), a.merge(b.merge(c)));
    }
}
```

## Keeping type machinery proportionate

- Worth it: a newtype for every value from untrusted input; an enum for every closed set of
  kinds or outcomes; typestate for a real ordering rule; a capability for every effect that a
  security rule restricts.
- Not worth it: type-level numbers for a single bound; generic parameters with one
  instantiation; traits with one implementation; macros that hide control flow.
- If the type makes the next change harder for the maintainer than the bug it prevents, use a
  plainer type and a test.
