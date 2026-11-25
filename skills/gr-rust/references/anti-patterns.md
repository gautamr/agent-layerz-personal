# Anti-patterns

Read this when reviewing Rust, and always when porting from TypeScript, JavaScript, Python or
Java. Each entry: the habit, why it hurts in Rust, and the Rust shape.

| Habit | Why it hurts | Rust shape |
| --- | --- | --- |
| Stringly typed data, string unions, `HashMap<String, Value>` as an object | No exhaustiveness, typos compile, every reader re-validates | Enums, newtypes, typed structs with `deny_unknown_fields` |
| Sentinel values (`-1`, `""`, a fake "null") | Indistinguishable from real values | `Option`, an enum variant |
| `unwrap()` used like TypeScript's `!` | Panics on the first unexpected input | `?` with typed errors; `expect` with a reason only for real invariants |
| Panics or `catch_unwind` as exceptions | Panics are for bugs; unwinding is not control flow | `Result`, diagnostics as values |
| Swallowing errors (`let _ =`, `.ok()`, `catch {}`) | Failures disappear | Handle, propagate or record; lints `let_underscore_must_use`, `unused_result_ok` |
| Class hierarchies through traits or `Deref` to a "base" struct | Rust has no inheritance; `Deref` polymorphism confuses method resolution | Enums for closed sets, composition plus small traits for open behaviour |
| Interfaces for everything, single-implementation traits, dependency-injection containers | Indirection without a second implementation | Concrete types first, then generics, then `dyn` when truly needed |
| Over-generic signatures (`impl Into<String> + AsRef<str> + Clone` everywhere) | Compile time, error messages, monomorphisation bloat | Concrete parameter types; `impl AsRef<Path>` where it really helps |
| `Box<dyn Error>` or `anyhow` in library APIs | Callers cannot match on failures | `thiserror` enums per boundary |
| Mocked filesystem traits (jest-style) | Tests prove the mock, not the behaviour | Pure core plus real temporary directories; narrow seams |
| `Arc<Mutex<T>>` or `Rc<RefCell<T>>` by default | Shared mutable state hides ownership and deadlocks | A single owner, message passing, `thread::scope`, restructured ownership |
| Async without concurrency | Runtime weight, coloured functions, blocking inside async | Synchronous code; async only for concurrent network I/O |
| `.clone()` to quiet the borrow checker | Hides a design problem, costs allocations | Named bindings, `mem::take`, splitting borrows |
| Barrel files (`pub use foo::*`) | Unclear public paths, accidental API | Re-export items one by one; one public path per item |
| Getters and setters for every field | Ceremony without invariants | Private fields with methods that keep invariants; public fields only for plain data |
| `utils.rs`, `helpers.rs`, `Manager`, `Service`, `Factory` | Names that say nothing about the domain | Modules and types named after the domain |
| Bags of `Option` fields (TypeScript `Partial<T>`) | Most combinations are meaningless | An enum of the real shapes |
| Numeric enums with `as` casts, float `==` | Truncation, sign loss, NaN surprises | `TryFrom`, `#[repr]` only at FFI boundaries, approximate comparison |
| Mutating the process environment in tests | Data races; `unsafe` in edition 2024 | An `Env` value passed in |
| `HashMap` in anything serialised or printed | Nondeterministic output | `BTreeMap`, `IndexMap` |
