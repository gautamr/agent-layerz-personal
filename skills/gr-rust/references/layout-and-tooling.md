# Layout and tooling

Read this when creating a Rust project or workspace, adding a crate, or setting up lints and CI.

## Workspace

```text
repo/
├── Cargo.toml            # virtual manifest: [workspace], members = ["crates/*", "xtask"]
├── Cargo.lock            # committed for anything that ships a binary
├── rust-toolchain.toml   # pinned stable channel, components = ["rustfmt", "clippy"]
├── deny.toml             # cargo-deny
├── clippy.toml           # thresholds and test allowances
├── crates/
│   ├── <name>-core/      # pure domain, no effect dependencies
│   ├── <name>-io/        # effects behind capability types (only when the split is enforced)
│   └── <name>/           # the binary: CLI, wiring, rendering, exit codes
└── xtask/                # cargo xtask: automation in Rust instead of shell scripts
```

- Flat `crates/` folder; folder name equals crate name; unpublished crates `publish = false`.
- Start with one crate. Split only for an enforced boundary, a second consumer, or build time.
- Per crate: unit tests in `#[cfg(test)] mod tests`, integration tests in `tests/`, benchmarks in
  `benches/`, examples in `examples/`, fuzz targets in a top-level `fuzz/`.
- Test-only helpers in a `publish = false` support crate or behind a `test-util` feature.

## Root `Cargo.toml`

```toml
[workspace]
members = ["crates/*", "xtask"]
resolver = "3"

[workspace.package]
edition = "2024"
rust-version = "1.85"        # the declared MSRV; raise deliberately
license = "MIT"

[workspace.dependencies]
# one version per dependency, referenced from members with `dep.workspace = true`

[workspace.lints.rust]
unsafe_code = "forbid"
missing_docs = "warn"
missing_debug_implementations = "warn"
unused_lifetimes = "warn"
redundant_lifetimes = "warn"
trivial_numeric_casts = "warn"
unsafe_op_in_unsafe_fn = "warn"

[workspace.lints.clippy]
pedantic = { level = "warn", priority = -1 }
# selected restriction lints, each for a stated reason
unwrap_used = "warn"
panic_in_result_fn = "warn"
unwrap_in_result = "warn"
indexing_slicing = "warn"
string_slice = "warn"
allow_attributes = "warn"
allow_attributes_without_reason = "warn"
dbg_macro = "warn"
todo = "warn"
unimplemented = "warn"
print_stdout = "warn"
print_stderr = "warn"
exit = "warn"
as_conversions = "warn"
map_err_ignore = "warn"
let_underscore_must_use = "warn"
unused_result_ok = "warn"
mem_forget = "warn"
wildcard_enum_match_arm = "warn"
clone_on_ref_ptr = "warn"
rc_buffer = "warn"
undocumented_unsafe_blocks = "warn"
tests_outside_test_module = "warn"
```

Members add `[lints] workspace = true`. CI turns warnings into errors with `-D warnings`; source
never contains `#![deny(warnings)]`. Suppress a lint locally with
`#[expect(clippy::lint_name, reason = "…")]`, which fails once the lint no longer fires.

`clippy.toml`:

```toml
allow-unwrap-in-tests = true
allow-expect-in-tests = true
allow-print-in-tests = true
allow-indexing-slicing-in-tests = true
```

A pure core crate adds its own `clippy.toml` with `disallowed-methods` for `std::fs`,
`std::process` and `std::env` functions, so effects cannot creep in.

## CI

```text
cargo fmt --all --check
cargo clippy --workspace --all-targets --all-features -- -D warnings
cargo nextest run --workspace          # plus: cargo test --doc (nextest skips doc tests)
RUSTDOCFLAGS="-D warnings" cargo doc --workspace --no-deps
cargo deny check                       # licences, bans, advisories, sources
an MSRV job (pinned toolchain or cargo hack --rust-version)
Miri, only if any unsafe exists; cargo-semver-checks for published libraries
```

## Dependencies

Each new dependency is a recorded decision: what it does, why the standard library is not
enough, its maintenance state, licence and transitive weight. Prefer small, widely used crates;
check `cargo deny` before adding.

Common, well-maintained choices: `clap` (derive) for CLIs; `serde` with an actively maintained
format crate; `thiserror`; `anyhow` (binaries only); `cap-std` or `rustix` for safe directory
access; `tempfile`; `proptest`; `insta`; `assert_cmd` with `predicates` and `assert_fs`. Verify
maintenance state before relying on any crate (for example, `serde_yaml` is no longer maintained).

## Release profile

Measure before tuning. `lto = "thin"`, `codegen-units = 1` and `strip = true` are reasonable for
a CLI; avoid `target-cpu=native` (non-portable binaries) and consider `panic = "abort"` only with
its trade-offs understood.
