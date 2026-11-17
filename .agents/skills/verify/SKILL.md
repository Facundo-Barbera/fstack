---
name: verify
description: Set up and run a repo's two-level verify - worker checks without a server, orchestrator merge train with a single locked dev server, E2E and screenshots. Use for any task that must prove it works, for test and bug work, and when creating a repo's verify script.
---

# verify

The repo's AGENTS.md sets the test policy; this skill sets how it runs.
Start from `scripts/verify.template.sh` (copy it into the repo as its `verify`).

## Worker level (no server)

Types, lint, unit tests, property tests (fast-check, Hypothesis), contract tests.
Never start a dev server, watcher, browser or background process.

## Orchestrator level

1. Merge train: merge worker branches one by one into an integration branch;
   run worker-level checks after each merge so a breakage has one owner.
2. Start ONE dev server through the lock: `scripts/devserver-lock.sh`.
   Fixed port per repo, lockfile; if one is running, reuse or wait. Never open a
   second one.
3. Run E2E and screenshots against it.
4. Send each failure back to the owning worker with evidence (command, output,
   screenshot path). Do not patch their piece yourself.
5. Stop after 3 failed rounds and escalate to the owner.
6. Shut the server down and release the lock when done.

## Priorities

E2E first, then property tests, then differential tests (migrations: old vs new
schema on the same data).

## Rules

- `set -o pipefail` in every script, so a failing step in a pipe fails the run.
- Flaky tests: no retries, no sleeps. Fix the race or quarantine with an issue.
- "Done" on data work requires the real dev database; mocks alone never count.
- Local dev never points at production.
- Close with evidence: the command and its result. Anything unchecked is
  **NOT VERIFIED** with the reason.
