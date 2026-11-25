# Errors and effects

Read this when designing error types, diagnostics, exit codes, or any code that touches files,
processes, the environment or the terminal.

## Error types

```rust
/// Errors reading a lock file.
#[derive(Debug, thiserror::Error)]
#[non_exhaustive]
pub enum LockError {
    #[error("cannot read the lock file")]
    Read(#[source] std::io::Error),
    #[error("the lock file is not valid YAML")]
    Syntax(#[source] YamlError),
    #[error("entry {index} has an invalid object id")]
    ObjectId { index: usize },
}
```

- One enum per boundary (a module or operation), not one crate-wide enum.
- `#[non_exhaustive]` on public error enums so adding a variant is not a breaking change.
- Messages: lower case, no trailing punctuation, no untrusted text.
- `#[source]` keeps the chain; `#[from]` only where the conversion is unambiguous.
- Callers that need to branch match variants; nobody parses `Display` text.

## Diagnostics versus errors

A tool that reports several problems in one run treats them as values:

```rust
pub struct Diagnostic { pub code: DiagnosticCode, pub message: String, pub at: Option<Location> }
pub struct Diagnostics(Vec<Diagnostic>);
```

Collect them, decide the outcome (`has_errors`), and render once in the binary. Reserve `Err` for
"cannot continue at all" (an I/O failure, a corrupted cache).

## The binary

```rust
fn main() -> std::process::ExitCode {
    let cli = Cli::parse();
    match alz::run(cli.into()) {
        Ok(outcome) => outcome.exit_code(),
        Err(err) => {
            render_error(&err); // one place, stderr, chain printed once
            ExitCode::from(70)
        }
    }
}
```

- Do not return `Result` from `main`: it prints the `Debug` form.
- Only `main` chooses the exit code; library code never calls `process::exit`.
- Write output through a locked, buffered handle with `writeln!` and treat
  `ErrorKind::BrokenPipe` as a quiet exit; `println!` panics when a pipe closes.

## Files

- Untrusted relative paths: check `Path::components()` and reject `ParentDir`, `RootDir`,
  `Prefix`; then open relative to a directory handle, not by joining strings.
- Directory-relative access: `cap_std::fs::Dir` (capability-scoped, blocks escapes) or `rustix`
  (`openat`, `O_NOFOLLOW`, `O_NONBLOCK`) when finer control is needed. Both are safe APIs, so the
  crate can keep `unsafe_code = "forbid"`.
- Canonicalise-then-check is a time-of-check/time-of-use race; prefer opening once and checking
  the handle (`fstat`).
- Exclusive creation: `File::create_new`. Atomic replace: write a temp file in the same directory,
  `fsync`, rename (`tempfile::NamedTempFile::new_in(dir)?.persist(target)`).
- Modes: create secrets-adjacent files with explicit permissions (`OpenOptionsExt::mode`) rather
  than relying on the umask.

## Processes

```rust
let status = Command::new("git")
    .args(["-c", "protocol.file.allow=never", "clone", "--quiet", "--"])
    .arg(&url)       // after `--`: cannot be parsed as an option
    .arg(&target)
    .env_remove("GIT_ALLOW_PROTOCOL")
    .stdin(Stdio::null())
    .status()?;
```

- Argument arrays, never a shell string.
- `--` before untrusted positionals.
- Decide the child environment explicitly.
- Check `status.success()` and capture stderr for the error, stripped of control characters.

## Environment and terminal

- Edition 2024 makes `std::env::set_var` and `remove_var` `unsafe`: take one `Env` snapshot at
  start and pass it down; tests build an `Env` value instead of mutating the process.
- Presence checks (`env.contains("NAME")`) when only existence matters; never read a value you
  do not need, especially ones that can hold secrets.
- `std::io::IsTerminal` for TTY checks; honour `NO_COLOR`.
