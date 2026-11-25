# Sources

Compiled 2026-11-22. Where sources disagree, this skill's choice is noted.

Primary skill and guideline sources:
- BeautifulRust (github.com/morganlinton/BeautifulRust): the backbone. Grounded in the canonical
  references, opinionated with reasons, separates application and library rules, ships a lint
  file. Not adopted: `exhaustive_enums` on every exported enum, nursery `redundant_clone`, a
  blanket "log, don't print" without the CLI stdout exception.
- rust-skills (claudemarketplace.net/skills/rust-skills; the repository lists 265 rules in 26
  categories, the marketplace page is older): used for coverage only. Not adopted: micro-
  optimisation crates ranked above API design, `panic = "abort"`/fat LTO/`target-cpu=native` as
  defaults, a prelude module, `impl Into<T>` everywhere, `mockall` as the default test seam,
  `mod.rs` files.
- Rustacean / Rust Brain (agricidaniel.github.io/rustacean): a large, edition-2024 knowledge base
  of notes; use it as a lookup by note name, not as rules.

Canonical references:
- Rust API Guidelines (rust-lang.github.io/api-guidelines): naming, conversions, common traits,
  documentation, constructors, encapsulation.
- Microsoft Pragmatic Rust Guidelines: workspace layout, lints, errors, panics, docs. Not
  adopted: `correctness` at warn (kept at deny), mimalloc by default for applications, canonical
  error structs instead of enums for small libraries.
- Rust Design Patterns (rust-unofficial.github.io/patterns): idioms, newtype, typestate-style
  builders, anti-patterns (clone to satisfy the borrow checker, `#![deny(warnings)]`, `Deref`
  polymorphism).
- Clippy lint index (rust-lang.github.io/rust-clippy): every lint named in this skill was checked
  against the stable index (Clippy 1.99).
- Alexis King, "Parse, don't validate"; Cliff Biffle, the typestate pattern; matklad, "Large Rust
  Workspaces"; the Rust CLI book; cargo-deny documentation; the Rust 2024 edition guide.
