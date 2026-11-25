# Persisting invariants atomically

Read this when a change writes data, runs a transaction, changes ownership or
lifecycle state, touches row-level security or adds a migration.

- Name the exact uniqueness, ownership, lifecycle and referential constraints the
  write depends on. Database-enforceable invariants belong in constraints as well as
  in application rules.
- Use a transaction for invariants that span writes. Use a conditional update, row
  lock or version check for concurrent transitions.
- Check affected-row counts where they decide ownership, successful consumption or
  optimistic concurrency. A query that ran without error may have changed nothing.
- Scope every query and update to the right tenant or owner. Row-level security is
  defence in depth, not permission to skip the application's authorisation decision.
- With pooled connections, keep actor settings local to the transaction. Test with
  the application's real database role; an administrator bypassing RLS proves little.
- Keep network I/O outside database transactions by default. Where an existing
  design deliberately holds a lock across a storage effect, keep its rationale,
  bounded deadlines and crash-recovery proof rather than rearranging it casually.
- No transaction makes an irreversible provider effect atomic with SQL. Design the
  recovery for a crash after the external effect and before the commit.
- Map specific SQLSTATE codes and constraint names to domain conflicts. Outages and
  bugs stay distinct from conflicts.
- Schema changes go through the repository's shared migration workflow.

Check the deployed PostgreSQL version before relying on detailed behaviour.
[Constraints](https://www.postgresql.org/docs/current/ddl-constraints.html) and
[transaction isolation](https://www.postgresql.org/docs/current/transaction-iso.html)
cover different parts of the guarantee; neither replaces the application's policy.
