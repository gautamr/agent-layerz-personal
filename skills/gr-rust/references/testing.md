# Testing

Read this when choosing how to prove a change.

## Layers of evidence

- **Unit tests** beside the code (`#[cfg(test)] mod tests { use super::*; }`): behaviour and
  properties, not restated constants.
- **Doc tests** on public items: every example compiles and uses `?`; hide setup lines with `# `.
  A `compile_fail` doc test proves an illegal use does not compile:

  ```rust
  /// ```compile_fail
  /// let name = mycrate::LayerName::from("NOT valid".to_string()); // no infallible From
  /// ```
  ```

- **Integration tests** in `tests/` use only the public API.
- **CLI tests** with `assert_cmd` (`cargo_bin_cmd!`), `predicates`, and real temporary
  directories (`tempfile`, `assert_fs`): assert the exit code, stdout, stderr and the files on
  disk.
- **Snapshot tests** with `insta` for generated files and long output; review changes with
  `cargo insta review`. `trycmd` for file-driven CLI cases.
- **Property tests** with `proptest` for parsers (round-trip `parse(print(x)) == x`, rejection of
  generated invalid input) and for merge laws (associativity, identity, idempotence of unions,
  monotonicity of security settings, determinism of a build).
- **Fuzzing** with `cargo fuzz` for every parser of untrusted input.

## Isolation

- Every test that touches the filesystem works in its own temporary directory and an isolated
  `HOME`; no test reads or writes the real home, caches or account folders.
- Build an `Env` value for the test; never mutate the process environment.
- Real temporary directories over mocked filesystems. Where a seam is needed, keep it narrow:
  `impl Read`/`impl Write`, a clock parameter, a capability value the test constructs.
- Clean up: rely on `tempfile`'s drop, so a run leaves nothing behind.

## Writing the test first

For a bug: write the test that fails, then fix. For a new rule: the test names the spec section
it proves. A test that cannot fail (asserts what the code just set) proves nothing.

## Running

`cargo nextest run` for speed and isolation, plus `cargo test --doc`. CI runs the full set with
`-D warnings` clippy and `cargo deny`.
