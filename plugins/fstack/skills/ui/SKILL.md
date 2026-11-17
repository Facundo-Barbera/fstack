---
name: ui
description: UI work in Facundo's repos - inventory the real design system, follow a visual reference, mockups as 2-3 directions with real tokens, build rules (colour-blind safe, dark mode), verify by role and review for slop. Use for any task that touches screens, CSS, components or mockups.
user-invocable: false
---

# ui

## 1. Inventory first

Find the tokens (CSS variables, theme or Tailwind config), the components most
used, the routes and the product's words for its things. Reuse them; one concept,
one name. A missing token or component is proposed as an addition, never inlined.
`git grep -nE '#[0-9a-fA-F]{3,6}\b|\[[0-9]+px\]'` shows raw values to avoid.

## 2. Reference

If Facundo sent a screenshot or URL, open it and cite it. If you cannot open it,
say NOT VERIFIED and ask for a screenshot. Take layout, density and hierarchy from
it in numbers, mapped to the nearest token. It outranks your taste.

## 3. Mockups

New screens or redesigns: 2-3 directions that differ in structure (table, cards,
split), built with the repo's real tokens and components on a prototype route or
story, with realistic fixtures (long names, empty, error). Never generic HTML.
Facundo picks before anything is built; the losers are deleted in the same PR.

## 4. Build rules

- Tokens only: no raw hex, rgb or pixel values outside token files.
- Meaning never by colour alone: pair it with an icon or a word. Facundo is
  colour-blind; avoid red/green as the only contrast.
- Dark mode works (default if the repo has no preference). Text through i18n if
  the repo has it.
- Calm: no boxes in boxes, no gratuitous gradients, glows or decorative icons.
  Affordances visible without hover.
- A replacement deletes what it replaces in the same PR.

## 5. Verify

- Worker: typecheck, lint, component tests with fixtures (empty, loading, error,
  long text, many items). Report "visual check pending orchestrator" with the
  routes and fixtures to capture.
- Orchestrator: on the one locked dev server, screenshots at 360, 768 and 1280,
  dark first. If not seen, write NOT VISUALLY VERIFIED.
- At most 2 rounds of visual patches. If round 2 does not converge, stop and
  diagnose the layout, then propose a new mockup.

## 6. Review (own diff or a PR)

Flag: slop from section 4, a second component that duplicates one that exists,
spacing that matches neither tokens nor the reference, contrast under WCAG AA,
controls without keyboard focus or accessible name. Rank as ⛔ Blocks, ⚠ Review,
ℹ Note, with file:line.
