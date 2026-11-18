#!/usr/bin/env bash
# SessionStart: a few lines of rules plus which fstack skill to load. Pure bash so it
# stays fast and needs no jq. Reads ~/.config/fstack/config if present; writes nothing.

role="" machine=""
cfg=${FSTACK_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/fstack/config}
if [ -f "$cfg" ]; then
  while IFS='=' read -r k v; do
    case $k in role) role=$v ;; machine) machine=$v ;; esac
  done <"$cfg"
fi

if [ -n "$role" ]; then
  where="This machine: ${machine:-unnamed}, role ${role}. A role in the brief wins."
else
  where="Role: what the brief says; if it says nothing, act as worker."
fi

text="fstack (user plugin, writes nothing to this repo).
- ${where} A worker only writes code, reviews it by reading, commits and opens the PR. It runs nothing: no tests, typecheck, lint, builds, installs, dev servers, watchers, browsers or background jobs. The orchestrator runs the PR's checks one run at a time through devserver-lock.sh, owns the one dev server and stops everything when done.
- Nothing is done without evidence. Anything not run or checked is reported as NOT VERIFIED (a worker: pending the orchestrator, with the commands to run).
- Clean repos: one short AGENTS.md, no stray .md or report files, comments say why, fix causes instead of patching symptoms, reuse the repo's real design system. No AI co-author trailers.
- Load the skill for the task: screens, CSS, mockups -> fstack:ui; proving it works, tests, merge train, dev server -> fstack:verify; reviewing or opening a PR, secrets, infra -> fstack:review; reporting to Facundo -> fstack:digest; briefing another agent or an AGENTS.md -> fstack:fstack.
- Before editing any UI file (.tsx/.jsx/.vue/.svelte/.css, Tailwind, tokens) load fstack:ui, even if the brief already describes the design; UI reports end with its UI evidence block."

text=${text//\\/\\\\}
text=${text//\"/\\\"}
text=${text//$'\t'/ }
text=${text//$'\r'/}
text=${text//$'\n'/\\n}
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$text"
