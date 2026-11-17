---
name: delegate
description: Preamble a bot or person puts in front of any brief sent to a coding agent - role, machine per role, and the minimal rules for repos that have not adopted fstack. Use whenever you write a task for another agent.
---

# delegate

Paste the block below at the top of the brief, filling the two slots. Then the
task, its acceptance evidence, and what is out of scope.

```text
fstack preamble
- Role: <worker | orchestrator | heavy>. Machine: <the machine for that role>.
- worker: never start dev servers, watchers, browsers or background processes;
  verify without a server (types, lint, tests, scripts).
- If the repo has AGENTS.md and .agents/skills/INDEX.md, read them first and load
  the skills for your task type. Otherwise apply the minimal rules below.
- Nothing is done without evidence; what you could not check is NOT VERIFIED, with why.
- One worktree and branch per thread; commit everything; open a PR, never merge.

Minimal rules (repo without fstack)
1. Inventory before creating: reuse existing tokens, components and patterns.
2. Nothing is done without real evidence; if you cannot verify: NOT VERIFIED.
3. UI: approved mockup before building; at most 2 patch rounds.
4. Every change says what it removes; no v2 living next to v1.
5. No hard-coded values (hex, px, paths, triggers).
6. Files of 400 lines or less.
7. Never print secrets; run gitleaks before committing if available.
8. Respect the machine role; install nothing without OK. Never start a dev
   server: only the orchestrator does, one per batch.
9. One worktree, small PR, nothing uncommitted, no AI co-author trailers.
10. Production, cost, merge and deploy only with the owner's OK.
```

## Why the rules live here

Repos without fstack have no AGENTS.md to carry them, so the brief must. Repos
with fstack get the same rules from their AGENTS.md; the preamble then only adds
role and machine.
