---
name: verify
description: Prove a change works at the right level for the machine's role - workers without any server, the orchestrator with a merge train and the single locked dev server. Use for tests, bugs, anything that must be shown to work, and for integrating a batch of PRs.
user-invocable: false
---

# verify

Use the repo's own commands (its `AGENTS.md`, `package.json`, `Makefile`). Close
with the command and its result. Anything unchecked is NOT VERIFIED, with why.

## Worker (no server, ever)

Types, lint, unit and property tests, contract tests, component tests with
fixtures. A bug fix starts with a test that fails, then passes. If proof needs a
running app, hand the orchestrator the exact steps instead of starting one.

## Orchestrator

1. Merge train: merge PR branches one at a time into an integration branch and
   run the worker checks after each, so a break has one owner.
2. One dev server per repo, through the lock:
   `scripts/devserver-lock.sh start -- <dev command>` (needs `FSTACK_ROLE=orchestrator`
   and `FSTACK_DEV_PORT`). It reuses a running server and never starts a second.
   The lock and log live under `~/.cache/fstack`, never in the repo.
3. E2E and screenshots against it. Send each failure back to the owning worker
   with the command and output; do not patch their piece.
4. Stop after 3 failed rounds and tell Facundo. `devserver-lock.sh stop` when done.

## Rules

- `set -o pipefail` in scripts. Flaky tests: no retries or sleeps; fix the race.
- Data work is done only against the real dev database, never mocks alone.
- Local dev never points at production.
