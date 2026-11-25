# Evidence and tests

Read this when choosing or writing tests, or when reporting what a change proves.

- Write a defect's regression test against the violated guarantee. Derive the
  expectation from the contract, not from the implementation. A characterisation test
  that documents a known defect is not permission to keep the defect.
- Use property-based tests for laws: canonicalisation is idempotent, private data is
  never disclosed, identities are preserved, only legal transitions occur. Pair broad
  generation with known regression examples, and keep reproducing seeds and
  counterexamples. [fast-check](https://fast-check.dev/docs/introduction/why-property-based/)
  is the usual TypeScript choice.
- Use typed test builders and narrow fakes. Never weaken production types for test
  convenience.
- A mocked fluent SQL chain cannot prove SQL validity, constraints, RLS or isolation.
  A passing fake does not prove the provider.
- Type-level assertions (`@ts-expect-error`) count only when a real compiler run
  includes the file. Check `tsconfig.json` includes and the test runner's transform.
- Run focused checks while editing, then the required build, typecheck, lint and tests
  for the final change. Widen the checks when a failure or open concern justifies it.
- Do not add tests for reversible prose or formatting edits, or tests that mirror the
  implementation line by line.
- Report each check's target, actual outcome and limits.
