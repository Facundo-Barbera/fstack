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
- ${where} Workers never start dev servers, watchers, browsers or background jobs and install nothing global; they verify with types, lint, tests and component fixtures. Only the orchestrator runs the one locked dev server and the merge train.
- Nothing is done without evidence. Anything unchecked is reported as NOT VERIFIED, with why.
- Clean repos: one short AGENTS.md, no stray .md or report files, comments say why, fix causes instead of patching symptoms, reuse the repo's real design system. No AI co-author trailers.
- Load the skill for the task: screens, CSS, mockups -> fstack:ui; proving it works, tests, merge train, dev server -> fstack:verify; reviewing or opening a PR, secrets, infra -> fstack:review; reporting to Facundo -> fstack:digest; briefing another agent or an AGENTS.md -> fstack:fstack.
- Before editing any UI file (.tsx/.jsx/.vue/.svelte/.css, Tailwind, tokens) load fstack:ui, even if the brief already describes the design; UI reports end with its UI evidence block."

text=${text//\\/\\\\}
text=${text//\"/\\\"}
text=${text//$'\t'/ }
text=${text//$'\r'/}
text=${text//$'\n'/\\n}
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$text"
