---
name: fstack-bots
description: Delegate, close and report work the fstack way
---

# fstack-bots

Use this skill when you write a brief for a coding agent, when a delegated
thread or task finishes, and when you report to Facundo. It carries the rules of
the fstack Claude Code plugin (`plugins/fstack` in
https://github.com/Facundo-Barbera/fstack) to long-lived bots.

## Machine roles

Read `~/.config/fstack/config` (`key=value`: `role`, `machine`, `orchestrator`,
`worker`) on the machine you run on. Never copy host names into a repo, a skill
or a public message. Without the file, ask once, remember the answer, and brief
as worker by default.

## Delegation brief

Start every brief with this block (copied from the fstack skill, section
"Briefing another agent"; keep both in sync), slots filled from the config:

```text
Machine: <host>. Role: <WORKER | ORCHESTRATOR>.
- WORKER: write the code, review it by reading, commit, open a PR, never merge.
  Run nothing: no tests, typecheck, lint, builds, installs, servers, watchers,
  browsers or background processes. Mark everything unexecuted NOT VERIFIED
  (pending the orchestrator) and list the exact commands to run.
- ORCHESTRATOR: run the PR's checks one run at a time with
  `devserver-lock.sh run -- <command>`, then stop every process you started.
- Read the repo's AGENTS.md first if it has one; it wins over this brief, except
  that a worker still runs nothing.
- Nothing is done without evidence; what was not run or checked is NOT VERIFIED.
- One worktree and branch; commit everything.
- No AI co-author trailers; no report or plan files in the repo.
```

Then add:

- Clean repo: comments say why, fix causes, reuse the repo's design system.
- The skill to load for the task when the agent has fstack: `fstack:ui`,
  `fstack:verify`, `fstack:review`, `fstack:digest`.
- The task, the evidence that closes it, and what is out of scope.
- Everything already decided, so the agent does not ask again.

Send it, end the turn, and wait for the agent's report. Do not poll.

## Closing a thread

When a delegated thread ends:

1. Keep the result: PR link, branch, head commit, checks, NOT VERIFIED items.
2. Close your own gaps first by reading: the PR, the diff, the NOT VERIFIED
   list. Tests and builds never run on a worker machine; the orchestrator runs
   them, one run at a time, so ask it for the run and report the result.
3. Clean up: stop processes, timers or watchers you started for it; archive or
   close the thread. Never discard unmerged work.

## Digest for Facundo

Short, product first, no file lists:

1. What changed, one or two sentences.
2. Decisions taken without him, one line of why each.
3. Needs your eye, at most 5, icon plus word (⛔ Blocks, ⚠ Review, ℹ Note),
   never colour alone. Always include security, data, production, money,
   irreversible steps, new dependencies and every NOT VERIFIED check.
4. Technical detail collapsed (commands and results), or omitted in chat.

For an HTML page use the fstack template
`plugins/fstack/skills/digest/assets/digest.html` from your fstack checkout,
copied outside any work repo. In chat, send the same blocks as text.

This skill writes nothing into work repos.
