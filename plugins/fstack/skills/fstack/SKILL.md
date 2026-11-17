---
name: fstack
description: Facundo's rules, the map of which fstack skill to load per task, the preamble for briefing another agent, and the optional AGENTS.md template. Use when Facundo types /fstack, when briefing another agent, or when he asks for an AGENTS.md.
---

# fstack

## Rules

1. Nothing is done without evidence: the command and its result, a test that
   failed and then passed. Anything unchecked is **NOT VERIFIED**, with why.
2. Roles. **Worker**: one worktree, one branch, one PR, never merge. Never start
   dev servers, watchers, browsers or background processes; install nothing
   global. Verify with types, lint, tests and component tests with fixtures.
   **Orchestrator** (one machine): owns the single dev server through the lock
   and runs the merge train (`fstack:verify`).
3. Clean repos: one short `AGENTS.md`, no stray markdown, no plans or reports
   committed as files (they go in the answer or the PR body). Comments explain
   why, not what. Fix the cause; no band-aid patches, no v2 next to v1.
4. UI uses the repo's real tokens and components, mockups included (`fstack:ui`).
5. Reports to Facundo are one screen, at most 5 items that need him, severity as
   icon plus word, never colour alone (`fstack:digest`).
6. No AI co-author trailers. Production, cost, merges and deploys only with
   Facundo's OK.
7. The repo's own `AGENTS.md` wins over these rules where they conflict. In
   repos Facundo shares with others, follow theirs and add nothing of fstack.

## Which skill

| Task | Skill |
| --- | --- |
| Screens, CSS, components, mockups, a visual reference | `fstack:ui` |
| Prove it works, tests, bugs, merge train, dev server | `fstack:verify` |
| Review or open a PR; endpoints, schema, infra, secrets | `fstack:review` |
| Report a PR or a batch to Facundo | `fstack:digest` |

## Machine config (optional)

`~/.config/fstack/config`, never in a repo, `key=value`: `role`, `machine`,
`orchestrator` and `worker` (host names for briefs). Without it, everything
works the same and the role comes from the brief (default worker).

## Briefing another agent

Start the brief with this block, slots filled from the config or by Facundo,
then the task, the evidence that closes it and what is out of scope.

```text
Machine: <host>. Role: <WORKER | ORCHESTRATOR>.
- WORKER: never start dev servers, watchers, browsers or background processes;
  install nothing global. Verify without a server: types, lint, tests, scripts.
- Read the repo's AGENTS.md first if it has one; it wins over this brief.
- Nothing is done without evidence; what you could not check is NOT VERIFIED.
- One worktree and branch; commit everything; open a PR, never merge.
- No AI co-author trailers; no report or plan files in the repo.
```

## AGENTS.md (only when Facundo asks, only in repos he controls)

Start from `assets/AGENTS.md`. If the repo already has one, propose only the
missing pieces as a diff for him to approve; never replace it. Fill slots from
the code, mark guesses NOT VERIFIED, and leave machine names and roles out.
