# Retries, delivery and API contracts

Read this when a change adds or alters a mutating endpoint, a webhook, an event, a
queue consumer, a background job, or a public request or response shape.

## Contents
- Idempotency and identity
- Events and delivery
- Recovery cut points
- API semantics and resource limits

## Idempotency and identity

For each mutating command or consumer, name the business idempotency key, its scope,
what a replay returns, and whether the first write wins. Reusing a key with a
different owner or payload must never grant access or create a different operation.
Test concurrent duplicates, not only sequential retries.

Keep these identities apart even when related:
- An external object: bucket, exact key, generation or version.
- An event: stable business or event identity plus schema version.
- An effect: its completion, recorded independently of delivery attempts.

## Events and delivery

- Commit the domain change and the durable event record together when they share a
  database (outbox). Publish with bounded work and keep a durable recovery path for
  the gap after commit.
- A successful publish does not prove a consumer finished.
- Never use an in-memory bus for an effect that must survive process loss.
- Request-driven consumers acknowledge only after the required durable work and
  cleanup finish. Never start detached work and return success.
- Bound timeouts, retries, batch sizes and concurrency. Retry only failures that are
  safe to retry; never retry non-idempotent effects blindly or drop permanent
  failures silently.
- A late delivery must not resurrect a deleted aggregate.
- Do not promise exactly-once delivery or effects without a proof that covers the
  provider and the database boundary.

## Recovery cut points

Show what happens if the process dies at each point:
1. Before the external write.
2. After the external write, before the SQL commit.
3. After the record is ready, before cleanup.
4. After completion, before acknowledgement.

## API semantics and resource limits

- Validate request bodies without destructive coercion. Keep query-string coercion
  deliberate: turning it off everywhere breaks numeric query parameters.
- In patches, distinguish omission from explicit clearing. Never turn a rejected value
  into `null` silently.
- Declare response shapes and meaningful failure statuses. Return allow-listed
  projections, never a spread internal entity or SQL row.
- Version public contracts and durable event envelopes deliberately. A new union
  member can break readers; call that out in the rollout.
- Bound pagination, upload bytes, collection sizes, provider requests, SQL result
  sizes and concurrent work. Validate the bytes received, not the client's claimed
  size or content type.
- No floating promises and no unbounded `Promise.all`. Wire cancellation and shutdown
  to the process's request, job or worker ownership.
- Use strings for external counters or generations that can exceed the safe integer
  range. Keep wire timestamps and units as received; convert deliberately.
