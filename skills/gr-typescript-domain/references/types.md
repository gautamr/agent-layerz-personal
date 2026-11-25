# Types: worked examples and limits

Read this when designing domain types, parsers, state transitions or type-level APIs.
The examples form one illustrative module. In a real repository, reuse its existing
`Result`, brand and ID helpers instead of copying these.

## Contents
- Parse before you brand
- Canonical identity
- Transitions with explicit input and output states
- Visible exhaustiveness
- Keeping type machinery proportionate

## Parse before you brand

```ts
type Result<TValue, TError> =
  | { readonly ok: true; readonly value: TValue }
  | { readonly ok: false; readonly error: TError };

declare const brand: unique symbol;
type Brand<TValue, TName extends string> = TValue & { readonly [brand]: TName };

type EpochMillis = Brand<number, "EpochMillis">;
type InvalidTime = { readonly code: "INVALID_TIME" };

// Contract: nonnegative, safely representable milliseconds.
function parseEpochMillis(raw: unknown): Result<EpochMillis, InvalidTime> {
  if (typeof raw !== "number" || !Number.isSafeInteger(raw) || raw < 0) {
    return { ok: false, error: { code: "INVALID_TIME" } };
  }
  return { ok: true, value: raw as EpochMillis };
}
```

The only cast sits inside the constructor whose checks justify it. Some existing
"trusted" constructors assume a route schema already validated the value; follow the
route validation into the feature before changing their signatures or assuming input
is trusted. Revalidate durable messages when they are consumed, not only when produced.

## Canonical identity

Canonicalise a semantic identity once, at the owning boundary, and use that value
everywhere: writes, comparisons, responses and idempotency decisions. Define equality
before normalising. UUID letter case can be insignificant while storage object names,
signatures, URLs and opaque credentials stay case-sensitive. Preserve an external
object's exact identity and version when reading or deleting it. Never apply a global
lowercase or trim rule to arbitrary identifiers or tokens.

## Transitions with explicit input and output states

```ts
type SessionState =
  | { readonly status: "created" }
  | { readonly status: "active"; readonly startedAt: EpochMillis }
  | { readonly status: "ended"; readonly startedAt: EpochMillis; readonly endedAt: EpochMillis };

type ActiveSession = Extract<SessionState, { status: "active" }>;
type EndedSession = Extract<SessionState, { status: "ended" }>;
type EndError = { readonly code: "END_BEFORE_START" };

function endSession(session: ActiveSession, now: EpochMillis): Result<EndedSession, EndError> {
  if (now < session.startedAt) return { ok: false, error: { code: "END_BEFORE_START" } };
  return { ok: true, value: { status: "ended", startedAt: session.startedAt, endedAt: now } };
}
```

Types exclude ending an ended session; the runtime check enforces time order; the
database must stop a concurrent writer between read and write. Do not add a stored
state enum or a new API status just to mirror an example: the in-memory decision
model, the persistence model and the wire contract may differ.

## Visible exhaustiveness

```ts
function unreachable(_value: never): never {
  throw new Error("UNREACHABLE_STATE"); // never serialise the value: it may hold sensitive data
}

function sessionLabel(session: SessionState): string {
  switch (session.status) {
    case "created": return "Waiting";
    case "active": return "Live";
    case "ended": return "Finished";
    default: return unreachable(session);
  }
}

declare const finished: EndedSession;
declare const now: EpochMillis;
// @ts-expect-error An ended session is not an active session.
endSession(finished, now);
```

Claim the negative check works only if a real compiler run includes the file. Tests
executed through a transpiler (esbuild, swc, tsx, Vitest's default transform) do not
type-check, and many `tsconfig.json` files exclude `tests/`.

## Keeping type machinery proportionate

- Derive DTOs from runtime schemas and persistence rows from ORM definitions. Add a
  separate domain model only when its business meaning differs from those shapes.
- `satisfies` checks configuration and policy tables while keeping inferred types. It
  is compile-time conformance, not parsing, and not exact-object checking.
- `unknown` for unknown values; narrow before use.
- Keep `strict`, `noUncheckedIndexedAccess` and `exactOptionalPropertyTypes` where
  configured. They are separate options; `strict` does not include the other two.
- Generics express a real relationship between values; constrain them only when an
  operation needs it.
- Conditional, mapped and template-literal types only when they remove a real source
  of drift. Prefer a named intermediate type to a nested type puzzle.
- No type-level arithmetic, recursive type programs or simulated higher-kinded types
  unless a concrete public abstraction needs them and compile time stays acceptable.
- Use a non-empty tuple only when later code benefits; tuple types cannot validate a
  JSON array's length at runtime.
- No FP library, DI framework, generic repository, mapper framework or workflow
  engine to simplify one ordinary function.
