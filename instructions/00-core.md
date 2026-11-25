# Personal defaults (layer 1)

These apply in every project unless the client hub or the repository says otherwise.
Lower layers win only where they state an override explicitly.

## How I work
- Separate what the contract requires, what the code does now, and what you propose.
  Settle disagreements against current code and tests, not old docs.
- Read only the instructions and docs the task needs. Memory and notes are context,
  not proof of the current code or deployment.
- Preserve unrelated changes. One complete vertical change beats a broad migration.
- Never claim a check passed that you did not run. Keep completion states distinct:
  code changed, built, pushed, deployed.
- Ask before anything irreversible: deleting data, rewriting history, production
  changes, payments, publishing.

## Defaults for new projects
Existing repositories keep their configuration; these apply only when starting fresh.
- Runtimes through mise (`.mise.toml`), never global installs.
- Tooling, CLIs, libraries and services: Rust, idiomatic, with the toolchain pinned through
  mise. Follow the gr-rust skill; for business domains also gr-rust-domain.
- Frontends: Vite and Vue 3 with `<script setup lang="ts">`. TypeScript elsewhere only where a
  project needs it (TypeScript on Node.js, relative imports without `.js` extensions); follow
  the gr-typescript-domain skill.
- Prefer functional programming over imperative in every language: pure functions, immutable
  values, expressions, pipelines and algebraic data types, with effects at the edges.
  Imperative code needs a reason.
- Small cohesive files. Names from the business domain.

## Secrets
- Never read, print or commit `.env*` files, keys or tokens. Secrets live in
  gitignored `.env`, `.env.dev`, `.env.prod` files or a secret manager.

## Personal skills
Personal skills are prefixed `gr-`. Client profiles in `docs/standards/` (hub, then
repository) refine them; apply the most specific one.

## Agents and delivery
- Role agents (architect, backend-engineer, qa-engineer, reviewers, engineering-manager and
  others) come from this layer; client and repository layers specialise them with overlays.
- Task-driven work follows the delivery-protocol skill and the board-conventions skill. A
  project's delivery profile (a client board skill or `docs/standards/delivery.md`) refines both.

## Confidentiality
- Never write client or employer names, domains, emails, hostnames or people's identities
  into a repository, task, doc, test fixture, commit message or pull request, even when they
  appear in tool output. Write "a client" or describe the kind of thing instead.
- When you find such a value, tell me in the session and redact it from anything you write.
- Client facts live only in that client's private hub layer.
