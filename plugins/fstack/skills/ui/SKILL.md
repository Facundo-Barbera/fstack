---
name: ui
description: Mandatory before editing any UI file in Facundo's repos - .tsx, .jsx, .vue, .svelte, .css/.scss, Tailwind classes or config, theme or token files - and for mockups or prototypes, even when the brief already describes the design. Inventory the real design system, Facundo's colour-blind and dark-mode rules, prototypes inside the app, the tools to delegate to, and the UI evidence block without which UI work is not done.
user-invocable: false
---

# ui

## Before the first edit: inventory

Run `scripts/ui-check.sh inventory` (next to this file; read-only, bash 3.2,
git/grep/awk, and `cvd` also needs python3). It lists the Tailwind config and theme colours,
CSS variables and token files, `components.json` and the component folders. Build
with what it lists. A missing token or component goes into the token file or
component folder, never inline in a view.

## Facundo's rules

- He is colour-blind: meaning is never carried by colour alone. Every status,
  threshold or diff state also has an icon or a word.
- Dark mode is the default.
- Prototypes live inside the app (a prototype route, story or `?proto=` flag) with
  the real components and fixture data, and the chosen one moves to the real route.
  Never a standalone HTML mockup or an image.

## Who does what

- Worker: writes the code and proves it without a server (types, lint, component
  tests with fixtures, `ui-check.sh`). Hands over routes, flags and viewports.
- Orchestrator: the one locked dev server and the screenshots (`fstack:verify`).

## Delegate to existing tools

Use them if this session has them; if not, say so in the report and carry on. Never
install them from here and never write `.mcp.json` or any other config into the repo.

- `components.json` present: the shadcn MCP to browse, read and add registry
  components instead of hand-writing them.
- Accessibility and detail review: the `web-design-guidelines` skill (Vercel).
- `frontend-design` (Anthropic): only for a new screen in a repo with no design
  system. It fights an existing one.
- Screenshots: Playwright MCP, run by the orchestrator.

## Gate: UI evidence

UI work is not done until the report or PR body ends with this block:

```text
UI evidence
- ui-check diff: <clean | each finding with its reason>
- ui-check cvd: <BG and colours that carry meaning, worst ΔE and contrast | no meaningful colour changed>
- Screenshots (dark, orchestrator, this commit): <links | PENDING ORCHESTRATOR: routes, flags, viewports>
```

- `scripts/ui-check.sh diff [base]` checks committed, uncommitted and untracked
  changes. It ignores the repo's theme colours and the classes the base already uses.
- `scripts/ui-check.sh cvd BG HEX HEX...` takes the background first. Fix or justify
  any ΔE under 20 or contrast under 4.5 (3 for icons).
- A worker always writes PENDING ORCHESTRATOR, never "done". Screenshots from an
  older commit do not count.
