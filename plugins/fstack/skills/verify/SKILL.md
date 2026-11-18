---
name: verify
description: Prove a change works, split by role - workers write code and tests and run nothing, the orchestrator runs every check one run at a time through the lock, owns the single dev server and the merge train, and stops everything when done. Use for tests, bugs, anything that must be shown to work, and for integrating a batch of PRs.
user-invocable: false
---

# verify

Use the repo's own commands (its `AGENTS.md`, `package.json`, `Makefile`). Close
with the command and its result. Anything not run is NOT VERIFIED, with why.

## Worker (runs nothing)

Write the code and its tests: a bug fix comes with the test that should fail
before and pass after; UI comes with component tests and fixtures. Review it by
reading the diff. Run nothing: no tests, typecheck, lint, builds, installs,
servers, watchers, browsers or background processes. Commit, open the PR and end
it with a NOT VERIFIED list, pending the orchestrator: the exact commands to run
and, for UI, the routes, fixture flags and viewports to capture.

## Orchestrator

`scripts/devserver-lock.sh` (needs `FSTACK_ROLE=orchestrator`; lock and logs
under `~/.cache/fstack`, never in the repo):

1. Checks: `devserver-lock.sh run -- <command>` for each command the PR lists.
   One run at a time on this machine: a second run waits for the first
   (`FSTACK_RUN_WAIT` seconds, default 1800) or fails. When the command ends,
   everything it started is killed and the lock released.
2. Merge train: merge PR branches one at a time into an integration branch and
   run the checks after each, so a break has one owner.
3. One dev server per repo: `devserver-lock.sh start -- <dev command>` with
   `FSTACK_DEV_PORT`. It reuses a running server and never starts a second.
4. E2E and screenshots against it. UI screenshots: Playwright MCP if this session
   has it (`browser_emulate_media` with `colorScheme: dark`, `browser_resize`,
   `browser_navigate`, `browser_take_screenshot`), else the repo's own
   Playwright; never install or configure it in the repo. Capture what the
   worker handed over, dark first, at 360, 768 and 1280 unless asked otherwise,
   on the commit under review, and replace PENDING ORCHESTRATOR in the UI
   evidence block with results and links. With no way to capture, write NOT
   VISUALLY VERIFIED.
5. Send each failure back to the owning worker with the command and output; do
   not patch their piece. Stop after 3 failed rounds and tell Facundo.
6. Close everything: `devserver-lock.sh stop`, and `devserver-lock.sh status`
   shows no server and no run.

## Rules

- `set -o pipefail` in scripts. Flaky tests: no retries or sleeps; fix the race.
- Data work is done only against the real dev database, never mocks alone.
- Local dev never points at production.
