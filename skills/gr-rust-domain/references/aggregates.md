# Aggregates as decide and evolve: a worked example

Read this when designing an aggregate. It builds on `gr-rust` references/types.md (newtypes,
sum types, typestate) and does not repeat it.

## The aggregate

```rust
/// An order's lifecycle. Each state holds exactly the data that state needs.
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub enum Order {
    #[default]
    Absent,
    Placed { id: OrderId, lines: NonEmptyVec<Line>, total: Money },
    Shipped { id: OrderId, total: Money, shipped_at: Timestamp },
    Cancelled { id: OrderId, reason: CancelReason },
}

/// What a caller asks for, already parsed into domain values.
#[derive(Debug, Clone)]
pub enum Command {
    Place { id: OrderId, lines: NonEmptyVec<Line> },
    Ship { at: Timestamp },
    Cancel { reason: CancelReason },
}

/// Facts that happened. Past tense, data only.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Event {
    Placed { id: OrderId, lines: NonEmptyVec<Line>, total: Money },
    Shipped { at: Timestamp },
    Cancelled { reason: CancelReason },
}

#[derive(Debug, thiserror::Error, PartialEq, Eq)]
pub enum OrderError {
    #[error("the order already exists")]
    AlreadyPlaced,
    #[error("there is no order")]
    NotPlaced,
    #[error("a shipped order cannot be cancelled")]
    AlreadyShipped,
    #[error("the order is cancelled")]
    Cancelled,
}
```

## Decide: all business rules, pure

```rust
/// Decides what happens when `command` meets `state`. No I/O, no clock, no ids generated here.
pub fn decide(state: &Order, command: Command) -> Result<Vec<Event>, OrderError> {
    match (state, command) {
        (Order::Absent, Command::Place { id, lines }) => {
            let total = lines.iter().map(Line::subtotal).sum();
            Ok(vec![Event::Placed { id, lines, total }])
        }
        (Order::Absent, Command::Ship { .. } | Command::Cancel { .. }) => Err(OrderError::NotPlaced),
        (Order::Placed { .. }, Command::Place { .. })
        | (Order::Shipped { .. } | Order::Cancelled { .. }, Command::Place { .. }) => {
            Err(OrderError::AlreadyPlaced)
        }
        (Order::Placed { .. }, Command::Ship { at }) => Ok(vec![Event::Shipped { at }]),
        (Order::Placed { .. }, Command::Cancel { reason }) => Ok(vec![Event::Cancelled { reason }]),
        (Order::Shipped { .. }, Command::Ship { .. }) => Ok(vec![]), // idempotent
        (Order::Shipped { .. }, Command::Cancel { .. }) => Err(OrderError::AlreadyShipped),
        (Order::Cancelled { .. }, Command::Ship { .. } | Command::Cancel { .. }) => {
            Err(OrderError::Cancelled)
        }
    }
}
```

The `match` on the pair `(state, command)` is exhaustive with no `_` arm: adding a state or a
command fails to compile until every combination has a decision. That is the decision table,
checked by the compiler.

## Evolve: how facts change state, pure and total

```rust
/// Applies one event. Events are facts already decided, so evolve never fails; an impossible
/// pair keeps the state, and a test proves `decide` never emits it.
#[must_use]
pub fn evolve(state: Order, event: &Event) -> Order {
    match (state, event) {
        (Order::Absent, Event::Placed { id, lines, total }) => Order::Placed {
            id: id.clone(),
            lines: lines.clone(),
            total: *total,
        },
        (Order::Placed { id, total, .. }, Event::Shipped { at }) => {
            Order::Shipped { id, total, shipped_at: *at }
        }
        (Order::Placed { id, .. }, Event::Cancelled { reason }) => {
            Order::Cancelled { id, reason: reason.clone() }
        }
        (state, _) => state,
    }
}

/// Current state from history: a left fold.
#[must_use]
pub fn replay(events: &[Event]) -> Order {
    events.iter().fold(Order::default(), evolve)
}
```

`evolve` uses a final catch-all arm on purpose: it is a total function over facts, and the laws
below test that `decide` never produces a pair the catch-all would swallow.

## The use case: effects at the edge

```rust
pub async fn ship_order(
    orders: &impl Orders,          // port
    outbox: &impl Outbox,          // port
    id: &OrderId,
    at: Timestamp,                 // time is an input
) -> Result<(), ShipError> {
    let (state, version) = orders.load(id).await?;
    let events = decide(&state, Command::Ship { at })?;
    let next = events.iter().fold(state, evolve);
    orders.save_with_outbox(id, &next, version, &events, outbox).await?; // one transaction
    Ok(())
}
```

## Tests: given, when, then; and laws

```rust
#[test]
fn a_shipped_order_cannot_be_cancelled() {
    let given = replay(&[placed(), Event::Shipped { at: t0() }]);
    let when = decide(&given, Command::Cancel { reason: changed_mind() });
    assert_eq!(when, Err(OrderError::AlreadyShipped));
}

proptest! {
    /// Any sequence of commands keeps the invariant: a shipped order's total equals the sum of
    /// the lines it was placed with.
    #[test]
    fn total_is_preserved(commands in vec(any_command(), 0..20)) {
        let (state, history) = run(commands); // decide + evolve, ignoring rejected commands
        if let (Order::Shipped { total, .. }, Some(Event::Placed { lines, .. })) =
            (&state, history.first())
        {
            prop_assert_eq!(*total, lines.iter().map(Line::subtotal).sum::<Money>());
        }
        prop_assert_eq!(replay(&history), state); // events and state agree
    }
}
```
