---
name: ui-build
description: Build UI with the repo's tokens and components under strict rules (no raw hex or pixel values, i18n, colour-blind safe, dark by default, calm layouts). Use when implementing any screen, component or style change.
---

# ui-build

## Rules

- Tokens only: no hex, rgb or `[Npx]` arbitrary values outside the token files.
- All user-facing text goes through i18n.
- Affordances are visible without hover: buttons look like buttons, links are
  marked, actions are not hidden until mouse-over.
- Meaning is never carried by colour alone: pair it with an icon, a label or a
  pattern. Use colour-blind-safe palettes (avoid red/green as the only contrast).
- Dark mode is the default; light mode must still work if the repo supports it.
- Calm by default: flat cards, one accent colour, no boxes inside boxes, no
  gratuitous gradients or decorative icons.
- One concept, one name, everywhere (see the vocabulary from `ui-adopt`).
- A v2 deletes the v1 in the same PR. No feature flags keeping both alive unless
  the owner asked for a staged rollout.
- Files stay under 400 lines; split components instead of growing them.

## Close

- PR body says what was removed (components, styles, routes, strings).
- Run `ui-verify` at your role's level.
